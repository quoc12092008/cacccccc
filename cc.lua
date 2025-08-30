local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
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
    checkInterval = 10, -- Check for updates every 60 seconds
    versionEndpoint = "https://raw.githubusercontent.com/quoc12092008/cacccccc/refs/heads/main/version.txt" -- Optional version file
}

-- Global script control
if not getgenv().PET_TRACKER_RUNNING then
    getgenv().PET_TRACKER_RUNNING = false
end

-- Set current version from script
local currentVersion = "1.0.1"
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
    apiSendInterval = 120,
    forceUpdateInterval = 480
}

local allowedPets = {
    "La Vacca Saturno Saturnita", 
    "Chimpanzini Spiderini", 
    "Karkerkar Kurkur",
    "Los Tralaleritos", 
    "Las Tralaleritas",
    "Graipuss Medussi",
    "La Grande Combinasion", 
    "Chicleteira Bicicleteira", 
    "Garama and Madundung",
    "Job Job Job Sahur",
    "Secret Lucky Block",
    "Lucky Block",
    "Sammyni Spyderini",
    "Dul Dul Dul",
    "Blsonte Gluppltere",
    "Lucky Block Secret"
}

local allowedPetSet = {}
for _, petName in ipairs(allowedPets) do
    allowedPetSet[petName:lower()] = true
end

local isAuthenticated = false
local userInfo = nil
local recheckConnection = nil
local updateCheckConnection = nil
local lastFoundPets = {}
local lastPetCheckTime = 0
local lastApiSendTime = 0
local lastForceUpdateTime = 0
local lastUpdateCheckTime = 0

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
            
            -- Extract version from new script
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
        -- Try to restart current instance
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
            
            -- Format pets with required fields
            local formattedPets = {}
            for _, pet in ipairs(pets) do
                if allowedPetSet[pet.name:lower()] then
                    table.insert(formattedPets, {
                        name = pet.name,
                        mut = pet.mut,
                        id = pet.name .. "_" .. pet.mut .. "_" .. os.time() .. "_" .. math.random(100000, 999999),
                        addedAt = os.date("!%Y-%m-%dT%H:%M:%SZ")
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

-- Find player's plot
local function findMyPlot()
    for _, plot in ipairs(Workspace.Plots:GetChildren()) do
        local ownerTag = plot:FindFirstChild("Owner")
        if ownerTag and ownerTag.Value == LocalPlayer then
            return plot
        end
        
        local sign = plot:FindFirstChild("PlotSign")
        local label = sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui.Frame:FindFirstChild("TextLabel")
        if label then
            local txt = label.Text:lower()
            if txt:match(LocalPlayer.Name:lower()) or txt:match(LocalPlayer.DisplayName:lower()) then
                return plot
            end
        end
    end
    return nil
end

-- Get pet data from spawn
local function getPetDataFromSpawn(spawn)
    if not spawn then return nil end

    local attach = spawn:FindFirstChild("Attachment")
    if not attach then return nil end
    
    local overhead = attach:FindFirstChild("AnimalOverhead")
    if not overhead then return nil end
    
    local lbl = overhead:FindFirstChild("DisplayName")
    if not lbl then return nil end
    
    local name = lbl.Text
    if not name or name == "" then return nil end

    local mut = "Normal"
    local petObj = Workspace:FindFirstChild(name)
    if petObj then
        local attrMut = petObj:GetAttribute("Mutation")
        if attrMut and attrMut ~= "" then
            mut = attrMut
        end
    end

    return {name = name, mut = mut}
end

-- Get all allowed pets in plot
local function getAllowedPetsInPlot(plot)
    local pets = {}
    local podFolder = plot and plot:FindFirstChild("AnimalPodiums")
    if not podFolder then return pets end
    
    for _, podium in ipairs(podFolder:GetChildren()) do
        if podium:IsA("Model") then
            local base = podium:FindFirstChild("Base")
            if base then
                local spawn = base:FindFirstChild("Spawn")
                local data = getPetDataFromSpawn(spawn)
                if data and allowedPetSet[data.name:lower()] then
                    table.insert(pets, data)
                end
            end
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
        oldPetMap[key] = (oldPetMap[key] or 0) + 1
    end
    
    for _, pet in ipairs(newPets) do
        local key = pet.name .. "|" .. pet.mut
        newPetMap[key] = (newPetMap[key] or 0) + 1
    end
    
    local added = {}
    local removed = {}
    
    for key, count in pairs(newPetMap) do
        local oldCount = oldPetMap[key] or 0
        if count > oldCount then
            local name, mut = key:match("([^|]+)|(.+)")
            for i = 1, count - oldCount do
                table.insert(added, {name = name, mut = mut})
            end
        end
    end
    
    for key, count in pairs(oldPetMap) do
        local newCount = newPetMap[key] or 0
        if count > newCount then
            local name, mut = key:match("([^|]+)|(.+)")
            for i = 1, count - newCount do
                table.insert(removed, {name = name, mut = mut})
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

-- Display changes
local function displayChanges(added, removed)
    if #added > 0 then
        print("New pets found:")
        for _, pet in ipairs(added) do
            print("  + " .. pet.name .. " | " .. pet.mut)
        end
    end
    
    if #removed > 0 then
        print("Pets removed:")
        for _, pet in ipairs(removed) do
            print("  - " .. pet.name .. " | " .. pet.mut)
        end
    end
end

-- Main monitor function
local function startPetMonitor(plot)
    lastPetCheckTime = tick()
    lastApiSendTime = tick()
    lastForceUpdateTime = tick()
    lastUpdateCheckTime = tick()
    
    lastFoundPets = getAllowedPetsInPlot(plot)
    
    print("Pet Monitor started for: " .. LocalPlayer.Name)
    print("Version: " .. currentVersion)
    print("Found " .. #lastFoundPets .. " pets")
    print("Monitoring " .. #allowedPets .. " pet types")
    print("Auto-update enabled (checks every " .. UPDATE_CONFIG.checkInterval .. "s)")
    
    if API_CONFIG.enabled and isAuthenticated then
        sendDataToAPI(LocalPlayer.Name, lastFoundPets)
        lastApiSendTime = tick()
        lastForceUpdateTime = tick()
    end
    
    -- Mark as running
    getgenv().PET_TRACKER_RUNNING = true
    
    recheckConnection = RunService.Heartbeat:Connect(function()
        -- Check if should stop
        if not getgenv().PET_TRACKER_RUNNING then
            print("Script stop signal received")
            stopScript()
            return
        end
        
        local currentTime = tick()
        
        -- Check for updates
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
        
        -- Regular pet checking
        if currentTime - lastPetCheckTime >= TIMING_CONFIG.petCheckInterval then
            lastPetCheckTime = currentTime
            
            if not plot.Parent then
                print("Plot no longer exists. Stopping monitor.")
                stopScript()
                return
            end
            
            local newPets = getAllowedPetsInPlot(plot)
            local added, removed = comparePetLists(lastFoundPets, newPets)
            
            if #added > 0 or #removed > 0 then
                displayChanges(added, removed)
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

-- Stop old monitor if exists
if recheckConnection then
    recheckConnection:Disconnect()
    print("Stopped old monitor")
end

-- Validate key first
print("Validating key...")
if not validateKey() then
    error("Key validation failed! Check your key and try again.")
    return
end

-- Find plot and start monitoring
local myPlot = findMyPlot()
if not myPlot then
    error("Cannot find your plot! Make sure you're in the game.")
    return
end

startPetMonitor(myPlot)

-- Remove this line as it's not needed
-- getgenv().CURRENT_SCRIPT_SIZE = #tostring(debug.getinfo(1).source)
