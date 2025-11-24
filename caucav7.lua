-- // AUTO FISH + SELL - ULTRA BYPASS (CHẠY ỔN ĐỊNH VỚI MỌI SCRIPT)
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

print("🔥 [ULTRA BYPASS] Starting...")

-- ═══════════════════════════════════════════════════════════
-- ⚡ BACKUP TOÀN BỘ REFERENCES TRƯỚC KHI SCRIPT KHÁC CHẠY
-- ═══════════════════════════════════════════════════════════

-- Backup Instance methods
local originalFindFirstChild = game.FindFirstChild
local originalWaitForChild = game.WaitForChild
local originalGetAttribute = game.GetAttribute

-- Net framework
local Net = require(ReplicatedStorage.Packages.Net)
local Synchronizer = require(ReplicatedStorage.Packages.Synchronizer)

-- ═══════════════════════════════════════════════════════════
-- 📦 CACHE REMOTES SỚM NHẤT CÓ THỂ
-- ═══════════════════════════════════════════════════════════
local RemoteCache = {}
local RemoteInstances = {}

local function DeepCacheRemote(remoteName, remoteType)
    local success, remote = pcall(function()
        if remoteType == "Event" then
            return Net:RemoteEvent(remoteName)
        else
            return Net:RemoteFunction(remoteName)
        end
    end)
    
    if success and remote then
        -- Lưu instance gốc
        RemoteInstances[remoteName] = remote
        
        -- Backup methods
        RemoteCache[remoteName] = {
            remote = remote,
            type = remoteType,
            originalFire = remote.FireServer,
            originalInvoke = remoteType == "Function" and remote.InvokeServer or nil,
        }
        print("✅ [CACHE]", remoteName)
        return true
    else
        warn("❌ [CACHE] Failed:", remoteName)
        return false
    end
end

DeepCacheRemote("FishingRod.Cast", "Event")
DeepCacheRemote("FishingRod.Cancel", "Event")
DeepCacheRemote("FishingRod.MinigameClick", "Event")
DeepCacheRemote("FishingRod.Reward", "Event")
DeepCacheRemote("FishingRod.BiteGot", "Event")

local NetFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")
local BuyRodRF = NetFolder:WaitForChild("RF/RodsShopService/RequestBuy")
local EquipRodRF = NetFolder:WaitForChild("RF/RodsShopService/RequestEquip")
local SellPetRE = NetFolder:WaitForChild("RE/PlotService/Sell")

RemoteInstances["BuyRod"] = BuyRodRF
RemoteInstances["EquipRod"] = EquipRodRF
RemoteInstances["SellPet"] = SellPetRE

RemoteCache["BuyRod"] = {remote = BuyRodRF, type = "Function", originalInvoke = BuyRodRF.InvokeServer}
RemoteCache["EquipRod"] = {remote = EquipRodRF, type = "Function", originalInvoke = EquipRodRF.InvokeServer}

print("✅ [CACHE] All remotes cached!")

-- ═══════════════════════════════════════════════════════════
-- 🔐 SAFE REMOTE CALLS (DÙNG BACKUP)
-- ═══════════════════════════════════════════════════════════
local function UltraSafeFireRemote(remoteName, ...)
    local args = {...}
    local cached = RemoteCache[remoteName]
    
    if not cached then
        warn("[ULTRA] Remote not found:", remoteName)
        return false
    end
    
    -- Method 1: Dùng backup
    local success1 = pcall(function()
        cached.originalFire(cached.remote, unpack(args))
    end)
    
    if success1 then return true end
    
    -- Method 2: Dùng instance backup
    local instance = RemoteInstances[remoteName]
    if instance then
        local success2 = pcall(function()
            instance:FireServer(unpack(args))
        end)
        if success2 then return true end
    end
    
    -- Method 3: Tìm lại từ đầu
    local success3, newRemote = pcall(function()
        return Net:RemoteEvent(remoteName)
    end)
    
    if success3 and newRemote then
        local success4 = pcall(function()
            newRemote:FireServer(unpack(args))
        end)
        if success4 then 
            -- Update cache
            RemoteInstances[remoteName] = newRemote
            RemoteCache[remoteName].remote = newRemote
            return true 
        end
    end
    
    warn("[ULTRA] All methods failed for:", remoteName)
    return false
end

local function UltraSafeInvokeRemote(remoteName, ...)
    local args = {...}
    local cached = RemoteCache[remoteName]
    
    if not cached then
        warn("[ULTRA] Remote not found:", remoteName)
        return false, nil
    end
    
    -- Method 1: Backup
    local success1, result1 = pcall(function()
        return cached.originalInvoke(cached.remote, unpack(args))
    end)
    if success1 then return true, result1 end
    
    -- Method 2: Instance backup
    local instance = RemoteInstances[remoteName]
    if instance then
        local success2, result2 = pcall(function()
            return instance:InvokeServer(unpack(args))
        end)
        if success2 then return true, result2 end
    end
    
    return false, nil
end

-- ═══════════════════════════════════════════════════════════
-- 🔄 SYNCHRONIZER (BACKUP RIÊNG)
-- ═══════════════════════════════════════════════════════════
local playerChannel = Synchronizer:Get(LocalPlayer)
if not playerChannel then
    playerChannel = Synchronizer:Wait(LocalPlayer)
end
print("✅ [SYNC] Player channel ready")

local function SafeGetAnimalPodiums()
    -- Method 1: playerChannel
    local success1, data1 = pcall(function()
        return playerChannel:Get("AnimalPodiums")
    end)
    if success1 and data1 and type(data1) == "table" then
        local hasData = false
        for _ in pairs(data1) do hasData = true break end
        if hasData then return data1 end
    end
    
    -- Method 2: Tạo channel mới
    local success2, newChannel = pcall(function()
        return Synchronizer:Get(LocalPlayer)
    end)
    if success2 and newChannel then
        local success3, data3 = pcall(function()
            return newChannel:Get("AnimalPodiums")
        end)
        if success3 and data3 and type(data3) == "table" then
            return data3
        end
    end
    
    return nil
end

-- ═══════════════════════════════════════════════════════════
-- 📋 SCAN IMPORTANT PETS
-- ═══════════════════════════════════════════════════════════
local ImportantPetSet = {}

local function ScanImportantPets()
    local success, Animals = pcall(function()
        return require(ReplicatedStorage.Datas.Animals)
    end)
    
    if not success or not Animals then
        warn("❌ Cannot read Animals!")
        return false
    end
    
    ImportantPetSet = {}
    local counts = {secret = 0, og = 0, lucky = 0}
    
    for petName, petData in pairs(Animals) do
        local rarity = petData.Rarity
        
        if rarity == "Secret" or rarity == "OG" or 
           tostring(petName):lower():find("lucky block") or 
           tostring(rarity):lower():find("lucky") then
            
            ImportantPetSet[petName:lower()] = true
            
            if rarity == "Secret" then counts.secret = counts.secret + 1
            elseif rarity == "OG" then counts.og = counts.og + 1
            else counts.lucky = counts.lucky + 1 end
        end
    end
    
    print("📋 [PETS] Secret:" .. counts.secret .. " | OG:" .. counts.og .. " | Lucky:" .. counts.lucky)
    return true
end

ScanImportantPets()

-- ═══════════════════════════════════════════════════════════
-- ⚙️ CONFIG
-- ═══════════════════════════════════════════════════════════
getgenv().AUTO_FISH = true
getgenv().AUTO_SELL = true
getgenv().AUTO_BEST_ROD = true
getgenv().AUTO_EQUIP_ROD = true

-- ═══════════════════════════════════════════════════════════
-- 💰 AUTO SELL
-- ═══════════════════════════════════════════════════════════
local lastSellTime = 0

local function ShouldKeepPet(petName)
    if not petName then return false end
    return ImportantPetSet[petName:lower()] == true
end

local function SmartAutoSell()
    if not getgenv().AUTO_SELL then return 0 end
    
    local now = tick()
    if now - lastSellTime < 2 then return 0 end
    
    local animalList = SafeGetAnimalPodiums()
    if not animalList then 
        warn("⚠️ [SELL] Cannot read animals")
        return 0
    end
    
    local soldCount = 0
    
    for slotIndex, animalData in pairs(animalList) do
        if animalData and animalData.Index then
            local petName = animalData.Index
            
            if not ShouldKeepPet(petName) then
                local success = pcall(function()
                    SellPetRE:FireServer(slotIndex)
                end)
                
                if success then
                    print("💰 [SELL]", petName, "slot", slotIndex)
                    soldCount = soldCount + 1
                    lastSellTime = now
                    task.wait(0.3)
                end
            end
        end
    end
    
    return soldCount
end

-- ═══════════════════════════════════════════════════════════
-- 🎣 FISHING LOGIC
-- ═══════════════════════════════════════════════════════════
local RodPriority = {"Radioactive Rod", "Fiery Rod", "Frozen Rod", "Starter Rod"}
local currentRodTool = nil
local lastCastAttempt = 0
local lastMiniClick = 0
local isCasting = false

local function ForceEquipTool()
    if not getgenv().AUTO_EQUIP_ROD then return false end
    
    local char = LocalPlayer.Character
    if not char then return false end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    
    -- Đã cầm tool rồi
    if char:FindFirstChildOfClass("Tool") then return true end
    
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not backpack then return false end
    
    local equippedName = LocalPlayer:GetAttribute("EquippedFishingRod")
    local targetTool = backpack:FindFirstChild(equippedName)
    
    if not targetTool then
        for _, t in ipairs(backpack:GetChildren()) do
            if t:IsA("Tool") and t.Name:find("Rod") then
                targetTool = t
                break
            end
        end
    end
    
    if targetTool then
        hum:EquipTool(targetTool)
        task.wait(0.3)
        return true
    end
    
    return false
end

local function TryBuyBestRod()
    if not getgenv().AUTO_BEST_ROD then return false end
    
    for _, rodName in ipairs(RodPriority) do
        UltraSafeInvokeRemote("EquipRod", rodName)
        task.wait(0.2)
        
        if LocalPlayer:GetAttribute("EquippedFishingRod") == rodName then
            print("[ROD] ✅", rodName)
            ForceEquipTool()
            return true
        end
        
        UltraSafeInvokeRemote("BuyRod", rodName)
        task.wait(0.2)
        
        UltraSafeInvokeRemote("EquipRod", rodName)
        task.wait(0.2)
        
        if LocalPlayer:GetAttribute("EquippedFishingRod") == rodName then
            print("[ROD] ✅ Bought", rodName)
            ForceEquipTool()
            return true
        end
    end
    
    return false
end

local function UpdateTool()
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

local function AutoMinigame()
    if not currentRodTool then return end
    if not currentRodTool:GetAttribute("minigame") then return end
    
    local hits = currentRodTool:GetAttribute("minigameHits")
    local hp = currentRodTool:GetAttribute("minigameHP")
    if not hits or not hp or hp == 0 then return end
    
    local now = tick()
    if now - lastMiniClick > 0.15 then
        lastMiniClick = now
        UltraSafeFireRemote("FishingRod.MinigameClick")
    end
end

local function AutoCast()
    if not currentRodTool then return false end
    if currentRodTool:GetAttribute("minigame") then return false end
    if currentRodTool:GetAttribute("casted") then return false end
    if currentRodTool:GetAttribute("castCooldown") then return false end
    if isCasting then return false end
    
    local now = tick()
    if now - lastCastAttempt < 1 then return false end
    
    lastCastAttempt = now
    isCasting = true
    
    local power = math.random(90, 100) / 100
    local success = UltraSafeFireRemote("FishingRod.Cast", power)
    
    task.delay(0.5, function()
        isCasting = false
    end)
    
    if success then
        print("🎣 [CAST] OK")
        return true
    else
        warn("⚠️ [CAST] Failed")
        return false
    end
end

-- ═══════════════════════════════════════════════════════════
-- 🎯 EVENT LISTENERS
-- ═══════════════════════════════════════════════════════════

-- Bite Event
local BiteRE = RemoteInstances["FishingRod.BiteGot"]
if BiteRE then
    BiteRE.OnClientEvent:Connect(function(player)
        if player ~= LocalPlayer then return end
        if not getgenv().AUTO_FISH then return end
        
        print("🐟 [BITE]")
        UltraSafeFireRemote("FishingRod.MinigameClick")
    end)
end

-- Reward Event
local RewardRE = RemoteInstances["FishingRod.Reward"]
if RewardRE then
    RewardRE.OnClientEvent:Connect(function(player, tool, pos, _, animalId, _)
        if player ~= LocalPlayer then return end
        if not getgenv().AUTO_FISH then return end
        
        print("━━━━━━━━━━━━━━━━━━")
        print("🎁 [REWARD]", animalId)
        
        local shouldKeep = ShouldKeepPet(animalId)
        
        if shouldKeep then
            print("⭐ [KEEP] Important!")
        else
            print("💰 [SELL] Trash pet")
            
            -- Sell ngay trong 2 giây
            task.delay(2, function()
                SmartAutoSell()
            end)
        end
        
        print("━━━━━━━━━━━━━━━━━━")
        
        -- QUAN TRỌNG: LUÔN CAST LẠI SAU 1 GIÂY (BẤT KỂ GIỮ HAY BÁN)
        task.delay(1, function()
            -- Force reset state
            isCasting = false
            lastCastAttempt = 0
            
            -- Update tool
            UpdateTool()
            
            -- Nếu không có tool, equip lại
            if not currentRodTool then
                print("🔧 [RESET] Re-equip tool...")
                ForceEquipTool()
                task.wait(0.5)
                UpdateTool()
            end
            
            -- Cast ngay
            print("🎣 [RESET] Force cast now...")
            AutoCast()
        end)
    end)
end

-- Character setup
local function OnCharAdded(char)
    task.wait(2)
    UpdateTool()
    TryBuyBestRod()
    ForceEquipTool()
    task.wait(0.5)
    UpdateTool()
    
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

LocalPlayer.CharacterAdded:Connect(OnCharAdded)
if LocalPlayer.Character then
    OnCharAdded(LocalPlayer.Character)
end

-- ═══════════════════════════════════════════════════════════
-- 🔁 MAIN LOOP (SMART MONITORING)
-- ═══════════════════════════════════════════════════════════
local lastAutoSell = 0
local consecutiveFailures = 0
local lastSuccessfulCast = tick()
local STUCK_TIMEOUT = 15  -- Nếu 15s không cast được, force reset

task.spawn(function()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("✅ ULTRA BYPASS RUNNING!")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    while task.wait(0.2) do
        if not getgenv().AUTO_FISH then continue end
        
        UpdateTool()
        
        local now = tick()
        
        -- Auto sell định kỳ
        if getgenv().AUTO_SELL and (now - lastAutoSell >= 10) then
            lastAutoSell = now
            task.spawn(SmartAutoSell)
        end
        
        -- KIỂM TRA STUCK (15s không cast được)
        if now - lastSuccessfulCast > STUCK_TIMEOUT then
            print("⚠️ [STUCK] No cast for 15s, force reset!")
            
            -- Force reset toàn bộ
            isCasting = false
            lastCastAttempt = 0
            consecutiveFailures = 0
            lastSuccessfulCast = now
            
            UpdateTool()
            if not currentRodTool then
                TryBuyBestRod()
                ForceEquipTool()
                task.wait(1)
                UpdateTool()
            end
            
            -- Cast ngay
            if currentRodTool and not currentRodTool:GetAttribute("minigame") then
                AutoCast()
            end
        end
        
        -- Fishing logic
        if not currentRodTool then
            if not ForceEquipTool() then
                TryBuyBestRod()
            end
            consecutiveFailures = consecutiveFailures + 1
            
            -- Nếu fail quá nhiều, reset mạnh
            if consecutiveFailures > 20 then
                print("⚠️ [ULTRA] Too many failures, force reset...")
                consecutiveFailures = 0
                isCasting = false
                lastCastAttempt = 0
                TryBuyBestRod()
                ForceEquipTool()
                task.wait(1)
            end
        else
            consecutiveFailures = 0
            
            if currentRodTool:GetAttribute("minigame") then
                AutoMinigame()
            elseif currentRodTool:GetAttribute("casted") then
                -- Đang chờ cá cắn, OK
            else
                -- Thử cast
                local castSuccess = AutoCast()
                if castSuccess then
                    lastSuccessfulCast = now
                end
            end
        end
    end
end)

print("🔥 ✅ ULTRA BYPASS LOADED!")
print("💡 This version runs independently with ANY script!")
