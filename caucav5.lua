-- // AUTO FISH + AUTO SELL (TỰ ĐỘNG BÁN PET KHÔNG QUAN TRỌNG)
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

print("🔥 [AUTO FISH + SELL] Đang khởi động...")

-- ⚡ CACHE REMOTES SỚM
local Net = require(ReplicatedStorage.Packages.Net)
local RemoteCache = {}

local function CacheRemote(remoteName, remoteType)
    local success, remote = pcall(function()
        if remoteType == "Event" then
            return Net:RemoteEvent(remoteName)
        else
            return Net:RemoteFunction(remoteName)
        end
    end)
    
    if success and remote then
        RemoteCache[remoteName] = {
            remote = remote,
            type = remoteType,
            Fire = remote.FireServer,
            Invoke = remoteType == "Function" and remote.InvokeServer or nil
        }
        print("✅ [CACHE] Cached:", remoteName)
        return true
    else
        warn("❌ [CACHE] Failed:", remoteName)
        return false
    end
end

-- Cache fishing remotes
CacheRemote("FishingRod.Cast", "Event")
CacheRemote("FishingRod.Cancel", "Event")
CacheRemote("FishingRod.MinigameClick", "Event")
CacheRemote("FishingRod.Reward", "Event")
CacheRemote("FishingRod.BiteGot", "Event")

-- Cache shop remotes
local NetFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")
local BuyRodRF = NetFolder:WaitForChild("RF/RodsShopService/RequestBuy")
local EquipRodRF = NetFolder:WaitForChild("RF/RodsShopService/RequestEquip")
local SellPetRE = NetFolder:WaitForChild("RE/PlotService/Sell")

RemoteCache["BuyRod"] = {remote = BuyRodRF, type = "Function", Invoke = BuyRodRF.InvokeServer}
RemoteCache["EquipRod"] = {remote = EquipRodRF, type = "Function", Invoke = EquipRodRF.InvokeServer}

-- ⚡ INIT SYNCHRONIZER
local Synchronizer = require(ReplicatedStorage.Packages.Synchronizer)
local playerChannel = Synchronizer:Get(LocalPlayer)

if not playerChannel then
    print("⏳ Đợi player channel...")
    playerChannel = Synchronizer:Wait(LocalPlayer)
end

print("✅ Synchronizer ready!")

-- ⚡ LẤY DANH SÁCH PET QUAN TRỌNG (SECRET, OG, LUCKY BLOCK)
local ImportantPets = {}
local ImportantPetSet = {}

local function ScanImportantPets()
    local success, Animals = pcall(function()
        return require(ReplicatedStorage.Datas.Animals)
    end)
    
    if not success or not Animals then
        warn("❌ Không đọc được Animals data!")
        return false
    end
    
    ImportantPets = {}
    ImportantPetSet = {}
    
    local secretCount = 0
    local ogCount = 0
    local luckyCount = 0
    
    for petName, petData in pairs(Animals) do
        local rarity = petData.Rarity
        
        if rarity == "Secret" or rarity == "OG" or 
           tostring(petName):lower():find("lucky block") or 
           tostring(rarity):lower():find("lucky") then
            
            table.insert(ImportantPets, petName)
            ImportantPetSet[petName:lower()] = true
            
            if rarity == "Secret" then
                secretCount = secretCount + 1
            elseif rarity == "OG" then
                ogCount = ogCount + 1
            else
                luckyCount = luckyCount + 1
            end
        end
    end
    
    print("📋 [IMPORTANT PETS]")
    print("  🟡 Secret: " .. secretCount)
    print("  🔵 OG: " .. ogCount)
    print("  🟣 Lucky Block: " .. luckyCount)
    print("  ✅ Total: " .. #ImportantPets .. " pets sẽ KHÔNG BÁN")
    
    return true
end

-- Scan ngay khi khởi động
ScanImportantPets()

-- Cấu hình
getgenv().AUTO_FISH = true
getgenv().AUTO_SELL = true  -- BẬT/TẮT AUTO SELL
getgenv().AUTO_BEST_ROD = true
getgenv().AUTO_EQUIP_ROD = true

----------------------------------------------------------------
-- 🛡️ SAFE REMOTE CALLS
----------------------------------------------------------------
local function SafeFireRemote(remoteName, arg1, arg2, arg3, arg4, arg5)
    local cached = RemoteCache[remoteName]
    if not cached then
        warn("[BYPASS] Remote not cached:", remoteName)
        return false
    end
    
    local success, result = pcall(function()
        return cached.Fire(cached.remote, arg1, arg2, arg3, arg4, arg5)
    end)
    
    if not success then
        success, result = pcall(function()
            return cached.remote:FireServer(arg1, arg2, arg3, arg4, arg5)
        end)
    end
    
    return success, result
end

local function SafeInvokeRemote(remoteName, arg1, arg2, arg3, arg4, arg5)
    local cached = RemoteCache[remoteName]
    if not cached or cached.type ~= "Function" then
        warn("[BYPASS] Remote function not cached:", remoteName)
        return false, nil
    end
    
    local success, result = pcall(function()
        return cached.Invoke(cached.remote, arg1, arg2, arg3, arg4, arg5)
    end)
    
    if not success then
        success, result = pcall(function()
            return cached.remote:InvokeServer(arg1, arg2, arg3, arg4, arg5)
        end)
    end
    
    return success, result
end

----------------------------------------------------------------
-- 🐟 ĐỌC DANH SÁCH PET TRONG PLOT
----------------------------------------------------------------
local function GetAnimalPodiums()
    if not playerChannel then return nil end
    
    local success, animalList = pcall(function()
        return playerChannel:Get("AnimalPodiums")
    end)
    
    if success and animalList and type(animalList) == "table" then
        return animalList
    end
    
    return nil
end

----------------------------------------------------------------
-- 💰 AUTO SELL PET KHÔNG QUAN TRỌNG
----------------------------------------------------------------
local lastSellTime = 0
local SELL_COOLDOWN = 2  -- Đợi 2s giữa mỗi lần sell

local function ShouldKeepPet(petName)
    if not petName then return false end
    return ImportantPetSet[petName:lower()] == true
end

local function AutoSellTrashPets()
    if not getgenv().AUTO_SELL then return end
    
    local now = tick()
    if now - lastSellTime < SELL_COOLDOWN then
        return
    end
    
    local animalList = GetAnimalPodiums()
    if not animalList then 
        warn("⚠️ [AUTO SELL] Không đọc được AnimalPodiums")
        return 
    end
    
    -- Duyệt qua tất cả pet trong plot
    for slotIndex, animalData in pairs(animalList) do
        if animalData and animalData.Index then
            local petName = animalData.Index
            
            -- Kiểm tra có phải pet quan trọng không
            if not ShouldKeepPet(petName) then
                -- Sell pet này
                local success, err = pcall(function()
                    SellPetRE:FireServer(slotIndex)
                end)
                
                if success then
                    print("💰 [AUTO SELL] Đã bán: " .. petName .. " (slot " .. slotIndex .. ")")
                    lastSellTime = now
                    task.wait(0.5)  -- Đợi 0.5s giữa các lần sell
                else
                    warn("❌ [AUTO SELL] Lỗi bán pet:", err)
                end
            end
        end
    end
end

----------------------------------------------------------------
-- 🌈 ROD MANAGEMENT
----------------------------------------------------------------
local RodPriority = {
    "Radioactive Rod",
    "Fiery Rod", 
    "Frozen Rod",
    "Starter Rod",
}

local function EquipCurrentRodTool()
    if not getgenv().AUTO_EQUIP_ROD then return false end
    
    local char = LocalPlayer.Character
    if not char then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end

    if char:FindFirstChildOfClass("Tool") then return true end

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return false end

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
        task.wait(0.5)
        return true
    end
    
    return false
end

local function AutoBuyAndEquipBestRod()
    if not getgenv().AUTO_BEST_ROD then return false end

    for _, rodName in ipairs(RodPriority) do
        local okEquip, resEquip = SafeInvokeRemote("EquipRod", rodName)
        task.wait(0.3)

        if LocalPlayer:GetAttribute("EquippedFishingRod") == rodName then
            print("[AUTO ROD] ✅ Equipped:", rodName)
            EquipCurrentRodTool()
            return true
        end

        local okBuy, resBuy = SafeInvokeRemote("BuyRod", rodName)
        task.wait(0.3)

        okEquip, resEquip = SafeInvokeRemote("EquipRod", rodName)
        task.wait(0.3)

        if LocalPlayer:GetAttribute("EquippedFishingRod") == rodName then
            print("[AUTO ROD] ✅ Bought + Equipped:", rodName)
            EquipCurrentRodTool()
            return true
        end
    end

    print("[AUTO ROD] ⚠️ Không mua/equip được")
    return false
end

----------------------------------------------------------------
-- 🎣 TOOL MANAGEMENT
----------------------------------------------------------------
local currentRodTool = nil

local function UpdateCurrentRodTool()
    local char = LocalPlayer.Character
    currentRodTool = nil
    if not char then return end

    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and obj.Name:find("Rod") then
            currentRodTool = obj
            return
        end
    end
end

local function OnCharacterAdded(char)
    task.wait(2)
    UpdateCurrentRodTool()
    
    if AutoBuyAndEquipBestRod() then
        task.wait(0.5)
        EquipCurrentRodTool()
        task.wait(0.5)
        UpdateCurrentRodTool()
    end
    
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
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
if LocalPlayer.Character then
    OnCharacterAdded(LocalPlayer.Character)
end

----------------------------------------------------------------
-- 🧨 AUTO MINIGAME
----------------------------------------------------------------
local lastMiniClick = 0
local MINIGAME_CLICK_DELAY = 0.15

local function AutoPerfectMinigame()
    if not currentRodTool then return end
    if not currentRodTool:GetAttribute("minigame") then return end

    local hits = currentRodTool:GetAttribute("minigameHits")
    local hp = currentRodTool:GetAttribute("minigameHP")

    if not hits or not hp or hp == 0 then return end

    local now = tick()
    if now - lastMiniClick > MINIGAME_CLICK_DELAY then
        lastMiniClick = now
        SafeFireRemote("FishingRod.MinigameClick")
    end
end

----------------------------------------------------------------
-- ⚡ AUTO CAST
----------------------------------------------------------------
local lastCastAttempt = 0
local CAST_RETRY_DELAY = 1

local function AutoCast()
    if not currentRodTool then return false end
    if currentRodTool:GetAttribute("minigame") then return false end
    if currentRodTool:GetAttribute("casted") then return false end
    if currentRodTool:GetAttribute("castCooldown") then return false end
    
    local now = tick()
    if now - lastCastAttempt < CAST_RETRY_DELAY then
        return false
    end
    
    lastCastAttempt = now

    local power = math.random(90, 100) / 100
    local ok, err = SafeFireRemote("FishingRod.Cast", power)
    
    if ok then
        print("🎣 [AUTO FISH] Cast thành công!")
        return true
    else
        warn("⚠️ [AUTO FISH] Cast lỗi:", err)
        return false
    end
end

----------------------------------------------------------------
-- 🐟 BITE EVENT
----------------------------------------------------------------
local BiteRE = RemoteCache["FishingRod.BiteGot"]
if BiteRE and BiteRE.remote then
    BiteRE.remote.OnClientEvent:Connect(function(playerWhoGotBite)
        if not getgenv().AUTO_FISH then return end
        if playerWhoGotBite ~= LocalPlayer then return end

        print("🐟 [AUTO FISH] Cá cắn! Giật cần...")
        SafeFireRemote("FishingRod.MinigameClick")
    end)
else
    warn("⚠️ [BYPASS] Không thể listen BiteRE!")
end

----------------------------------------------------------------
-- 🎁 REWARD EVENT (KIỂM TRA VÀ SELL)
----------------------------------------------------------------
local RewardRE = RemoteCache["FishingRod.Reward"]
if RewardRE and RewardRE.remote then
    RewardRE.remote.OnClientEvent:Connect(function(pPlayer, tool, position, _, animalId, _)
        if pPlayer ~= LocalPlayer then return end
        if not getgenv().AUTO_FISH then return end

        print("━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎁 [REWARD] Câu được: " .. tostring(animalId))
        
        -- Kiểm tra xem có phải pet quan trọng không
        if ShouldKeepPet(animalId) then
            print("⭐ [KEEP] Pet quan trọng, GIỮ LẠI!")
        else
            print("💰 [SELL] Pet thường, sẽ bán trong 3 giây...")
            
            -- Đợi 3 giây rồi sell (để pet spawn vào plot)
            task.delay(3, function()
                AutoSellTrashPets()
            end)
        end
        print("━━━━━━━━━━━━━━━━━━━━━━━")
        
        -- Cast lại sau 1 giây
        task.delay(1, function()
            AutoCast()
        end)
    end)
else
    warn("⚠️ [BYPASS] Không thể listen RewardRE!")
end

----------------------------------------------------------------
-- 🔁 MAIN LOOP
----------------------------------------------------------------
local MAIN_LOOP_DELAY = 0.2
local AUTO_SELL_INTERVAL = 10  -- Check sell mỗi 10 giây
local lastAutoSellCheck = 0

task.spawn(function()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("✅ AUTO FISH + SELL ĐANG CHẠY!")
    print("🎣 Auto Fish: " .. tostring(getgenv().AUTO_FISH))
    print("💰 Auto Sell: " .. tostring(getgenv().AUTO_SELL))
    print("📋 Giữ lại: " .. #ImportantPets .. " loại pet")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    while task.wait(MAIN_LOOP_DELAY) do
        if not getgenv().AUTO_FISH then continue end
        
        UpdateCurrentRodTool()
        
        -- Check auto sell định kỳ
        local now = tick()
        if getgenv().AUTO_SELL and (now - lastAutoSellCheck >= AUTO_SELL_INTERVAL) then
            lastAutoSellCheck = now
            task.spawn(AutoSellTrashPets)
        end
        
        -- Logic câu cá
        if not currentRodTool then
            if EquipCurrentRodTool() then
                task.wait(0.5)
                UpdateCurrentRodTool()
            else
                AutoBuyAndEquipBestRod()
            end
        else
            if currentRodTool:GetAttribute("minigame") then
                AutoPerfectMinigame()
            else
                AutoCast()
            end
        end
    end
end)

print("🔥 ✅ AUTO FISH + AUTO SELL LOADED!")
print("💡 Để tắt auto sell: getgenv().AUTO_SELL = false")
print("💡 Để tắt auto fish: getgenv().AUTO_FISH = false")
