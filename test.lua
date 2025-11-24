repeat task.wait() until game:IsLoaded() 
repeat task.wait() until game:GetService('Players') and game:GetService('Players').LocalPlayer and game:GetService('Players').LocalPlayer.Character
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local http = syn and syn.request or http_request or request

-- Check key
if not getgenv().PET_TRACKER_KEY or getgenv().PET_TRACKER_KEY == "" then
    error("Missing key! Set key first:\ngetgenv().PET_TRACKER_KEY = 'your_key_here'")
    return
end

-- Global script control
if not getgenv().PET_TRACKER_RUNNING then
    getgenv().PET_TRACKER_RUNNING = false
end

-- Stop any existing instance
if getgenv().PET_TRACKER_STOP then
    getgenv().PET_TRACKER_STOP()
    print("Stopped previous instance")
    task.wait(1)
end

local API_CONFIG = {
    baseUrl = "https://tracksab.com/trackgameantrom",
    enabled = true,
    retryAttempts = 3,
    retryDelay = 2
}

local TIMING_CONFIG = {
    petCheckInterval = 30,
    apiSendInterval = 60,
    forceUpdateInterval = 120,
    luckyBlockCheckInterval = 5,
    petListRefreshInterval = 5 * 60 -- 5 phút scan lại danh sách pet
}

-- ===== AUTO PET SCANNER =====

local allowedPets = {}
local allowedPetSet = {}
local lastPetScanTime = 0
local LUCKY_BLOCKS = {}

-- Hàm scan pets từ game data
local function scanPetsFromGame()
    local success, result = pcall(function()
        local Animals = require(ReplicatedStorage.Datas.Animals)
        
        local secretPets = {}
        local ogPets = {}
        local luckyBlockPets = {}
        
        for name, data in pairs(Animals) do
            local rarity = data.Rarity
            
            if rarity == "Secret" then
                table.insert(secretPets, name)
            elseif rarity == "OG" then
                table.insert(ogPets, name)
            elseif tostring(name):lower():find("lucky block") or tostring(rarity):lower():find("lucky") then
                table.insert(luckyBlockPets, name)
            end
        end
        
        return {
            secret = secretPets,
            og = ogPets,
            luckyBlocks = luckyBlockPets
        }
    end)
    
    if success and result then
        return result
    else
        warn("Failed to scan pets from game: " .. tostring(result))
        return nil
    end
end

-- Hàm update allowed pets list
local function updateAllowedPetsList()
    local scannedPets = scanPetsFromGame()
    
    if not scannedPets then
        print("⚠️  Pet scan failed, keeping old list")
        return false
    end
    
    -- Clear old lists
    allowedPets = {}
    allowedPetSet = {}
    LUCKY_BLOCKS = {}
    
    -- Add Secret pets
    for _, petName in ipairs(scannedPets.secret) do
        table.insert(allowedPets, petName)
        allowedPetSet[petName:lower()] = true
    end
    
    -- Add OG pets
    for _, petName in ipairs(scannedPets.og) do
        table.insert(allowedPets, petName)
        allowedPetSet[petName:lower()] = true
    end
    
    -- Add Lucky Block pets
    for _, petName in ipairs(scannedPets.luckyBlocks) do
        table.insert(LUCKY_BLOCKS, petName)
        allowedPetSet[petName:lower()] = true
    end
    
    lastPetScanTime = tick()
    
    print("✅ Pet scan complete:")
    print("  🟡 Secret: " .. #scannedPets.secret)
    print("  🔵 OG: " .. #scannedPets.og)
    print("  🟣 Lucky Blocks: " .. #scannedPets.luckyBlocks)
    print("  📊 Total tracking: " .. #allowedPets .. " pets")
    
    return true
end

-- ===== GLOBAL VARIABLES =====

local isAuthenticated = false
local userInfo = nil
local recheckConnection = nil
local luckyBlockConnection = nil
local petScanConnection = nil
local lastFoundPets = {}
local lastPetCheckTime = 0
local lastApiSendTime = 0
local lastForceUpdateTime = 0
local lastLuckyBlockCheckTime = 0

-- Initialize Synchronizer
local Synchronizer = nil
local playerSync = nil

local function initSynchronizer()
    local success, result = pcall(function()
        Synchronizer = require(ReplicatedStorage.Packages.Synchronizer)
        playerSync = Synchronizer:Get(Players.LocalPlayer)
        return true
    end)
    
    if success and playerSync then
        print("✓ Synchronizer initialized")
        return true
    else
        warn("Failed to initialize Synchronizer: " .. tostring(result))
        return false
    end
end

-- Get animal list using Synchronizer
local function getAnimalListViaSynchronizer()
    if not playerSync then return nil end
    
    local success, animalList = pcall(function()
        return playerSync:Get("AnimalPodiums")
    end)
    
    if success and animalList then
        return animalList
    end
    return nil
end

-- Get PlotController safely (fallback)
local function getPlotController()
    local success, controller = pcall(function()
        return require(ReplicatedStorage.Controllers.PlotController)
    end)
    if success then
        return controller
    end
    return nil
end

-- Get animal list from plot (fallback method)
local function getAnimalListViaPlot()
    local controller = getPlotController()
    if not controller then return nil end
    
    local success, animalList = pcall(function()
        local myPlot = controller.GetMyPlot()
        if myPlot and myPlot.Channel then
            return myPlot.Channel:Get("AnimalList")
        end
        return nil
    end)
    
    if success then
        return animalList
    end
    return nil
end

-- Format pet display name with mutation
local function formatPetDisplayName(petName, traits, mutation)
    local displayName = petName
    
    if mutation and mutation ~= "Normal" and mutation ~= "" then
        displayName = displayName .. " | " .. mutation
    end
    
    if traits and type(traits) == "table" and #traits > 0 then
        displayName = displayName .. " (" .. table.concat(traits, ", ") .. ")"
    end
    
    return displayName
end

-- Detect lucky block in animal list
local function detectLuckyBlock()
    local animalList = getAnimalListViaSynchronizer() or getAnimalListViaPlot()
    if not animalList then return nil end
    
    for index, animal in pairs(animalList) do
        if animal and animal.Index then
            for _, luckyBlockName in ipairs(LUCKY_BLOCKS) do
                if animal.Index == luckyBlockName then
                    return index
                end
            end
        end
    end
    
    return nil
end

-- Open lucky block
local function openLuckyBlock(luckyIndex)
    if not luckyIndex then return false end
    
    local success, result = pcall(function()
        local openEvent = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net"):WaitForChild("RE/PlotService/Open")
        openEvent:FireServer(luckyIndex)
        return true
    end)
    
    if success then
        print("✨ Opened lucky block at index: " .. tostring(luckyIndex))
        return true
    else
        warn("Failed to open lucky block: " .. tostring(result))
        return false
    end
end

-- Check and open lucky blocks
local function checkAndOpenLuckyBlocks()
    local luckyIndex = detectLuckyBlock()
    if luckyIndex then
        print("🎁 Lucky block detected!")
        openLuckyBlock(luckyIndex)
    end
end

-- Stop function for cleanup
local function stopScript()
    print("Stopping Pet Tracker...")
    getgenv().PET_TRACKER_RUNNING = false
    
    if recheckConnection then
        recheckConnection:Disconnect()
        recheckConnection = nil
    end
    
    if luckyBlockConnection then
        luckyBlockConnection:Disconnect()
        luckyBlockConnection = nil
    end
    
    if petScanConnection then
        petScanConnection:Disconnect()
        petScanConnection = nil
    end
    
    print("Pet Tracker stopped")
end

-- Set global stop function
getgenv().PET_TRACKER_STOP = stopScript

-- Validate key with server
local function validateKey()
    if not http then
        warn("HTTP request function not available")
        return false
    end
    
    local success, result = pcall(function()
        local url = API_CONFIG.baseUrl .. "/api/auth/validate"
        local requestData = { key = getgenv().PET_TRACKER_KEY }
        local jsonData = HttpService:JSONEncode(requestData)
        
        local response = http({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Accept"] = "application/json"
            },
            Body = jsonData
        })
        
        if response.Success then
            local responseData = HttpService:JSONDecode(response.Body)
            if responseData.success then
                userInfo = responseData.keyInfo
                isAuthenticated = true
                print("Key validated: " .. userInfo.description .. " (" .. userInfo.slots .. " slots)")
                return true
            else
                error("Key validation failed: " .. (responseData.error or "Unknown error"))
            end
        else
            error("HTTP Error: " .. (response.StatusCode or "Unknown"))
        end
    end)
    
    if not success then
        warn("Key validation error: " .. tostring(result))
    end
    
    return success
end

-- Send data to API
local function sendDataToAPI(accountName, pets)
    if not API_CONFIG.enabled or not isAuthenticated then
        return false
    end
    
    local attempt = 0
    while attempt < API_CONFIG.retryAttempts do
        attempt = attempt + 1
        
        local success, result = pcall(function()
            local url = API_CONFIG.baseUrl .. "/api/accounts/" .. HttpService:UrlEncode(accountName)
            
            local formattedPets = {}
            for _, pet in ipairs(pets) do
                if allowedPetSet[pet.name:lower()] then
                    table.insert(formattedPets, {
                        name = pet.name,
                        mut = pet.mut or "Normal",
                        traits = pet.traits or {},
                        count = pet.count or 1,
                        displayName = formatPetDisplayName(pet.name, pet.traits, pet.mut),
                    })
                end
            end
            
            local requestData = {
                pets = formattedPets,
                timestamp = os.time(),
                game_info = {
                    place_id = game.PlaceId,
                    player_id = LocalPlayer.UserId,
                    display_name = LocalPlayer.DisplayName,
                    server_id = game.JobId
                },
                mode = "replace"
            }
            
            local response = http({
                Url = url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Accept"] = "application/json",
                    ["X-API-Key"] = getgenv().PET_TRACKER_KEY
                },
                Body = HttpService:JSONEncode(requestData)
            })
            
            if response.Success then
                local responseData = HttpService:JSONDecode(response.Body)
                if responseData.success then
                    print("API updated: " .. responseData.message)
                    return true
                else
                    error("API Error: " .. (responseData.error or "Unknown"))
                end
            elseif response.StatusCode == 401 then
                error("Authentication failed - invalid key")
            elseif response.StatusCode == 403 then
                error("Slot limit reached")
            elseif response.StatusCode == 429 then
                local retryAfter = 60
                task.wait(retryAfter)
                error("RETRY_RATE_LIMIT")
            else
                error("HTTP " .. (response.StatusCode or "Unknown"))
            end
        end)
        
        if success then
            return true
        else
            if tostring(result):find("RETRY_RATE_LIMIT") then
                continue
            end
            
            if attempt < API_CONFIG.retryAttempts then
                task.wait(API_CONFIG.retryDelay)
            else
                warn("API failed after " .. attempt .. " attempts: " .. tostring(result))
                return false
            end
        end
    end
    
    return false
end

-- Get allowed pets from Synchronizer AnimalPodiums with mutation info
local function getAllowedPetsFromSynchronizer()
    local pets = {}
    local animalList = getAnimalListViaSynchronizer()
    
    if not animalList then return pets end
    
    for index, animal in pairs(animalList) do
        if animal and animal.Index and allowedPetSet[animal.Index:lower()] then
            local mutation = animal.Mutation or "Normal"
            local traits = animal.Traits or {}
            
            table.insert(pets, {
                name = animal.Index,
                mut = mutation,
                traits = traits,
                count = 1,
                lastCollect = animal.LastCollect or nil,
                displayName = formatPetDisplayName(animal.Index, traits, mutation)
            })
        end
    end
    
    return pets
end

-- Compare pet lists for changes
local function comparePetLists(oldPets, newPets)
    local oldPetMap = {}
    local newPetMap = {}
    
    for _, pet in ipairs(oldPets) do
        local key = pet.name .. "|" .. pet.mut
        oldPetMap[key] = (oldPetMap[key] or 0) + (pet.count or 1)
    end
    
    for _, pet in ipairs(newPets) do
        local key = pet.name .. "|" .. pet.mut
        newPetMap[key] = (newPetMap[key] or 0) + (pet.count or 1)
    end
    
    local added = {}
    local removed = {}
    
    for key, count in pairs(newPetMap) do
        local oldCount = oldPetMap[key] or 0
        if count > oldCount then
            local name, mut = key:match("([^|]+)|(.+)")
            for i = 1, count - oldCount do
                local petObj = nil
                for _, pet in ipairs(newPets) do
                    if pet.name == name and pet.mut == mut then
                        petObj = pet
                        break
                    end
                end
                table.insert(added, petObj or {name = name, mut = mut, count = 1, displayName = formatPetDisplayName(name, {}, mut)})
            end
        end
    end
    
    for key, count in pairs(oldPetMap) do
        local newCount = newPetMap[key] or 0
        if count > newCount then
            local name, mut = key:match("([^|]+)|(.+)")
            for i = 1, count - newCount do
                local petObj = nil
                for _, pet in ipairs(oldPets) do
                    if pet.name == name and pet.mut == mut then
                        petObj = pet
                        break
                    end
                end
                table.insert(removed, petObj or {name = name, mut = mut, count = 1, displayName = formatPetDisplayName(name, {}, mut)})
            end
        end
    end
    
    return added, removed
end

-- Check if should send to API
local function shouldSendToAPI(added, removed, timeSinceLastSend, timeSinceLastForce)
    return (#added > 0 or #removed > 0 or 
            timeSinceLastSend >= TIMING_CONFIG.apiSendInterval or 
            timeSinceLastForce >= TIMING_CONFIG.forceUpdateInterval)
end

-- Display changes with mutation info
local function displayChanges(added, removed)
    if #added > 0 then
        print("New pets found:")
        for _, pet in ipairs(added) do
            local countText = pet.count and pet.count > 1 and (" x" .. pet.count) or ""
            print("  + " .. pet.displayName .. countText)
        end
    end
    
    if #removed > 0 then
        print("Pets removed:")
        for _, pet in ipairs(removed) do
            local countText = pet.count and pet.count > 1 and (" x" .. pet.count) or ""
            print("  - " .. pet.displayName .. countText)
        end
    end
end

-- Display current pet counts with mutation info
local function displayPetCounts(pets)
    local petSummary = {}
    
    for _, pet in ipairs(pets) do
        local key = pet.displayName
        petSummary[key] = (petSummary[key] or 0) + (pet.count or 1)
    end
    
    print("Current pets in plot:")
    for petKey, count in pairs(petSummary) do
        local countText = count > 1 and (" x" .. count) or ""
        print("  " .. petKey .. countText)
    end
end

-- ===== MAIN MONITOR FUNCTION =====

local function startPetMonitor()
    -- Initial pet scan
    updateAllowedPetsList()
    
    lastPetCheckTime = tick()
    lastApiSendTime = tick()
    lastForceUpdateTime = tick()
    lastLuckyBlockCheckTime = tick()
    
    lastFoundPets = getAllowedPetsFromSynchronizer()
    
    print("╔════════════════════════════════════════════╗")
    print("║   AUTO PET SCANNER & TRACKER v4.0         ║")
    print("╠════════════════════════════════════════════╣")
    print("║ Player: " .. LocalPlayer.Name)
    print("║ Tracking: " .. #allowedPets .. " pets (auto-scanned)")
    print("║ Found: " .. #lastFoundPets .. " pets in plot")
    print("║ Auto-scan: Every 5 minutes")
    print("║ Lucky Block: Auto-open enabled ✨")
    print("╚════════════════════════════════════════════╝")
    
    displayPetCounts(lastFoundPets)
    
    if API_CONFIG.enabled and isAuthenticated then
        sendDataToAPI(LocalPlayer.Name, lastFoundPets)
        lastApiSendTime = tick()
        lastForceUpdateTime = tick()
    end
    
    getgenv().PET_TRACKER_RUNNING = true
    
    task.spawn(checkAndOpenLuckyBlocks)
    
    recheckConnection = RunService.Heartbeat:Connect(function()
        if not getgenv().PET_TRACKER_RUNNING then
            print("Script stop signal received")
            stopScript()
            return
        end
        
        local currentTime = tick()
        
        -- Auto-scan pets every 5 minutes
        if currentTime - lastPetScanTime >= TIMING_CONFIG.petListRefreshInterval then
            print("🔄 Auto-scanning pets from game...")
            updateAllowedPetsList()
        end
        
        -- Lucky block check
        if currentTime - lastLuckyBlockCheckTime >= TIMING_CONFIG.luckyBlockCheckInterval then
            lastLuckyBlockCheckTime = currentTime
            task.spawn(checkAndOpenLuckyBlocks)
        end
        
        -- Pet check
        -- Pet check
        if currentTime - lastPetCheckTime >= TIMING_CONFIG.petCheckInterval then
            lastPetCheckTime = currentTime
            
            local newPets = getAllowedPetsFromSynchronizer()
            local added, removed = comparePetLists(lastFoundPets, newPets)
            
            -- Hiển thị changes (nếu có)
            if #added > 0 or #removed > 0 then
                displayChanges(added, removed)
            end
            
            -- LUÔN hiển thị current pets mỗi 30s (dù không có thay đổi)
            print("─────────────────────────────────────────")
            print("🔄 Recheck at " .. os.date("%H:%M:%S"))
            displayPetCounts(newPets)
            print("─────────────────────────────────────────")
            
            local timeSinceLastSend = currentTime - lastApiSendTime
            local timeSinceLastForce = currentTime - lastForceUpdateTime
            
            if API_CONFIG.enabled and isAuthenticated and shouldSendToAPI(added, removed, timeSinceLastSend, timeSinceLastForce) then
                local isForced = (timeSinceLastForce >= TIMING_CONFIG.forceUpdateInterval)
                
                local success = sendDataToAPI(LocalPlayer.Name, newPets)
                if success then
                    lastApiSendTime = currentTime
                    if isForced then
                        lastForceUpdateTime = currentTime
                    end
                end
            end
            
            lastFoundPets = newPets
        end
    end)
end

-- ===== STARTUP SEQUENCE =====

if recheckConnection then
    recheckConnection:Disconnect()
    print("Stopped old monitor")
end

print("Validating key...")
if not validateKey() then
    error("Key validation failed! Check your key and try again.")
    return
end

print("Initializing Synchronizer...")
if not initSynchronizer() then
    warn("Failed to initialize Synchronizer. Script will attempt to use fallback methods.")
end

startPetMonitor()
