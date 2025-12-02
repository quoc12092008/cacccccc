-- 🍌 PET FARM - NO GUI VERSION
-- Tầng trệt: Y < 10 | Tầng 1: Y >= 10 & < 20 | Tầng 2: Y >= 20

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

local PlotController = require(ReplicatedStorage.Controllers.PlotController)

-- ⚙️ CẤU HÌNH
local AccHold = getgenv().AccHold or {}
local HoldTime = getgenv().HoldTime or 3.5
local CheckInterval = getgenv().CheckInterval or 10

-- 🏠 CẤU HÌNH TẦNG
local FLOOR_GROUND_MAX = 10  -- Y < 10 = tầng trệt
local FLOOR_1_MAX = 20       -- Y >= 10 & < 20 = tầng 1
                              -- Y >= 20 = tầng 2
local BOOST_SPEED = 65

-- Xác định pet target
local CurrentPet = nil
local farmMode = "Checker"
for _, cfg in ipairs(AccHold) do
	if cfg.AccountName == player.Name then
		CurrentPet = cfg.Pet
		farmMode = "Farmer"
		break
	end
end

-- Speed Coil
local speedCoilBought = false
local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net", 10)
local remotePath = "RF/CoinsShopService/RequestBuy"
local remoteFunction = Net and Net:FindFirstChild(remotePath, true)

local function BuySpeedCoil()
	if speedCoilBought or not remoteFunction then return end
	local success = pcall(function()
		remoteFunction:InvokeServer("Speed Coil")
	end)
	if success then
		speedCoilBought = true
		print("[✅] Speed Coil purchased")
	end
end

local function EquipSpeedCoil()
	if not speedCoilBought then return end
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
	task.wait(0.1)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
end

---------------------------------------------------------------------
-- 🏠 DETECT TẦNG
---------------------------------------------------------------------
local function GetFloor(y)
	if y < FLOOR_GROUND_MAX then
		return 0 -- Tầng trệt
	elseif y < FLOOR_1_MAX then
		return 1 -- Tầng 1
	else
		return 2 -- Tầng 2
	end
end

---------------------------------------------------------------------
-- 🚀 BOOST LÊN BẰNG LINEARVELOCITY
---------------------------------------------------------------------
local function BoostUp(targetY)
	local heightDiff = targetY - hrp.Position.Y
	if heightDiff <= 3 then return true end
	
	print("[🚀] Boosting from Y:" .. math.floor(hrp.Position.Y) .. " to Y:" .. math.floor(targetY))
	
	local attachment = Instance.new("Attachment")
	attachment.Parent = hrp
	
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = attachment
	lv.MaxForce = 100000
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.VectorVelocity = Vector3.new(0, BOOST_SPEED, 0)
	lv.Parent = hrp
	
	local startTime = tick()
	local maxTime = heightDiff / BOOST_SPEED + 2
	
	while hrp.Position.Y < targetY - 1 and tick() - startTime < maxTime do
		local remaining = targetY - hrp.Position.Y
		if remaining < 8 then
			lv.VectorVelocity = Vector3.new(0, math.max(15, remaining * 2), 0)
		end
		task.wait(0.02)
	end
	
	lv:Destroy()
	attachment:Destroy()
	task.wait(0.1)
	
	return hrp.Position.Y >= targetY - 3
end

---------------------------------------------------------------------
-- 🚶 PATHFINDING
---------------------------------------------------------------------
local characterDied = false

local function SetupCharacter()
	characterDied = false
	humanoid.Died:Connect(function()
		characterDied = true
	end)
end
SetupCharacter()

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	hrp = character:WaitForChild("HumanoidRootPart")
	SetupCharacter()
	task.wait(0.2)
	characterDied = false
end)

local function WalkTo(targetPos)
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentCanClimb = true,
		WaypointSpacing = 6,
	})
	
	local success = pcall(function()
		path:ComputeAsync(hrp.Position, targetPos)
	end)
	
	if not success or path.Status ~= Enum.PathStatus.Success then
		humanoid:MoveTo(targetPos)
		task.wait(2)
		return true
	end
	
	for _, waypoint in ipairs(path:GetWaypoints()) do
		if characterDied then return false end
		
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid.Jump = true
		end
		
		humanoid:MoveTo(waypoint.Position)
		
		local startTime = tick()
		local lastPos = hrp.Position
		local stuckTime = tick()
		
		while (hrp.Position - waypoint.Position).Magnitude > 4 do
			if characterDied then return false end
			
			if tick() - stuckTime > 0.5 then
				if (hrp.Position - lastPos).Magnitude < 0.5 then
					humanoid.Jump = true
					task.wait(0.1)
				end
				lastPos = hrp.Position
				stuckTime = tick()
			end
			
			if tick() - startTime > 3 then break end
			task.wait(0.02)
		end
	end
	
	return true
end

-- 🎯 DI CHUYỂN THÔNG MINH (xử lý nhiều tầng)
local function SmartWalkTo(targetPos)
	local currentY = hrp.Position.Y
	local targetY = targetPos.Y
	local currentFloor = GetFloor(currentY)
	local targetFloor = GetFloor(targetY)
	
	print(string.format("[📍] Floor %d (Y:%.0f) → Floor %d (Y:%.0f)", currentFloor, currentY, targetFloor, targetY))
	
	-- Cần leo lên tầng cao hơn
	if targetY - currentY > 8 then
		-- Bước 1: Đi đến vị trí dưới pet
		local groundPos = Vector3.new(targetPos.X, currentY, targetPos.Z)
		WalkTo(groundPos)
		task.wait(0.3)
		
		-- Bước 2: Boost lên
		BoostUp(targetY + 3)
		task.wait(0.2)
		
		-- Bước 3: Đi đến pet
		humanoid:MoveTo(targetPos)
		task.wait(1)
		return true
	end
	
	-- Cần xuống tầng thấp hơn
	if currentY - targetY > 8 then
		local abovePos = Vector3.new(targetPos.X, currentY, targetPos.Z)
		humanoid:MoveTo(abovePos)
		task.wait(1)
		humanoid:MoveTo(targetPos)
		task.wait(2)
		return true
	end
	
	-- Cùng tầng
	return WalkTo(targetPos)
end

---------------------------------------------------------------------
-- 🔧 FARM FUNCTIONS
---------------------------------------------------------------------
local function GetMyPlot()
	local myPlot = PlotController.GetMyPlot()
	if myPlot and myPlot.PlotModel then
		return myPlot.PlotModel
	end
	return nil
end

local function GetHomeSpawn(myPlot)
	if not myPlot then return nil end
	local deco = myPlot:FindFirstChild("Decorations")
	if not deco then return nil end
	local spawnPart = deco:GetChildren()[12]
	if spawnPart and spawnPart.CFrame then
		return spawnPart.CFrame.Position
	end
	return nil
end

local function GetAnimalPodiumClaim(myPlot)
	if not myPlot then return nil end
	local animalPodiums = myPlot:FindFirstChild("AnimalPodiums")
	if not animalPodiums then return nil end
	local podium1 = animalPodiums:FindFirstChild("1")
	if not podium1 then return nil end
	local claim = podium1:FindFirstChild("Claim")
	if not claim then return nil end
	local main = claim:FindFirstChild("Main")
	if main then return main.CFrame.Position end
	return nil
end

local function AdjustCamera(pet)
	local cam = Workspace.CurrentCamera
	if not cam or not pet then return end
	local petPos = pet.WorldPivot and pet.WorldPivot.Position or pet.Position
	local dir = (petPos - hrp.Position).Unit
	local camPos = hrp.Position - dir * 5 + Vector3.new(0, 3, 0)
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.new(camPos, hrp.Position + Vector3.new(0, 2, 0))
	task.delay(4, function()
		cam.CameraType = Enum.CameraType.Custom
	end)
end

local function HoldE(duration)
	local start = tick()
	while tick() - start < duration do
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		RunService.Heartbeat:Wait()
	end
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function HandlePet(pet, myPlot)
	if characterDied then return end
	
	local targetPos = pet.WorldPivot and pet.WorldPivot.Position
	if not targetPos then return end
	
	local targetFloor = GetFloor(targetPos.Y)
	print("[🎯] Going to " .. pet.Name .. " at Floor " .. targetFloor .. " (Y:" .. math.floor(targetPos.Y) .. ")")
	
	local success = SmartWalkTo(targetPos + Vector3.new(0, 2, 0))
	
	if success and not characterDied then
		AdjustCamera(pet)
		print("[✋] Holding E on " .. pet.Name)
		HoldE(HoldTime)

		local homePos = GetHomeSpawn(myPlot)
		if homePos then
			print("[🏠] Returning home...")
			
			-- Nếu đang ở tầng cao, xuống trước
			if hrp.Position.Y > FLOOR_GROUND_MAX + 5 then
				local dropPos = Vector3.new(homePos.X, hrp.Position.Y, homePos.Z)
				humanoid:MoveTo(dropPos)
				task.wait(1)
			end
			
			WalkTo(homePos + Vector3.new(0, 2, 0))
			
			if not speedCoilBought then
				task.wait(1.5)
				local claimPos = GetAnimalPodiumClaim(myPlot)
				if claimPos then
					WalkTo(claimPos + Vector3.new(0, 2, 0))
					task.wait(0.5)
					BuySpeedCoil()
					task.wait(1)
					EquipSpeedCoil()
				end
			else
				task.wait(0.5)
				EquipSpeedCoil()
			end
		end
	end
end

local function ScanAllPlots()
	if characterDied then return end
	
	local myPlot = GetMyPlot()
	if not myPlot then return end

	local plotsFolder = workspace:FindFirstChild("Plots")
	if not plotsFolder then return end

	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if characterDied then return end
		
		if plot:IsA("Model") and plot ~= myPlot then
			for _, pet in ipairs(plot:GetChildren()) do
				if pet.Name == CurrentPet then
					HandlePet(pet, myPlot)
				end
			end
		end
	end
end

local function CheckMyPlotEmpty()
	local myPlot = GetMyPlot()
	if not myPlot then return true end
	for _, pet in ipairs(myPlot:GetChildren()) do
		for _, cfg in ipairs(AccHold) do
			if pet.Name == cfg.Pet then 
				return false
			end
		end
	end
	return true
end

---------------------------------------------------------------------
-- 🚀 START
---------------------------------------------------------------------
print("=====================================")
print("🍌 PET FARM - NO GUI")
print("=====================================")
print("👤 Account: " .. player.Name)
print("🎯 Target: " .. (CurrentPet or "None"))
print("⚙️ Mode: " .. farmMode)
print("🏠 Floors: Ground(<10) | F1(10-20) | F2(>20)")
print("=====================================")

if CurrentPet then
	task.spawn(function()
		while true do
			if not characterDied then
				pcall(ScanAllPlots)
			end
			task.wait(CheckInterval)
		end
	end)
else
	task.spawn(function()
		while true do
			pcall(function()
				if CheckMyPlotEmpty() then
					player:Kick("Hết pet rồi.")
				end
			end)
			task.wait(5)
		end
	end)
end

print("✅ Script loaded!")
