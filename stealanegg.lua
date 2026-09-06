local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local areas = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("Areas"))
local riftSpawnNotification = require(
    ReplicatedStorage:WaitForChild("Client"):WaitForChild("Notifications"):WaitForChild("RiftSpawn")
)
local messageNotification = require(
    ReplicatedStorage:WaitForChild("Client"):WaitForChild("Notifications"):WaitForChild("Message")
)
local smartProximityPrompt = require(
    ReplicatedStorage:WaitForChild("Client"):WaitForChild("SmartProximityPrompt")
)
local random = Random.new()
local ADMIN_USERNAME = "misfitsbsthree"
local ADMIN_USER_ID = 10751598093

-- ====== ADMIN AVATAR WITH NATURAL SCALING & LOWER POSITION ======
local identityState = _G.CartiAdminAbuseIdentityState or {}
if identityState.CharacterAddedConnection then
    identityState.CharacterAddedConnection:Disconnect()
end
_G.CartiAdminAbuseIdentityState = identityState

local function applyCreatorTag(character)
    local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 5)
    if not head then return false end
    
    local oldTag = head:FindFirstChild("CartiCreatorTag")
    if oldTag then oldTag:Destroy() end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CartiCreatorTag"
    billboard.Adornee = head
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 200
    billboard.Size = UDim2.fromOffset(160, 35)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.0, 0) -- Lowered from 3.5 to 2.0
    billboard.Parent = head
    
    local title = Instance.new("TextLabel")
    title.Name = "Creator"
    title.BackgroundTransparency = 1
    title.Size = UDim2.fromScale(1, 1)
    title.Font = Enum.Font.GothamBlack
    title.Text = "👑 CREATOR 👑"
    title.TextColor3 = Color3.fromRGB(239, 42, 54)
    title.TextSize = 18
    title.TextScaled = true
    title.TextStrokeColor3 = Color3.new(0, 0, 0)
    title.TextStrokeTransparency = 0
    title.Parent = billboard
    
    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.new(0, 0, 0)
    textStroke.Thickness = 1.5
    textStroke.Parent = title
    
    -- Update size based on distance for natural feel
    local connection
    connection = RunService.Heartbeat:Connect(function()
        if not head.Parent then
            connection:Disconnect()
            return
        end
        local distance = (head.Position - Camera.CFrame.Position).Magnitude
        local scale = math.clamp(30 / distance, 0.3, 1.8)
        billboard.Size = UDim2.fromOffset(160 * scale, 35 * scale)
        billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.0 * scale, 0)
    end)
    
    return true
end

local function clearAvatarAppearance(character)
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Accoutrement") or child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("BodyColors") or child:IsA("CharacterMesh") then
            child:Destroy()
        end
    end
end

local function findCharacterAttachment(character, attachmentName)
    for _, descendant in ipairs(character:GetDescendants()) do
        if descendant:IsA("Attachment") and descendant.Name == attachmentName then
            return descendant
        end
    end
    return nil
end

local function weldAvatarAccessory(accessory, character)
    local handle = accessory:FindFirstChild("Handle")
    if not (handle and handle:IsA("BasePart")) then return end
    handle.Anchored = false
    handle.CanCollide = false
    handle.Massless = true
    local handleAttachment = handle:FindFirstChildOfClass("Attachment")
    local characterAttachment = handleAttachment and findCharacterAttachment(character, handleAttachment.Name)
    local targetPart = characterAttachment and characterAttachment.Parent or character:FindFirstChild("Head")
    if not (targetPart and targetPart:IsA("BasePart")) then return end
    local weld = handle:FindFirstChild("AccessoryWeld") or Instance.new("Weld")
    weld.Name = "AccessoryWeld"
    weld.Part0 = handle
    weld.Part1 = targetPart
    if handleAttachment and characterAttachment then
        weld.C0 = handleAttachment.CFrame
        weld.C1 = characterAttachment.CFrame
    else
        weld.C0 = CFrame.new()
        weld.C1 = accessory.AttachmentPoint
        handle.CFrame = targetPart.CFrame * weld.C1
    end
    weld.Parent = handle
end

local function copyGeneratedAvatar(userId, character)
    local generatedOk, sourceModel = pcall(function()
        return Players:CreateHumanoidModelFromUserId(userId)
    end)
    if not generatedOk or not sourceModel then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local sourceHumanoid = sourceModel:FindFirstChildOfClass("Humanoid")
    clearAvatarAppearance(character)
    if humanoid and sourceHumanoid and humanoid.RigType == Enum.HumanoidRigType.R15 and sourceHumanoid.RigType == Enum.HumanoidRigType.R15 then
        local bodyParts = {
            Head = Enum.BodyPartR15.Head,
            UpperTorso = Enum.BodyPartR15.UpperTorso,
            LowerTorso = Enum.BodyPartR15.LowerTorso,
            LeftUpperArm = Enum.BodyPartR15.LeftUpperArm,
            LeftLowerArm = Enum.BodyPartR15.LeftLowerArm,
            LeftHand = Enum.BodyPartR15.LeftHand,
            RightUpperArm = Enum.BodyPartR15.RightUpperArm,
            RightLowerArm = Enum.BodyPartR15.RightLowerArm,
            RightHand = Enum.BodyPartR15.RightHand,
            LeftUpperLeg = Enum.BodyPartR15.LeftUpperLeg,
            LeftLowerLeg = Enum.BodyPartR15.LeftLowerLeg,
            LeftFoot = Enum.BodyPartR15.LeftFoot,
            RightUpperLeg = Enum.BodyPartR15.RightUpperLeg,
            RightLowerLeg = Enum.BodyPartR15.RightLowerLeg,
            RightFoot = Enum.BodyPartR15.RightFoot,
        }
        for partName, bodyPart in pairs(bodyParts) do
            local sourcePart = sourceModel:FindFirstChild(partName)
            if sourcePart and sourcePart:IsA("BasePart") then
                local replacement = sourcePart:Clone()
                replacement.Name = partName
                replacement.Anchored = false
                replacement.CanCollide = false
                pcall(function()
                    humanoid:ReplaceBodyPartR15(bodyPart, replacement)
                end)
            end
        end
    end
    for _, child in ipairs(sourceModel:GetChildren()) do
        if child:IsA("BodyColors") or child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or child:IsA("CharacterMesh") then
            child:Clone().Parent = character
        elseif child:IsA("Accessory") or child:IsA("Accoutrement") then
            local accessory = child:Clone()
            accessory.Parent = character
            weldAvatarAccessory(accessory, character)
        end
    end
    local sourceHead = sourceModel:FindFirstChild("Head")
    local targetHead = character:FindFirstChild("Head")
    if sourceHead and targetHead then
        for _, child in ipairs(targetHead:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                child:Destroy()
            end
        end
        for _, child in ipairs(sourceHead:GetChildren()) do
            if child:IsA("Decal") or child:IsA("Texture") then
                child:Clone().Parent = targetHead
            end
        end
    end
    sourceModel:Destroy()
    return true
end

local function applyAdminAvatar(character)
    character = character or localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    if not humanoid then return false end
    local descriptionOk, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(ADMIN_USER_ID)
    end)
    if not descriptionOk or not description then
        applyCreatorTag(character)
        return false
    end
    local applied = pcall(function()
        humanoid:ApplyDescriptionReset(description)
    end)
    if not applied then
        applied = pcall(function()
            humanoid:ApplyDescription(description)
        end)
    end
    local copied = copyGeneratedAvatar(ADMIN_USER_ID, character)
    task.defer(function()
        if character == localPlayer.Character then
            applyCreatorTag(character)
        end
    end)
    return applied or copied
end

identityState.CharacterAddedConnection = localPlayer.CharacterAdded:Connect(function(character)
    task.spawn(function()
        task.wait(0.35)
        if character == localPlayer.Character then
            applyAdminAvatar(character)
        end
    end)
end)
task.spawn(applyAdminAvatar, localPlayer.Character)

-- ====== DESTROY OLD UI ======
if _G.CartiAdminAbuseUI then
    pcall(function() _G.CartiAdminAbuseUI:Destroy() end)
end

-- ====== 20 USERNAMES ======
local usernamePool = {
    "tttooo_3838", "JJBUT5", "Lizzy25724", "BobdaCHIKEN2572", 
    "Nash2234247", "XccidentsX", "dropin6s", "Sofijaja1112",
    "Elsaannakommi", "Mamedov5778", "maltesergirl16", "Proinallgames198",
    "cucugto67", "carkaczX", "ellaminapina", "Leo444418",
    "Plutofn9", "beniza_4", "ghost_tricky123", "B0bbyBear1"
}
local poolIndex = 1
local cycleRunning = true
local cycleTask = nil

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end
shuffle(usernamePool)

-- ====== UI FUNCTIONS ======
local function create(className, properties, parent)
    local instance = Instance.new(className)
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    instance.Parent = parent
    return instance
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return create("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local COLORS = {
    panel = Color3.fromRGB(7, 6, 14),
    surface = Color3.fromRGB(29, 12, 54),
    purple = Color3.fromRGB(128, 31, 221),
    purpleBright = Color3.fromRGB(168, 45, 255),
    line = Color3.fromRGB(49, 27, 70),
    text = Color3.fromRGB(213, 190, 239),
    muted = Color3.fromRGB(148, 125, 170),
    white = Color3.fromRGB(239, 227, 248),
}

-- ====== FLOATING CIRCLE (always visible, draggable) ======
local floatingCircle = create("ImageButton", {
    Name = "FloatingCircle",
    Size = UDim2.fromOffset(50, 50),
    Position = UDim2.fromOffset(15, 100),
    BackgroundColor3 = COLORS.purple,
    Image = "rbxassetid://6031090678",
    ImageColor3 = COLORS.white,
    ImageTransparency = 0,
    ZIndex = 100,
    Visible = true,
    BackgroundTransparency = 0,
}, playerGui)
corner(floatingCircle, 25)
stroke(floatingCircle, COLORS.purpleBright, 0.5, 2.5)

-- Circle label
local circleLabel = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(50, 50),
    Font = Enum.Font.GothamBold,
    Text = "⚡",
    TextColor3 = COLORS.white,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 101,
}, floatingCircle)

-- ====== MAIN UI (RESIZED) ======
local gui = create("ScreenGui", {
    Name = "CartiAdminAbuseUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)
_G.CartiAdminAbuseUI = gui

local panel = create("Frame", {
    Name = "Panel",
    AnchorPoint = Vector2.new(0, 0),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(75, 100),
    Size = UDim2.fromOffset(190, 0),
    ClipsDescendants = true,
    Visible = true,
    ZIndex = 50,
    BackgroundTransparency = 0,
}, gui)
corner(panel, 10)
stroke(panel, Color3.fromRGB(38, 20, 55), 0.2, 1)

local content = create("Frame", {
    Name = "Content",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 0),
    ZIndex = 10,
}, panel)

local y = 0

-- Title with X close button
local titleFrame = create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, y),
    Size = UDim2.fromOffset(190, 28),
    ZIndex = 10,
}, content)

create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(160, 28),
    Font = Enum.Font.GothamBold,
    Text = "⚡ ADMIN",
    TextColor3 = COLORS.white,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 10,
}, titleFrame)

local closeBtn = create("TextButton", {
    Name = "CloseBtn",
    AutoButtonColor = false,
    BackgroundColor3 = Color3.fromRGB(60, 20, 30),
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(165, 2),
    Size = UDim2.fromOffset(24, 24),
    Font = Enum.Font.GothamBold,
    Text = "✕",
    TextColor3 = Color3.fromRGB(255, 100, 100),
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 10,
}, titleFrame)
corner(closeBtn, 12)
closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 30)
end)
closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 30)
end)

y = y + 32

-- Divider
create("Frame", {
    BackgroundColor3 = COLORS.line,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(8, y),
    Size = UDim2.new(1, -16, 0, 1),
}, content)
y = y + 6

-- Telegram link
create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, y),
    Size = UDim2.fromOffset(190, 16),
    Font = Enum.Font.Gotham,
    Text = "t.me/cookierealms",
    TextColor3 = COLORS.muted,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 10,
}, content)
y = y + 20

-- Quantity
local qRow = create("Frame", {
    BackgroundColor3 = COLORS.surface,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(8, y),
    Size = UDim2.fromOffset(174, 26),
}, content)
corner(qRow, 4)
create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(5, 0),
    Size = UDim2.fromOffset(50, 26),
    Font = Enum.Font.Gotham,
    Text = "Qty:",
    TextColor3 = COLORS.text,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
}, qRow)
local quantityInput = create("TextBox", {
    BackgroundColor3 = Color3.fromRGB(26, 10, 51),
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(55, 2),
    Size = UDim2.fromOffset(113, 22),
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    Text = "1",
    TextColor3 = COLORS.text,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 10,
}, qRow)
corner(quantityInput, 3)
y = y + 30

-- Player
local pRow = create("Frame", {
    BackgroundColor3 = COLORS.surface,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(8, y),
    Size = UDim2.fromOffset(174, 26),
}, content)
corner(pRow, 4)
create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(5, 0),
    Size = UDim2.fromOffset(50, 26),
    Font = Enum.Font.Gotham,
    Text = "Player:",
    TextColor3 = COLORS.text,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
}, pRow)
local playerInput = create("TextBox", {
    BackgroundColor3 = Color3.fromRGB(26, 10, 51),
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(55, 2),
    Size = UDim2.fromOffset(113, 22),
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    PlaceholderColor3 = COLORS.muted,
    PlaceholderText = "Username",
    Text = "",
    TextColor3 = COLORS.text,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 10,
}, pRow)
corner(playerInput, 3)
y = y + 30

-- Buttons
local function makeBtn(text, yPos)
    local btn = create("TextButton", {
        Name = text,
        AutoButtonColor = false,
        BackgroundColor3 = COLORS.surface,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, yPos),
        Size = UDim2.fromOffset(174, 24),
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = COLORS.text,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10,
    }, content)
    corner(btn, 4)
    stroke(btn, COLORS.line, 0.5, 1)
    create("UIPadding", { PaddingLeft = UDim.new(0, 6) }, btn)
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(45, 20, 75)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = COLORS.surface
    end)
    return btn
end

local btnSpawn = makeBtn("🥚 Spawn", y)
y = y + 28
local btnSpawnPlayer = makeBtn("📤 Spawn to Player", y)
y = y + 28
local btnSpawnServer = makeBtn("🌍 Spawn Server", y)
y = y + 28
local btnRift = makeBtn("🌌 Rift", y)
y = y + 28
local btnAdmin = makeBtn("👑 Give Admin", y)
y = y + 28

local botInput = create("TextBox", {
    BackgroundColor3 = COLORS.surface,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(8, y),
    Size = UDim2.fromOffset(174, 24),
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    PlaceholderColor3 = COLORS.muted,
    PlaceholderText = "Bot name",
    Text = "",
    TextColor3 = COLORS.text,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 10,
}, content)
corner(botInput, 4)
y = y + 28

local btnBot = makeBtn("🤖 Create Bot", y)
y = y + 28
local btnCycle = makeBtn("⏯️ Stop Cycle", y)
y = y + 28

local statusLabel = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(8, y),
    Size = UDim2.fromOffset(174, 16),
    Font = Enum.Font.Gotham,
    Text = "Cycle: Running",
    TextColor3 = COLORS.muted,
    TextSize = 8,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
}, content)
y = y + 18

content.Size = UDim2.new(1, 0, 0, y + 6)
panel.Size = UDim2.fromOffset(190, y + 6)

-- ====== TOGGLE LOGIC ======
local panelVisible = true
local circleSize = 50

-- Close button - shrinks to circle
closeBtn.MouseButton1Click:Connect(function()
    panelVisible = false
    panel.Visible = false
    floatingCircle.Size = UDim2.fromOffset(circleSize, circleSize)
    floatingCircle.ImageColor3 = COLORS.white
    circleLabel.Text = "⚡"
    TweenService:Create(floatingCircle, TweenInfo.new(0.2), {
        Size = UDim2.fromOffset(circleSize, circleSize),
        ImageColor3 = COLORS.white
    }):Play()
end)

-- Circle click - opens panel
floatingCircle.MouseButton1Click:Connect(function()
    panelVisible = not panelVisible
    panel.Visible = panelVisible
    if panelVisible then
        floatingCircle.Size = UDim2.fromOffset(35, 35)
        floatingCircle.ImageColor3 = Color3.fromRGB(200, 200, 255)
        circleLabel.Text = ""
        TweenService:Create(floatingCircle, TweenInfo.new(0.15), {
            Size = UDim2.fromOffset(35, 35),
            ImageColor3 = Color3.fromRGB(200, 200, 255)
        }):Play()
        -- Position panel next to circle
        panel.Position = UDim2.new(
            0,
            floatingCircle.Position.X.Offset + 50,
            0,
            floatingCircle.Position.Y.Offset - 10
        )
    else
        floatingCircle.Size = UDim2.fromOffset(circleSize, circleSize)
        floatingCircle.ImageColor3 = COLORS.white
        circleLabel.Text = "⚡"
        TweenService:Create(floatingCircle, TweenInfo.new(0.15), {
            Size = UDim2.fromOffset(circleSize, circleSize),
            ImageColor3 = COLORS.white
        }):Play()
    end
end)

-- ====== DRAGGABLE CIRCLE (moves panel with it) ======
local dragData = { dragging = false, startPos = nil, startMouse = nil }

floatingCircle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragData.dragging = true
        dragData.startPos = floatingCircle.Position
        dragData.startMouse = input.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragData.dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragData.dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    
    local delta = input.Position - dragData.startMouse
    local newX = dragData.startPos.X.Offset + delta.X
    local newY = dragData.startPos.Y.Offset + delta.Y
    
    -- Clamp to screen edges
    newX = math.max(5, math.min(newX, 800))
    newY = math.max(5, math.min(newY, 500))
    
    floatingCircle.Position = UDim2.new(0, newX, 0, newY)
    
    if panelVisible then
        panel.Position = UDim2.new(0, newX + 50, 0, newY - 10)
    end
end)

-- ====== CORE FUNCTIONS ======
local function trim(value)
    return string.match(tostring(value or ""), "^%s*(.-)%s*$")
end

local function getRandomBiomeId()
    local biomeIds = {}
    for areaId in pairs(areas.Directory) do
        table.insert(biomeIds, areaId)
    end
    table.sort(biomeIds, function(left, right) return tostring(left) < tostring(right) end)
    if #biomeIds == 0 then return nil end
    return biomeIds[random:NextInteger(1, #biomeIds)]
end

local function showRandomRiftNotification()
    local biomeId = getRandomBiomeId()
    if biomeId == nil then return nil end
    riftSpawnNotification.Top({ AreaId = biomeId, Time = 6 })
    return biomeId
end

local VERIFIED_BADGE = utf8.char(0xE000)

local function escapeRichText(value)
    local escaped = tostring(value or "")
    escaped = string.gsub(escaped, "&", "&amp;")
    escaped = string.gsub(escaped, "<", "&lt;")
    escaped = string.gsub(escaped, ">", "&gt;")
    escaped = string.gsub(escaped, '"', "&quot;")
    escaped = string.gsub(escaped, "'", "&apos;")
    return escaped
end

local selectedEgg = "Unicorn"

local function composeEggName(quantity)
    local suffix = quantity == 1 and " Egg" or " Eggs"
    return "Divine " .. selectedEgg .. suffix
end

local function showEggSpawnNotification(quantity, targetPlayer)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local sender = escapeRichText(ADMIN_USERNAME)
    local eggName = escapeRichText(composeEggName(quantity))
    local firstLine = string.format(
        '<font color="#20BFFF">%s %s</font> <font color="#FFFFFF">spawned</font> <font color="#FFD51B">%d %s</font>',
        sender, VERIFIED_BADGE, quantity, eggName
    )
    local message
    local singleLine
    if targetPlayer ~= nil then
        targetPlayer = trim(targetPlayer)
        if targetPlayer == "" then return false end
        message = string.format(
            "%s\n<font color=\"#FFFFFF\">in</font> <font color=\"#FF3B3B\">%s's server!</font>",
            firstLine, escapeRichText(targetPlayer)
        )
        singleLine = false
    else
        message = firstLine .. '<font color="#FFD51B">!</font>'
        singleLine = true
    end
    messageNotification.Top({
        ShowShadow = true,
        Message = message,
        Time = 6,
        Color = Color3.new(1, 1, 1),
        Size = not singleLine and UDim2.fromScale(1.5, 0.6) or nil,
        WrapText = not singleLine,
        SingleLine = singleLine,
    })
    return true
end

local function showSpawnEggs(quantity)
    return showEggSpawnNotification(quantity, nil)
end

local function showSpawnEggsToPlayer(playerName, quantity)
    return showEggSpawnNotification(quantity, playerName)
end

local function showGiveAdminNotification(playerName)
    playerName = trim(playerName)
    if playerName == "" then return false end
    local sender = escapeRichText(ADMIN_USERNAME)
    local message = string.format(
        '<font color="#20BFFF">%s %s</font> <font color="#FFFFFF">gave admin to</font> <font color="#FF3B3B">%s!</font>',
        sender, VERIFIED_BADGE, escapeRichText(playerName)
    )
    messageNotification.Top({
        ShowShadow = true,
        Message = message,
        Time = 6,
        Color = Color3.new(1, 1, 1),
        SingleLine = true,
    })
    return true
end

local EGG_MODEL_NAMES = {
    Unicorn = "Unicorn",
    Kitsune = "Kitsune",
    Nightflame = "Godzilla",
    Archdemon = "Archdemon Dragon",
    Dreadscale = "Monster Egg",
    Mecha = "Mecha Egg",
    Shattered = "Crystal Egg",
}

local function attachDivineRarityVfx(model)
    local hitbox = model:FindFirstChild("Hitbox")
    local particles = ReplicatedStorage:FindFirstChild("Assets")
    particles = particles and particles:FindFirstChild("Particles")
    local rarityVfx = particles and particles:FindFirstChild("EggRarityVFX")
    local source = rarityVfx and rarityVfx:FindFirstChild("RarityNumber9+")
    if not (hitbox and hitbox:IsA("BasePart") and source) then return false end
    local vfxModel = Instance.new("Model")
    for _, child in ipairs(source:GetChildren()) do
        child:Clone().Parent = vfxModel
    end
    local sourceHitboxY = math.max(source:GetAttribute("HitboxSizeY") or 5, 1)
    vfxModel:ScaleTo(hitbox.Size.Y / sourceHitboxY)
    for _, child in ipairs(vfxModel:GetChildren()) do
        child.Parent = hitbox
    end
    vfxModel:Destroy()
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Trail") or descendant:IsA("Light") then
            descendant.Enabled = true
        end
    end
    return true
end

local function getLocalEggFolder()
    local folder = workspace:FindFirstChild("CartiLocalSpawnedEggs")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "CartiLocalSpawnedEggs"
        folder.Parent = workspace
    end
    return folder
end

local function addNativeEggPrompt(model)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "CarryAreaEgg"
    prompt.ActionText = "Steal"
    prompt.ObjectText = "Egg"
    prompt.HoldDuration = 1.2
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = false
    prompt.Style = Enum.ProximityPromptStyle.Custom
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.ClickablePrompt = true
    prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
    smartProximityPrompt.AttachToModel(prompt, model, {
        PartName = "CartiEggSmartPromptPart",
        SurfaceOffset = 0.75,
        TrackDistance = 8,
        MaxActivationDistance = 8,
    })
    return prompt
end

local function getNativeNestTemplate()
    local objects = workspace:FindFirstChild("__OBJECTS")
    local areasFolder = objects and objects:FindFirstChild("Areas")
    local guardAreas = areasFolder and areasFolder:FindFirstChild("GuardAreas")
    if not guardAreas then return nil end
    for _, descendant in ipairs(guardAreas:GetDescendants()) do
        if descendant:IsA("Model") and descendant.Name == "NestModel" then
            return descendant
        end
    end
    return nil
end

local function makePassThrough(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
        end
    end
end

local function groundModelAt(model, targetPosition, raycastFilter)
    local templateRotation = model:GetPivot().Rotation
    model:PivotTo(CFrame.new(targetPosition) * templateRotation)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = raycastFilter
    raycastParams.IgnoreWater = false
    raycastParams.RespectCanCollide = true
    local hit = workspace:Raycast(targetPosition + Vector3.new(0, 24, 0), Vector3.new(0, -100, 0), raycastParams)
    local groundY = hit and hit.Position.Y or targetPosition.Y - 3
    local boundingCFrame, boundingSize = model:GetBoundingBox()
    local verticalOffset = groundY + (boundingSize.Y / 2) - boundingCFrame.Position.Y
    model:PivotTo(model:GetPivot() + Vector3.new(0, verticalOffset, 0))
    return groundY
end

local function spawnNativeEggModels(quantity)
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    local modelName = EGG_MODEL_NAMES[selectedEgg]
    local eggTemplates = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Models"):WaitForChild("Eggs")
    local template = modelName and eggTemplates:FindFirstChild(modelName)
    if not (template and template:IsA("Model")) then return false end
    quantity = math.clamp(math.floor(tonumber(quantity) or 1), 1, 20)
    local folder = getLocalEggFolder()
    local nestTemplate = getNativeNestTemplate()
    local columns = math.min(quantity, 5)
    local spacing = 28
    for index = 1, quantity do
        local row = math.floor((index - 1) / columns)
        local column = (index - 1) % columns
        local horizontalOffset = (column - ((columns - 1) / 2)) * spacing
        local forwardOffset = 16 + (row * spacing)
        local targetPosition = rootPart.Position
            + (rootPart.CFrame.LookVector * forwardOffset)
            + (rootPart.CFrame.RightVector * horizontalOffset)
        local clone = template:Clone()
        clone.Name = "Divine " .. selectedEgg .. " Egg"
        attachDivineRarityVfx(clone)
        clone:ScaleTo(clone:GetScale() * 4)
        clone.Parent = folder
        makePassThrough(clone)
        local nest
        if nestTemplate then
            nest = nestTemplate:Clone()
            nest.Name = clone.Name .. " Nest"
            nest.Parent = folder
            local _, eggSize = clone:GetBoundingBox()
            local _, originalNestSize = nest:GetBoundingBox()
            local originalDiameter = math.max(originalNestSize.X, originalNestSize.Z)
            if originalDiameter > 0 then
                local desiredDiameter = math.max(eggSize.X, eggSize.Z) * 1.2
                nest:ScaleTo(nest:GetScale() * (desiredDiameter / originalDiameter))
            end
            makePassThrough(nest)
            local groundY = groundModelAt(nest, targetPosition, { character, folder })
            local eggSpotBottom = nest:FindFirstChild("EggSpotBottom", true)
            if eggSpotBottom and eggSpotBottom:IsA("BasePart") then
                local fullSink = groundY - eggSpotBottom.Position.Y
                nest:PivotTo(nest:GetPivot() + Vector3.new(0, fullSink * 0.5, 0))
            end
            local _, scaledNestSize = nest:GetBoundingBox()
            local nestCFrame = nest:GetBoundingBox()
            local seatPosition = eggSpotBottom and eggSpotBottom.Position
                or Vector3.new(targetPosition.X, nestCFrame.Position.Y + (scaledNestSize.Y / 2), targetPosition.Z)
            clone:PivotTo(CFrame.new(seatPosition) * clone:GetPivot().Rotation)
            local eggCFrame, seatedEggSize = clone:GetBoundingBox()
            local eggBottom = eggCFrame.Position.Y - (seatedEggSize.Y / 2)
            clone:PivotTo(clone:GetPivot() + Vector3.new(0, seatPosition.Y - eggBottom, 0))
        else
            groundModelAt(clone, targetPosition, { character, folder })
        end
        addNativeEggPrompt(clone)
    end
    return true, quantity
end

local function getBotFolder()
    local folder = workspace:FindFirstChild("CartiLocalBots")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "CartiLocalBots"
        folder.Parent = workspace
    end
    return folder
end

local function spawnedEggChoices()
    local folder = workspace:FindFirstChild("CartiLocalSpawnedEggs")
    local choices = {}
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Model") and child.Name:match(" Egg$") and not child:GetAttribute("CartiBotCarried") then
                table.insert(choices, child)
            end
        end
    end
    return choices, folder
end

local function floorYAt(position, exclude)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = exclude or {}
    params.IgnoreWater = false
    params.RespectCanCollide = true
    local hit = workspace:Raycast(position + Vector3.new(0, 40, 0), Vector3.new(0, -140, 0), params)
    return hit and hit.Position.Y or position.Y
end

local function placeBotOnFloor(bot, position, lookAtPosition, exclude)
    local rotation = CFrame.new()
    local flatLook = Vector3.new(lookAtPosition.X, position.Y, lookAtPosition.Z)
    if (flatLook - position).Magnitude > 0.1 then
        rotation = CFrame.lookAt(position, flatLook).Rotation
    end
    bot:PivotTo(CFrame.new(position) * rotation)
    local boundsCFrame, boundsSize = bot:GetBoundingBox()
    local groundY = floorYAt(position, exclude)
    local bottomY = boundsCFrame.Position.Y - (boundsSize.Y / 2)
    bot:PivotTo(bot:GetPivot() + Vector3.new(0, groundY - bottomY, 0))
end

local function nativeCharacterAnimationId(folderName, animationName, fallback)
    local character = localPlayer.Character
    local animate = character and character:FindFirstChild("Animate")
    local folder = animate and animate:FindFirstChild(folderName)
    local animation = folder and folder:FindFirstChild(animationName)
    return animation and animation:IsA("Animation") and animation.AnimationId or fallback
end

local function loadBotTrack(humanoid, animationId, priority, looped)
    local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
    animator.Parent = humanoid
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId
    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    animation:Destroy()
    if not ok or not track then return nil end
    track.Priority = priority
    track.Looped = looped
    return track
end

local function moveBotTo(bot, destination, timeout)
    local humanoid = bot:FindFirstChildOfClass("Humanoid")
    local root = bot:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return false end
    local started = os.clock()
    local lastCommand = 0
    while bot.Parent and humanoid.Health > 0 and os.clock() - started < timeout do
        local flatDistance = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(destination.X, 0, destination.Z)).Magnitude
        if flatDistance <= 4 then
            humanoid:MoveTo(root.Position)
            return true
        end
        if os.clock() - lastCommand >= 1.5 then
            humanoid:MoveTo(destination)
            lastCommand = os.clock()
        end
        RunService.Heartbeat:Wait()
    end
    return false
end

local function removeEggPromptNear(egg)
    local eggCFrame, eggSize = egg:GetBoundingBox()
    local radius = math.max(eggSize.X, eggSize.Y, eggSize.Z)
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("BasePart") and child.Name == "CartiEggSmartPromptPart" and (child.Position - eggCFrame.Position).Magnitude <= radius then
            child:Destroy()
        end
    end
end

local function carryEggWithBot(bot, egg, eggFolder)
    local root = bot:FindFirstChild("HumanoidRootPart")
    local humanoid = bot:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return nil end
    egg:SetAttribute("CartiBotCarried", true)
    removeEggPromptNear(egg)
    local nest = eggFolder and eggFolder:FindFirstChild(egg.Name .. " Nest")
    if nest then nest:Destroy() end
    for _, descendant in ipairs(egg:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.Massless = true
        end
    end
    local eggBoundsCFrame, eggBoundsSize = egg:GetBoundingBox()
    local pivotToBottom = egg:GetPivot().Position.Y - (eggBoundsCFrame.Position.Y - (eggBoundsSize.Y / 2))
    local rootGroundOffset = humanoid.HipHeight + (root.Size.Y / 2)
    local carryHeight = pivotToBottom - rootGroundOffset + 0.75
    local carryForward = math.max(2.5, math.max(eggBoundsSize.X, eggBoundsSize.Z) * 0.3)
    local connection = RunService.Heartbeat:Connect(function()
        if bot.Parent and egg.Parent and root.Parent then
            egg:PivotTo(root.CFrame * CFrame.new(0, carryHeight, -carryForward))
        end
    end)
    return connection
end

local function createEggStealingBot(username)
    username = trim(username)
    if username == "" then
        return false, "Enter a Roblox username"
    end
    local eggChoices, eggFolder = spawnedEggChoices()
    if #eggChoices == 0 then
        return false, "Spawn an egg in the server first"
    end
    local targetEgg = eggChoices[random:NextInteger(1, #eggChoices)]
    local userId
    local resolved = pcall(function()
        userId = Players:GetUserIdFromNameAsync(username)
    end)
    if not resolved or not userId then
        return false, "Roblox user not found"
    end
    local created, bot = pcall(function()
        return Players:CreateHumanoidModelFromUserId(userId)
    end)
    if not created or not bot then
        return false, "Could not create bot avatar"
    end
    local humanoid = bot:FindFirstChildOfClass("Humanoid")
    local root = bot:FindFirstChild("HumanoidRootPart")
    local separationLine = workspace:FindFirstChild("__OBJECTS")
        and workspace.__OBJECTS:FindFirstChild("Areas")
        and workspace.__OBJECTS.Areas:FindFirstChild("SeparationLine")
    if not humanoid or not root or not (separationLine and separationLine:IsA("BasePart")) then
        bot:Destroy()
        return false, "Bot rig or safe-zone line is unavailable"
    end
    bot.Name = username .. " Bot"
    humanoid.DisplayName = username
    humanoid.NameDisplayDistance = 120
    humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    humanoid.WalkSpeed = 340
    bot.PrimaryPart = root
    bot.Parent = getBotFolder()
    local eggCFrame, eggSize = targetEgg:GetBoundingBox()
    local lineRight = separationLine.CFrame.RightVector
    local lineForward = separationLine.CFrame.LookVector
    local lateral = math.clamp(
        lineRight:Dot(eggCFrame.Position - separationLine.Position),
        -(separationLine.Size.X / 2) + 6,
        (separationLine.Size.X / 2) - 6
    )
    local spawnPosition = separationLine.Position + (lineRight * lateral) - (lineForward * 5)
    placeBotOnFloor(bot, spawnPosition, eggCFrame.Position, { bot, eggFolder })
    local approachDirection = Vector3.new(
        -targetEgg:GetPivot().LookVector.X,
        0,
        -targetEgg:GetPivot().LookVector.Z
    )
    approachDirection = approachDirection.Magnitude > 0.1 and approachDirection.Unit or lineForward
    local approachRadius = (math.max(eggSize.X, eggSize.Z) / 2) + 3
    local approachPosition = eggCFrame.Position + (approachDirection * approachRadius)
    approachPosition = Vector3.new(
        approachPosition.X,
        floorYAt(approachPosition, { bot, eggFolder }),
        approachPosition.Z
    )
    local runId = humanoid.RigType == Enum.HumanoidRigType.R6
        and "rbxassetid://180426354"
        or nativeCharacterAnimationId("run", "RunAnim", "rbxassetid://913376220")
    local runTrack = loadBotTrack(humanoid, runId, Enum.AnimationPriority.Movement, true)
    if runTrack then
        runTrack:Play(0.15)
        runTrack:AdjustSpeed(humanoid.WalkSpeed / 16)
    end
    task.spawn(function()
        local reachedEgg = moveBotTo(bot, approachPosition, 45)
        if not reachedEgg or not bot.Parent or not targetEgg.Parent then
            bot:Destroy()
            return
        end
        if runTrack then
            runTrack:Stop(0.15)
        end
        humanoid:MoveTo(root.Position)
        bot:PivotTo(bot:GetPivot() + Vector3.new(
            approachPosition.X - root.Position.X,
            0,
            approachPosition.Z - root.Position.Z
        ))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        local faceEgg = Vector3.new(eggCFrame.Position.X, root.Position.Y, eggCFrame.Position.Z)
        if (faceEgg - root.Position).Magnitude > 0.1 then
            root.CFrame = CFrame.lookAt(root.Position, faceEgg)
        end
        task.wait(2)
        local stealId = humanoid.RigType == Enum.HumanoidRigType.R6
            and "rbxassetid://182393478"
            or nativeCharacterAnimationId("toolnone", "ToolNoneAnim", "rbxassetid://507768375")
        local stealTrack = loadBotTrack(humanoid, stealId, Enum.AnimationPriority.Action, true)
        if stealTrack then
            stealTrack:Play(0.1)
        end
        local carryConnection = carryEggWithBot(bot, targetEgg, eggFolder)
        local exitLateral = math.clamp(
            lineRight:Dot(root.Position - separationLine.Position),
            -(separationLine.Size.X / 2) + 6,
            (separationLine.Size.X / 2) - 6
        )
        local exitPosition = separationLine.Position + (lineRight * exitLateral) - (lineForward * 24)
        exitPosition = Vector3.new(
            exitPosition.X,
            floorYAt(exitPosition, { bot, eggFolder }),
            exitPosition.Z
        )
        if runTrack then
            runTrack:Play(0.1)
            runTrack:AdjustSpeed(humanoid.WalkSpeed / 16)
        end
        moveBotTo(bot, exitPosition, 30)
        if carryConnection then
            carryConnection:Disconnect()
        end
        if targetEgg.Parent then
            targetEgg:Destroy()
        end
        bot:Destroy()
    end)
    return true, bot
end

-- ====== API ======
local callbacks = {
    SendAnnouncement = function() return true end,
    SpawnEggs = showSpawnEggs,
    SpawnEggsToPlayer = showSpawnEggsToPlayer,
    StartRift = showRandomRiftNotification,
    GiveAdmin = showGiveAdminNotification,
    SpawnEggsInServer = spawnNativeEggModels,
    CreateBot = createEggStealingBot,
}

local api = {}

function api.CreateBot(username)
    if username ~= nil then
        botInput.Text = tostring(username)
    end
    return callbacks.CreateBot(botInput.Text)
end

function api.Destroy()
    if gui.Parent then
        gui:Destroy()
    end
end

_G.CartiAdminAbuse = api

-- ====== BUTTON CONNECTIONS ======
btnSpawn.MouseButton1Click:Connect(function()
    callbacks.SpawnEggs(tonumber(quantityInput.Text) or 1)
end)

btnSpawnPlayer.MouseButton1Click:Connect(function()
    callbacks.SpawnEggsToPlayer(playerInput.Text, tonumber(quantityInput.Text) or 1)
end)

btnSpawnServer.MouseButton1Click:Connect(function()
    callbacks.SpawnEggsInServer(tonumber(quantityInput.Text) or 1)
end)

btnRift.MouseButton1Click:Connect(function()
    callbacks.StartRift()
end)

btnAdmin.MouseButton1Click:Connect(function()
    callbacks.GiveAdmin(playerInput.Text)
end)

btnBot.MouseButton1Click:Connect(function()
    callbacks.CreateBot(botInput.Text)
end)

-- ====== AUTO CYCLE ======
local function spawnTwoBots()
    if not cycleRunning then return end
    for i = 1, 2 do
        if #usernamePool == 0 then
            shuffle(usernamePool)
            poolIndex = 1
        end
        local name = usernamePool[poolIndex]
        poolIndex = poolIndex + 1
        if poolIndex > #usernamePool then poolIndex = 1 end
        task.spawn(function()
            api.CreateBot(name)
        end)
        task.wait(1)
    end
end

local function botCycle()
    while cycleRunning do
        spawnTwoBots()
        for t = 120, 1, -1 do
            if not cycleRunning then break end
            statusLabel.Text = "Cycle: " .. t .. "s"
            task.wait(1)
        end
    end
    statusLabel.Text = "Cycle: Stopped"
end

btnCycle.MouseButton1Click:Connect(function()
    if cycleRunning then
        cycleRunning = false
        if cycleTask then
            task.cancel(cycleTask)
            cycleTask = nil
        end
        btnCycle.Text = "⏯️ Start Cycle"
        statusLabel.Text = "Cycle: Stopped"
    else
        cycleRunning = true
        btnCycle.Text = "⏯️ Stop Cycle"
        cycleTask = task.spawn(botCycle)
    end
end)

-- Start cycle automatically
cycleTask = task.spawn(botCycle)

-- ====== KEYBIND ======
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F7 and gui.Parent then
        panelVisible = not panelVisible
        panel.Visible = panelVisible
        if panelVisible then
            floatingCircle.Size = UDim2.fromOffset(35, 35)
            floatingCircle.ImageColor3 = Color3.fromRGB(200, 200, 255)
            circleLabel.Text = ""
            TweenService:Create(floatingCircle, TweenInfo.new(0.15), {
                Size = UDim2.fromOffset(35, 35),
                ImageColor3 = Color3.fromRGB(200, 200, 255)
            }):Play()
            panel.Position = UDim2.new(0, floatingCircle.Position.X.Offset + 50, 0, floatingCircle.Position.Y.Offset - 10)
        else
            floatingCircle.Size = UDim2.fromOffset(50, 50)
            floatingCircle.ImageColor3 = COLORS.white
            circleLabel.Text = "⚡"
            TweenService:Create(floatingCircle, TweenInfo.new(0.15), {
                Size = UDim2.fromOffset(50, 50),
                ImageColor3 = COLORS.white
            }):Play()
        end
    end
end)

-- ====== CLOSE ON PANEL CLICK OUTSIDE ======
local function closePanel()
    if panelVisible then
        panelVisible = false
        panel.Visible = false
        floatingCircle.Size = UDim2.fromOffset(50, 50)
        floatingCircle.ImageColor3 = COLORS.white
        circleLabel.Text = "⚡"
        TweenService:Create(floatingCircle, TweenInfo.new(0.15), {
            Size = UDim2.fromOffset(50, 50),
            ImageColor3 = COLORS.white
        }):Play()
    end
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if panelVisible then
            local mousePos = input.Position
            local panelPos = panel.AbsolutePosition
            local panelSize = panel.AbsoluteSize
            if not (mousePos.X >= panelPos.X and mousePos.X <= panelPos.X + panelSize.X and
                    mousePos.Y >= panelPos.Y and mousePos.Y <= panelPos.Y + panelSize.Y) then
                if not floatingCircle:IsHovering() then
                    closePanel()
                end
            end
        end
    end
end)

return api
