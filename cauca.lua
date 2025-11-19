repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

--------------------------------------------------------
-- 🔧 SERVICES & MODULES
--------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Animals = require(ReplicatedStorage.Datas.Animals)
local Synchronizer = require(ReplicatedStorage.Packages.Synchronizer)
local Net = require(ReplicatedStorage.Packages.Net)

-- Remotes
local SellRemote = ReplicatedStorage.Packages.Net["RE/PlotService/Sell"]
local CastRE = Net:RemoteEvent("FishingRod.Cast")
local CancelRE = Net:RemoteEvent("FishingRod.Cancel")
local SetupBobberRE = Net:RemoteEvent("FishingRod.SetupBobber")
local MinigameClick = Net:RemoteEvent("FishingRod.MinigameClick")
local RewardRE = Net:RemoteEvent("FishingRod.Reward")
local BiteRE = Net:RemoteEvent("FishingRod.BiteGot")

local NetFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")
local BuyRodRF = NetFolder:WaitForChild("RF/RodsShopService/RequestBuy")
local EquipRodRF = NetFolder:WaitForChild("RF/RodsShopService/RequestEquip")

--------------------------------------------------------
-- ⚙ CONFIG
--------------------------------------------------------
getgenv().AUTO_FISH = true
getgenv().AUTO_BEST_ROD = true
getgenv().AUTO_EQUIP_ROD = true
getgenv().AUTO_CLEAN_PLOT = true
getgenv().CLEAN_LOOP_DELAY = 1

local WEBHOOK_URL = "NHẬP_WEBHOOK_CỦA_BẠN"

--------------------------------------------------------
-- 🌈 DANH SÁCH CẦN CÂU THEO THỨ TỰ XỊN
--------------------------------------------------------
local RodPriority = {
    "Radioactive Rod",
    "Fiery Rod",
    "Frozen Rod",
    "Starter Rod",
}

--------------------------------------------------------
-- 🟡 LOAD DANH SÁCH PET
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
-- 🏠 LẤY DANH SÁCH PET TRONG NHÀ
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

    warn("⚠ Không lấy được danh sách pet từ plot!")
    return {}
end

--------------------------------------------------------
-- 🧹 XOÁ PET KHÔNG THUỘC SECRET / OG / LUCKY BLOCK
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
                warn("🗑 Xoá:", name, "| Slot:", index)
                pcall(function()
                    SellRemote:FireServer(index)
                end)
            end
        end
    end

    print(string.format("🐾 Cleaned | Total %d | Keep %d | Deleted %d", total, kept, deleted))
end

--------------------------------------------------------
-- 🚀 CLEAN LOOP
--------------------------------------------------------
local function StartCleanLoop()
    if not getgenv().AUTO_CLEAN_PLOT then return end
    
    task.spawn(function()
        while getgenv().AUTO_CLEAN_PLOT do
            local categories = LoadPetCategories()
            CleanPlot(categories)
            task.wait(getgenv().CLEAN_LOOP_DELAY)
        end
    end)
end

--------------------------------------------------------
-- 🎯 EVENT PET DETECTOR + WEBHOOK
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
    return nil
end

local function SendEventWebhook()
    if HasSentWebhook then return end

    local msg = {
        username = "Fishing Event Tracker",
        embeds = {{
            title = "🎉 EVENT PET REACHED 5!",
            description = "**Bạn đã câu đủ 5 PET SỰ KIỆN!**",
            color = 16753920,
            fields = {
                { name = "🎣 Pets:", value =
                    "• Tralaledon\n• Eviledon\n• Los Primos\n• Orcaledon\n• Capitano Moby", inline = false },
                { name = "⭐ Tổng số:", value = tostring(EventCounter), inline = true }
            },
            footer = { text = "Fishing Auto Script" },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }

    local req = http_request or request or syn.request
    if req then
        pcall(function()
            req({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = game:GetService("HttpService"):JSONEncode(msg)
            })
            print("📨 Webhook sent!")
        end)
    end

    HasSentWebhook = true
end

--------------------------------------------------------
-- 🧠 AUTO ROD FUNCTIONS
--------------------------------------------------------
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

    local targetTool = nil
    local equippedRodName = LocalPlayer:GetAttribute("EquippedFishingRod")

    if equippedRodName and backpack:FindFirstChild(equippedRodName) then
        targetTool = backpack[equippedRodName]
    else
        for _, t in ipairs(backpack:GetChildren()) do
            if t:IsA("Tool") and t.Name:find("Rod") then
                targetTool = t
                break
            end
        end
    end

    if targetTool then
        hum:EquipTool(targetTool)
    end
end

local function AutoBuyAndEquipBestRod()
    if not getgenv().AUTO_BEST_ROD then return end

    for _, rodName in ipairs(RodPriority) do
        local okEquip, resEquip = pcall(function()
            return EquipRodRF:InvokeServer(rodName)
        end)

        task.wait(0.2)

        if LocalPlayer:GetAttribute("EquippedFishingRod") == rodName then
            print("[AUTO ROD] Equipped owned rod:", rodName)
            EquipCurrentRodTool()
            return
        end

        local okBuy, resBuy = pcall(function()
            return BuyRodRF:InvokeServer(rodName)
        end)

        task.wait(0.2)

        okEquip, resEquip = pcall(function()
            return EquipRodRF:InvokeServer(rodName)
        end)

        task.wait(0.2)

        if LocalPlayer:GetAttribute("EquippedFishingRod") == rodName then
            print("[AUTO ROD] Bought + Equipped rod:", rodName)
            EquipCurrentRodTool()
            return
        end
    end

    print("[AUTO ROD] Không mua/equip được cây nào trong danh sách.")
end

--------------------------------------------------------
-- 🧨 AUTO MINIGAME
--------------------------------------------------------
local lastMiniClick = 0

local function AutoPerfectMinigame()
    if not currentRodTool then return end
    if not currentRodTool:GetAttribute("minigame") then return end

    local hits = currentRodTool:GetAttribute("minigameHits")
    local hp = currentRodTool:GetAttribute("minigameHP")

    if not hits or not hp or hp == 0 then return end

    if tick() - lastMiniClick > 0.12 then
        lastMiniClick = tick()
        MinigameClick:FireServer()
    end
end

--------------------------------------------------------
-- ⚡ AUTO CAST
--------------------------------------------------------
local function AutoCast()
    if not currentRodTool then return end
    if currentRodTool:GetAttribute("minigame") then return end
    if currentRodTool:GetAttribute("casted") then return end
    if currentRodTool:GetAttribute("castCooldown") then return end

    local power = math.random(90, 100) / 100
    CastRE:FireServer(power)
end

--------------------------------------------------------
-- 🐟 AUTO GIẬT CẦN KHI CÓ CÁ CẮN
--------------------------------------------------------
BiteRE.OnClientEvent:Connect(function(playerWhoGotBite)
    if not getgenv().AUTO_FISH then return end
    if playerWhoGotBite ~= LocalPlayer then return end
    MinigameClick:FireServer()
end)

--------------------------------------------------------
-- 🎁 EVENT REWARD HANDLER
--------------------------------------------------------
RewardRE.OnClientEvent:Connect(function(pPlayer, bobber, pos, _, animalId, _)
    if pPlayer ~= LocalPlayer then return end
    
    -- Check event pet
    local name = GetPetNameById(animalId)
    if name and EventPets[name] then
        EventCounter += 1
        print("🔥 EVENT PET:", name, "| Total =", EventCounter)

        if EventCounter >= 5 and not HasSentWebhook then
            SendEventWebhook()
        end
    end
    
    -- Auto cast lại
    if getgenv().AUTO_FISH then
        task.delay(0.7, function()
            AutoCast()
        end)
    end
end)

--------------------------------------------------------
-- 🎮 CHARACTER SETUP
--------------------------------------------------------
local function SetupCharacter()
    task.wait(1)
    UpdateCurrentRodTool()
    AutoBuyAndEquipBestRod()
    EquipCurrentRodTool()
end

LocalPlayer.CharacterAdded:Connect(SetupCharacter)

if LocalPlayer.Character then
    SetupCharacter()
end

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
-- 🚀 KHỞI ĐỘNG
--------------------------------------------------------
print("✅ COMBINED AUTO FISHING SCRIPT LOADED")
print("🎣 Auto Fish: " .. tostring(getgenv().AUTO_FISH))
print("🎣 Auto Best Rod: " .. tostring(getgenv().AUTO_BEST_ROD))
print("🧹 Auto Clean Plot: " .. tostring(getgenv().AUTO_CLEAN_PLOT))

StartCleanLoop()
