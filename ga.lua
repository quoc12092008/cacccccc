repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

--------------------------------------------------------
-- 🔧 SERVICES & MODULES
--------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Animals = require(ReplicatedStorage.Datas.Animals)
local Synchronizer = require(ReplicatedStorage.Packages.Synchronizer)

-- Net remotes
local Net = require(ReplicatedStorage.Packages.Net)

local SellRemote       = ReplicatedStorage.Packages.Net["RE/PlotService/Sell"]
local RewardRE_Fish    = Net:RemoteEvent("FishingRod.Reward")
local CastRE           = Net:RemoteEvent("FishingRod.Cast")
local CancelRE         = Net:RemoteEvent("FishingRod.Cancel")
local SetupBobberRE    = Net:RemoteEvent("FishingRod.SetupBobber")
local MinigameClick    = Net:RemoteEvent("FishingRod.MinigameClick")
local BiteRE           = Net:RemoteEvent("FishingRod.BiteGot")

local NetFolder = ReplicatedStorage.Packages.Net
local BuyRodRF   = NetFolder:WaitForChild("RF/RodsShopService/RequestBuy")
local EquipRodRF = NetFolder:WaitForChild("RF/RodsShopService/RequestEquip")

--------------------------------------------------------
-- ⚙ CONFIG
--------------------------------------------------------
local AUTO_LOOP  = true
local LOOP_DELAY = 1

getgenv().AUTO_FISH         = getgenv().AUTO_FISH or true
getgenv().AUTO_BEST_ROD     = getgenv().AUTO_BEST_ROD or true
getgenv().AUTO_EQUIP_ROD    = getgenv().AUTO_EQUIP_ROD or true
getgenv().EVENT_WEBHOOK     = getgenv().EVENT_WEBHOOK or ""  -- bạn set ở ngoài

--------------------------------------------------------
-- 🟡 LOAD PET CATEGORY (SECRET / OG / LUCKY)
--------------------------------------------------------
local function LoadPetCategories()
    local AllowedSet = {}
    local Secret, OG, LuckyBlocks = {}, {}, {}

    for name, data in pairs(Animals) do
        local rarity = data.Rarity or ""
        local lname = name:lower()
        local lrar = rarity:lower()

        if rarity == "Secret" then
            AllowedSet[name] = true
            table.insert(Secret, name)

        elseif rarity == "OG" then
            AllowedSet[name] = true
            table.insert(OG, name)

        elseif lname:find("lucky block") or lrar:find("lucky") then
            AllowedSet[name] = true
            table.insert(LuckyBlocks, name)
        end
    end

    return {
        AllowedSet = AllowedSet,
        Secret = Secret,
        OG = OG,
        LuckyBlocks = LuckyBlocks,
    }
end

--------------------------------------------------------
-- 🏠 GET PET IN PLOT
--------------------------------------------------------
local function GetAnimalList()
    local sync = Synchronizer:Get(LocalPlayer)
    if sync then
        local ok, list = pcall(function()
            return sync:Get("AnimalPodiums")
        end)
        if ok and list then return list end
    end

    local ok2, PlotController = pcall(function()
        return require(ReplicatedStorage.Controllers.PlotController)
    end)
    if ok2 and PlotController then
        local myPlot = PlotController.GetMyPlot()
        if myPlot and myPlot.Channel then
            local ok3, list = pcall(function()
                return myPlot.Channel:Get("AnimalList")
            end)
            if ok3 and list then return list end
        end
    end

    return {}
end

--------------------------------------------------------
-- 🧹 REMOVE PET BAD
--------------------------------------------------------
local function CleanPlot(categories)
    local allowed = categories.AllowedSet
    local pets = GetAnimalList()

    local kept, deleted, total = 0, 0, 0

    for index, data in pairs(pets) do
        if data and data.Index then
            local name = data.Index
            total += 1

            if allowed[name] then
                kept += 1
            else
                deleted += 1
                pcall(function()
                    SellRemote:FireServer(index)
                end)
            end
        end
    end

    print(string.format("🐾 CLEAN: Total %d | Keep %d | Deleted %d", total, kept, deleted))
end

--------------------------------------------------------
-- LOOP CLEAN
--------------------------------------------------------
local function RunOnce()
    CleanPlot(LoadPetCategories())
end

local function StartLoop()
    task.spawn(function()
        while true do
            RunOnce()
            task.wait(LOOP_DELAY)
        end
    end)
end

--------------------------------------------------------
-- 🎯 EVENT PET WEBHOOK
--------------------------------------------------------
local EventPets = {
    ["Tralaledon"] = true,
    ["Eviledon"] = true,
    ["Los Primos"] = true,
    ["Orcaledon"] = true,
    ["Capitano Moby"] = true,
}

local EventCounter = 0
local HasSentWebhook = false

local function GetPetNameById(id)
    for name, data in pairs(Animals) do
        if tostring(data.Id) == tostring(id) then
            return name
        end
    end
end

local function SendEventWebhook()
    if HasSentWebhook then return end
    if not getgenv().EVENT_WEBHOOK or getgenv().EVENT_WEBHOOK == "" then
        warn("❌ Không có webhook! Bỏ qua.")
        return
    end

    local msg = {
        username = "Fishing Event Tracker",
        embeds = {{
            title = "🎉 ĐỦ 5 PET SỰ KIỆN!",
            description = "**Bạn đã câu đủ 5 PET SỰ KIỆN!**",
            color = 16753920,
            fields = {
                { name = "🎣 Danh sách:", value =
                    "• Tralaledon\n• Eviledon\n• Los Primos\n• Orcaledon\n• Capitano Moby" },
                { name = "⭐ Tổng số:", value = tostring(EventCounter) }
            },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    local req = http_request or request or syn.request
    if req then
        req({
            Url = getgenv().EVENT_WEBHOOK,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(msg)
        })
    end

    HasSentWebhook = true
end

--------------------------------------------------------
-- 🎣 AUTO FISHING + AUTO ROD
--------------------------------------------------------
local RodPriority = {
    "Radioactive Rod",
    "Fiery Rod",
    "Frozen Rod",
    "Starter Rod",
}

local currentRodTool = nil

local function UpdateCurrentRodTool()
    local char = LocalPlayer.Character
    currentRodTool = nil
    if not char then return end

    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and obj.Name:find("Rod") then
            currentRodTool = obj
            break
        end
    end
end

local function EquipCurrentRodTool()
    if not getgenv().AUTO_EQUIP_ROD then return end
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if char:FindFirstChildOfClass("Tool") then return end

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return end

    local equipped = LocalPlayer:GetAttribute("EquippedFishingRod")
    if equipped and backpack:FindFirstChild(equipped) then
        hum:EquipTool(backpack[equipped])
        return
    end

    for _, t in ipairs(backpack:GetChildren()) do
        if t:IsA("Tool") and t.Name:find("Rod") then
            hum:EquipTool(t)
            return
        end
    end
end

local function AutoBuyAndEquipBestRod()
    if not getgenv().AUTO_BEST_ROD then return end

    for _, name in ipairs(RodPriority) do
        pcall(function()
            EquipRodRF:InvokeServer(name)
        end)
        task.wait(0.2)

        if LocalPlayer:GetAttribute("EquippedFishingRod") == name then
            print("[AUTO ROD] Equipped owned rod:", name)
            EquipCurrentRodTool()
            return
        end

        pcall(function()
            BuyRodRF:InvokeServer(name)
        end)
        task.wait(0.2)

        pcall(function()
            EquipRodRF:InvokeServer(name)
        end)
        task.wait(0.2)

        if LocalPlayer:GetAttribute("EquippedFishingRod") == name then
            print("[AUTO ROD] Bought + Equipped rod:", name)
            EquipCurrentRodTool()
            return
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    UpdateCurrentRodTool()
    AutoBuyAndEquipBestRod()
    EquipCurrentRodTool()
end)

if LocalPlayer.Character then
    task.wait(1)
    UpdateCurrentRodTool()
    AutoBuyAndEquipBestRod()
    EquipCurrentRodTool()
end

-- Cập nhật currentRodTool khi cầm/thả tool
LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and child.Name:find("Rod") then
            currentRodTool = child
        end
    end)
    char.ChildRemoved:Connect(function(child)
        if child == currentRodTool then
            currentRodTool = nil
        end
    end)
end)

local lastMiniClick = 0

local function AutoPerfectMinigame()
    if not currentRodTool then return end
    if not currentRodTool:GetAttribute("minigame") then return end

    local hits = currentRodTool:GetAttribute("minigameHits")
    local hp   = currentRodTool:GetAttribute("minigameHP")

    if not hits or not hp or hp == 0 then return end

    if tick() - lastMiniClick > 0.12 then
        lastMiniClick = tick()
        MinigameClick:FireServer()
    end
end

local function AutoCast()
    if not currentRodTool then return end
    if currentRodTool:GetAttribute("minigame") then return end
    if currentRodTool:GetAttribute("casted") then return end
    if currentRodTool:GetAttribute("castCooldown") then return end

    local power = math.random(90, 100) / 100
    CastRE:FireServer(power)
end

BiteRE.OnClientEvent:Connect(function(p)
    if p ~= LocalPlayer then return end
    if not getgenv().AUTO_FISH then return end
    MinigameClick:FireServer()
end)

--------------------------------------------------------
-- 🔥 FIX: GỘP 2 LOGIC VÀO 1 CONNECTION DUY NHẤT
--------------------------------------------------------
RewardRE_Fish.OnClientEvent:Connect(function(pPlayer, bobber, pos, _, animalId, _)
    if pPlayer ~= LocalPlayer then return end
    
    -- 1️⃣ ĐẾM EVENT PET
    local petName = GetPetNameById(animalId)
    if petName and EventPets[petName] then
        EventCounter += 1
        print("🔥 EVENT PET:", petName, "| Count:", EventCounter)
        
        if EventCounter >= 5 then
            SendEventWebhook()
        end
    end
    
    -- 2️⃣ AUTO CAST LẠI (CHỈ KHI BẬT AUTO_FISH)
    if getgenv().AUTO_FISH then
        task.delay(0.7, function()
            AutoCast()
        end)
    end
end)

--------------------------------------------------------
-- 🔁 MAIN LOOP AUTO FISH
--------------------------------------------------------
task.spawn(function()
    while task.wait(0.05) do
        if getgenv().AUTO_FISH then
            if not currentRodTool then
                EquipCurrentRodTool()
                AutoBuyAndEquipBestRod()
            else
                if currentRodTool:GetAttribute("minigame") then
                    AutoPerfectMinigame()
                else
                    AutoCast()
                end
            end
        end
    end
end)

--------------------------------------------------------
-- 🔚 START CLEAN
--------------------------------------------------------
print("✅ FULL SCRIPT LOADED | AUTO FISH + CLEAN PLOT + EVENT WEBHOOK")

if AUTO_LOOP then
    StartLoop()
else
    RunOnce()
end
