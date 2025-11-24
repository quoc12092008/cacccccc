-- // AUTO FISH - BYPASS VERSION (CHỐNG CONFLICT VỚI SCRIPT KHÁC)
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer

-- ⚡ LƯU TRỮ REFERENCES SỚM NHẤT CÓ THỂ (TRƯỚC KHI SCRIPT KHÁC HOOK)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

print("🔥 [BYPASS] Đang lấy references...")

-- Backup các hàm gốc trước khi bị hook
local originalFireServer = Instance.new("RemoteEvent").FireServer
local originalInvokeServer = Instance.new("RemoteFunction").InvokeServer

-- Net (Sleitnick) - LƯU SỚM
local Net = require(ReplicatedStorage.Packages.Net)

-- ⚡ LƯU TẤT CẢ REMOTES VÀO CACHE NGAY
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
            -- Backup phương thức gốc
            Fire = remote.FireServer,
            Invoke = remoteType == "Function" and remote.InvokeServer or nil
        }
        print("✅ [BYPASS] Cached:", remoteName)
        return true
    else
        warn("❌ [BYPASS] Failed to cache:", remoteName)
        return false
    end
end

-- Cache tất cả remotes ngay lập tức
CacheRemote("FishingRod.Cast", "Event")
CacheRemote("FishingRod.Cancel", "Event")
CacheRemote("FishingRod.SetupBobber", "Event")
CacheRemote("FishingRod.MinigameClick", "Event")
CacheRemote("FishingRod.Reward", "Event")
CacheRemote("FishingRod.BiteGot", "Event")

-- Remotes shop
local NetFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")
local BuyRodRF   = NetFolder:WaitForChild("RF/RodsShopService/RequestBuy")
local EquipRodRF = NetFolder:WaitForChild("RF/RodsShopService/RequestEquip")

-- Backup shop remotes
RemoteCache["BuyRod"] = {
    remote = BuyRodRF,
    type = "Function",
    Invoke = BuyRodRF.InvokeServer
}
RemoteCache["EquipRod"] = {
    remote = EquipRodRF,
    type = "Function",
    Invoke = EquipRodRF.InvokeServer
}

print("🔥 [BYPASS] Đã cache xong tất cả remotes!")

-- Cấu hình
getgenv().AUTO_FISH         = true
getgenv().AUTO_BEST_ROD     = true
getgenv().AUTO_EQUIP_ROD    = true

----------------------------------------------------------------
-- 🛡️ HÀM CALL REMOTE AN TOÀN (DÙNG CACHE)
----------------------------------------------------------------
local function SafeFireRemote(remoteName, arg1, arg2, arg3, arg4, arg5)
    local cached = RemoteCache[remoteName]
    if not cached then
        warn("[BYPASS] Remote not cached:", remoteName)
        return false
    end
    
    local success, result = pcall(function()
        -- Dùng phương thức đã backup
        return cached.Fire(cached.remote, arg1, arg2, arg3, arg4, arg5)
    end)
    
    if not success then
        -- Fallback: thử dùng cách thông thường
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
        -- Fallback
        success, result = pcall(function()
            return cached.remote:InvokeServer(arg1, arg2, arg3, arg4, arg5)
        end)
    end
    
    return success, result
end

----------------------------------------------------------------
-- 🌈 DANH SÁCH CẦN CÂU
----------------------------------------------------------------
local RodPriority = {
    "Radioactive Rod",
    "Fiery Rod", 
    "Frozen Rod",
    "Starter Rod",
}

----------------------------------------------------------------
-- 🧠 EQUIP CẦN
----------------------------------------------------------------
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

----------------------------------------------------------------
-- 💎 AUTO MUA + EQUIP CẦN XỊN NHẤT
----------------------------------------------------------------
local function AutoBuyAndEquipBestRod()
    if not getgenv().AUTO_BEST_ROD then return false end

    for _, rodName in ipairs(RodPriority) do
        -- Thử EQUIP
        local okEquip, resEquip = SafeInvokeRemote("EquipRod", rodName)
        task.wait(0.3)

        if LocalPlayer:GetAttribute("EquippedFishingRod") == rodName then
            print("[AUTO ROD] ✅ Equipped:", rodName)
            EquipCurrentRodTool()
            return true
        end

        -- Thử MUA
        local okBuy, resBuy = SafeInvokeRemote("BuyRod", rodName)
        task.wait(0.3)

        -- Equip lại sau khi mua
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
-- 🎣 QUẢN LÝ TOOL
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
    local hp   = currentRodTool:GetAttribute("minigameHP")

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

    -- 🔧 FORCE RESET TOOL STATE (tránh conflict với script gốc)
    pcall(function()
        -- Thử deactivate tool nếu đang activate
        if currentRodTool.Activated then
            currentRodTool:Deactivate()
        end
    end)
    
    task.wait(0.1)

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
-- 🐟 LISTEN BITE EVENT (DÙNG CACHE)
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
-- 🎁 LISTEN REWARD EVENT
----------------------------------------------------------------
local RewardRE = RemoteCache["FishingRod.Reward"]
if RewardRE and RewardRE.remote then
    RewardRE.remote.OnClientEvent:Connect(function(pPlayer, bobber, pos, _, animalId, _)
        if pPlayer ~= LocalPlayer then return end
        if not getgenv().AUTO_FISH then return end

        print("🎁 [AUTO FISH] Câu được rồi! Đợi cast lại...")
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

task.spawn(function()
    print("✅ AUTO FISH ĐANG CHẠY (BYPASS MODE)...")
    
    while task.wait(MAIN_LOOP_DELAY) do
        if not getgenv().AUTO_FISH then continue end
        
        UpdateCurrentRodTool()
        
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

print("🔥 ✅ AUTO FISH + AUTO RODS LOADED (BYPASS MODE)")
