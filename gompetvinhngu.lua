--[[
    HOLD PET SCRIPT - SAFE VERSION (getgc)
    
    CONFIG TRƯỚC KHI CHẠY:
    
    getgenv().TARGET_PETS = {
        ["Secret Lucky Block"] = true,
        ["Festive Lucky Block"] = true,
        -- Thêm pet muốn farm
    }
    getgenv().HoldTime = 3.5      -- Thời gian giữ E
    getgenv().CheckInterval = 3   -- Interval check pet
    
    Rồi loadstring script này
]]

repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
local plr = game.Players.LocalPlayer
repeat task.wait() until plr.Character
repeat task.wait() until plr.Character:FindFirstChild("HumanoidRootPart")
task.wait(5)

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

--[[ ====================== CONFIG ====================== ]]

local SERVER_URL = "http://127.0.0.1:3000"
local MAX_PETS = 10

getgenv().TARGET_PETS = getgenv().TARGET_PETS or {
    ["Secret Lucky Block"] = false,
}

local HoldTime = getgenv().HoldTime or 3.5
local CheckInterval = getgenv().CheckInterval or 3

local HEARTBEAT_INTERVAL = 3
local STEAL_CHECK_INTERVAL = 1
local MAX_STEAL_ATTEMPTS = 3
local PET_SKIP_TIMEOUT = 60

local CAMERA_ZOOM = 15

local FLOOR_CONFIG = {
    GROUND_MAX = 10,
    FLOOR1_MAX = 20,
    FLOOR2_MIN = 20,
}

local STAIR_LV_POINTS = {
    Vector3.new(-301, 12, 113),
    Vector3.new(-301, 12, 6),
    Vector3.new(-301, 12, 220),
    Vector3.new(-301, 12, -99),
    Vector3.new(-518, 13, 112),
    Vector3.new(-518, 12, 6),
    Vector3.new(-518, 12, 220),
    Vector3.new(-518, 12, -100),
}

--[[ ====================== CONSOLE LOGGER ====================== ]]

local function log(emoji, message, important)
    local prefix = important and "\n" or ""
    local suffix = important and "\n" or ""
    print(prefix .. emoji .. " " .. message .. suffix)
end

--[[ ====================== MOUSE BLOCKER SYSTEM ====================== ]]

local mouseBlockerGui = nil
local mouseBlockerActive = false

local function SetCameraZoom(zoomLevel)
    pcall(function()
        LocalPlayer.CameraMinZoomDistance = zoomLevel
        LocalPlayer.CameraMaxZoomDistance = zoomLevel
        log("🔭", string.format("Camera zoom locked at: %d", zoomLevel))
    end)
end

local function ResetCameraZoom()
    pcall(function()
        LocalPlayer.CameraMinZoomDistance = 0.5
        LocalPlayer.CameraMaxZoomDistance = 400
        log("🔭", "Camera zoom reset to default")
    end)
end

local function CreateMouseBlocker()
    mouseBlockerGui = Instance.new("ScreenGui")
    mouseBlockerGui.Name = "MouseBlocker"
    mouseBlockerGui.ResetOnSpawn = false
    mouseBlockerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mouseBlockerGui.DisplayOrder = 999999
    mouseBlockerGui.IgnoreGuiInset = true
    
    local blocker = Instance.new("TextButton")
    blocker.Name = "Blocker"
    blocker.Size = UDim2.new(1, 0, 1, 0)
    blocker.Position = UDim2.new(0, 0, 0, 0)
    blocker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blocker.BackgroundTransparency = 0.97
    blocker.BorderSizePixel = 0
    blocker.Text = ""
    blocker.AutoButtonColor = false
    blocker.Active = true
    blocker.ZIndex = 999999
    blocker.Parent = mouseBlockerGui
    
    blocker.MouseButton1Click:Connect(function() end)
    blocker.MouseButton2Click:Connect(function() end)
    
    local warningLabel = Instance.new("TextLabel")
    warningLabel.Name = "WarningText"
    warningLabel.Size = UDim2.new(1, 0, 0, 80)
    warningLabel.Position = UDim2.new(0, 0, 0, 10)
    warningLabel.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    warningLabel.BackgroundTransparency = 0.2
    warningLabel.BorderSizePixel = 0
    warningLabel.Text = "SCRIPT ĐANG CHẠY"
    warningLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    warningLabel.TextSize = 24
    warningLabel.Font = Enum.Font.GothamBold
    warningLabel.TextWrapped = true
    warningLabel.TextStrokeTransparency = 0
    warningLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    warningLabel.ZIndex = 9999999
    warningLabel.Parent = blocker
    
    mouseBlockerGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    log("🔒", "Mouse Blocker UI created!", true)
end

local function EnableMouseBlock()
    if mouseBlockerActive then return end
    mouseBlockerActive = true
    
    if not mouseBlockerGui then
        CreateMouseBlocker()
    end
    mouseBlockerGui.Enabled = true
    
    ContextActionService:BindActionAtPriority("BlockAllMouse1", function()
        return Enum.ContextActionResult.Sink
    end, false, 10000, Enum.UserInputType.MouseButton1)
    
    ContextActionService:BindActionAtPriority("BlockAllMouse2", function()
        return Enum.ContextActionResult.Sink
    end, false, 10000, Enum.UserInputType.MouseButton2)
    
    ContextActionService:BindActionAtPriority("BlockAllMouse3", function()
        return Enum.ContextActionResult.Sink
    end, false, 10000, Enum.UserInputType.MouseButton3)
    
    ContextActionService:BindActionAtPriority("BlockAllMouseMove", function()
        return Enum.ContextActionResult.Sink
    end, false, 10000, Enum.UserInputType.MouseMovement)
    
    ContextActionService:BindActionAtPriority("BlockAllMouseWheel", function()
        return Enum.ContextActionResult.Sink
    end, false, 10000, Enum.UserInputType.MouseWheel)
    
    ContextActionService:BindActionAtPriority("BlockAllTouch", function()
        return Enum.ContextActionResult.Sink
    end, false, 10000, Enum.UserInputType.Touch)
    
    pcall(function()
        UserInputService.MouseIconEnabled = false
    end)
    
    log("🔒", "Mouse input BLOCKED!")
end

local function DisableMouseBlock()
    if not mouseBlockerActive then return end
    mouseBlockerActive = false
    
    ContextActionService:UnbindAction("BlockAllMouse1")
    ContextActionService:UnbindAction("BlockAllMouse2")
    ContextActionService:UnbindAction("BlockAllMouse3")
    ContextActionService:UnbindAction("BlockAllMouseMove")
    ContextActionService:UnbindAction("BlockAllMouseWheel")
    ContextActionService:UnbindAction("BlockAllTouch")
    
    pcall(function()
        UserInputService.MouseIconEnabled = true
    end)
    
    if mouseBlockerGui then
        mouseBlockerGui.Enabled = false
    end
    
    log("🔓", "Mouse input UNBLOCKED!")
end

--[[ ====================== HTTP API ====================== ]]

local function httpPost(endpoint, data)
    local success, result = pcall(function()
        return request({
            Url = SERVER_URL .. endpoint,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
    if success and result and result.Body then
        local ok, json = pcall(function()
            return HttpService:JSONDecode(result.Body)
        end)
        if ok then return json end
    end
    return nil
end

local function closeGame()
    DisableMouseBlock()
    ResetCameraZoom()
    
    task.spawn(function()
        pcall(function()
            request({
                Url = SERVER_URL .. "/hold/kill",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({username = LocalPlayer.Name})
            })
        end)
    end)
end

--[[ ====================== AUTH ====================== ]]

log("🔐", "Authenticating: " .. LocalPlayer.Name)
local authResult = httpPost("/auth", {username = LocalPlayer.Name})

if not authResult or authResult.status ~= "ok" then
    log("❌", "Authentication failed!", true)
    closeGame()
    return
end

log("✅", "Authentication successful")

--[[ ====================== GETGC() - ĐỌC DATA AN TOÀN ====================== ]]

local function getAnimalPodiumsViaGC()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            local cache = rawget(v, "CacheTable")
            if cache and type(cache) == "table" then
                local animals = rawget(cache, "AnimalPodiums")
                if animals and type(animals) == "table" and next(animals) then
                    return animals
                end
            end
        end
    end
    return nil
end

local function getAnimalListSafe()
    for attempt = 1, 3 do
        local animalList = getAnimalPodiumsViaGC()
        
        if animalList and type(animalList) == "table" then
            local hasData = false
            for _ in pairs(animalList) do
                hasData = true
                break
            end
            if hasData then
                return animalList
            end
        end
        task.wait(0.5)
    end
    return nil
end

--[[ ====================== PET COUNTER ====================== ]]

local function countPetsInBase()
    local animalList = getAnimalListSafe()
    
    if not animalList then
        log("⚠️", "Failed to read pet list")
        return 0, "Failed"
    end
    
    local count = 0
    for index, animal in pairs(animalList) do
        local animalName = animal.Index or animal.Animal or animal.Name
        if animalName then
            count = count + 1
        end
    end
    
    log("📊", string.format("Pet count: %d/%d (via getgc)", count, MAX_PETS))
    return count, "getgc"
end

--[[ ====================== STATE ====================== ]]

local characterDied = false
local collecting = false
local isClimbingFloor2 = false
local savedStairPosition = nil
local isHandlingPet = false
local currentPetCount = 0
local myPlot = nil
local collectedPets = {}
local skippedPets = {}

local homePosition = hrp.Position
log("🏠", string.format("Home position saved: (%.0f, %.0f, %.0f)", homePosition.X, homePosition.Y, homePosition.Z))

local lastHeartbeat = tick()

local function sendHeartbeat()
    if tick() - lastHeartbeat >= HEARTBEAT_INTERVAL then
        for attempt = 1, 3 do
            local result = httpPost("/hold/heartbeat", {
                username = LocalPlayer.Name,
                pet_count = currentPetCount,
                status = isHandlingPet and "collecting" or "searching"
            })
            
            if result then
                lastHeartbeat = tick()
                return true
            end
            
            if attempt < 3 then
                task.wait(0.5)
            end
        end
        
        log("⚠️", "Heartbeat failed after 3 attempts!")
        lastHeartbeat = tick()
        return false
    end
    return true
end

--[[ ====================== CHARACTER MONITOR ====================== ]]

local function setupCharacterMonitor()
    characterDied = false
    humanoid.Died:Connect(function()
        characterDied = true
    end)
end

setupCharacterMonitor()

LocalPlayer.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    hrp = character:WaitForChild("HumanoidRootPart")
    setupCharacterMonitor()
    task.wait(0.3)
    characterDied = false
    collecting = false
    isClimbingFloor2 = false
    isHandlingPet = false
end)

--[[ ====================== PLOT UTILS ====================== ]]

local PlotController = nil

local function initPlotController()
    local success, result = pcall(function()
        PlotController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("PlotController"))
        return true
    end)
    return success
end

local function GetMyPlot()
    if not PlotController then return nil end
    local success, result = pcall(function()
        local myPlotClient = PlotController.GetMyPlot()
        if myPlotClient and myPlotClient.PlotModel then
            return myPlotClient.PlotModel
        end
        return nil
    end)
    if success then return result end
    return nil
end

--[[ ====================== INIT ====================== ]]

log("🔌", "Initializing systems...")

-- Test getgc()
log("🔍", "Testing getgc() method...")
local testData = getAnimalPodiumsViaGC()
if testData then
    local count = 0
    for _ in pairs(testData) do count = count + 1 end
    log("✅", "getgc() working - Found " .. count .. " pets in cache")
else
    log("⚠️", "getgc() returned nil - Waiting for data...")
    task.wait(3)
end

initPlotController()
task.wait(1)

myPlot = GetMyPlot()

currentPetCount = countPetsInBase()
httpPost("/hold/pet-count", {username = LocalPlayer.Name, pet_count = currentPetCount})

if currentPetCount >= MAX_PETS then
    log("✅", "ALREADY FULL! " .. currentPetCount .. " PETS", true)
    httpPost("/hold/full", {username = LocalPlayer.Name, pet_count = currentPetCount})
    closeGame()
    return
end

httpPost("/hold/ready", {username = LocalPlayer.Name})
log("✅", "Ready to farm!", true)

EnableMouseBlock()
SetCameraZoom(CAMERA_ZOOM)

task.spawn(function()
    while true do
        local success = sendHeartbeat()
        if not success then
            task.wait(0.5)
        else
            task.wait(1)
        end
    end
end)

--[[ ====================== FLOOR UTILS ====================== ]]

local function GetFloorLevel(yPos)
    if yPos < FLOOR_CONFIG.GROUND_MAX then return 0
    elseif yPos < FLOOR_CONFIG.FLOOR1_MAX then return 1
    else return 2 end
end

local function GetPetPosition(pet)
    if not pet or not pet.Parent then return nil end

    if pet.WorldPivot then
        local ok, cf = pcall(function() return pet.WorldPivot end)
        if ok and typeof(cf) == "CFrame" then return cf.Position end
    end

    if pet:IsA("Model") then
        local pp = pet.PrimaryPart or pet:FindFirstChildWhichIsA("BasePart", true)
        if pp then return pp.Position end
    elseif pet:IsA("BasePart") then
        return pet.Position
    end

    return nil
end

--[[ ====================== CAMERA LOCK ====================== ]]

local cameraConnection = nil
local lockedCFrame = nil

local function LockCamera(cam, targetCFrame)
    lockedCFrame = targetCFrame
    
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = lockedCFrame
    
    if cameraConnection then
        cameraConnection:Disconnect()
    end
    cameraConnection = RunService.RenderStepped:Connect(function()
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = lockedCFrame
    end)
    
    log("📷", "Camera LOCKED")
end

local function UnlockCamera(cam, originalCFrame, originalCameraType)
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
    end
    
    cam.CFrame = originalCFrame
    cam.CameraType = originalCameraType or Enum.CameraType.Custom
    
    lockedCFrame = nil
    
    log("📷", "Camera UNLOCKED")
end

--[[ ====================== HOLD E + STEALING CHECK ====================== ]]

local function CheckStealingStatus()
    local success, stealing = pcall(function()
        return LocalPlayer:GetAttribute("Stealing")
    end)
    
    if success then
        return stealing
    end
    return nil
end

local function HoldKeyE(duration, pet)
    collecting = true
    
    humanoid:Move(Vector3.new(0, 0, 0))
    task.wait(0.1)
    
    local cam = Workspace.CurrentCamera
    local originalCam = cam.CFrame
    local originalCameraType = cam.CameraType
    
    local targetCFrame = originalCam
    if pet and pet.Parent then
        local petPos = GetPetPosition(pet)
        if petPos then
            targetCFrame = CFrame.new(hrp.Position + Vector3.new(0, 2, 0), petPos)
        end
    end
    
    LockCamera(cam, targetCFrame)
    
    task.wait(1.5)
    
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    
    local holdStart = tick()
    local stealingConfirmed = false
    
    while tick() - holdStart < duration do
        local stealing = CheckStealingStatus()
        
        if stealing == true then
            stealingConfirmed = true
            log("✅", "Stealing = true → Pet grabbed!")
            break
        end
        
        task.wait(0.3)
    end
    
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    
    task.wait(0.3)
    
    if not stealingConfirmed then
        local finalCheck = CheckStealingStatus()
        if finalCheck == true then
            stealingConfirmed = true
            log("✅", "Final check: Stealing = true → Pet grabbed!")
        end
    end
    
    UnlockCamera(cam, originalCam, originalCameraType)
    
    task.wait(0.1)
    collecting = false
    
    if not stealingConfirmed then
        log("⚠️", "Stealing still nil after hold → May not have grabbed")
    end
    
    return stealingConfirmed
end

--[[ ====================== FIND NEAREST STAIR TO PET ====================== ]]

local function FindNearestStairToPet(petPos)
    local nearestStair = nil
    local minDist = math.huge
    
    for _, stairPos in ipairs(STAIR_LV_POINTS) do
        local dist = (Vector3.new(petPos.X, stairPos.Y, petPos.Z) - stairPos).Magnitude
        if dist < minDist then
            minDist = dist
            nearestStair = stairPos
        end
    end
    
    return nearestStair, minDist
end

--[[ ====================== LEVITATE FUNCTIONS ====================== ]]

local function FlyUp(duration, speed)
    duration = duration or 0.8
    speed = speed or 40
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = hrp

    local lv = Instance.new("LinearVelocity")
    lv.Attachment0 = attachment
    lv.MaxForce = 50000
    lv.VectorVelocity = Vector3.new(0, speed, 0)
    lv.Parent = hrp

    task.wait(duration)
    lv:Destroy()
    attachment:Destroy()
    task.wait(0.1)
end

local function FlyDirection(direction, duration, speed)
    duration = duration or 0.5
    speed = speed or 30
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = hrp

    local lv = Instance.new("LinearVelocity")
    lv.Attachment0 = attachment
    lv.MaxForce = 50000
    lv.VectorVelocity = direction.Unit * speed
    lv.Parent = hrp

    task.wait(duration)
    lv:Destroy()
    attachment:Destroy()
    task.wait(0.1)
end

local function FlyDown(duration, speed)
    duration = duration or 0.6
    speed = speed or 30
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = hrp

    local lv = Instance.new("LinearVelocity")
    lv.Attachment0 = attachment
    lv.MaxForce = 50000
    lv.VectorVelocity = Vector3.new(0, -speed, 0)
    lv.Parent = hrp

    task.wait(duration)
    lv:Destroy()
    attachment:Destroy()
    task.wait(0.1)
end

--[[ ====================== WALL DETECTION ====================== ]]

local function IsStuckAgainstWall()
    local lookVector = hrp.CFrame.LookVector
    local checkDistance = 3
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {character}
    
    local rayOrigin = hrp.Position + Vector3.new(0, 1, 0)
    local rayDirection = lookVector * checkDistance
    
    local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
    
    if rayResult and rayResult.Instance then
        local hitPart = rayResult.Instance
        if hitPart:IsA("BasePart") and hitPart.CanCollide then
            return true, rayResult.Position
        end
    end
    
    return false, nil
end

local function ForceUnstuckFromWall()
    log("🧱", "Stuck against wall! Trying to move away...")
    
    local directions = {
        -hrp.CFrame.LookVector * 8,
        hrp.CFrame.RightVector * 8,
        -hrp.CFrame.RightVector * 8,
    }
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {character}
    
    for i, dir in ipairs(directions) do
        local checkPos = hrp.Position + dir
        local ray = workspace:Raycast(hrp.Position, dir, rayParams)
        
        if not ray or ray.Distance > 6 then
            humanoid:MoveTo(checkPos)
            humanoid.Jump = true
            
            local moveStart = tick()
            while (hrp.Position - checkPos).Magnitude > 3 and tick() - moveStart < 2 do
                task.wait(0.1)
            end
            
            log("✅", string.format("Moved away from wall (direction %d)", i))
            return true
        end
    end
    
    log("⚠️", "All directions blocked! Force jump...")
    humanoid.Jump = true
    humanoid:MoveTo(hrp.Position + (-hrp.CFrame.LookVector * 5))
    task.wait(1)
    
    return false
end

--[[ ====================== SIMPLE MOVE (ANTI-WALL) ====================== ]]

local function DirectMoveTo(targetPos, timeout)
    if not targetPos then return false end
    timeout = timeout or 5
    
    humanoid:MoveTo(targetPos)
    
    local startTime = tick()
    local lastPos = hrp.Position
    local stuckTime = tick()
    local stuckCount = 0
    local wallStuckCount = 0
    local lastWallUnstuck = 0
    
    while (hrp.Position - targetPos).Magnitude > 4 do
        if tick() - startTime > timeout then 
            log("⏱️", "DirectMove timeout")
            break 
        end
        if characterDied then return false end
        
        if tick() - lastWallUnstuck > 2 then
            local isWallStuck, wallPos = IsStuckAgainstWall()
            if isWallStuck then
                wallStuckCount = wallStuckCount + 1
                if wallStuckCount >= 3 then
                    local success = ForceUnstuckFromWall()
                    if success then
                        lastWallUnstuck = tick()
                        wallStuckCount = 0
                        stuckCount = 0
                    end
                end
            else
                wallStuckCount = 0
            end
        end
        
        if tick() - stuckTime > 0.5 then
            local moved = (hrp.Position - lastPos).Magnitude
            if moved < 0.3 then
                stuckCount = stuckCount + 1
                
                if stuckCount == 1 then
                    humanoid.Jump = true
                elseif stuckCount == 2 then
                    humanoid.Jump = true
                    local rightDir = hrp.CFrame.RightVector
                    humanoid:MoveTo(hrp.Position + rightDir * 5)
                    task.wait(0.3)
                elseif stuckCount == 3 then
                    humanoid.Jump = true
                    local leftDir = -hrp.CFrame.RightVector
                    humanoid:MoveTo(hrp.Position + leftDir * 5)
                    task.wait(0.3)
                elseif stuckCount >= 4 then
                    if tick() - lastWallUnstuck > 2 then
                        ForceUnstuckFromWall()
                        lastWallUnstuck = tick()
                    end
                    stuckCount = 0
                end
            else
                stuckCount = 0
            end
            
            lastPos = hrp.Position
            stuckTime = tick()
        end
        
        humanoid:MoveTo(targetPos)
        task.wait(0.08)
    end
    
    return (hrp.Position - targetPos).Magnitude < 10
end

--[[ ====================== PATHFINDING (ANTI-WALL) ====================== ]]

local function WalkToPosition(targetPos, targetPet, enableJump)
    if not targetPos then return false end
    if targetPet and not targetPet.Parent then return false end
    
    if enableJump == nil then enableJump = true end

    local dist = (hrp.Position - targetPos).Magnitude
    if dist < 30 then
        return DirectMoveTo(targetPos, 8)
    end

    local maxRetries = 2
    local retryCount = 0
    
    while retryCount < maxRetries do
        retryCount = retryCount + 1
        
        local path = PathfindingService:CreatePath({
            AgentRadius = 7,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentCanClimb = true,
            WaypointSpacing = 8,
            Costs = {
                Water = math.huge,
                Danger = math.huge
            }
        })

        local ok = pcall(function()
            path:ComputeAsync(hrp.Position, targetPos)
        end)

        if not ok or path.Status ~= Enum.PathStatus.Success then
            if retryCount >= maxRetries then
                log("⚠️", "Pathfinding failed, using DirectMove")
                return DirectMoveTo(targetPos, 10)
            end
            task.wait(0.2)
            continue
        end
        
        local waypoints = path:GetWaypoints()
        local pathStuckCount = 0
        local lastPathPos = hrp.Position
        local pathStuckTime = tick()
        local needRecompute = false
        
        for i, waypoint in ipairs(waypoints) do
            if characterDied then return false end
            if targetPet and not targetPet.Parent then return false end
            if needRecompute then break end

            humanoid:MoveTo(waypoint.Position)

            local reachedWaypoint = false
            local connection
            connection = humanoid.MoveToFinished:Connect(function(reached)
                reachedWaypoint = true
                if connection then connection:Disconnect() end
            end)

            local startTime = tick()
            local lastPosition = hrp.Position
            local stuckCheckTime = tick()
            local waypointStuckCount = 0
            local wallCheckTime = tick()

            while not reachedWaypoint and (hrp.Position - waypoint.Position).Magnitude > 3 do
                if characterDied then
                    if connection then connection:Disconnect() end
                    return false
                end
                if targetPet and not targetPet.Parent then
                    if connection then connection:Disconnect() end
                    return false
                end

                if waypoint.Action == Enum.PathWaypointAction.Jump and enableJump then
                    humanoid.Jump = true
                end

                if tick() - wallCheckTime > 0.4 then
                    local isWallStuck, wallPos = IsStuckAgainstWall()
                    if isWallStuck then
                        log("🧱", "Wall detected ahead! Recomputing path...")
                        needRecompute = true
                        break
                    end
                    wallCheckTime = tick()
                end

                if tick() - stuckCheckTime > 0.3 then
                    local distanceMoved = (hrp.Position - lastPosition).Magnitude
                    if distanceMoved < 0.3 then
                        waypointStuckCount = waypointStuckCount + 1
                        
                        if waypointStuckCount == 1 and enableJump then
                            humanoid.Jump = true
                        elseif waypointStuckCount == 2 then
                            humanoid.Jump = true
                            local sideDir = hrp.CFrame.RightVector
                            humanoid:MoveTo(hrp.Position + sideDir * 5)
                            task.wait(0.3)
                        elseif waypointStuckCount >= 3 then
                            log("⚠️", "Waypoint stuck! Recomputing path...")
                            needRecompute = true
                            break
                        end
                        
                        humanoid:MoveTo(waypoint.Position)
                    else
                        waypointStuckCount = 0
                    end
                    lastPosition = hrp.Position
                    stuckCheckTime = tick()
                end

                if tick() - pathStuckTime > 2 then
                    local pathMoved = (hrp.Position - lastPathPos).Magnitude
                    if pathMoved < 2 then
                        pathStuckCount = pathStuckCount + 1
                        if pathStuckCount >= 2 then
                            log("⚠️", "Path stuck! Recomputing...")
                            needRecompute = true
                            break
                        end
                    else
                        pathStuckCount = 0
                    end
                    lastPathPos = hrp.Position
                    pathStuckTime = tick()
                end

                if tick() - startTime > 3 then
                    break
                end
                task.wait(0.05)
            end

            if connection then connection:Disconnect() end
        end
        
        if not needRecompute then
            local finalDist = (hrp.Position - targetPos).Magnitude
            if finalDist < 10 then
                return true
            end
        end
        
        if needRecompute then
            local isWallStuck = IsStuckAgainstWall()
            if isWallStuck then
                ForceUnstuckFromWall()
            else
                humanoid.Jump = true
                local backDir = -hrp.CFrame.LookVector
                humanoid:MoveTo(hrp.Position + backDir * 6)
                task.wait(0.5)
            end
        end
    end
    
    log("⚠️", "Max retries reached, using DirectMove")
    return DirectMoveTo(targetPos, 10)
end

--[[ ====================== FLOOR 2 NAVIGATION ====================== ]]

local function NavigateToFloor2(plot, petPos, pet)
    if pet and not pet.Parent then return false end

    isClimbingFloor2 = true
    
    local nearestStair, stairDist = FindNearestStairToPet(petPos)
    if not nearestStair then
        log("⚠️", "Cannot find stair for target house!")
        isClimbingFloor2 = false
        return false
    end
    
    log("🏠", string.format("Target house stair: (%.0f, %.0f, %.0f) - dist to pet: %.1f", 
        nearestStair.X, nearestStair.Y, nearestStair.Z, stairDist))
    savedStairPosition = nearestStair
    
    log("🏃", "Walking to target house stair (floor 1)...")
    if not WalkToPosition(nearestStair, nil, true) then
        isClimbingFloor2 = false
        return false
    end
    
    task.wait(0.3)
    
    local toPet = Vector3.new(petPos.X - nearestStair.X, 0, petPos.Z - nearestStair.Z)
    local flyForward = toPet.Magnitude > 0.1 and toPet.Unit or Vector3.new(1, 0, 0)
    
    log("🚁", "Flying UP to floor 2...")
    FlyUp(0.9, 45)
    
    log("➡️", "Flying forward to exit stair hole...")
    FlyDirection(flyForward, 0.5, 35)
    
    task.wait(0.3)
    
    if pet and not pet.Parent then 
        isClimbingFloor2 = false
        return false 
    end

    log("🎯", "Walking to pet on floor 2...")
    if not WalkToPosition(petPos + Vector3.new(0, 2, 0), pet, false) then
        isClimbingFloor2 = false
        return false
    end
    
    return true
end

local function ReturnFromFloor2()
    log("⬇️", "Returning from floor 2...")
    
    if savedStairPosition then
        local stairAbove = Vector3.new(savedStairPosition.X, hrp.Position.Y, savedStairPosition.Z)
        DirectMoveTo(stairAbove, 5)
    end
    
    FlyDown(0.7, 35)
    task.wait(0.3)
    
    if savedStairPosition then
        local toHome = Vector3.new(homePosition.X - savedStairPosition.X, 0, homePosition.Z - savedStairPosition.Z)
        local escapeDir
        
        if toHome.Magnitude > 1 then
            escapeDir = toHome.Unit
        else
            escapeDir = Vector3.new(hrp.Position.X - savedStairPosition.X, 0, hrp.Position.Z - savedStairPosition.Z)
            if escapeDir.Magnitude > 0.1 then
                escapeDir = escapeDir.Unit
            else
                escapeDir = Vector3.new(1, 0, 0)
            end
        end
        
        log("🚶", "Escaping from under staircase...")
        local escapePos = hrp.Position + escapeDir * 15
        escapePos = Vector3.new(escapePos.X, hrp.Position.Y, escapePos.Z)
        DirectMoveTo(escapePos, 4)
    end
    
    isClimbingFloor2 = false
    savedStairPosition = nil
    task.wait(0.2)
end

--[[ ====================== FIND PET ====================== ]]

local function FindTargetPet()
    local plotsFolder = Workspace:FindFirstChild("Plots")
    if not plotsFolder then return nil, nil end

    local enabled = getgenv().TARGET_PETS or {}
    
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if plot:IsA("Model") and plot ~= myPlot then
            for _, obj in ipairs(plot:GetChildren()) do
                if enabled[obj.Name] and not collectedPets[obj] and not skippedPets[obj] then
                    local pos = GetPetPosition(obj)
                    if pos then
                        local dist = (pos - hrp.Position).Magnitude
                        if dist >= 30 then
                            return obj, pos
                        end
                    end
                end
            end
        end
    end

    return nil, nil
end

--[[ ====================== HANDLE PET ====================== ]]

local function HandlePet(pet, petPos)
    if isHandlingPet or not pet or not pet.Parent then return false end

    isHandlingPet = true
    
    local petStartTime = tick()
    local success = false

    local ok = pcall(function()
        local petFloor = GetFloorLevel(petPos.Y)
        local wasOnFloor2 = false

        log("🎯", string.format("Target: %s (Floor %d, Y=%.1f)", pet.Name, petFloor, petPos.Y))

        if petFloor == 2 then
            wasOnFloor2 = true
            if not NavigateToFloor2(pet.Parent, petPos, pet) then 
                log("❌", "Failed to navigate to floor 2")
                return 
            end
        else
            if not WalkToPosition(petPos + Vector3.new(0, 2, 0), pet, true) then 
                log("❌", "Failed to walk to pet")
                return 
            end
        end

        if tick() - petStartTime > PET_SKIP_TIMEOUT then
            log("⏱️", string.format("Pet timeout (%ds), đợi 5s thử lại...", PET_SKIP_TIMEOUT))
            task.wait(5)
            return
        end

        if not pet.Parent then 
            log("⚠️", "Pet disappeared before collection")
            return 
        end

        log("✋", "Collecting pet...")
        local grabbed = HoldKeyE(HoldTime, pet)
        
        pcall(function()
            task.wait(0.5)
            for i = 1, 4 do
                local keyCode = Enum.KeyCode["Key" .. i]
                VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
            end
        end)

        if wasOnFloor2 then
            ReturnFromFloor2()
        end

        log("🏠", "Returning to home position...")
        WalkToPosition(homePosition, nil, true)

        task.wait(1)
        local oldPetCount = currentPetCount
        currentPetCount = countPetsInBase()
        httpPost("/hold/pet-count", {username = LocalPlayer.Name, pet_count = currentPetCount})
        
        if currentPetCount > oldPetCount then
            log("✅", string.format("Pet grabbed! %d → %d", oldPetCount, currentPetCount))
            collectedPets[pet] = true
            success = true
        elseif not grabbed then
            log("❌", "Failed to grab pet, đợi 5s thử lại...")
            httpPost("/hold/pet-skip", {
                username = LocalPlayer.Name,
                pet_name = pet.Name,
                reason = "stealing_failed"
            })
            task.wait(5)
            return
        else
            log("⚠️", "Pet may have disappeared")
            collectedPets[pet] = true
            success = true
        end

        if currentPetCount >= MAX_PETS then
            log("✅", "FULL! " .. currentPetCount .. " PETS!", true)
            httpPost("/hold/full", {username = LocalPlayer.Name, pet_count = currentPetCount})
            closeGame()
        end
    end)

    isHandlingPet = false
    
    if not success then
        log("⚠️", string.format("Pet handling failed after %.1fs", tick() - petStartTime))
    end
    
    return success
end

--[[ ====================== MAIN LOOP ====================== ]]

log("🚀", "Farm loop started!", true)

local noTargetCount = 0
local MAX_NO_TARGET = 3

while true do
    if characterDied or isHandlingPet then
        task.wait(0.3)
        continue
    end

    if currentPetCount >= MAX_PETS then break end

    local pet, petPos = FindTargetPet()

    if pet and petPos then
        noTargetCount = 0
        HandlePet(pet, petPos)
    else
        noTargetCount = noTargetCount + 1
        log("🔍", string.format("Searching... (%d/%d)", noTargetCount, MAX_NO_TARGET))

        if noTargetCount >= MAX_NO_TARGET then
            log("✅", "Server cleared!", true)
            httpPost("/hold/collected", {username = LocalPlayer.Name, pet_count = currentPetCount})
            closeGame()
            break
        end
    end

    task.wait(CheckInterval)
end

DisableMouseBlock()
ResetCameraZoom()

log("🏁", "Script finished!", true)
