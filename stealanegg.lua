local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

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

local identityState = _G.CartiAdminAbuseIdentityState or {}
if identityState.CharacterAddedConnection then
    identityState.CharacterAddedConnection:Disconnect()
end
_G.CartiAdminAbuseIdentityState = identityState

local function applyCreatorTag(character)
    local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 5)
    if not head then
        return false
    end

    local oldTag = head:FindFirstChild("CartiCreatorTag")
    if oldTag then
        oldTag:Destroy()
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CartiCreatorTag"
    billboard.Adornee = head
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 150
    billboard.Size = UDim2.fromOffset(245, 46)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.3, 0)
    billboard.Parent = head

    local title = Instance.new("TextLabel")
    title.Name = "Creator"
    title.BackgroundTransparency = 1
    title.Size = UDim2.fromScale(1, 1)
    title.Font = Enum.Font.GothamBlack
    title.Text = "👑 CREATOR 👑"
    title.TextColor3 = Color3.fromRGB(239, 42, 54)
    title.TextSize = 25
    title.TextStrokeColor3 = Color3.new(0, 0, 0)
    title.TextStrokeTransparency = 0
    title.Parent = billboard

    local textStroke = Instance.new("UIStroke")
    textStroke.Color = Color3.new(0, 0, 0)
    textStroke.Thickness = 1.5
    textStroke.Parent = title
    return true
end

local function clearAvatarAppearance(character)
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Accessory")
            or child:IsA("Accoutrement")
            or child:IsA("Shirt")
            or child:IsA("Pants")
            or child:IsA("ShirtGraphic")
            or child:IsA("BodyColors")
            or child:IsA("CharacterMesh") then
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
    if not (handle and handle:IsA("BasePart")) then
        return
    end

    handle.Anchored = false
    handle.CanCollide = false
    handle.Massless = true
    local handleAttachment = handle:FindFirstChildOfClass("Attachment")
    local characterAttachment = handleAttachment and findCharacterAttachment(character, handleAttachment.Name)
    local targetPart = characterAttachment and characterAttachment.Parent or character:FindFirstChild("Head")
    if not (targetPart and targetPart:IsA("BasePart")) then
        return
    end

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
    if not generatedOk or not sourceModel then
        return false
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local sourceHumanoid = sourceModel:FindFirstChildOfClass("Humanoid")
    clearAvatarAppearance(character)

    if humanoid and sourceHumanoid
        and humanoid.RigType == Enum.HumanoidRigType.R15
        and sourceHumanoid.RigType == Enum.HumanoidRigType.R15 then
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
        if child:IsA("BodyColors")
            or child:IsA("Shirt")
            or child:IsA("Pants")
            or child:IsA("ShirtGraphic")
            or child:IsA("CharacterMesh") then
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
    if not humanoid then
        return false
    end

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

if _G.CartiAdminAbuseUI then
    pcall(function()
        _G.CartiAdminAbuseUI:Destroy()
    end)
end

local COLORS = {
    panel = Color3.fromRGB(7, 6, 14),
    surface = Color3.fromRGB(29, 12, 54),
    surfaceDark = Color3.fromRGB(23, 9, 44),
    purple = Color3.fromRGB(128, 31, 221),
    purpleBright = Color3.fromRGB(168, 45, 255),
    purpleSoft = Color3.fromRGB(87, 25, 145),
    line = Color3.fromRGB(49, 27, 70),
    text = Color3.fromRGB(213, 190, 239),
    muted = Color3.fromRGB(148, 125, 170),
    white = Color3.fromRGB(239, 227, 248),
}

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

local function gradient(parent, topColor, bottomColor, rotation)
    return create("UIGradient", {
        Color = ColorSequence.new(topColor, bottomColor),
        Rotation = rotation or 90,
    }, parent)
end

local function label(parent, text, position, size, textSize, color, alignment)
    return create("TextLabel", {
        BackgroundTransparency = 1,
        Position = position,
        Size = size,
        Font = Enum.Font.Gotham,
        Text = text,
        TextColor3 = color or COLORS.text,
        TextSize = textSize,
        TextXAlignment = alignment or Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }, parent)
end

local function button(parent, name, text, position, size, active)
    local control = create("TextButton", {
        Name = name,
        AutoButtonColor = false,
        BackgroundColor3 = active and Color3.fromRGB(116, 27, 204) or Color3.fromRGB(36, 16, 61),
        BorderSizePixel = 0,
        Position = position,
        Size = size,
        Font = Enum.Font.GothamMedium,
        Text = text,
        TextColor3 = active and COLORS.white or COLORS.text,
        TextSize = 12,
    }, parent)
    corner(control, 6)
    stroke(control, active and COLORS.purpleBright or COLORS.line, active and 0.54 or 0.7, 1)
    control:SetAttribute("CartiBaseColor", control.BackgroundColor3)
    return control
end

local function addHover(control)
    control.MouseEnter:Connect(function()
        local baseColor = control:GetAttribute("CartiBaseColor") or control.BackgroundColor3
        control.BackgroundColor3 = Color3.fromRGB(
            math.min(255, math.floor(baseColor.R * 255) + 14),
            math.min(255, math.floor(baseColor.G * 255) + 7),
            math.min(255, math.floor(baseColor.B * 255) + 18)
        )
    end)
    control.MouseLeave:Connect(function()
        control.BackgroundColor3 = control:GetAttribute("CartiBaseColor") or control.BackgroundColor3
    end)
end

local function setButtonActive(control, active)
    local baseColor = active and Color3.fromRGB(116, 27, 204) or Color3.fromRGB(36, 16, 61)
    control:SetAttribute("CartiBaseColor", baseColor)
    control.BackgroundColor3 = baseColor
    control.TextColor3 = active and COLORS.white or COLORS.text
end

local gui = create("ScreenGui", {
    Name = "CartiAdminAbuseUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

_G.CartiAdminAbuseUI = gui

local panel = create("Frame", {
    Name = "Panel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(220, 380),
    ClipsDescendants = true,
}, gui)
corner(panel, 11)
stroke(panel, Color3.fromRGB(38, 20, 55), 0.22, 1)
gradient(panel, Color3.fromRGB(10, 8, 18), Color3.fromRGB(5, 5, 11), 90)

local header = create("Frame", {
    Name = "Header",
    BackgroundTransparency = 1,
    Size = UDim2.new(1, 0, 0, 50),
    ZIndex = 3,
}, panel)

label(header, "⚡", UDim2.fromOffset(14, 3), UDim2.fromOffset(17, 20), 15, Color3.fromRGB(255, 205, 70))
local titleLabel = label(header, "ADMIN ABUSE", UDim2.fromOffset(30, 3), UDim2.fromOffset(145, 20), 13, COLORS.text)
titleLabel.Font = Enum.Font.GothamBold
local gameSubtitle = label(header, "Steal an Egg", UDim2.fromOffset(15, 24), UDim2.fromOffset(160, 20), 11, COLORS.muted)
gameSubtitle.Font = Enum.Font.GothamMedium
local watermark = label(
    header,
    "t<b><font size=\"15\">.</font></b>me/cartiscripts",
    UDim2.new(1, -125, 0, 24),
    UDim2.fromOffset(110, 20),
    8,
    COLORS.muted,
    Enum.TextXAlignment.Right
)
watermark.Font = Enum.Font.GothamMedium
watermark.Name = "Watermark"
watermark.RichText = true

local toggleHint = label(
    header,
    "F7 Toggle",
    UDim2.new(1, -91, 0, 3),
    UDim2.fromOffset(53, 18),
    8,
    COLORS.muted,
    Enum.TextXAlignment.Right
)
toggleHint.Name = "ToggleHint"
toggleHint.Font = Enum.Font.GothamMedium

local closeButton = button(header, "CartiCloseButton", "X", UDim2.new(1, -30, 0, 3), UDim2.fromOffset(24, 23), false)
closeButton.TextSize = 12
closeButton.BackgroundColor3 = Color3.fromRGB(72, 20, 101)
closeButton:SetAttribute("CartiBaseColor", closeButton.BackgroundColor3)
addHover(closeButton)

create("Frame", {
    Name = "HeaderDivider",
    BackgroundColor3 = COLORS.line,
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(15, 48),
    Size = UDim2.new(1, -30, 0, 1),
}, header)

local pages = create("Frame", {
    Name = "Pages",
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(0, 50),
    Size = UDim2.new(1, 0, 1, -50),
}, panel)

local overview = create("ScrollingFrame", {
    Name = "Content",
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),
    BorderSizePixel = 0,
    CanvasSize = UDim2.fromOffset(0, 820),
    ElasticBehavior = Enum.ElasticBehavior.Never,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ScrollBarImageColor3 = Color3.fromRGB(102, 42, 143),
    ScrollBarImageTransparency = 0.08,
    ScrollBarThickness = 2,
    VerticalScrollBarInset = Enum.ScrollBarInset.Always,
}, pages)

local globalTab = button(overview, "GlobalTab", "🌍 Global", UDim2.fromOffset(13, 13), UDim2.fromOffset(94, 35), false)
local serverTab = button(overview, "ServerTab", "🖥️ Server", UDim2.fromOffset(112, 13), UDim2.fromOffset(95, 35), true)
local announcementScope = "Server"

local announcementInput = create("TextBox", {
    Name = "AnnouncementInput",
    BackgroundColor3 = Color3.fromRGB(32, 14, 56),
    BorderSizePixel = 0,
    Position = UDim2.fromOffset(13, 57),
    Size = UDim2.fromOffset(194, 39),
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    PlaceholderColor3 = Color3.fromRGB(111, 88, 132),
    PlaceholderText = "Type your message...",
    Text = "",
    TextColor3 = COLORS.text,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Center,
}, overview)
corner(announcementInput, 6)
stroke(announcementInput, COLORS.line, 0.7, 1)

local announce = button(overview, "SendAnnouncement", "📣 Send Announcement", UDim2.fromOffset(18, 105), UDim2.fromOffset(184, 31), true)
announce.TextSize = 11

local mutationNames = {
    "Unicorn",
    "Kitsune",
    "Nightflame",
    "Archdemon",
    "Dreadscale",
    "Mecha",
    "Shattered",
}
local mutationButtons = {}
local selectedEgg = "Unicorn"
for index, name in ipairs(mutationNames) do
    local column = (index - 1) % 3
    local row = math.floor((index - 1) / 3)
    local mutation = button(
        overview,
        name,
        name,
        UDim2.fromOffset(13 + (column * 66), 146 + (row * 42)),
        UDim2.fromOffset(column == 2 and 62 or 61, 35),
        index == 1
    )
    mutation.TextSize = 11
    mutation.TextScaled = true
    create("UITextSizeConstraint", {
        MinTextSize = 7,
        MaxTextSize = 11,
    }, mutation)
    addHover(mutation)
    mutationButtons[name] = mutation
end

local actions = overview

local function inputRow(name, caption, value, y)
    local row = create("Frame", {
        Name = name,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(13, y),
        Size = UDim2.fromOffset(194, 34),
    }, actions)
    corner(row, 4)
    gradient(row, Color3.fromRGB(34, 15, 62), Color3.fromRGB(23, 9, 44), 0)
    label(row, caption, UDim2.fromOffset(8, 0), UDim2.fromOffset(66, 34), 11, COLORS.text)

    local input = create("TextBox", {
        Name = "Input",
        BackgroundColor3 = Color3.fromRGB(26, 10, 51),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(74, 3),
        Size = UDim2.fromOffset(116, 28),
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderColor3 = COLORS.muted,
        Text = value,
        TextColor3 = COLORS.text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center,
    }, row)
    corner(input, 4)
    return input
end

local quantityInput = inputRow("QuantityRow", "Quantity:", "1", 278)
local playerInput = inputRow("PlayerRow", "Player:", "", 316)

local spawnEggs = button(actions, "SpawnEggs", "🥚 Spawn Eggs", UDim2.fromOffset(13, 362), UDim2.fromOffset(194, 39), false)
local spawnToPlayer = button(actions, "SpawnEggsToPlayer", "🥚 Spawn Eggs to Player", UDim2.fromOffset(13, 409), UDim2.fromOffset(194, 39), false)
local spawnEggsInServer = button(actions, "SpawnEggsInServer", "🥚 Spawn Eggs in Server", UDim2.fromOffset(13, 456), UDim2.fromOffset(194, 39), false)
local startRift = button(actions, "StartRift", "🌌 Start Rift", UDim2.fromOffset(13, 503), UDim2.fromOffset(194, 39), false)
local giveAdmin = button(actions, "GiveAdmin", "👑 Give Admin", UDim2.fromOffset(13, 550), UDim2.fromOffset(194, 39), false)
local botNameInput = inputRow("BotNameRow", "Bot Name:", "", 597)
botNameInput.PlaceholderText = "Roblox username"
local createBotButton = button(actions, "CreateBot", "🤖 Create Bot", UDim2.fromOffset(13, 639), UDim2.fromOffset(194, 39), false)

-- Cycle controls
local cycleButton = button(actions, "CycleToggle", "⏯️ Start Cycle", UDim2.fromOffset(13, 686), UDim2.fromOffset(194, 35), false)
local statusLabel = label(actions, "CycleStatus", "Cycle: Stopped", UDim2.fromOffset(13, 729), UDim2.fromOffset(194, 20), 10, COLORS.muted)
statusLabel.TextXAlignment = Enum.TextXAlignment.Center

for _, actionButton in ipairs({ spawnEggs, spawnToPlayer, startRift, giveAdmin, spawnEggsInServer, createBotButton, cycleButton }) do
    actionButton.TextSize = 11
    actionButton.TextColor3 = Color3.fromRGB(220, 199, 239)
    actionButton.BackgroundColor3 = Color3.fromRGB(39, 18, 65)
    actionButton:SetAttribute("CartiBaseColor", actionButton.BackgroundColor3)
    actionButton.TextXAlignment = Enum.TextXAlignment.Left
    create("UIPadding", { PaddingLeft = UDim.new(0, 9) }, actionButton)
    addHover(actionButton)
end

-- ==================== USERNAME POOL ====================
local rawUsernames = {
"tttooo_3838","JJBUT5","Lizzy25724","BobdaCHIKEN2572","Nash2234247","XccidentsX","dropin6s","Sofijaja1112","Elsaannakommi","Mamedov5778","maltesergirl16","Proinallgames198","cucugto67","carkaczX","ellaminapina","adoptmepooortorich0","Leo444418","Plutofn9","beniza_4","ghost_tricky123","B0bbyBear1","womer968","alrbr142","Cenmar_DJ2","heudhdd30","kendallies_y","Avaj28167","ilov3el4","Adam10malik17ahmad1","theyknowaverii","GBDEAoaoro","kopott66","B1ood_D4rk","PreppySla5","PSZ9913","ilayda_kilicsoy","didhorrible","FlipDaOppsV","greeee390","JustZombiePanGod","Jojo_siwa124386","Tyler92081","EarthSpike771","Uma2013love","Krav_171717","Delilah2_342","Sxonuf67","kirbylikepoyo","Arracheur2amory","Ashtyn00994","Naichina_1","The_boy33681","jerittalovesicecream","gojo42715","madara_uchida6","xiannacua123","Edersonmolho","janerpro1230","hfafugauifaifaa7fass","ninja1_white2","DarlingEunice","kareem_4167","welele22","Unqualified3","Meow56ii","URFAV_JUNEI","rqchel80","BLUE_YOURO","Icescreamcandle","Zovyys","Urfavvvanita","gongaginga129","melonsugarXD","panda2the","chilx_joshy","wwRussgirlww","Ak2938424","mearalove7","Tbtrapz43","Jopeta623","Adam1209h8","Dianiboy008","Rayjamason","slxughter16","hfhdsnf","VissRyo2004","428297392A","Iamakidneys","Au_poit","lankyboxisawsomed","Ilterzi","iamadumbwaytodie","bannana_421","ErichR221","wearxxxskz","cupcakKesbedbug32","Oreonikki2","anathequeen409","Broken_One82","entonces398","nuhonits","ReaI_floppa","luna_heart072","zaratha25","marc_only6","leminh8139","bruhbruhbear8","KingStarryBlaze2006","Princess_nena264","OFFICIAL_CECEEEE","wowoplays123","Djdjsskskm","ilix0re","imcringe_4","Sharkyvr03","rphina44","isa1239777","ruasdesangue","tatoriscute20","brbr2523","Sugarmoonoo","zloy_kotenok111","rayankarakiran","Boiiiiii_244","Berriesandcream654","1Curlyrabbit","suooo123450","tbbt_34","UNFORGIVEN_SWEETRY","Displayname_12374","Love_BIueberries","ugly_minion123","sofiaaaiaiaiaiaa","queen_uni21","lybly_kakashku","Osieeiei7","LYN23003","Omulit","Akhsunah07","Moomnnlgh","Moon_RadianceUwU","Give_freemm2","Rududhh34","IloveMM2forever937","reareaoma","kooletz20","Davidis17389","tuphlo","Kamilas110810","jjs_91981","adwhjd9","Viperissocool123","bulut_yt2","sniper_ethan36","Aimeelin_12328","bashfulll_phiaz","MichaelFrisbie123","Music_987765","awdawdaaadawasf2","BiggyCheez67675","leno112218","158245ggg","SICXWBXKVQJXSWXXJlIl","TheRealChair7","ServusWerner1","DylanSkibidi813","tuff_only67","llUUll_914","Leonis319","Spookdacity","qweras_014","Froggyboy186","y67nii","Cyranoh44","kostya_top96","Sherlynje","Ill1_Ill","Weirdo_201200","Ado_optmex","67sebas4132","Szokika3","Marseille0_01","l4rakiralyno","imbetterthanyou_180","edn_neuf1cn","sanna0066","RunningFromTommy","Leetherat20","izziehere2009","YeoJiaX","princesskylie_will","guilty_asian","system_robloxstodio","Gaby_moonk","niin602","baonek123nek","GalexOZD","Arthur_MC218","rajab_618","forbigamon","mayumi041494","pepechion2010","Diniks_rbx2","sartikelik","DE_3577","Djsxhxd2","daddyjonesgaming","kosmo_piesek","Sasha188218","devoelmanov","THEHABIB2011","nygel8457","St4r_Samy4","mica6y","Bobertius10","sebastiano_379","montagna27","GX_NICO13","unafemmina6","brajanek_pro100wryj","kamunanyaropip","fartboy_208","Ashley_cutie161","SunL823","Shaurmasofa098","Laur3n451","dadamanuwu1","Reatawwqg","Lol_001122334445","evie78113","mrgoldy08","Mochi_coco2023","anemia817","ty_nter","Mia19122000","MOLEK_RBX35","Duck0330973","Veevee206","bebelote0","ripsalim999","bina_cute6","yoboibacon8","Ryervason85007","221max12","Rip_samy776","antonkpyto6767ANTON","ArabicRaiders","justin1028883","SVStormYT","jason2009979","Mygem43number1","MrJawad0008","miasholding","astrotoilet_skibidi2","phu1792","BADRGUI0987","BADRGU0987","maximilianoo987","angel_12340320","yourmomi_74","getoz11","hihovo_script","mozzu_8","Sammy_etoppp","Stupidman5231","123456gift1","Dudesus074","Anthony21558","PLSNOBAN676767676767","CantLoggedIn2","00_Girlfriend","Tdot_8sthebest","CantLoggedIn","flowzer288","ultrasCT1946","mojrx101","rererer06666","Love_AG5","hackingisbadguys0","rafifyamin38","Elizae442","rdx_domnic","pitucho101","Olllie362","Regegh52","feinnn_0","xkizerekx","kqk470","krwball123","Itz_leviRM","aurarego674267","Silverzinho174","kaiquejose82929","ashleylino20","DaniiAsfe","vampzin_segundaria","Kevinv_29","SubzeroKjkj","desculpaporsergai","mila0943621","my_alexss","rip_adrian2239","xvx3609","IIIII2kgoatIIIIII","infecctffz","Emiilly_181","Uncorn22304","cooerbroff","Lolozoca10k","fzn99g","locaaa646","pugsareprittyandcute","Jaydenmcarty","t0nn1o","Purrito524","SofzSAB","loid3597_lindeza","Pam_33346","simply_rinnn","Bbynana2015","wesos714","twizzzyJaJa","juliaboneca1235","hellohola_938","ZombiePanGod","ooferpoofer_561","JERZEEJJMN","djtjed2637","Geremythekingg","meow_urii","Konfirance","nyan_cat2016ya","artem1344213","Banne5b","Yolo_16128","boboka1015","Orikwr4ithth3311","bubble0sneaky","afterclass_0","hdhdjruejiehd","Xrttin","therealtb139","Doorsrp346","fragolina33214","ADXSE2211","Bananistio1221","Benny_vale8","Sono_Iviee","simon121325","Kitty0345790","mamiEli1989","ronny_mylife7","Adrian456_Zepa44","kiaralara43","Gorilla_tag42","Adam_miko3212","ChryChry_80","Leonq207","DRAGON_GOKU2079","Topapi1223","DESTROYERGAMER974","Clarissa1234225","Amyyy_211","Azopetya407krnl3","capuzwf","Steyrtsis10","flexinale_30","rhino31o","kkomaya31","Bzo814","Arya_Pal7","eir_1239","RUZGATBEY2944","Amirali_0614","MTRN_OfficialGHG","Savagechris2018","Sup16385","testacount424524","Cooliiio_W","luvgigi14","27loveeveryone","Sssilver123456","des_spam1","black_hood10","misael677736","Vanillaconeeee","planta_700700","Blackbunny249","fufycjcjj63","sagorbos","hsdhsjns82","AidosCond","imnot_prince005","Lunamoonlight6453","TR4PPA4","Awalote43xD","George_WashMachin","Gacha_lifekid1231233","cat_beeloveyou","Alex_lopezC137","bellason010","Djdjdkrieidisosl","doombello","duna_27197","beton23234","Santanamoneygang08","PizzaFrency","iacovinoantonio","kiul88","theo2accountFB","vekalo200","ii09k_7k","French_fries1648","Dohip123","concak123lol111","SissyThings11","MoondropMoonPumpkin","BugBearx","Valen_oro15","makemedoadance","conichiwua67sixseven","onlyrivals837","5acc_vb","kalakatta1236","OPTIMUSPRIME_PLAYZ","Img4yyforall","nyupoka","dfgghgtrs","Pan_du1c31","cung_nhau","TheFIRDAVIS_7","shibasquad_Gemini","Hello_y0u2009","Sophieisdabests","iloveguapo2019","arbolitosemadera","giane67584","davidngo77","2O77v","Lurknchalls","Anela_hamidovic22","v6qyz","Lifesuchs67","Qqqqwew01","BrooklynTrenchs","rayngameralt","Briella9791","Heymanwa04","ultraNoraClubYTdino5","Malay_scorpio","lorimagyar22","Squeaker_theUnicorn","jojopopo66","Imgoingtoplay3049","dwillz27","Eslam56g0","surf676967","Fireballdevyon","Dinukaee","cicoWGF4_ita","Ironman95maxx","Moritz0022","Mr_sburreitor90","TTMAlby11","XDlol23783","buhonaranja","luijens","alexisymessi1231","poncopalino321","kazajr19","Spartann40","edibozz34","Lolligan321","Bugattiboss78","simo_sem12","Daniel_5679005","gabitos79","Osimhentrattore","ALEXE72766","Ggggsghsghhg8","Erickashtoner","coolboyeverlasting","GOJO_2088","Paolobing17","Vincent15772","cesarynacho","Alex2317_Pro","jimbo65256","lapatatadi2","Levi173133","kddavid63","clarissa09455","AcontadoRicardo","Gius23531","Roblox_pinkflower","saber2267","calavera1094","ILOVE_CHICKENS1230","Theverynoob200","q_IIIIIIIIIIIII","theverynoob670","ST4R1373y","Alexander01030103","Tyler20121504","NotUrFriend_011","B3AMER847","Hackabdc","Tightboi207","Bra3diz","Ilovechoa93","Mohammedrashid12g","JuanHorton92","ImGoatedAtSniper","TheEg1r","ogm716","Bxxie_erals","xdder1234567","tigerbrsnd","StealABrainrot15_2","macizysko09","kethufunk4","Felixstoweb","12EL12A","SoyElAlex6850","buahpq","Toilacucogaideptrai","minhquangpqieo11","c4reless_V0ices","Hollinger777","https_inki","roblox_user_3647763910","ashxcsj","GenaGurl16","Ruvt382","Maggie_vegas","llllllllllllappa","max_8376483","FiNoHack","OmidMessi123","Donatemepleaseyo","ROXXANNNEEEEFRD","sugawarriorl","Alexplayz12371","DV_CHILL","Gala12345_Gaming","Oxie12364","NicoSugiPula7","goldman0203","Goldmandell","pignig999","OMGHIPOOKIE12345","ItachiUchiha_2735","dksisjmx","Whoisyou_l7","spionirogolibiro67","OnTheRoadtoEmerald","chillingwithri","5HPwy","Williamop1l5","MAYOOR_89","happy_339y","djozli_k1ller","3str31la","ZORO_29711","Gatomcuabeo","drew1231142","Achievement_bot67","Moonnice170","KevinRBLXaltacc","unicorn_xxxxxcer","TIGER_COMMANDO36","princeart113","nothingjemmm","mirunastar13","PatrikBan20","PenaBranca022","Joe_bar2","prty_tulips","BankruptBacon0","hola7623456","rtuyompuj","Trycie_16","wtxamelia","alonsofredy2023","inkvdjrf","ian43652","qiupcmxz2852","Loops_RVA","Babatundedupexx0","MINECRAFTKID4107","testrefimmoxshock","byet21240","Not_aSpeedtypist1","Cosmo_259","ash_boba7","seyaqic","Sigma165227","Dhjfjfidj778","SA1234_J","kevinaribowo5","Y3TZ3LL","slnakak","squejol","jornalents","Losbrosisbetter6","michiganKel","zynep_2000","Chienhihi6648","MCK_23231","AURA_FARMER7123","Beatrizze09","4gwvertft","st4rdust_rev3ri3e","howstpddoyou","Avzxl77","Saifnasser46","Huymotedepzaivc","xkog03","fruit_mean","masterbancon_41","flussoxez","lamenolcita28","breadth04","ELEGOISTA10wa","oyyr746","isaac123ggj2","KenzoOuzu17","Thejesterthatscyan1","rhumjean1","1ivingdeadgrl","SonataMoonligth","Chasedftrewr","raynopr20","Strenghtandforce","glogloxDpicar0","Xxcookiemonsterxwoof","AryIsNoob1","rayyanp55rm","kate153pro","BrainrotKeeperSecert","Jerremywas16","Yba_accnew","Zxyieee19","y3ciz","focapapa32","Queen_Kagura536","rush_wohoo","kitsune_dxdyt","huigkyuftf0","Urth28450","hstsbac_1","Juhcfu8vhfdibf","notoday12307","MESOHAIB68","Baseball_0529jax","SuperGirlXVI","IFellSoLucky1","asihdiafs","hiimbob2378","noobtopro27317","ITS A1K48THE2TH","IlIlIIllIIllIIIlIlII","hilolaxtn","Stealabrainrot_Aless","Nthingmuch12","BaconHaze199679","Pumaleaps","Sanntester1","lithiumdestroyer","CallMeGrek","imalreadydead_600","KINGVN7775","Fulo2034","Crimefullajm","joseaco208","tiagozzkk_3","BEAMLARPBOI","cxcvcxxcvxcvxvcxcvxc","HEYbro1234845","XxC0N3XI0NxX","Luigi42_WGF3","Ziopera12345678987","Giulia_26085","Coccobello2932","Lilone250","miagolo66","therivals_King65","meghla12345","MANGO_BROS1","drowzziie_s","sololeveling2035","Asia_tofine5","leenisme123","CandyBlossoms31","lchdnxn","I_AmAt0mlx","growlkneetest1","bobay336","samrinakhterr","Marixyssss","rissa_585","Footflyfungus","Jasnen872","stealth78910","unicornworld_cat1","SASALELEehe","IHEARTSTITCHANDANGE","aalexandrkk","IchEsseeKinderr","October_Girl101","rodel_7alt","luizapeissler2","sulaimanflash","idhehdieve","Mehmet01654","join23306","windowtuarture_bang","liksfacee","stylexkormeh","Thiswasnt_Chuckie","givemerubo2","lqstIove","Yurimelo201","its_mizukiee","milad67840","omad_zone11","genggengboy67","Foltyn32838","mercury19963","sergiogamer9A","gabr30624","Rupiboss138","Wh2pers_9","milosky345","bananorcaz","hakerdellazona","sottiletta_3","adoptme83120","fai_scifo2","IOHANNES31","vivimango23","Bellah_467","RUBA_laStracciatella","RonaldoRfgu","Mathias678892","ilcaloferito","Ciro783775","andrispace1011","fratm_vincy","iWantAllBranrot1703","Codarb6","huigkyuftf","ciaosoyaniir","FaccinaSorridente2_0","and_rei272","fischgamer_09","Darkdogs170","muzyka861","jorden173cm","Grupgxt","Matteolarue1","AgentStefan_sk","roblox2706tt998","ciaobellomio_6","gilugi2300","Khabib_fighter548","stealbrairot379","gilugi2400","Serpentecotto1234567","pinkyxcharchar","lotina_verdina","Jayla_frr","jana283250","superaltacc_67","Xmister_fps","NAZARCHIK14880","iwoeofekw","Methebest106","kenny_me7","Memeseapro789434","rxverrie0","RIOS_JEGUE","x44dkidd","M0NESY228","SHIVANG167167","granin554","Sankalp642","Softsoap445","hahaha12345678901215","jessica_a245","gravegrime","IdkyoubutimcoolxX2","Notleahashe0999","Shoikot_hero","Bananayanna032","GamerBoyAsh9","nothanz55","pink_un1corn14","Mo7sta52fa","mygame7022","missymours","akopogi_625","HE4RTSFORSCAR","Theodore7416","pollua11456","DoodleLover_2022","Alvin_23576","Thrill3R4ever","lynnis2swag","1LYRAIIIX0","YourgurllizA2","Dtx_Chris76","computer_error999","nekoandrudy","ademmmmmmmmmmm3","TTK_MILANEZTV","kakarotond","vini200vk","Ameliablox04","KingMeddy12","alien_ufo00","Ren_fh3","kaylee_wassam","Yappamurin572","DxstinyGenOnTop_3","nepopa123","dragon49441","jevader12257","YASH_TOONS","pavel_ff4","testaccjhar","Aresboss49","TimurBysyin1","alexandre1234AA1","lego_king67","Newzaza_99","agam_45651","harshrawata","hghght769","sutorobeliiin","Yhen0828","PRO_N00B0992","Kevenzen1234","Windmill210","777shoteye","potpotborak12345","crazyGuyzz77","kyle_xvani2","Pls_fruits7278","anas_maroc96","Awwwad85","diogo_voley","tungtungtungsa0r","rubiaherm0sa","san36284","ekgr123","Shadowguy_33532","RoxanneLover1AIBtw","FunwithLilly13","Alast0r_6663","RIVALSHACKS_2","Luvv_kaylan","asher_Theonlyone0","ONBLOCK125","nothingeverhappens77","m_yVanity","Yoyo20122017","00_ITZWe1rd67","Itzsilah24","Pirog222808","cosmicxlabrAdOrite","Iceywater106","VampyRaidzV2","Kamihen12","Elias_89920","Ilovemyfans12376","5starr_dre0","ilo_vedino","Toowasup08","viktorr282","Noamkapara11","real_dejavo","Littleknoxy21","1katseyemegan112","Mhel92729","joshwa_carlo","derth598","Sammyha708","DemonFan136","Cassie99241","lilyisthebest8973","sigmabalib1","Capys67alt","dunceman_43","Solmaz_pro8","haiedr_990","Itz_SILAH","godop541209","Thebesttester45","wetrdrgdrgdr","ghtlo906","HASHIII_454","ArnavPro14","yoness452","Eggplant_2014","alinasatty","Moohidch809","Mohidch123","bajithegamer37","DontB3amMe","Gamerriyansh5504","fijiwsij","maeiiq11","rata84796","Bamtet0","IamAhmed12349","Sora10295","INSHAL_2K3","Sam414175","Andreiu7878","TakenbyAF","corne3009","tayin_086","ionenmesswit3","humanv3_1239","UltraChiroDidito","Cut3_p4nda313","dorpikmylove","Mandraka_0932","CandyBots_1","loirinho244730","cliffforddar","Sloth1ove26","omarmenbr9","skidzzs_rip","LILTREL_1","kevinseci102","Darkness_56637","LilKingB101","aphmeow33333","Rip_skibidi3001","Beamtesterrrr","Fafamonarc123","zq4zk","r4thaveinfaurarizz","xxxBloodRushxxx","jeremyg110","QAIS478","Jxulxes","Jasiu5074","Sndro1710","JWUSHZH4","Xolexie01","Havinn230","ellijamestay66","axelkasam","guhpid","C00LKHVLIL","TESLA_123350","Alwaysandforever_S","Leker_Gamer4","y01991gh","yasser123436e1","gojo312799","NUGGETKA2014","imranee20990","333Finalalt","noluv_4lee","paschal9081","TIC_Al3ksPr0","sarahs16599","mamarley12345","3DSMARTGAMER","killerboyshhawn","krancz12345","GABRY4ACCOUNT","poiuyhnb8","xmimi_546","simmmmam","Gabriel670946","mochisannn_2","Spidey_30999","miguella210","Taynuggets21","holdthisdude","AzzamPr0","lysieble","koro12319","Jayden122245t6","Rip_Now101","visarayk","RomerMercury","ACHIKU90","jaylou_2013","hacked_666","mara_whysmallboy","omarsaltacc67","Pinkbunny110714","Ebie_xox","SPARKLE_HARPER123","tumadreconfidewa","la_fandanyme023","Teddi_0380","Madmad4440","ilovespeeddrawhah","Cookie289341","Ozi_8580","Bpt_speed","unite_784","bee_swarmalracc","Bangenergy5537","Rip_Naresh8","s2zzSt0rmKn1ght4819","iho1QueenGlitch4259","BasedDronePro","lamipakaymatug22","npontes1919","Traditionaltitaniu3","Ssekeeekele","Lexi_kai15","Stackedsabacc677","fendifab678","test123test32119","Trillegaming3","Mj1112290","lian1739475","Mikegir1","Collin_NotFound","myattempt16","Calysita26","AmbriaAldriz_Alt","123_abc644","ryler1934","Ms_Ash32178","spuleypaulbg","LaraLola04","Flurrysaad","lovefruit44","Lixxy_Bubbles","zoroluffyexerolo132","khalenmontano","yonatantamru15","getaloadofthisguy553","xoi703","albert_me12","Agon473998","N4COS154","Simply_sofi13","Olivia_8987614","zoroluffyexerolo","Tiara04473","Rakai_YT4","khenz753","Mangekyouo_Sharingan","Walidlawi8","goonet23","HJajaosisu1992Jjs","supercalifrazeb","ninjaxx_160","Dernyyq","Koolooopu10","diva_09285","pretty_123066","sleepyjoebdog","Paldo234078","manastar12","dontbeemplz","kiffy_anddeck0","rip_jhen08","sertonbakitba","buzzabadalright","clarise20274","Shikimako","tizonkhent","MyManVex","Robloxisking1qw","Mayomonster2014","DEOLSING","gurlkis212","Drizzly_PR","prooftheyear14","hafhth_2","CRIXSBOY15","cececute1817","temango3","ely123456983","Clintnsst","Kaydee2829","nathan1511196","Shinigamiilo","Craxel1000p","ITZHEIDISTAR","Josjoslolo","AngleDragon22","EmilyDonut10","Thereal45j20","LaylaTheLeader","Bonitagirl82","damznskwalanz","BAB2Y_Aw","lowkeyh0ney","cutie_from2hell","stwdgrf","official_king203","Beone6710","seltoogood","hutao8210","msnsgbddhhf","Cute3i_bunny","Jellycatdragon7","MYDOGATEMTHOMEWORK3","jakePlayzRoblox024","Thjjhnmmkj","Zcgggyyggh","Ronjababy27","couco910","Hkwkknwj","ihatesombr_719","catcatmiau124","lenood_8","Shimme_95","maskbacon_1","dennis_duke0","imasprinkleru123","rdmathzz","Gladbach97","NOTvidbtw","zenu379","sammysamloviebibie","shahidaforever","Cain_uinco","Haike_slt","yla_isnothin","HAZ3L126","KiaririIsAHakxe","IAM_NOTRUSS0","nikko0530","lolboy121214","G4BRIEL123THH","ttqws55","Bluenyancat1117","dwayne899992","princeYT_674A","K1sha_67","Martine91130","strawberryman220","kiramira213721","Azerty811254","TWISTEDcandyfloss123","enzoriduet","Tc_sae101","Shashashasha2983","midnella","free_please11","Ludlaj123","Zb3sT_1","Ailin13228","istel1155","hohojode","ishaaaaa_bon","Hrfeergnhghf","kalluche_6","Jhianjake4","PrincessCh3ryl","kittypurry10924","Riza_Mae1238","archidior4","HIITSCONOR1","Raizen63381","clarkcruz3123","GxchaCwndy","dave03710","Noob_guylos65","ytiuoip","BRON_Op","rymuxlzsiu","sprinkolladybug","testingaccobl","Spaghettiomania","theamarie446","micinnyawit","Keisha_CUTE1432","Xingli91","Barboach604","Zachyriahrobotfiyah","testmeow67","Gkz9p","8xzxq","justintheph0","wownana303","x5kaiser06","Darkfruitninja_1100","Cesarrios1101","angelelespro12345","tensenavy","sayberd123456","itzme_khia0","lance_deniel290","broslie_10","rurutyi_6","BloxoBacon_YTalt","ligthing2387","Xian_Jhoban","olivia_898761","cj123455822","Clamps1351","ssa12200","Elmasveloz_pru9","Preppy_girl987124","Princezzinthena","Ayva1407","baby_96272","chae0971","Kaseyl119","lilyboss1351","tre5846","ngocxyz1","xXV4MPXx_792","hiimdaniel6767","amilea12329","micupbonjour2","Dior_stardeluxe","Ufurfhvbhfhff","Michael_50394","HiimJJL2","CxcclI","Bruh123lol26","jghjbhuygfy","MariaTaddei13","katieadele8","DarkXwolf_478","67onmy6744","Bohaychoifaifai55","jaycee_rails","celine_second5","domenighinidavide2","Sacha15477","anna_grsm","cutesycharIie","labby1352","Juligo227","Lamakitty346","Sleeperguy1231","sleepergirl1231","Bushy_slab98","fester20010","Jye744","maxipro8828","unicornfairy052011","Virtual1433","AlphaImperatore","Xxzachgamezxxx","Wolfcat0ozzi","Rileylang20","Lolsickslocks","kwartamoney77","Xxboyfred","nemia708","DizGurlKillz","Moon_auicuiq","DisGirl5531","Antemaloi_7","nixie_1453","MRYOUTUBEWOJCICI","VoidedLucas","realfussedryt","3dry_ean","yunhojeong1999","BonecoDoMiguelito","RayisntGrayReal","catman11013","Babbbyemmmma","Tacticolor","gogogoriva","melodypink0677","deadreals2430","Jeremy88834","Twilightwitchgirl","Aaa_ya12","H3ARTZ_14","Sbolavucu316","Emama_793","Nam3_Thr33","Bliss_Dragon","isagany1239","Grenka0116","IlikeChocolat124","cleaf_unknown","jian_9ab","eggchan_230","TainzyBro2","BugEggMethod","tanjirotopg","hammbal45","KayleeLove3444","terrence12i2","baysided666","farmer3eak","kipli7751","DeadVillagerYT","MoonlightsFAKEACC","AnonymsU0","BOBO_ARINAA","LinoGurki","Babalar1233231","Littlenamejune","Cinamoroll_ivy","st1awberiiii","babyboylenaki0","4_koolaid","Kinleyidk2","kinleyidk1","atlas_can4545","iflfk22","Texasgirl_478","XxXhayleighXxXxd","dekus_lefttoenail","PinkFluffy_Uni67667","PixieB26","ayda_lol03","NoMiAl10","Adoptmeee402","GamerGirl_emur","Rafayak_2","marafame4","Gamerboy73133","Challyboy1312","sigmacoolboy1008","prxness1208","yasser9543","Elfik633","Eun_xxz","Alibox_2","AHMEDLEGRANDJOUEURE","Lina_679495","Ajayhenry72","Summer20398","Adoupmeiloveyou","Byebybbyebybbyebyb","testaccount8965l","Supercar691","chengweiwei4","srini1406","iatemydoritoscute","SyMNphOnY_0","Erisbabaalt8","hannahOSC_FAN","DeffONotSay_Say","bonquishaxnamnam","GraceyDoDoDo","laurenodododo","autumnisthegoat777","elioheregr","Thiago_30julio"
}

-- Deduplicate
local unique = {}
for _, name in ipairs(rawUsernames) do
    local clean = string.gsub(name, "^%s*(.-)%s*$", "%1") -- trim
    if clean ~= "" and clean ~= "Unknown" and not unique[clean] then
        unique[clean] = true
    end
end
local usernamePool = {}
for name in pairs(unique) do
    table.insert(usernamePool, name)
end

-- Shuffle function
local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end
shuffle(usernamePool)

local poolIndex = 1
local cycleRunning = false
local cycleTask = nil

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
            statusLabel.Text = "Cycle: Running - next in " .. t .. "s"
            task.wait(1)
        end
    end
    statusLabel.Text = "Cycle: Stopped"
end

-- ==================== REST OF ORIGINAL FUNCTIONS ====================
local function getRandomBiomeId()
    local biomeIds = {}
    for areaId in pairs(areas.Directory) do
        table.insert(biomeIds, areaId)
    end
    table.sort(biomeIds, function(left, right)
        return tostring(left) < tostring(right)
    end)
    if #biomeIds == 0 then
        return nil
    end
    return biomeIds[random:NextInteger(1, #biomeIds)]
end

local function showRandomRiftNotification()
    local biomeId = getRandomBiomeId()
    if biomeId == nil then
        return nil
    end
    riftSpawnNotification.Top({
        AreaId = biomeId,
        Time = 6,
    })
    return biomeId
end

local function trim(value)
    return string.match(tostring(value or ""), "^%s*(.-)%s*$")
end

local function showAnnouncement(message)
    message = trim(message)
    if message == "" then
        return false
    end
    local thumbnail = ""
    pcall(function()
        thumbnail = Players:GetUserThumbnailAsync(
            ADMIN_USER_ID,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size150x150
        )
    end)
    messageNotification.Top({
        ShowShadow = true,
        Message = ": " .. message,
        Time = 6,
        Color = Color3.new(1, 1, 1),
        Image = thumbnail ~= "" and thumbnail or nil,
        SingleLine = true,
    })
    return true
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
        sender,
        VERIFIED_BADGE,
        quantity,
        eggName
    )
    local message
    local singleLine
    if targetPlayer ~= nil then
        targetPlayer = trim(targetPlayer)
        if targetPlayer == "" then
            return false
        end
        message = string.format(
            "%s\n<font color=\"#FFFFFF\">in</font> <font color=\"#FF3B3B\">%s's server!</font>",
            firstLine,
            escapeRichText(targetPlayer)
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
    if playerName == "" then
        return false
    end
    local sender = escapeRichText(ADMIN_USERNAME)
    local message = string.format(
        '<font color="#20BFFF">%s %s</font> <font color="#FFFFFF">gave admin to</font> <font color="#FF3B3B">%s!</font>',
        sender,
        VERIFIED_BADGE,
        escapeRichText(playerName)
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
    if not (hitbox and hitbox:IsA("BasePart") and source) then
        return false
    end
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
        if descendant:IsA("ParticleEmitter")
            or descendant:IsA("Beam")
            or descendant:IsA("Trail")
            or descendant:IsA("Light") then
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
    if not guardAreas then
        return nil
    end
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
    local hit = workspace:Raycast(
        targetPosition + Vector3.new(0, 24, 0),
        Vector3.new(0, -100, 0),
        raycastParams
    )
    local groundY = hit and hit.Position.Y or targetPosition.Y - 3
    local boundingCFrame, boundingSize = model:GetBoundingBox()
    local verticalOffset = groundY + (boundingSize.Y / 2) - boundingCFrame.Position.Y
    model:PivotTo(model:GetPivot() + Vector3.new(0, verticalOffset, 0))
    return groundY
end

local function spawnNativeEggModels(quantity)
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false
    end
    local modelName = EGG_MODEL_NAMES[selectedEgg]
    local eggTemplates = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Models"):WaitForChild("Eggs")
    local template = modelName and eggTemplates:FindFirstChild(modelName)
    if not (template and template:IsA("Model")) then
        return false
    end
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
            if child:IsA("Model")
                and child.Name:match(" Egg$")
                and not child:GetAttribute("CartiBotCarried") then
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
    local hit = workspace:Raycast(
        position + Vector3.new(0, 40, 0),
        Vector3.new(0, -140, 0),
        params
    )
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
    if not ok or not track then
        return nil
    end
    track.Priority = priority
    track.Looped = looped
    return track
end

local function moveBotTo(bot, destination, timeout)
    local humanoid = bot:FindFirstChildOfClass("Humanoid")
    local root = bot:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then
        return false
    end
    local started = os.clock()
    local lastCommand = 0
    while bot.Parent and humanoid.Health > 0 and os.clock() - started < timeout do
        local flatDistance = (
            Vector3.new(root.Position.X, 0, root.Position.Z)
            - Vector3.new(destination.X, 0, destination.Z)
        ).Magnitude
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
        if child:IsA("BasePart")
            and child.Name == "CartiEggSmartPromptPart"
            and (child.Position - eggCFrame.Position).Magnitude <= radius then
            child:Destroy()
        end
    end
end

local function carryEggWithBot(bot, egg, eggFolder)
    local root = bot:FindFirstChild("HumanoidRootPart")
    local humanoid = bot:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then
        return nil
    end
    egg:SetAttribute("CartiBotCarried", true)
    removeEggPromptNear(egg)
    local nest = eggFolder and eggFolder:FindFirstChild(egg.Name .. " Nest")
    if nest then
        nest:Destroy()
    end
    for _, descendant in ipairs(egg:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.Massless = true
        end
    end
    local eggBoundsCFrame, eggBoundsSize = egg:GetBoundingBox()
    local pivotToBottom = egg:GetPivot().Position.Y
        - (eggBoundsCFrame.Position.Y - (eggBoundsSize.Y / 2))
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

local callbacks = {
    SendAnnouncement = showAnnouncement,
    SpawnEggs = showSpawnEggs,
    SpawnEggsToPlayer = showSpawnEggsToPlayer,
    StartRift = showRandomRiftNotification,
    GiveAdmin = showGiveAdminNotification,
    SpawnEggsInServer = spawnNativeEggModels,
    CreateBot = createEggStealingBot,
}

local integrityFailed = false
local integrityConnection
local api = {}

function api.SetCallbacks(newCallbacks)
    if integrityFailed then
        return false
    end
    for name, callback in pairs(newCallbacks or {}) do
        if callbacks[name] ~= nil and type(callback) == "function" then
            callbacks[name] = callback
        end
    end
    return true
end

function api.ShowOverview()
    overview.Visible = true
    overview.CanvasPosition = Vector2.zero
end

function api.ShowActions()
    overview.Visible = true
    overview.CanvasPosition = Vector2.new(0, 266)
end

function api.SetPlayerName(name)
    playerInput.Text = tostring(name or "")
end

function api.SetQuantity(amount)
    quantityInput.Text = tostring(math.max(1, math.floor(tonumber(amount) or 1)))
end

function api.SetSelectedEgg(name)
    if not mutationButtons[name] then
        return false
    end
    selectedEgg = name
    for eggName, eggButton in pairs(mutationButtons) do
        setButtonActive(eggButton, eggName == selectedEgg)
    end
    return true
end

function api.GetSelectedEgg()
    return selectedEgg
end

function api.SetAnnouncementMessage(message)
    announcementInput.Text = tostring(message or "")
end

function api.SendAnnouncement(message)
    if message ~= nil then
        announcementInput.Text = tostring(message)
    end
    return callbacks.SendAnnouncement(announcementInput.Text)
end

function api.StartRift()
    return callbacks.StartRift()
end

function api.ShowSpawnEggs(quantity)
    return callbacks.SpawnEggs(quantity or quantityInput.Text)
end

function api.ShowSpawnEggsToPlayer(playerName, quantity)
    return callbacks.SpawnEggsToPlayer(playerName or playerInput.Text, quantity or quantityInput.Text)
end

function api.GiveAdmin(playerName)
    if playerName ~= nil then
        playerInput.Text = tostring(playerName)
    end
    return callbacks.GiveAdmin(playerInput.Text)
end

function api.SpawnEggsInServer(quantity)
    return callbacks.SpawnEggsInServer(quantity or quantityInput.Text)
end

function api.CreateBot(username)
    if username ~= nil then
        botNameInput.Text = tostring(username)
    end
    return callbacks.CreateBot(botNameInput.Text)
end

function api.Destroy()
    integrityFailed = true
    if integrityConnection then
        integrityConnection:Disconnect()
        integrityConnection = nil
    end
    if _G.CartiAdminAbuse == api then
        _G.CartiAdminAbuse = nil
    end
    if gui.Parent then
        gui:Destroy()
    end
end

_G.CartiAdminAbuse = api

integrityConnection = RunService.Heartbeat:Connect(function()
    local intact = watermark.Parent == header
        and watermark:IsDescendantOf(gui)
        and watermark.Name == "Watermark"
        and watermark.Text == "t<b><font size=\"15\">.</font></b>me/cartiscripts"
        and watermark.RichText
        and watermark.TextSize == 8
        and watermark.Font == Enum.Font.GothamMedium
        and watermark.TextXAlignment == Enum.TextXAlignment.Right
        and watermark.Visible
        and watermark.TextTransparency == 0
    if intact then
        return
    end
    integrityFailed = true
    for name in pairs(callbacks) do
        callbacks[name] = function()
            return false
        end
    end
    if _G.CartiAdminAbuse == api then
        _G.CartiAdminAbuse = nil
    end
    integrityConnection:Disconnect()
    integrityConnection = nil
    if gui.Parent then
        gui:Destroy()
    end
end)

globalTab.MouseButton1Click:Connect(function()
    announcementScope = "Global"
    setButtonActive(globalTab, true)
    setButtonActive(serverTab, false)
end)

serverTab.MouseButton1Click:Connect(function()
    announcementScope = "Server"
    setButtonActive(serverTab, true)
    setButtonActive(globalTab, false)
end)

for _, name in ipairs(mutationNames) do
    overview[name].MouseButton1Click:Connect(function()
        api.SetSelectedEgg(name)
    end)
end

announce.MouseButton1Click:Connect(function()
    callbacks.SendAnnouncement(announcementInput.Text)
end)

announcementInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        callbacks.SendAnnouncement(announcementInput.Text)
    end
end)

spawnEggs.MouseButton1Click:Connect(function()
    callbacks.SpawnEggs(math.max(1, tonumber(quantityInput.Text) or 1))
end)

spawnToPlayer.MouseButton1Click:Connect(function()
    callbacks.SpawnEggsToPlayer(playerInput.Text, math.max(1, tonumber(quantityInput.Text) or 1))
end)

startRift.MouseButton1Click:Connect(function()
    callbacks.StartRift()
end)

giveAdmin.MouseButton1Click:Connect(function()
    callbacks.GiveAdmin(playerInput.Text)
end)

spawnEggsInServer.MouseButton1Click:Connect(function()
    callbacks.SpawnEggsInServer(quantityInput.Text)
end)

createBotButton.MouseButton1Click:Connect(function()
    callbacks.CreateBot(botNameInput.Text)
end)

botNameInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        callbacks.CreateBot(botNameInput.Text)
    end
end)

-- Cycle button
cycleButton.MouseButton1Click:Connect(function()
    if cycleRunning then
        cycleRunning = false
        if cycleTask then
            task.cancel(cycleTask)
            cycleTask = nil
        end
        cycleButton.Text = "⏯️ Start Cycle"
        statusLabel.Text = "Cycle: Stopped"
    else
        cycleRunning = true
        cycleButton.Text = "⏯️ Stop Cycle"
        cycleTask = task.spawn(botCycle)
    end
end)

closeButton.MouseButton1Click:Connect(api.Destroy)

-- Floating Toggle Button
local toggleBtn = Instance.new("ImageButton")
toggleBtn.Name = "FloatingToggle"
toggleBtn.Size = UDim2.fromOffset(44, 44)
toggleBtn.Position = UDim2.fromOffset(10, 100)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
toggleBtn.Image = "rbxassetid://6031090678"
toggleBtn.ImageColor3 = Color3.fromRGB(200, 200, 255)
toggleBtn.Parent = playerGui
corner(toggleBtn, 22)
stroke(toggleBtn, Color3.fromRGB(128, 31, 221), 0.3, 1.5)
toggleBtn.MouseButton1Click:Connect(function()
    gui.Enabled = not gui.Enabled
end)

-- Draggable toggle
local toggleDrag = false
local toggleDragStart
local togglePosStart
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        toggleDrag = true
        toggleDragStart = input.Position
        togglePosStart = toggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                toggleDrag = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if not toggleDrag then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - toggleDragStart
    toggleBtn.Position = UDim2.new(
        togglePosStart.X.Scale,
        togglePosStart.X.Offset + delta.X,
        togglePosStart.Y.Scale,
        togglePosStart.Y.Offset + delta.Y
    )
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F7 and gui.Parent then
        gui.Enabled = not gui.Enabled
    end
end)

local dragging = false
local dragStart
local panelStart

header.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    dragging = true
    dragStart = input.Position
    panelStart = panel.Position
    input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
            dragging = false
        end
    end)
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then
        return
    end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    local delta = input.Position - dragStart
    panel.Position = UDim2.new(
        panelStart.X.Scale,
        panelStart.X.Offset + delta.X,
        panelStart.Y.Scale,
        panelStart.Y.Offset + delta.Y
    )
end)

return api