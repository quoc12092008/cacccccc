-- VERSION: 3.3
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local http = syn and syn.request or http_request or request

-- Check key
if not getgenv().PET_TRACKER_KEY or getgenv().PET_TRACKER_KEY == "" then
    error("Missing key! Set key first:\ngetgenv().PET_TRACKER_KEY = 'your_key_here'")
    return
end

-- Script update configuration
local UPDATE_CONFIG = {
    scriptUrl = "https://raw.githubusercontent.com/quoc12092008/cacccccc/refs/heads/main/cc.lua",
    checkInterval = 10,
    versionEndpoint = "https://raw.githubusercontent.com/quoc12092008/cacccccc/refs/heads/main/version.txt"
}

-- Global script control
if not getgenv().PET_TRACKER_RUNNING then
    getgenv().PET_TRACKER_RUNNING = false
end

-- Set current version from script
local currentVersion = "3.3"
getgenv().PET_TRACKER_VERSION = currentVersion

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
    luckyBlockCheckInterval = 5
}

-- ===== GITHUB PETS CONFIGURATION =====

local GITHUB_CONFIG = {
    owner = "quoc12092008",
    repo = "cacccccc",
    branch = "main",
    path = "allowed-pets.json"
}

local allowedPets = {}
local allowedPetSet = {}
local lastPetsFetch = 0
local PETS_CACHE_TTL = 3 * 60

-- Hàm fetch pets từ GitHub
local function fetchPetsFromGitHub()
    if not http then return false end
    
    local success, result = pcall(function()
        local url = string.format(
            "https://raw.githubusercontent.com/%s/%s/%s/%s",
            GITHUB_CONFIG.owner,
            GITHUB_CONFIG.repo,
            GITHUB_CONFIG.branch,
            GITHUB_CONFIG.path
        )
        
        print("📥 Fetching pets from GitHub...")
        
        local response = http({
            Url = url,
            Method = "GET",
            Headers = {
                ["Cache-Control"] = "no-cache"
            }
        })
        
        if response.Success then
            local pets = HttpService:JSONDecode(response.Body)
            if type(pets) == "table" and #pets > 0 then
                allowedPets = pets
                allowedPetSet = {}
                for _, petName in ipairs(allowedPets) do
                    allowedPetSet[petName:lower()] = true
                end
                lastPetsFetch = tick()
                print("✅ Loaded " .. #allowedPets .. " pets from GitHub")
                return true
            else
                print("⚠️  Empty pets list from GitHub")
                return false
            end
        else
            print("❌ GitHub fetch failed: HTTP " .. (response.StatusCode or "Unknown"))
            return false
        end
    end)
    
    if not success then
        print("❌ Error fetching pets: " .. tostring(result))
        return false
    end
end

-- Hàm get pets với cache
local function getPets()
    local now = tick()
    
    if #allowedPets > 0 and (now - lastPetsFetch < PETS_CACHE_TTL) then
        return true
    end
    
    if fetchPetsFromGitHub() then
        return true
    else
        print("⚠️  Using fallback pets list")
        allowedPets = {
        "1x1x1x1",
        "67",
        "Agarrini La Palini",
        "Aquatic Index",
        "Bicicleteira Family",
        "Bisonte Giuppitere",
        "Blackhole Goat",
        "Boatito Auratito",
        "Burguro and Fryuro",
        "Burrito Bandito",
        "Capitano Moby",
        "Celularcini Viciosini",
        "Chachechi",
        "Chicleteira Bicicleteira",
        "Chicleteirina Bicicleteirina",
        "Chillin Chili",
        "Chimpanzini Spiderini",
        "Chipso and Queso",
        "Combinasions",
        "Cooki and Milki",
        "Dragon Cannelloni",
        "Dul Dul Dul",
        "Duo Brainrots",
        "Esok Sekolah",
        "Eviledon",
        "Extinct Matteo",
        "Extinct Tralalero",
        "Fragrama and Chocrama",
        "Frankentteo",
        "Garama and Madundung",
        "Graipuss Medussi",
        "Guest 666",
        "Headless Horseman",
        "Horegini Boom",
        "Indonesian Event",
        "Jackorilla",
        "Job Job Job Sahur",
        "Karker Sahur",
        "Karkerkar Kurkur",
        "Karkerkur Family",
        "Ketchuru and Musturu",
        "Ketupat Kepat",
        "Zombie Tralala",
        "Yess my examine",
        "Vulturino Skeletono",
        "Trickolino",
        "Trenostruzzo Turbo 4000",
        "Tralaledon",
        "Torrtuginni Dragonfrutini",
        "To to to Sahur",
        "Tictac Sahur",
        "Tang Tang Keletang",
        "Tamaluk un Meass",
        "Tacorita Bicicleta",
        "Spooky Juggle",
        "Spooky and Pumpky",
        "Spaghetti Tualetti",
        "Secret Lucky Block",
        "Sammyni Spyderini",
        "Rang Ring Bus",
        "Quesadillo Vampiro",
        "Quesadilla Crocodila",
        "Pumpkini Spyderini",
        "Pot Pumpkin",
        "Pot Hotspot",
        "Pirulitoita Bicicleteira",
        "Perrito Burrito",
        "Nuclearo Dinossauro",
        "Nooo My Hotspot",
        "Noo my examine",
        "Noo my Candy",
        "Money Money Puggy",
        "Mieteteira Bicicleteira",
        "Mariachi Corazoni",
        "Lucky Blocks",
        "Los Tralaleritos",
        "Los Tortus",
        "Los Tacoritas",
        "Los Spyderinis",
        "Los Spooky Combinasionas",
        "Los Spaghettis",
        "Los Primos",
        "Los Nooo My Hotspotsitos",
        "Los Mobilis",
        "Los Matteos",
        "Los Karkeritos",
        "Los Jobcitos",
        "Los Hotspotsitos",
        "Los Combinasionas",
        "Los Chicleteiras",
        "Los Bros",
        "Los 67",
        "Las Vaquitas Saturnitas",
        "Las Tralaleritas",
        "Las Sis",
        "La Vacca Saturno Saturnita",
        "La Vacca Jacko Linterino",
        "La Taco Combinasion",
        "La Supreme Combinasion",
        "La Spooky Grande",
        "La Secret Combinasion",
        "La Sahur Combinasion",
        "La Karkerkar Combinasion",
        "La Grande Combinasion",
        "La Extinct Grande",
        "La Cucaracha",
        "La Casa Boo",
        "Fragola La La La",
        "Blsonte Gluppltere",
        "Guerirro Digitale",
        "Nucclearo Dinossauro",
        "Admin Lucky Block",
        "Taco Lucky Block",
        "Telemorte",
        "Los Spooky",
        "Combinasionas",
        "Tacorita Bicicleta",
        "La Extinct Grande"
        }
        allowedPetSet = {}
        for _, petName in ipairs(allowedPets) do
            allowedPetSet[petName:lower()] = true
        end
        return false
    end
end

-- ===== GLOBAL VARIABLES =====

local isAuthenticated = false
local userInfo = nil
local recheckConnection = nil
local updateCheckConnection = nil
local luckyBlockConnection = nil
local lastFoundPets = {}
local lastPetCheckTime = 0
local lastApiSendTime = 0
local lastForceUpdateTime = 0
local lastUpdateCheckTime = 0
local lastLuckyBlockCheckTime = 0

-- Lucky Block Configuration
local LUCKY_BLOCKS = {
}

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
    
    if updateCheckConnection then
        updateCheckConnection:Disconnect()
        updateCheckConnection = nil
    end
    
    if luckyBlockConnection then
        luckyBlockConnection:Disconnect()
        luckyBlockConnection = nil
    end
    
    print("Pet Tracker stopped")
end

-- Set global stop function
getgenv().PET_TRACKER_STOP = stopScript

-- Check for script updates
local function checkForUpdates()
    if not http then return false end
    
    local success, result = pcall(function()
        local response = http({
            Url = UPDATE_CONFIG.scriptUrl,
            Method = "GET",
            Headers = {
                ["Cache-Control"] = "no-cache",
                ["Pragma"] = "no-cache"
            }
        })
        
        if response.Success then
            local newScript = response.Body
            local newVersion = newScript:match("-- VERSION: ([%d%.]+)")
            if newVersion and newVersion ~= getgenv().PET_TRACKER_VERSION then
                getgenv().PET_TRACKER_VERSION = newVersion
                return true, newVersion
            end
        end
        
        return false
    end)
    
    if success then
        return result
    else
        warn("Update check failed: " .. tostring(result))
        return false
    end
end

-- Reload script
local function reloadScript()
    print("🔄 Reloading script...")
    stopScript()
    task.wait(2)
    
    local success, result = pcall(function()
        loadstring(game:HttpGet(UPDATE_CONFIG.scriptUrl))()
    end)
    
    if not success then
        warn("Failed to reload script: " .. tostring(result))
        getgenv().PET_TRACKER_RUNNING = true
    end
end

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
    getPets()
    
    lastPetCheckTime = tick()
    lastApiSendTime = tick()
    lastForceUpdateTime = tick()
    lastUpdateCheckTime = tick()
    lastLuckyBlockCheckTime = tick()
    
    lastFoundPets = getAllowedPetsFromSynchronizer()
    
    print("Pet Monitor started for: " .. LocalPlayer.Name)
    print("Version: " .. currentVersion)
    print("Found " .. #lastFoundPets .. " pets")
    print("Monitoring " .. #allowedPets .. " pet types")
    print("Auto-update enabled (checks every " .. UPDATE_CONFIG.checkInterval .. "s)")
    print("Lucky Block auto-open enabled ✨")
    
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
        
        if currentTime - lastLuckyBlockCheckTime >= TIMING_CONFIG.luckyBlockCheckInterval then
            lastLuckyBlockCheckTime = currentTime
            task.spawn(checkAndOpenLuckyBlocks)
        end
        
        if currentTime - lastUpdateCheckTime >= UPDATE_CONFIG.checkInterval then
            lastUpdateCheckTime = currentTime
            
            local hasUpdate, newVersion = checkForUpdates()
            if hasUpdate then
                print("🆕 Update detected! New version: " .. tostring(newVersion))
                print("Reloading script in 3 seconds...")
                task.wait(3)
                reloadScript()
                return
            end
        end
        
        if currentTime - lastPetCheckTime >= TIMING_CONFIG.petCheckInterval then
            lastPetCheckTime = currentTime
            
            local newPets = getAllowedPetsFromSynchronizer()
            local added, removed = comparePetLists(lastFoundPets, newPets)
            
            if #added > 0 or #removed > 0 then
                displayChanges(added, removed)
                displayPetCounts(newPets)
            end
            
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
