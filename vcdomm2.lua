local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local localPlayer = Players.LocalPlayer

-- Wrap module loading in wait-loops to prevent initial execution crashes
local modules = ReplicatedStorage:WaitForChild("Modules", 10)
local tradeModule = require(modules:WaitForChild("TradeModule"))
local inventoryModule = require(modules:WaitForChild("InventoryModule"))
local itemModule = require(modules:WaitForChild("ItemModule"))
local profileData = require(modules:WaitForChild("ProfileData"))
local sync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
local itemPopupService = require(ReplicatedStorage:WaitForChild("ClientServices"):WaitForChild("ItemPopupService"))

-- Create the required Server Communication RemoteEvent dynamically if it doesn't exist
local changeEvent = ReplicatedStorage:FindFirstChild("ChangeAppearanceEvent")
if not changeEvent then
	changeEvent = Instance.new("RemoteEvent")
	changeEvent.Name = "ChangeAppearanceEvent"
	changeEvent.Parent = ReplicatedStorage
end

-- ==================== HAX4YOU COMPACT THEME VARS ====================
local Theme = {
	MainBackground = Color3.fromRGB(15, 15, 18),
	TopBarBackground = Color3.fromRGB(22, 22, 26),
	ButtonBackground = Color3.fromRGB(28, 28, 34),
	ButtonHover = Color3.fromRGB(38, 38, 46),
	AccentColor = Color3.fromRGB(0, 229, 255), -- Tech Cyan Accent
	TextColor = Color3.fromRGB(240, 240, 245),
	SecondaryText = Color3.fromRGB(150, 150, 160),
	CornerRadius = UDim.new(0, 4), -- Sharp corners
}

-- Massive randomized pool of realistic Roblox usernames / display names
local RANDOM_USERNAMES = {
	"VibeCheck_99", "iX3_Shadow", "Silent_Aura", "StarlightGlimmer", "Toxic_Viper",
	"Kryptic_Dev", "DeltaV_0", "Luna_Eclipse", "Hyper_Active", "NovaStrike",
	"Blaze_Furry", "Frostbite_YT", "Alpha_Omega", "Xeno_Morph", "Cosmic_Dust",
	"Vortex_Gamer", "Nebula_Rider", "Solar_Flare", "Midnight_Run", "Ghost_Rider",
	"Shadow_Ninja", "Crimson_Blade", "Aqua_Marine", "Terra_Form", "Pyro_Maniac",
	"Electro_Shock", "Wind_Walker", "Iron_Clad", "Steel_Heart", "Golden_Boy",
	"Silver_Surfer", "Bronze_Bomber", "Diamond_Eye", "Emerald_King", "Ruby_Rose",
	"Sapphire_Blue", "Topaz_Gem", "Amethyst_Crystal", "Onyx_Stone", "Pearl_White",
	"Opall_Shine", "Jade_Dragon", "Amber_Glow", "Quartz_Spark", "Garnet_Red",
	"Peridot_Green", "Citrine_Yellow", "Tanzanite_Rare", "Zircon_Bright", "Spinel_Pink",
	"Tourmaline_Mix", "Moonstone_Soft", "Sunstone_Hot", "Bloodstone_Dark", "Malachite_Wave",
	"Azurite_Deep", "Lapis_Lazuli", "Turquoise_Sky", "Sodalite_Blue", "Fluorite_Color",
	"Calcite_Clear", "Aragonite_Star", "Wulfenite_Orange", "Pyromorphite_Green", "Vanadinite_Red",
	"Crocoite_Bright", "Dioptase_Emerald", "Chrysocolla_Cyan", "Rhodochrosite_Pink", "Cobaltocalcite",
	"Smithsonite_Blue", "Hemimorphite_Ice", "Prehnite_Light", "Datolite_White", "Axinite_Brown",
	"Titanite_Green", "Benitoite_Rare", "Neptunite_Black", "Joaquinite_Yellow", "Serandite_Orange",
	"Pectolite_Blue", "Inesite_Red", "Hureaulite_Pink", "Strengite_Purple", "Variscite_Green",
	"Wavellite_Radial", "Turquoise_Classic", "Chalcociderite", "Faustite_Apple", "Planerite_Alum",
	"Coeruleolactite", "Andradite_Demantoid", "Grossular_Tsavorite", "Pyrope_Chrome", "Spessartine_Mandarin",
	"Almandine_Classic", "Uvarovite_Green", "Schorl_Black", "Dravite_Brown", "Elbaite_Rubellite",
	"Indicolite_Blue", "Verdelite_Green", "Achroite_Clear", "Povondraite", "Chromdravite"
}

local function GetRandomPlayerName()
	return RANDOM_USERNAMES[math.random(1, #RANDOM_USERNAMES)]
end

local PLACEHOLDER_SENDER_NAME = GetRandomPlayerName()
local localOffer = {}
local theirOffer = {}
local localAcceptMode = "Accept"
local localConfirmStartedAt = 0
local cooldownEndsAt = 0
local cooldownSequence = 0
local otherAcceptSequence = 0
local redrawLocalTrade
local resetAcceptUi
local showIncomingTradeRequest
local installRequestAcceptBridge
local refreshMainInventoryItem

local function cleanupOldOverlays()
	local gui = tradeModule.GUI
	if not gui then return end
	for _, root in ipairs({ gui.RequestFrame, gui.TradeGUI }) do
		if root then
			for _, descendant in ipairs(root:GetDescendants()) do
				if descendant.Name == "ClientPlaceholderTradeRemove"
					or descendant.Name == "ClientPlaceholderTradeToggle"
					or descendant.Name == "ClientPlaceholderTradeAcceptBridge"
					or descendant.Name == "ClientPlaceholderTradeAcceptOverlay"
					or descendant.Name == "ClientPlaceholderTradeActionOverlay" then
					descendant:Destroy()
				end
			end
		end
	end
end

local function clearOfferSlots(offerFrame)
	if not offerFrame or not offerFrame:FindFirstChild("Container") then return end
	for index = 1, 4 do
		local slot = offerFrame.Container:FindFirstChild("NewItem" .. index)
		if slot then
			itemModule.DisplayItem(slot, nil)
			slot.Visible = false
		end
	end
end

local function copyItemData(itemId, itemType, amount)
	local source = sync[itemType] and sync[itemType][itemId]
	if not source then return nil end
	local data = {}
	for key, value in pairs(source) do data[key] = value end
	data.DataType = itemType
	data.Amount = amount or 1
	return data
end

local function getProfileOwnedTable(itemType)
	if itemType == "Weapons" or itemType == "Item" then
		return profileData.Weapons and profileData.Weapons.Owned
	elseif itemType == "Pets" then
		return profileData.Pets and profileData.Pets.Owned
	end
	local bucket = profileData[itemType]
	return bucket and bucket.Owned
end

local function applyInventoryDelta(itemId, itemType, delta)
	local owned = getProfileOwnedTable(itemType)
	if not owned then return end

	local current = tonumber(owned[itemId]) or 0
	local nextAmount = current + delta
	if nextAmount > 0 then
		owned[itemId] = nextAmount
	else
		owned[itemId] = nil
	end

	local tradeInventory = tradeModule.TradeInventory
	local entry = tradeInventory and tradeInventory.Data and tradeInventory.Data[itemType] and tradeInventory.Data[itemType].Current and tradeInventory.Data[itemType].Current[itemId]

	if entry then
		entry.Amount = math.max(0, (tonumber(entry.Amount) or current) + delta)
		if entry.Frame then
			if entry.Amount <= 0 then
				entry.Frame.Visible = false
			else
				local itemData = copyItemData(itemId, itemType, entry.Amount)
				if itemData then
					itemModule.DisplayItem(entry.Frame, itemData, nil, true)
				end
				entry.Frame.Visible = true
			end
		end
	end

	task.defer(function() refreshMainInventoryItem(itemId, itemType) end)
end

local function restoreLocalOfferToInventory()
	for _, offer in ipairs(localOffer) do
		applyInventoryDelta(offer.ItemID, offer.ItemType, offer.Amount or 1)
	end
	table.clear(localOffer)
end

local function addTheirOfferToInventory(offerList)
	for _, offer in ipairs(offerList or theirOffer) do
		applyInventoryDelta(offer.ItemID, offer.ItemType, offer.Amount or 1)
	end
end

local function getInventoryCategory(itemId, itemType)
	if itemType ~= "Weapons" and itemType ~= "Item" then return "Current" end
	local data = sync.Weapons and sync.Weapons[itemId]
	if not data then return "Current" end
	if data.Event == "Christmas" or data.Event == "Halloween" then return data.Event end
	return data.Season and "Current" or "Classic"
end

local refreshMainInventoryQueued = false

local function clearMainInventoryContainers()
	local gui = inventoryModule.GUI and inventoryModule.GUI.MyInventory
	if not gui or not gui.Main then return false end

	local blank = inventoryModule.CreateBlankInventoryTable()
	for itemType, categories in pairs(blank) do
		local typeFrame = gui.Main:FindFirstChild(itemType)
		local itemsContainer = typeFrame and typeFrame:FindFirstChild("Items") and typeFrame.Items:FindFirstChild("Container")
		if itemsContainer then
			for categoryName in pairs(categories) do
				local categoryFrame = itemsContainer:FindFirstChild(categoryName)
				if not categoryFrame and itemsContainer:FindFirstChild("Holiday") then
					local holiday = itemsContainer.Holiday:FindFirstChild("Container")
					categoryFrame = holiday and holiday:FindFirstChild(categoryName)
				end
				local container = categoryFrame and categoryFrame:FindFirstChild("Container")
				if container then container:ClearAllChildren() end
			end
		end
	end
	return true
end

-- ==================== NEW LOCAL EQUIPPING MATRIX ENGINE ====================
local CurrentLocalWeaponModels = { Knife = nil, Gun = nil }

local function RemoveLocalWeaponModel(weaponType)
	if CurrentLocalWeaponModels[weaponType] then
		pcall(function() CurrentLocalWeaponModels[weaponType]:Destroy() end)
		CurrentLocalWeaponModels[weaponType] = nil
	end
end

local function ForceLocalWeaponEquip(itemId, itemType)
	local itemData = sync[itemType] and sync[itemType][itemId]
	if not itemData then return end

	local weaponType = itemData.ItemType -- "Knife" or "Gun"
	if not weaponType then return end

	RemoveLocalWeaponModel(weaponType)

	local character = localPlayer.Character
	if not character then return end
	local hand = character:WaitForChild("RightHand", 5) or character:WaitForChild("Right Arm", 5)
	if not hand then return end

	-- Search game storage locations for the raw matching weapon model asset
	local targetModel = nil
	for _, container in ipairs({ ReplicatedStorage, game:GetService("Lighting") }) do
		local found = container:FindFirstChild(itemId, true) or container:FindFirstChild(itemData.ItemName or "", true)
		if found and (found:IsA("Model") or found:IsA("Tool")) then
			targetModel = found
			break
		end
	end

	if not targetModel then
		-- Fallback to general weapon blueprints folder if present
		local storage = ReplicatedStorage:FindFirstChild("Weapons") or ReplicatedStorage:FindFirstChild("WeaponModels")
		if storage then
			targetModel = storage:FindFirstChild(itemId) or storage:FindFirstChild(itemData.ItemName or "")
		end
	end

	if targetModel then
		local clone = targetModel:Clone()
		clone.Name = "LocalEquipped_" .. weaponType
		
		if clone:IsA("Tool") then
			-- Remove tool logic to prevent core inventory drop loops
			local handle = clone:FindFirstChild("Handle")
			if handle then
				clone = handle
				clone.Name = "LocalEquippedHandle_" .. weaponType
			end
		end

		-- Weld and scale the model into your screen character model's arm assembly
		if clone:IsA("BasePart") then
			clone.CanCollide = false
			clone.Parent = character
			
			local weld = Instance.new("ManualWeld")
			weld.Part0 = hand
			weld.Part1 = clone
			weld.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
			weld.Parent = clone
			
			CurrentLocalWeaponModels[weaponType] = clone
		elseif clone:IsA("Model") then
			local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
			if primary then
				clone.Parent = character
				primary.CanCollide = false
				
				local weld = Instance.new("ManualWeld")
				weld.Part0 = hand
				weld.Part1 = primary
				weld.C0 = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(-90), 0, 0)
				weld.Parent = primary
				
				for _, part in ipairs(clone:GetDescendants()) do
					if part:IsA("BasePart") then part.CanCollide = false end
				end
				CurrentLocalWeaponModels[weaponType] = clone
			end
		end
	end
end

local function InterceptEquipHooks(newInventory)
	-- Intercepts the generated UI buttons to override the default equip logic
	for itemType, subData in pairs(newInventory or {}) do
		if itemType == "Weapons" then
			for itemId, asset in pairs(subData) do
				local itemFrame = asset.Frame
				local equipBtn = itemFrame and (itemFrame:FindFirstChild("Equip") or itemFrame:FindFirstChild("Container") and itemFrame.Container:FindFirstChild("Equip"))
				if equipBtn and equipBtn:IsA("TextButton") then
					equipBtn.MouseButton1Click:Connect(function()
						task.defer(function()
							ForceLocalWeaponEquip(itemId, "Weapons")
						end)
					end)
				end
			end
		end
	end
end

local function refreshMainInventoryNow()
	local gui = inventoryModule.GUI and inventoryModule.GUI.MyInventory
	if not gui or not gui.Main then return end
	if not clearMainInventoryContainers() then return end

	local ok, newInventory = pcall(function() return inventoryModule.GenerateInventory(gui, profileData) end)
	if not ok then return end

	inventoryModule.MyInventory = newInventory
	pcall(function() inventoryModule.ConnectEquipButtons() end)
	pcall(function() inventoryModule.UpdateMyEquip() end)
	
	-- Fire local renderer attachment hooks
	pcall(InterceptEquipHooks, newInventory)
end
-- ===========================================================================

refreshMainInventoryItem = function()
	if refreshMainInventoryQueued then return end
	refreshMainInventoryQueued = true
	task.defer(function()
		refreshMainInventoryQueued = false
		refreshMainInventoryNow()
	end)
end

local function setLocalAcceptState(mode)
	local actions = tradeModule.GUI.Actions
	local accept = actions and actions:FindFirstChild("Accept")
	if not accept then return end

	localAcceptMode = mode
	if accept:FindFirstChild("Confirm") then accept.Confirm.Visible = mode == "Confirm" end
	if accept:FindFirstChild("Cancel") then accept.Cancel.Visible = mode == "Waiting" or mode == "BothAccepted" end
	if accept:FindFirstChild("Cooldown") and mode ~= "Cooldown" then accept.Cooldown.Visible = false end
	if tradeModule.GUI.YourOffer:FindFirstChild("Accepted") then tradeModule.GUI.YourOffer.Accepted.Visible = mode == "Waiting" or mode == "BothAccepted" end
	if tradeModule.GUI.TheirOffer:FindFirstChild("Accepted") then tradeModule.GUI.TheirOffer.Accepted.Visible = mode == "BothAccepted" end
end

local function promptReceivedTheirOfferItems(offerList)
	for _, offer in ipairs(offerList or theirOffer) do
		pcall(function() itemPopupService:AddNewItem(offer.ItemID, offer.ItemType, offer.Amount or 1) end)
	end
end

local function scheduleOtherSideAccept()
	otherAcceptSequence += 1
	local sequence = otherAcceptSequence
	local delaySeconds = math.random(10, 30) / 10

	task.delay(delaySeconds, function()
		if sequence ~= otherAcceptSequence or localAcceptMode ~= "Waiting" then return end
		if tradeModule.GUI.TheirOffer:FindFirstChild("Accepted") then tradeModule.GUI.TheirOffer.Accepted.Visible = true end

		task.delay(1, function()
			if sequence ~= otherAcceptSequence or localAcceptMode ~= "Waiting" then return end
			local tradeGui = tradeModule.GUI.TradeGUI
			local receivedItems = {}
			for _, offer in ipairs(theirOffer) do
				table.insert(receivedItems, { ItemID = offer.ItemID, ItemType = offer.ItemType, Amount = offer.Amount or 1 })
			end
			tradeGui.Enabled = false
			addTheirOfferToInventory(receivedItems)
			refreshMainInventoryItem()
			promptReceivedTheirOfferItems(receivedItems)
			tradeModule.TradeInventory = nil
			table.clear(localOffer)
			table.clear(theirOffer)
			resetAcceptUi()
			clearOfferSlots(tradeModule.GUI.YourOffer)
			clearOfferSlots(tradeModule.GUI.TheirOffer)
			installRequestAcceptBridge()
		end)
	end)
end

local function startAcceptCooldown(seconds)
	local actions = tradeModule.GUI.Actions
	local accept = actions and actions:FindFirstChild("Accept")
	local cooldown = accept and accept:FindFirstChild("Cooldown")
	local title = cooldown and cooldown:FindFirstChild("Title")
	if not cooldown then return end

	cooldownSequence += 1
	local sequence = cooldownSequence
	cooldownEndsAt = time() + seconds
	localAcceptMode = "Cooldown"

	if accept:FindFirstChild("Confirm") then accept.Confirm.Visible = false end
	if accept:FindFirstChild("Cancel") then accept.Cancel.Visible = false end
	if tradeModule.GUI.YourOffer:FindFirstChild("Accepted") then tradeModule.GUI.YourOffer.Accepted.Visible = false end
	cooldown.Visible = true

	task.spawn(function()
		while sequence == cooldownSequence do
			local remaining = math.max(0, math.ceil(cooldownEndsAt - time()))
			if title then title.Text = ("Please wait (%d) before accepting."):format(remaining) end
			if remaining <= 0 then break end
			task.wait(0.2)
		end
		if sequence == cooldownSequence then
			cooldown.Visible = false
			localAcceptMode = "Accept"
		end
	end)
end

resetAcceptUi = function()
	cooldownSequence += 1
	otherAcceptSequence += 1
	cooldownEndsAt = 0
	setLocalAcceptState("Accept")
	local actions = tradeModule.GUI.Actions
	if actions and actions:FindFirstChild("oldconfirm") then actions.oldconfirm.Visible = false end
end

local function installOfferRemoveButtons()
	local yourOffer = tradeModule.GUI.YourOffer
	if not yourOffer or not yourOffer:FindFirstChild("Container") then return end
	for index = 1, 4 do
		local slot = yourOffer.Container:FindFirstChild("NewItem" .. index)
		if slot then
			local oldOverlay = slot:FindFirstChild("ClientPlaceholderTradeRemove")
			if oldOverlay then oldOverlay:Destroy() end

			if localOffer[index] then
				local overlay = Instance.new("TextButton")
				overlay.Name = "ClientPlaceholderTradeRemove"
				overlay.BackgroundTransparency = 1
				overlay.Text = ""
				overlay.Size = UDim2.fromScale(1, 1)
				overlay.ZIndex = slot.ZIndex + 50
				overlay.Parent = slot
				overlay.MouseButton1Click:Connect(function()
					local removed = table.remove(localOffer, index)
					if removed then applyInventoryDelta(removed.ItemID, removed.ItemType, removed.Amount or 1) end
					if redrawLocalTrade then redrawLocalTrade() end
				end)
			end
		end
	end
end

local function drawOfferSlots(offerFrame, offerList)
	clearOfferSlots(offerFrame)
	for index, offer in ipairs(offerList) do
		local slot = offerFrame and offerFrame:FindFirstChild("Container") and offerFrame.Container:FindFirstChild("NewItem" .. index)
		local itemData = copyItemData(offer.ItemID, offer.ItemType, offer.Amount)
		if slot and itemData then
			itemModule.DisplayItem(slot, itemData)
			slot.Visible = true
		end
	end
end

redrawLocalTrade = function()
	drawOfferSlots(tradeModule.GUI.YourOffer, localOffer)
	drawOfferSlots(tradeModule.GUI.TheirOffer, theirOffer)
	resetAcceptUi()
	tradeModule.GUI.TheirOffer.Username.Text = "(" .. PLACEHOLDER_SENDER_NAME .. ")"
	installOfferRemoveButtons()
end

local function toggleLocalOffer(itemId, itemType)
	for index, offer in ipairs(localOffer) do
		if offer.ItemID == itemId and offer.ItemType == itemType then
			local removed = table.remove(localOffer, index)
			if removed then applyInventoryDelta(removed.ItemID, removed.ItemType, removed.Amount or 1) end
			redrawLocalTrade()
			return
		end
	end
	if #localOffer >= 4 then return end
	table.insert(localOffer, { ItemID = itemId, Amount = 1, ItemType = itemType })
	applyInventoryDelta(itemId, itemType, -1)
	redrawLocalTrade()
	startAcceptCooldown(5)
end

local function getRandomGodlyWeapon()
	local candidates = {}
	for itemId, data in pairs(sync.Weapons or {}) do
		if type(data) == "table" and data.Rarity == "Godly" and (data.ItemType == "Knife" or data.ItemType == "Gun") then
			local displayName = data.ItemName or data.Name or itemId
			if displayName ~= "???" and itemId ~= "???" then
				table.insert(candidates, { ItemID = itemId, Amount = 1, ItemType = "Weapons" })
			end
		end
	end
	if #candidates < 1 then return nil end
	return candidates[math.random(1, #candidates)]
end

local function addRandomGodlyToTheirOffer()
	if not tradeModule.GUI.TradeGUI.Enabled then return end
	if #theirOffer >= 4 then return end
	local item = getRandomGodlyWeapon()
	if not item then return end

	table.insert(theirOffer, item)
	drawOfferSlots(tradeModule.GUI.TheirOffer, theirOffer)
	resetAcceptUi()
	tradeModule.GUI.TheirOffer.Username.Text = "(" .. PLACEHOLDER_SENDER_NAME .. ")"
	startAcceptCooldown(5)
end

local function removeLastTheirOffer()
	if not tradeModule.GUI.TradeGUI.Enabled then return end
	if #theirOffer < 1 then return end
	table.remove(theirOffer)
	drawOfferSlots(tradeModule.GUI.TheirOffer, theirOffer)
	resetAcceptUi()
	tradeModule.GUI.TheirOffer.Username.Text = "(" .. PLACEHOLDER_SENDER_NAME .. ")"
	startAcceptCooldown(5)
end

local function addOverlayClickTarget(parent, itemId, itemType)
	if not parent or not parent:IsA("GuiObject") then return end
	local oldOverlay = parent:FindFirstChild("ClientPlaceholderTradeToggle")
	if oldOverlay then oldOverlay:Destroy() end

	local overlay = Instance.new("TextButton")
	overlay.Name = "ClientPlaceholderTradeToggle"
	overlay.BackgroundTransparency = 1
	overlay.Text = ""
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = parent.ZIndex + 100
	overlay.Parent = parent
	overlay.MouseButton1Click:Connect(function() toggleLocalOffer(itemId, itemType) end)
end

local function addActionOverlay(parent, callback)
	if not parent or not parent:IsA("GuiObject") then return end
	local oldOverlay = parent:FindFirstChild("ClientPlaceholderTradeActionOverlay")
	if oldOverlay then oldOverlay:Destroy() end

	local overlay = Instance.new("TextButton")
	overlay.Name = "ClientPlaceholderTradeActionOverlay"
	overlay.BackgroundTransparency = 1
	overlay.Text = ""
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = parent.ZIndex + 100
	overlay.Parent = parent
	overlay.MouseButton1Click:Connect(callback)
end

local function installTradeActionButtons()
	local actions = tradeModule.GUI.Actions
	if not actions then return end
	local accept = actions:FindFirstChild("Accept")
	local decline = actions:FindFirstChild("Decline")

	if accept then
		addActionOverlay(accept:FindFirstChild("ActionButton"), function()
			if localAcceptMode == "Accept" and time() >= cooldownEndsAt then
				localConfirmStartedAt = time()
				setLocalAcceptState("Confirm")
			end
		end)
		local confirmButton = accept:FindFirstChild("Confirm") and accept.Confirm:FindFirstChild("ActionButton")
		addActionOverlay(confirmButton, function()
			if localAcceptMode == "Confirm" and time() - localConfirmStartedAt >= 0.4 then
				setLocalAcceptState("Waiting")
				scheduleOtherSideAccept()
			end
		end)
		local cancelButton = accept:FindFirstChild("Cancel") and accept.Cancel:FindFirstChild("ActionButton")
		addActionOverlay(cancelButton, function() resetAcceptUi() end)
	end

	if decline then
		addActionOverlay(decline:FindFirstChild("ActionButton"), function()
			tradeModule.GUI.TradeGUI.Enabled = false
			tradeModule.TradeInventory = nil
			restoreLocalOfferToInventory()
			table.clear(theirOffer)
			resetAcceptUi()
		end)
	end
end

local function installInventoryToggleButtons()
	local tradeInventory = tradeModule.TradeInventory
	if not tradeInventory or not tradeInventory.Data then return end
	for itemType, categories in pairs(tradeInventory.Data) do
		for _, items in pairs(categories) do
			for itemId, entry in pairs(items) do
				local frame = entry.Frame
				local actionButton = frame and frame:FindFirstChild("Container") and frame.Container:FindFirstChild("ActionButton")
				if actionButton and actionButton:IsA("GuiObject") then
					addOverlayClickTarget(actionButton, itemId, itemType)
				elseif frame and frame:IsA("GuiObject") then
					addOverlayClickTarget(frame, itemId, itemType)
				end
			end
		end
	end
end

local function openTradeFrameFromAccept()
	local tradeGui = tradeModule.GUI.TradeGUI
	local tradeContainer = tradeGui.Container
	restoreLocalOfferToInventory()
	table.clear(theirOffer)
	resetAcceptUi()

	for _, categoryName in ipairs({ "Weapons", "Pets" }) do
		local category = tradeContainer.Items.Main:FindFirstChild(categoryName)
		if category and category:FindFirstChild("Items") and category.Items:FindFirstChild("Container") then
			for _, section in ipairs(category.Items.Container:GetChildren()) do
				local container = section:FindFirstChild("Container")
				if container then container:ClearAllChildren() end
			end
		end
	end

	tradeModule.TradeInventory = inventoryModule.GenerateInventory(tradeContainer.Items, profileData, "Trading", tradeModule.GUI.ItemsLayout)
	tradeModule.ConnectOfferButtons(tradeModule.TradeInventory)
	redrawLocalTrade()

	tradeModule.GUI.TheirOffer.Username.Text = "(" .. PLACEHOLDER_SENDER_NAME .. ")"
	tradeModule.GUI.RequestFrame.Visible = false
	tradeGui.Enabled = true

	task.defer(installInventoryToggleButtons)
	task.delay(0.5, installInventoryToggleButtons)
	installTradeActionButtons()
end

local requestFrame = tradeModule.GUI.RequestFrame
local receivingRequest = requestFrame:WaitForChild("ReceivingRequest")
local acceptButton = receivingRequest:WaitForChild("Accept")
local requestAcceptSession = 0
local requestAcceptConnection

cleanupOldOverlays()

installRequestAcceptBridge = function()
	requestAcceptSession += 1
	local session = requestAcceptSession
	local opened = false

	if requestAcceptConnection then requestAcceptConnection:Disconnect() requestAcceptConnection = nil end
	local oldBridge = acceptButton:FindFirstChild("ClientPlaceholderTradeAcceptBridge")
	if oldBridge then oldBridge:Destroy() end
	local oldOverlay = acceptButton:FindFirstChild("ClientPlaceholderTradeAcceptOverlay")
	if oldOverlay then oldOverlay:Destroy() end

	local bridge = Instance.new("BoolValue")
	bridge.Name = "ClientPlaceholderTradeAcceptBridge"
	bridge.Parent = acceptButton

	local overlay = Instance.new("TextButton")
	overlay.Name = "ClientPlaceholderTradeAcceptOverlay"
	overlay.BackgroundTransparency = 1
	overlay.Text = ""
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.ZIndex = acceptButton.ZIndex + 100
	overlay.Parent = acceptButton

	local function openOnce()
		if opened or session ~= requestAcceptSession or not bridge.Parent then return end
		opened = true
		bridge:Destroy()
		if overlay.Parent then overlay:Destroy() end
		if requestAcceptConnection then requestAcceptConnection:Disconnect() requestAcceptConnection = nil end
		task.defer(openTradeFrameFromAccept)
	end

	overlay.MouseButton1Click:Connect(openOnce)
	requestAcceptConnection = acceptButton.MouseButton1Click:Connect(function() task.defer(openOnce) end)
end

showIncomingTradeRequest = function()
	PLACEHOLDER_SENDER_NAME = GetRandomPlayerName()
	installRequestAcceptBridge()
	tradeModule.UpdateTradeRequestWindow("ReceivingRequest", { Sender = { Name = PLACEHOLDER_SENDER_NAME } })
end

local currentWeaponAmount = 1

local function findWeaponInDatabase(weaponName)
	if not weaponName or weaponName == "" or weaponName == "???" then return nil end
	local searchName = tostring(weaponName):lower()

	local function search(container, itemType)
		for itemId, data in pairs(container or {}) do
			if type(data) == "table" then
				local displayName = data.ItemName or data.Name or itemId
				if displayName ~= "???" and itemId ~= "???" then
					local idText = tostring(itemId)
					if tostring(displayName):lower() == searchName or tostring(displayName):lower():find(searchName, 1, true) or idText:lower() == searchName or idText:lower():find(searchName, 1, true) then
						return itemId, itemType, displayName
					end
				end
			end
		end
	end

local itemId, itemType, displayName = search(sync.Weapons, "Weapons")
	if itemId then return itemId, itemType, displayName end
	return search(sync.Item, "Item")
end

local function spawnWeapon(weaponNameOrId, amount)
	if weaponNameOrId == "???" then return false end
	local itemId, itemType, displayName = findWeaponInDatabase(weaponNameOrId)
	if not itemId then return false end

	amount = math.max(1, tonumber(amount) or 1)
	local owned = getProfileOwnedTable(itemType)
	if not owned then return false end

	owned[itemId] = (tonumber(owned[itemId]) or 0) + amount
	refreshMainInventoryNow()

	for _ = 1, math.min(amount, 10) do
		pcall(function() itemPopupService:AddNewItem(itemId, itemType, 1) end)
	end
	return true
end

local function spawnWeaponById(itemId, itemType, amount)
	if itemId == "???" then return false end
	local itemData = sync[itemType] and sync[itemType][itemId]
	if not itemData then return false end
	
	local displayName = itemData.ItemName or itemData.Name or itemId
	if displayName == "???" then return false end

	amount = math.max(1, tonumber(amount) or 1)
	local owned = getProfileOwnedTable(itemType)
	if not owned then return false end

	owned[itemId] = (tonumber(owned[itemId]) or 0) + amount
	refreshMainInventoryNow()

	for _ = 1, math.min(amount, 10) do
		pcall(function() itemPopupService:AddNewItem(itemId, itemType, 1) end)
	end
	return true
end

local function spawnAllGodlyWeapons(amount)
	amount = math.max(1, tonumber(amount) or 1)
	local spawnedCount = 0
	local seen = {}

	local function collect(container, itemType)
		for itemId, data in pairs(container or {}) do
			if type(data) == "table" and (data.Rarity == "Godly" or data.Rarity == "Ancient") and not seen[itemId] then
				local displayName = data.ItemName or data.Name or itemId
				if displayName ~= "???" and itemId ~= "???" then
					seen[itemId] = true
					local owned = getProfileOwnedTable(itemType)
					if owned then
						owned[itemId] = (tonumber(owned[itemId]) or 0) + amount
						spawnedCount += 1
					end
				end
			end
		end
	end

	collect(sync.Weapons, "Weapons")
	collect(sync.Item, "Item")
	refreshMainInventoryNow()
	return spawnedCount
end

local function getRarityColor(rarity)
	local rarities = sync.Rarities or sync.Rarity
	local rarityData = rarities and rarities[rarity]
	if rarityData then
		if typeof(rarityData.Color) == "Color3" then return rarityData.Color end
		if type(rarityData.Hex) == "string" then
			local hex = rarityData.Hex:gsub("#", "")
			if #hex == 6 then
				return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
			end
		end
	end
	if rarity == "Ancient" then return Color3.fromRGB(255, 140, 0) end
	return Color3.fromRGB(0, 229, 255)
end

local function isSpawnerRarity(data)
	return data.Rarity == "Godly" or data.Rarity == "Ancient"
end

-- ==================== HAX4YOU COMPACT INTERFACE WINDOW ====================
local function GetSafeGuiParent()
	local successLayer, resultLayer = pcall(function() return CoreGui.Name end)
	return successLayer and CoreGui or localPlayer:WaitForChild("PlayerGui")
end

local oldUi = GetSafeGuiParent():FindFirstChild("SakaModMenu")
if oldUi then oldUi:Destroy() end

local SakaUI = Instance.new("ScreenGui")
SakaUI.Name = "SakaModMenu"
SakaUI.ResetOnSpawn = false -- CRITICAL: Prevents menu UI from wiping upon player death
SakaUI.Parent = GetSafeGuiParent()

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 310, 0, 410)
MainFrame.Position = UDim2.new(0.5, -155, 0.5, -205)
MainFrame.BackgroundColor3 = Theme.MainBackground
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = SakaUI

local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = Theme.CornerRadius

local BorderStroke = Instance.new("UIStroke", MainFrame)
BorderStroke.Color = Theme.AccentColor
BorderStroke.Thickness = 1
BorderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Theme.TopBarBackground
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner", TopBar)
TopBarCorner.CornerRadius = Theme.CornerRadius

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "t.me/v_cdo"
Title.TextColor3 = Theme.TextColor
Title.Font = Enum.Font.RobotoMono
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 35)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Theme.SecondaryText
CloseBtn.Font = Enum.Font.RobotoMono
CloseBtn.TextSize = 14
CloseBtn.Parent = TopBar

local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 40, 0, 40)
OpenBtn.Position = UDim2.new(0.05, 0, 0.1, 0)
OpenBtn.BackgroundColor3 = Theme.MainBackground
OpenBtn.Text = "+"
OpenBtn.TextColor3 = Theme.AccentColor
OpenBtn.Font = Enum.Font.RobotoMono
OpenBtn.TextSize = 18
OpenBtn.Visible = false
OpenBtn.Parent = SakaUI
OpenBtn.Active = true
OpenBtn.Draggable = true

local OpenCorner = Instance.new("UICorner", OpenBtn)
OpenCorner.CornerRadius = UDim.new(1, 0)

local OpenStroke = Instance.new("UIStroke", OpenBtn)
OpenStroke.Color = Theme.AccentColor
OpenStroke.Thickness = 1

CloseBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = true
	OpenBtn.Visible = false
end)

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -16, 0, 26)
TabContainer.Position = UDim2.new(0, 8, 0, 43)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout", TabContainer)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 4)

local function CreateTabBtn(text, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.25, -3, 1, 0)
	btn.BackgroundColor3 = Theme.ButtonBackground
	btn.Text = text
	btn.TextColor3 = Theme.TextColor
	btn.Font = Enum.Font.SourceSansSemibold
	btn.TextSize = 13
	btn.LayoutOrder = order
	btn.AutoButtonColor = false
	btn.Parent = TabContainer
	
	local btnCorner = Instance.new("UICorner", btn)
	btnCorner.CornerRadius = Theme.CornerRadius

	local btnStroke = Instance.new("UIStroke", btn)
	btnStroke.Color = Color3.fromRGB(45, 45, 52)
	btnStroke.Thickness = 1

	return btn
end

local SpawnerTabBtn = CreateTabBtn("Spawner", 1)
local TradeTabBtn = CreateTabBtn("Trade", 2)
local SettingsTabBtn = CreateTabBtn("Settings", 3)
local KeybindsTabBtn = CreateTabBtn("Keys", 4)

SpawnerTabBtn.UIStroke.Color = Theme.AccentColor

local function CreateTabFrame()
	local frame = Instance.new("ScrollingFrame")
	frame.Size = UDim2.new(1, -16, 1, -85)
	frame.Position = UDim2.new(0, 8, 0, 77)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ScrollBarThickness = 2
	frame.CanvasSize = UDim2.new(0, 0, 1.5, 0)
	frame.Visible = false
	frame.Parent = MainFrame
	frame.ScrollBarImageColor3 = Theme.AccentColor

	local list = Instance.new("UIListLayout", frame)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 6)
	return frame
end

local SpawnerFrame = CreateTabFrame(); SpawnerFrame.Visible = true
local TradeFrame = CreateTabFrame()
local SettingsFrame = CreateTabFrame()
local KeybindsFrame = CreateTabFrame()

local function CreateBox(parent, placeholder)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 30)
	box.BackgroundColor3 = Theme.ButtonBackground
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = Theme.SecondaryText
	box.Text = ""
	box.TextColor3 = Theme.TextColor
	box.Font = Enum.Font.SourceSans
	box.TextSize = 14
	box.Parent = parent
	
	local bc = Instance.new("UICorner", box)
	bc.CornerRadius = Theme.CornerRadius

	local boxStroke = Instance.new("UIStroke", box)
	boxStroke.Color = Color3.fromRGB(50, 50, 58)
	boxStroke.Thickness = 1

	return box
end

local function CreateBtn(parent, text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = Theme.ButtonBackground
	btn.Text = text
	btn.TextColor3 = Theme.TextColor
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 13
	btn.AutoButtonColor = false
	btn.Parent = parent
	
	local btnCorner = Instance.new("UICorner", btn)
	btnCorner.CornerRadius = Theme.CornerRadius

	local btnStroke = Instance.new("UIStroke", btn)
	btnStroke.Color = Color3.fromRGB(55, 55, 65)
	btnStroke.Thickness = 1

	btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Theme.ButtonHover end)
	btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Theme.ButtonBackground end)

	return btn
end

local function CreateSlider(parent, text, min, max, defaultVal, step, callback)
	local container = Instance.new("Frame", parent)
	container.Size = UDim2.new(1, 0, 0, 42)
	container.BackgroundTransparency = 1

	local label = Instance.new("TextLabel", container)
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Text = text .. ": " .. defaultVal
	label.Font = Enum.Font.SourceSansBold
	label.TextColor3 = Theme.TextColor
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left

	local bg = Instance.new("Frame", container)
	bg.Size = UDim2.new(1, -4, 0, 6)
	bg.Position = UDim2.new(0, 2, 0, 24)
	bg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame", bg)
	fill.BackgroundColor3 = Theme.AccentColor
	fill.Size = UDim2.new((defaultVal - min) / (max - min), 0, 1, 0)
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("TextButton", fill)
	knob.Size = UDim2.new(0, 12, 0, 12)
	knob.Position = UDim2.new(1, -6, 0.5, -6)
	knob.BackgroundColor3 = Theme.TextColor
	knob.Text = ""
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local dragging = false
	knob.MouseButton1Down:Connect(function() dragging = true end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local mousePos = UserInputService:GetMouseLocation().X
			local startX = bg.AbsolutePosition.X
			local percent = math.clamp((mousePos - startX) / bg.AbsoluteSize.X, 0, 1)
			local rawVal = min + ((max - min) * percent)
			local val = math.floor(rawVal / step + 0.5) * step
			val = math.clamp(val, min, max)
			fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
			label.Text = text .. ": " .. val
			callback(val)
		end
	end)
end

-- ==================== SPAWNER OVERLAY MATRIX PANEL ====================
local SPAWNER_COLS = 5
local SPAWNER_BOX_SIZE = 76
local SPAWNER_PADDING = 4
local SPAWNER_NAME_HEIGHT = 20
local SPAWNER_RARITY_HEIGHT = 16
local SPAWNER_SLIDER_HEIGHT = 45
local spawnerWidth = (SPAWNER_BOX_SIZE + SPAWNER_PADDING) * SPAWNER_COLS + SPAWNER_PADDING + 16

local SpawnerGuiFrame = Instance.new("Frame")
SpawnerGuiFrame.Name = "WeaponSpawnerGUI"
SpawnerGuiFrame.Size = UDim2.new(0, spawnerWidth, 0, 380)
SpawnerGuiFrame.Position = UDim2.new(0.5, -(spawnerWidth / 2), 0.5, -190)
SpawnerGuiFrame.BackgroundColor3 = Theme.MainBackground
SpawnerGuiFrame.BorderSizePixel = 0
SpawnerGuiFrame.Active = true
SpawnerGuiFrame.Draggable = true
SpawnerGuiFrame.Visible = false
SpawnerGuiFrame.Parent = SakaUI

Instance.new("UICorner", SpawnerGuiFrame).CornerRadius = Theme.CornerRadius

local PopupStroke = Instance.new("UIStroke", SpawnerGuiFrame)
PopupStroke.Color = Theme.AccentColor
PopupStroke.Thickness = 1

local PopupTitle = Instance.new("TextLabel")
PopupTitle.Size = UDim2.new(1, -40, 0, 30)
PopupTitle.Position = UDim2.new(0, 12, 0, 0)
PopupTitle.BackgroundTransparency = 1
PopupTitle.Text = "Weapon Matrix Spawner"
PopupTitle.TextColor3 = Theme.TextColor
PopupTitle.Font = Enum.Font.RobotoMono
PopupTitle.TextSize = 13
PopupTitle.TextXAlignment = Enum.TextXAlignment.Left
PopupTitle.Parent = SpawnerGuiFrame

local PopupCloseBtn = Instance.new("TextButton")
PopupCloseBtn.Size = UDim2.new(0, 30, 0, 30)
PopupCloseBtn.Position = UDim2.new(1, -30, 0, 0)
PopupCloseBtn.BackgroundTransparency = 1
PopupCloseBtn.Text = "X"
PopupCloseBtn.TextColor3 = Theme.SecondaryText
PopupCloseBtn.Font = Enum.Font.RobotoMono
PopupCloseBtn.TextSize = 13
PopupCloseBtn.Parent = SpawnerGuiFrame

PopupCloseBtn.MouseButton1Click:Connect(function() SpawnerGuiFrame.Visible = false end)

local WeaponScrollFrame = Instance.new("ScrollingFrame")
WeaponScrollFrame.Size = UDim2.new(1, -8, 1, -(40 + SPAWNER_SLIDER_HEIGHT))
WeaponScrollFrame.Position = UDim2.new(0, 4, 0, 34)
WeaponScrollFrame.BackgroundTransparency = 1
WeaponScrollFrame.BorderSizePixel = 0
WeaponScrollFrame.ScrollBarThickness = 2
WeaponScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
WeaponScrollFrame.ScrollBarImageColor3 = Theme.AccentColor
WeaponScrollFrame.Parent = SpawnerGuiFrame

local WeaponGrid = Instance.new("UIGridLayout", WeaponScrollFrame)
WeaponGrid.CellSize = UDim2.new(0, SPAWNER_BOX_SIZE, 0, SPAWNER_BOX_SIZE + SPAWNER_NAME_HEIGHT + SPAWNER_RARITY_HEIGHT)
WeaponGrid.CellPadding = UDim2.new(0, SPAWNER_PADDING, 0, SPAWNER_PADDING)
WeaponGrid.FillDirectionMaxCells = SPAWNER_COLS
WeaponGrid.SortOrder = Enum.SortOrder.LayoutOrder
WeaponGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center

WeaponGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	WeaponScrollFrame.CanvasSize = UDim2.new(0, 0, 0, WeaponGrid.AbsoluteContentSize.Y + 6)
end)

local PopupSliderFrame = Instance.new("Frame")
PopupSliderFrame.Size = UDim2.new(1, -12, 0, SPAWNER_SLIDER_HEIGHT)
PopupSliderFrame.Position = UDim2.new(0, 6, 1, -(SPAWNER_SLIDER_HEIGHT + 4))
PopupSliderFrame.BackgroundColor3 = Theme.TopBarBackground
PopupSliderFrame.BorderSizePixel = 0
PopupSliderFrame.Parent = SpawnerGuiFrame
Instance.new("UICorner", PopupSliderFrame).CornerRadius = Theme.CornerRadius

local PopupAmountLabel = Instance.new("TextLabel")
PopupAmountLabel.Size = UDim2.new(1, -12, 0, 16)
PopupAmountLabel.Position = UDim2.new(0, 6, 0, 4)
PopupAmountLabel.BackgroundTransparency = 1
PopupAmountLabel.Text = "Spawn Count: " .. currentWeaponAmount
PopupAmountLabel.TextColor3 = Theme.TextColor
PopupAmountLabel.Font = Enum.Font.SourceSansBold
PopupAmountLabel.TextSize = 12
PopupAmountLabel.TextXAlignment = Enum.TextXAlignment.Left
PopupAmountLabel.Parent = PopupSliderFrame

local PopupSliderTrack = Instance.new("Frame")
PopupSliderTrack.Size = UDim2.new(1, -16, 0, 5)
PopupSliderTrack.Position = UDim2.new(0, 8, 0, 26)
PopupSliderTrack.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
PopupSliderTrack.BorderSizePixel = 0
PopupSliderTrack.Parent = PopupSliderFrame
Instance.new("UICorner", PopupSliderTrack).CornerRadius = UDim.new(1, 0)

local PopupSliderFill = Instance.new("Frame")
PopupSliderFill.Size = UDim2.new(0, 0, 1, 0)
PopupSliderFill.BackgroundColor3 = Theme.AccentColor
PopupSliderFill.BorderSizePixel = 0
PopupSliderFill.Parent = PopupSliderTrack
Instance.new("UICorner", PopupSliderFill).CornerRadius = UDim.new(1, 0)

local PopupSliderKnob = Instance.new("TextButton")
PopupSliderKnob.Size = UDim2.new(0, 10, 0, 10)
PopupSliderKnob.Position = UDim2.new(0, -5, 0.5, -5)
PopupSliderKnob.BackgroundColor3 = Theme.TextColor
PopupSliderKnob.Text = ""
PopupSliderKnob.Parent = PopupSliderFill
Instance.new("UICorner", PopupSliderKnob).CornerRadius = UDim.new(1, 0)

local popupDraggingAmount = false

local function setPopupSpawnAmountFromPercent(percent)
	local minAmount = 1
	local maxAmount = 50
	percent = math.clamp(percent, 0, 1)
	local value = math.floor(minAmount + ((maxAmount - minAmount) * percent) + 0.5)
	value = math.clamp(value, minAmount, maxAmount)

	currentWeaponAmount = value
	PopupAmountLabel.Text = "Spawn Count: " .. value
	PopupSliderFill.Size = UDim2.new((value - minAmount) / (maxAmount - minAmount), 0, 1, 0)
end

PopupSliderKnob.MouseButton1Down:Connect(function() popupDraggingAmount = true end)
PopupSliderTrack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local percent = (UserInputService:GetMouseLocation().X - PopupSliderTrack.AbsolutePosition.X) / PopupSliderTrack.AbsoluteSize.X
		setPopupSpawnAmountFromPercent(percent)
		popupDraggingAmount = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		popupDraggingAmount = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if popupDraggingAmount and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local percent = (UserInputService:GetMouseLocation().X - PopupSliderTrack.AbsolutePosition.X) / PopupSliderTrack.AbsoluteSize.X
		setPopupSpawnAmountFromPercent(percent)
	end
end)

setPopupSpawnAmountFromPercent((currentWeaponAmount - 1) / 49)

local function AddWeaponBox(itemId, itemType, weaponName, rarity)
	local rarityColor = getRarityColor(rarity)
	local itemData = sync[itemType] and sync[itemType][itemId]

	local container = Instance.new("TextButton")
	container.Name = tostring(itemId)
	container.Size = UDim2.fromOffset(SPAWNER_BOX_SIZE, SPAWNER_BOX_SIZE + SPAWNER_NAME_HEIGHT + SPAWNER_RARITY_HEIGHT)
	container.BackgroundColor3 = Theme.ButtonBackground
	container.BorderSizePixel = 0
	container.Text = ""
	container.AutoButtonColor = false
	container.Parent = WeaponScrollFrame
	Instance.new("UICorner", container).CornerRadius = Theme.CornerRadius

	local stroke = Instance.new("UIStroke", container)
	stroke.Color = rarityColor
	stroke.Thickness = 1

	local thumbnail = Instance.new("ImageLabel")
	thumbnail.Size = UDim2.new(1, -6, 0, 56)
	thumbnail.Position = UDim2.new(0, 3, 0, 3)
	thumbnail.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	thumbnail.BorderSizePixel = 0
	thumbnail.Image = itemData and itemData.Image or ""
	thumbnail.ScaleType = Enum.ScaleType.Fit
	thumbnail.Parent = container
	Instance.new("UICorner", thumbnail).CornerRadius = Theme.CornerRadius

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, -4, 0, SPAWNER_RARITY_HEIGHT)
	rarityLabel.Position = UDim2.new(0, 2, 0, 61)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = rarity or "Unknown"
	rarityLabel.TextColor3 = rarityColor
	rarityLabel.Font = Enum.Font.SourceSansBold
	rarityLabel.TextSize = 11
	rarityLabel.TextTruncate = Enum.TextTruncate.AtEnd
	rarityLabel.Parent = container

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -4, 0, SPAWNER_NAME_HEIGHT)
	nameLabel.Position = UDim2.new(0, 2, 0, 77)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = weaponName or itemId
	nameLabel.TextColor3 = Theme.TextColor
	nameLabel.Font = Enum.Font.SourceSans
	nameLabel.TextSize = 11
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = container

	container.MouseButton1Click:Connect(function() spawnWeaponById(itemId, itemType, currentWeaponAmount) end)
end

local didPopulateWeaponSpawner = false
local function populateWeaponSpawner()
	if didPopulateWeaponSpawner then return end
	didPopulateWeaponSpawner = true

	local weapons = {}
	local seen = {}

	local function collect(container, itemType)
		for itemId, data in pairs(container or {}) do
			if type(data) == "table" and isSpawnerRarity(data) and not seen[itemId] then
				local displayName = data.ItemName or data.Name or itemId
				if displayName ~= "???" and itemId ~= "???" then
					seen[itemId] = true
					table.insert(weapons, {
						itemId = itemId,
						itemType = itemType,
						name = displayName,
						rarity = data.Rarity or "Unknown",
					})
				end
			end
		end
	end

	collect(sync.Weapons, "Weapons")
	collect(sync.Item, "Item")

	table.sort(weapons, function(a, b)
		if a.rarity == b.rarity then return a.name < b.name end
		if a.rarity == "Ancient" and b.rarity ~= "Ancient" then return true end
		return false
	end)

	for index, weapon in ipairs(weapons) do
		AddWeaponBox(weapon.itemId, weapon.itemType, weapon.name, weapon.rarity)
		local child = WeaponScrollFrame:FindFirstChild(tostring(weapon.itemId))
		if child then child.LayoutOrder = index end
	end
end

-- Assemble Core Tab Buttons
local SpecificWeaponBox = CreateBox(SpawnerFrame, "Input Weapon Name (e.g. Harvester)")
local SpawnSpecificBtn = CreateBtn(SpawnerFrame, "EXECUTE GENERATE")

CreateSlider(SpawnerFrame, "Weapon Multiplier", 1, 500, 1, 1, function(val)
	currentWeaponAmount = val
	setPopupSpawnAmountFromPercent((val - 1) / 499)
end)

local SpawnGodliesBtn = CreateBtn(SpawnerFrame, "SPAWN ALL CODES")
local OpenSpawnerGuiBtn = CreateBtn(SpawnerFrame, "OPEN MATRIX GUI")

SpawnSpecificBtn.MouseButton1Click:Connect(function()
	local weaponName = SpecificWeaponBox.Text
	if weaponName and weaponName ~= "" then
		local success = spawnWeapon(weaponName, currentWeaponAmount)
		if success then
			SpecificWeaponBox.Text = ""
			SpecificWeaponBox.PlaceholderText = "Executed successfully."
		else
			SpecificWeaponBox.PlaceholderText = "Invalid signature identification."
		end
		task.delay(2, function() SpecificWeaponBox.PlaceholderText = "Input Weapon Name (e.g. Harvester)" end)
	end
end)

SpawnGodliesBtn.MouseButton1Click:Connect(function()
	local count = spawnAllGodlyWeapons(currentWeaponAmount)
	if count > 0 then
		SpawnGodliesBtn.Text = "INJECTED " .. count .. " ITEMS"
		task.delay(2, function() SpawnGodliesBtn.Text = "SPAWN ALL CODES" end)
	end
end)

OpenSpawnerGuiBtn.MouseButton1Click:Connect(function()
	populateWeaponSpawner()
	SpawnerGuiFrame.Visible = not SpawnerGuiFrame.Visible
end)

-- Trade Hub Configuration Panel
local OpponentBox = CreateBox(TradeFrame, "Target User Profile (Blank=Random)")
local StartTradeBtn = CreateBtn(TradeFrame, "INITIALIZE INTERCEPT")
local AddRandomBtn = CreateBtn(TradeFrame, "FORCE INJECT GODLY")
local RemoveLastBtn = CreateBtn(TradeFrame, "DESTRUCT PREVIOUS")

StartTradeBtn.MouseButton1Click:Connect(showIncomingTradeRequest)
AddRandomBtn.MouseButton1Click:Connect(addRandomGodlyToTheirOffer)
RemoveLastBtn.MouseButton1Click:Connect(removeLastTheirOffer)

-- Micro Notification Setup 
local function ShowFriendJoinedPill(player)
	if not player then return end
	local SG = Instance.new("ScreenGui")
	SG.Name = "CustomPillNotification_" .. tostring(math.random(100000, 999999))
	SG.IgnoreGuiInset = true
	SG.DisplayOrder = 999999
	SG.Parent = GetSafeGuiParent()

	local rawText = "<b>" .. player.Name .. "</b> intercepted workspace"
	local font = Enum.Font.SourceSansBold
	local textSize = 13
	
	local params = GetTextBoundsParams.new()
	params.Text = rawText
	params.Font = Font.fromEnum(font)
	params.Size = textSize
	params.Width = 1000

	local calculatedTextSize = TextService:GetTextBoundsAsync(params)
	local exactPillWidth = 60 + calculatedTextSize.X

	local MainPill = Instance.new("Frame")
	MainPill.Parent = SG
	MainPill.Size = UDim2.new(0, exactPillWidth, 0, 32)
	MainPill.Position = UDim2.new(0.5, -exactPillWidth / 2, 0, -40)
	MainPill.BackgroundColor3 = Theme.TopBarBackground
	MainPill.BorderSizePixel = 0

	local Corner = Instance.new("UICorner", MainPill)
	Corner.CornerRadius = Theme.CornerRadius

	local NS = Instance.new("UIStroke", MainPill)
	NS.Color = Theme.AccentColor
	NS.Thickness = 1

	local Layout = Instance.new("UIListLayout", MainPill)
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.VerticalAlignment = Enum.VerticalAlignment.Center
	Layout.Padding = UDim.new(0, 8)

	local Padding = Instance.new("UIPadding", MainPill)
	Padding.PaddingLeft = UDim.new(0, 8)

	local Ring = Instance.new("Frame", MainPill)
	Ring.Size = UDim2.new(0, 18, 0, 18)
	Ring.BackgroundTransparency = 1
	Instance.new("UIStroke", Ring).Color = Theme.AccentColor

	local Avatar = Instance.new("ImageLabel", Ring)
	Avatar.Size = UDim2.new(1, 0, 1, 0)
	Avatar.BackgroundTransparency = 1
	Avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	Instance.new("UICorner", Avatar).CornerRadius = UDim.new(1, 0)

	local Text = Instance.new("TextLabel", MainPill)
	Text.BackgroundTransparency = 1
	Text.Size = UDim2.new(0, calculatedTextSize.X, 1, 0)
	Text.Font = font
	Text.RichText = true
	Text.TextSize = textSize
	Text.TextColor3 = Theme.TextColor
	Text.Text = rawText

	pcall(function()
		Avatar.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)

	TweenService:Create(MainPill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -exactPillWidth / 2, 0, 15) }):Play()
	task.delay(4, function()
		local close = TweenService:Create(MainPill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, -exactPillWidth / 2, 0, -40) })
		close:Play()
		close.Completed:Wait()
		SG:Destroy()
	end)
end

-- System Environment Global Toggles
local TradeReqToggleBtn = CreateBtn(SettingsFrame, "TRADE REQUEST : DISABLE")
local AutoTradeToggleBtn = CreateBtn(SettingsFrame, "AUTO TRADE : DISABLE")
CreateSlider(SettingsFrame, "Listener Sync Buffer", 30, 300, 30, 10, function(val) end)
local FriendJoinToggleBtn = CreateBtn(SettingsFrame, "AUTO JOINER : ACTIVE")

-- Outfit Changer System Integration
local OutfitChangerBox = CreateBox(SettingsFrame, "Input Outfit Username")
local ApplyOutfitBtn = CreateBtn(SettingsFrame, "APPLY OUTFIT PACKAGE")

ApplyOutfitBtn.MouseButton1Click:Connect(function()
	local targetUsername = OutfitChangerBox.Text
	if targetUsername and targetUsername ~= "" then
		changeEvent:FireServer(targetUsername)
		OutfitChangerBox.Text = ""
		OutfitChangerBox.PlaceholderText = "Outfit Change Requested..."
		task.delay(2, function() OutfitChangerBox.PlaceholderText = "Input Outfit Username" end)
	end
end)

local JOIN_VISUAL_ENABLED = true
local JOIN_VISUAL_DELAY = 30

FriendJoinToggleBtn.MouseButton1Click:Connect(function()
	JOIN_VISUAL_ENABLED = not JOIN_VISUAL_ENABLED
	FriendJoinToggleBtn.Text = "AUTO JOINER : " .. (JOIN_VISUAL_ENABLED and "ACTIVE" or "SILENT")
end)

task.spawn(function()
	while true do
		task.wait(JOIN_VISUAL_DELAY)
		if JOIN_VISUAL_ENABLED then
			local players = Players:GetPlayers()
			if #players > 0 then
				local randomPlayer
				repeat randomPlayer = players[math.random(1, #players)] until #players == 1 or randomPlayer ~= localPlayer
				ShowFriendJoinedPill(randomPlayer)
			end
		end
	end
end)

-- Keybind Registration Engine
local function CreateBindBtn(parent, displayName, bindName, currentHotkey)
	return CreateBtn(parent, displayName .. ": " .. (currentHotkey or "Unassigned"))
end

CreateBindBtn(KeybindsFrame, "ToggleUI")
CreateBindBtn(KeybindsFrame, "StartTrade", "StartTrade", "G")
CreateBindBtn(KeybindsFrame, "FriendJoined")
CreateBindBtn(KeybindsFrame, "SpawnAllWeapons")
CreateBindBtn(KeybindsFrame, "AddRandomWeapon")
CreateBindBtn(KeybindsFrame, "RemoveLastOffer", "RemoveLastOffer", "J")

local function SwitchTab(activeBtn, activeFrame)
	SpawnerFrame.Visible = false
	TradeFrame.Visible = false
	SettingsFrame.Visible = false
	KeybindsFrame.Visible = false

	SpawnerTabBtn.UIStroke.Color = Color3.fromRGB(45, 45, 52)
	TradeTabBtn.UIStroke.Color = Color3.fromRGB(45, 45, 52)
	SettingsTabBtn.UIStroke.Color = Color3.fromRGB(45, 45, 52)
	KeybindsTabBtn.UIStroke.Color = Color3.fromRGB(45, 45, 52)

	activeFrame.Visible = true
	activeBtn.UIStroke.Color = Theme.AccentColor
end

SpawnerTabBtn.MouseButton1Click:Connect(function() SwitchTab(SpawnerTabBtn, SpawnerFrame) end)
TradeTabBtn.MouseButton1Click:Connect(function() SwitchTab(TradeTabBtn, TradeFrame) end)
SettingsTabBtn.MouseButton1Click:Connect(function() SwitchTab(SettingsTabBtn, SettingsFrame) end)
KeybindsTabBtn.MouseButton1Click:Connect(function() SwitchTab(KeybindsTabBtn, KeybindsFrame) end)

-- Global Input Handler
if _G.ClientPlaceholderTradeKeybindConnection then _G.ClientPlaceholderTradeKeybindConnection:Disconnect() end
_G.ClientPlaceholderTradeKeybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or UserInputService:GetFocusedTextBox() then return end
	
	if input.KeyCode == Enum.KeyCode.G then 
		showIncomingTradeRequest()
	elseif input.KeyCode == Enum.KeyCode.J then 
		removeLastTheirOffer()
	end
end)

-- ==================== CRITICAL SPAWN PERSISTENCE HOOK LAYER ====================
local function handleCharacterInitialization(character)
	-- Remove older model memory instances right away to keep memory allocations clear
	RemoveLocalWeaponModel("Knife")
	RemoveLocalWeaponModel("Gun")

	task.spawn(function()
		-- Wait until core elements register in the new Workspace allocation safely
		character:WaitForChild("HumanoidRootPart", 10)
		task.wait(0.5)

		-- Force target overlays to wire back into the active interface context cleanly
		cleanupOldOverlays()
		installRequestAcceptBridge()
		refreshMainInventoryNow()
	end)
end

if localPlayer.Character then
	task.defer(handleCharacterInitialization, localPlayer.Character)
end

localPlayer.CharacterAdded:Connect(function(character)
	handleCharacterInitialization(character)
end)
-- ==============================================================================

_G.VipHubStartTradeRequest = showIncomingTradeRequest
_G.VipHubAddRandomTheirGodly = addRandomGodlyToTheirOffer
_G.VipHubRemoveLastTheirOffer = removeLastTheirOffer
_G.VipHubSpawnWeapon = spawnWeapon
_G.VipHubSpawnWeaponById = spawnWeaponById
_G.VipHubSpawnAllGodlies = spawnAllGodlyWeapons
_G.VipHubPopulateWeaponSpawner = populateWeaponSpawner
_G.VipHubAddWeaponBox = AddWeaponBox

print("[Hax4You System] Thread loaded safely with spawn persistence layer hooks attached.")