-- // AUTO SELL PETS (STANDALONE) - CHỈ BÁN PET TRASH, GIỮ LẠI SECRET/OG/LUCKY BLOCK
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("💰 AUTO SELL PETS - STANDALONE")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- ═══════════════════════════════════════════════════════════
-- 🔧 INIT
-- ═══════════════════════════════════════════════════════════

-- Synchronizer
local Synchronizer = require(ReplicatedStorage.Packages.Synchronizer)
local playerChannel = Synchronizer:Get(LocalPlayer)

if not playerChannel then
    print("⏳ Waiting for player channel...")
    playerChannel = Synchronizer:Wait(LocalPlayer)
end
print("✅ Synchronizer ready")

-- Sell Remote
local NetFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")
local SellPetRE = NetFolder:WaitForChild("RE/PlotService/Sell")
print("✅ Sell remote found")

-- ═══════════════════════════════════════════════════════════
-- 📋 SCAN IMPORTANT PETS (SECRET, OG, LUCKY BLOCK)
-- ═══════════════════════════════════════════════════════════

local ImportantPetSet = {}
local ImportantPetList = {}

local function ScanImportantPets()
    local success, Animals = pcall(function()
        return require(ReplicatedStorage.Datas.Animals)
    end)
    
    if not success or not Animals then
        warn("❌ Cannot read Animals data!")
        return false
    end
    
    ImportantPetSet = {}
    ImportantPetList = {}
    
    local counts = {
        secret = 0,
        og = 0,
        lucky = 0
    }
    
    for petName, petData in pairs(Animals) do
        local rarity = petData.Rarity
        
        -- Check if pet is important
        if rarity == "Secret" or 
           rarity == "OG" or 
           tostring(petName):lower():find("lucky block") or 
           tostring(rarity):lower():find("lucky") then
            
            table.insert(ImportantPetList, petName)
            ImportantPetSet[petName:lower()] = true
            
            if rarity == "Secret" then
                counts.secret = counts.secret + 1
            elseif rarity == "OG" then
                counts.og = counts.og + 1
            else
                counts.lucky = counts.lucky + 1
            end
        end
    end
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("📋 IMPORTANT PETS (WILL NOT SELL):")
    print("  🟡 Secret:      " .. counts.secret)
    print("  🔵 OG:          " .. counts.og)
    print("  🟣 Lucky Block: " .. counts.lucky)
    print("  ✅ Total:       " .. #ImportantPetList .. " pets")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    return true
end

-- Scan on startup
if not ScanImportantPets() then
    error("Failed to scan important pets!")
end

-- ═══════════════════════════════════════════════════════════
-- ⚙️ CONFIG
-- ═══════════════════════════════════════════════════════════

getgenv().AUTO_SELL_ENABLED = true
getgenv().AUTO_SELL_INTERVAL = 5     -- Check every 5 seconds
getgenv().AUTO_SELL_DELAY = 0.3      -- Delay between each sell (seconds)

-- ═══════════════════════════════════════════════════════════
-- 🐟 READ ANIMAL PODIUMS
-- ═══════════════════════════════════════════════════════════

local function GetAnimalPodiums()
    if not playerChannel then 
        warn("⚠️ Player channel not available")
        return nil 
    end
    
    local success, animalList = pcall(function()
        return playerChannel:Get("AnimalPodiums")
    end)
    
    if success and animalList and type(animalList) == "table" then
        -- Check if has data
        local hasData = false
        for _ in pairs(animalList) do
            hasData = true
            break
        end
        
        if hasData then
            return animalList
        end
    end
    
    return nil
end

-- ═══════════════════════════════════════════════════════════
-- 💰 AUTO SELL LOGIC
-- ═══════════════════════════════════════════════════════════

local lastSellTime = 0
local totalSold = 0

local function ShouldKeepPet(petName)
    if not petName then return false end
    return ImportantPetSet[petName:lower()] == true
end

local function AutoSellTrashPets()
    if not getgenv().AUTO_SELL_ENABLED then return 0 end
    
    local now = tick()
    if now - lastSellTime < 1 then
        return 0
    end
    
    local animalList = GetAnimalPodiums()
    
    if not animalList then 
        warn("⚠️ [AUTO SELL] Cannot read AnimalPodiums")
        return 0
    end
    
    local soldThisCycle = 0
    
    -- Loop through all pets in plot
    for slotIndex, animalData in pairs(animalList) do
        if animalData and animalData.Index then
            local petName = animalData.Index
            
            -- Check if should keep this pet
            if not ShouldKeepPet(petName) then
                -- Sell this pet
                local success, err = pcall(function()
                    SellPetRE:FireServer(slotIndex)
                end)
                
                if success then
                    soldThisCycle = soldThisCycle + 1
                    totalSold = totalSold + 1
                    
                    print(string.format("💰 [SOLD] %s (slot %s) | Total: %d", 
                        petName, tostring(slotIndex), totalSold))
                    
                    lastSellTime = now
                    task.wait(getgenv().AUTO_SELL_DELAY)
                else
                    warn("❌ [SELL ERROR]", petName, ":", tostring(err))
                end
            end
        end
    end
    
    if soldThisCycle > 0 then
        print(string.format("✅ [CYCLE] Sold %d pets this cycle", soldThisCycle))
    end
    
    return soldThisCycle
end

-- Manual sell function
function ManualSell()
    print("🔄 [MANUAL] Running manual sell...")
    local sold = AutoSellTrashPets()
    print(string.format("✅ [MANUAL] Sold %d pets", sold))
    return sold
end

-- ═══════════════════════════════════════════════════════════
-- 🔁 MAIN LOOP
-- ═══════════════════════════════════════════════════════════

local lastAutoRun = 0

task.spawn(function()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("✅ AUTO SELL IS RUNNING!")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("⏱️  Check interval: " .. getgenv().AUTO_SELL_INTERVAL .. " seconds")
    print("⏳ Delay between sells: " .. getgenv().AUTO_SELL_DELAY .. " seconds")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    while task.wait(1) do
        if not getgenv().AUTO_SELL_ENABLED then 
            continue 
        end
        
        local now = tick()
        
        -- Auto sell based on interval
        if now - lastAutoRun >= getgenv().AUTO_SELL_INTERVAL then
            lastAutoRun = now
            
            task.spawn(function()
                AutoSellTrashPets()
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
-- 🎮 CONTROL FUNCTIONS
-- ═══════════════════════════════════════════════════════════

-- Enable/disable
function EnableAutoSell()
    getgenv().AUTO_SELL_ENABLED = true
    print("✅ Auto sell ENABLED")
end

function DisableAutoSell()
    getgenv().AUTO_SELL_ENABLED = false
    print("⛔ Auto sell DISABLED")
end

-- Change interval
function SetSellInterval(seconds)
    getgenv().AUTO_SELL_INTERVAL = seconds
    print("⏱️  Sell interval set to: " .. seconds .. " seconds")
end

-- Change delay between sells
function SetSellDelay(seconds)
    getgenv().AUTO_SELL_DELAY = seconds
    print("⏳ Sell delay set to: " .. seconds .. " seconds")
end

-- Get stats
function GetStats()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("📊 AUTO SELL STATS:")
    print("  Status: " .. (getgenv().AUTO_SELL_ENABLED and "ENABLED" or "DISABLED"))
    print("  Total sold: " .. totalSold .. " pets")
    print("  Interval: " .. getgenv().AUTO_SELL_INTERVAL .. "s")
    print("  Delay: " .. getgenv().AUTO_SELL_DELAY .. "s")
    print("  Important pets: " .. #ImportantPetList)
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
end

-- Show important pets list
function ShowImportantPets()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("📋 IMPORTANT PETS (WILL NOT SELL):")
    for i, petName in ipairs(ImportantPetList) do
        print("  " .. i .. ". " .. petName)
    end
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
end

-- Re-scan important pets
function RescanPets()
    print("🔄 Re-scanning important pets...")
    if ScanImportantPets() then
        print("✅ Re-scan complete!")
    else
        warn("❌ Re-scan failed!")
    end
end

-- ═══════════════════════════════════════════════════════════
-- 📝 HELP
-- ═══════════════════════════════════════════════════════════

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("💰 AUTO SELL LOADED!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📌 AVAILABLE COMMANDS:")
print("")
print("  ManualSell()           - Sell trash pets now")
print("  EnableAutoSell()       - Enable auto sell")
print("  DisableAutoSell()      - Disable auto sell")
print("  SetSellInterval(5)     - Set check interval (seconds)")
print("  SetSellDelay(0.3)      - Set delay between sells")
print("  GetStats()             - Show statistics")
print("  ShowImportantPets()    - Show pets that won't be sold")
print("  RescanPets()           - Re-scan important pets")
print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🎮 QUICK CONTROLS:")
print("")
print("  getgenv().AUTO_SELL_ENABLED = true/false")
print("  getgenv().AUTO_SELL_INTERVAL = 5  (seconds)")
print("  getgenv().AUTO_SELL_DELAY = 0.3   (seconds)")
print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
