--== REMOVE UI IF EXISTED ==--
if game.CoreGui:FindFirstChild("BananaStatsChecker") then
	game.CoreGui.BananaStatsChecker:Destroy()
end

--== SERVICES ==--
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

--== CONFIG FROM getgenv ==--
local AccHold = getgenv().AccHold or {}
local HoldTime = getgenv().HoldTime or 3.5
local CheckInterval = getgenv().CheckInterval or 10

--== GET CURRENT PET ==--
local CurrentPet = nil
local farmMode = "Checker"
for _, cfg in ipairs(AccHold) do
	if cfg.AccountName == player.Name then
		CurrentPet = cfg.Pet
		farmMode = "Farmer"
		break
	end
end

-----------------------------------------------------------------------
-- 🟦 TẦNG NHÀ THEO ĐỘ CAO
-----------------------------------------------------------------------
local function GetFloor(y)
	if y < 10 then return 0 end   -- Tầng trệt
	if y < 20 then return 1 end   -- Lầu 1
	return 2                      -- Lầu 2
end

-----------------------------------------------------------------------
-- 🟦 TÌM LADDER GẦN PET NHẤT
-----------------------------------------------------------------------
local function FindNearestLadder(plotModel, petPos)
	local nearest = nil
	local nearestDist = math.huge

	for _, obj in ipairs(plotModel:GetDescendants()) do
		if obj:IsA("BasePart") then
			local s = obj.Size

			-- Điều kiện nhận dạng thang đứng
			if s.Y > 7 and s.Y < 70 and s.X < 5 and s.Z < 5 then
				local d = (obj.Position - petPos).Magnitude
				if d < nearestDist then
					nearest = obj
					nearestDist = d
				end
			end
		end
	end
	
	return nearest
end

-----------------------------------------------------------------------
-- 🟦 AUTO CLIMB LADDER BẰNG LinearVelocity
-----------------------------------------------------------------------
local function ClimbToFloor(targetFloor)
	local currentFloor = GetFloor(hrp.Position.Y)
	if currentFloor >= targetFloor then return end

	print("[Climb] Moving to floor:", targetFloor)

	local lv = Instance.new("LinearVelocity")
	lv.MaxForce = 50000
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VectorVelocity = Vector3.new(0, 22, 0)
	lv.Parent = hrp

	-- thời gian leo mỗi tầng:
	local climbTime = 1.7 * (targetFloor - currentFloor)
	task.wait(climbTime)

	lv:Destroy()
end

-----------------------------------------------------------------------
-- 🟦 PATHFINDING CƠ BẢN
-----------------------------------------------------------------------
local function WalkTo(targetPos)
	humanoid:MoveTo(targetPos)
	humanoid.MoveToFinished:Wait()
end

-----------------------------------------------------------------------
-- 🟦 GET MY PLOT
-----------------------------------------------------------------------
local function GetMyPlot()
	local myPlot = PlotController.GetMyPlot()
	if myPlot and myPlot.PlotModel then return myPlot.PlotModel end
	return nil
end

local function GetHomeSpawn(plot)
	if not plot then return nil end
	local deco = plot:FindFirstChild("Decorations")
	if not deco then return nil end
	local spawn = deco:GetChildren()[12]
	return spawn and spawn.CFrame.Position or nil
end

-----------------------------------------------------------------------
-- 🟦 HOLD KEY E (real)
-----------------------------------------------------------------------
local function HoldKeyEReal(time)
	local t = tick()
	while tick() - t < time do
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		RunService.Heartbeat:Wait()
	end
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

-----------------------------------------------------------------------
-- 🟦 HANDLE PET (có AUTO LADDER)
-----------------------------------------------------------------------
local function HandlePet(pet, myPlot)
	if not pet or not pet.PrimaryPart then return end

	local petPos = pet.PrimaryPart.Position
	local petFloor = GetFloor(petPos.Y)
	local myFloor = GetFloor(hrp.Position.Y)

	-- Nếu pet ở tầng cao → leo thang
	if petFloor > myFloor then
		local ladder = FindNearestLadder(myPlot, petPos)
		if ladder then
			print("[INFO] Ladder found:", ladder.Name)
			-- đi đến chân thang trước
			WalkTo(ladder.Position + Vector3.new(0, 2, 0))
			task.wait(0.3)
			ClimbToFloor(petFloor)
		end
	end

	-- Khi đã đúng tầng → đi đến pet
	WalkTo(petPos + Vector3.new(0, 2, 0))

	-- Hold E
	HoldKeyEReal(HoldTime)

	-- Quay về nhà
	local home = GetHomeSpawn(myPlot)
	if home then
		WalkTo(home)
	end
end

-----------------------------------------------------------------------
-- 🟦 SCAN ALL PLOTS
-----------------------------------------------------------------------
local function ScanAllPlots()
	local myPlot = GetMyPlot()
	if not myPlot then return end

	local plots = workspace:FindFirstChild("Plots")
	if not plots then return end

	for _, plot in ipairs(plots:GetChildren()) do
		if plot ~= myPlot then
			for _, obj in ipairs(plot:GetChildren()) do
				if obj.Name == CurrentPet then
					HandlePet(obj, myPlot)
				end
			end
		end
	end
end

-----------------------------------------------------------------------
-- 🟦 START
-----------------------------------------------------------------------
if CurrentPet then
	print("[Farm] Bắt đầu gom pet:", CurrentPet)

	task.spawn(function()
		while true do
			pcall(ScanAllPlots)
			task.wait(CheckInterval)
		end
	end)

else
	print("[Checker] Tài khoản không trong danh sách farm")
	task.spawn(function()
		while true do
			task.wait(3)
		end
	end)
end

print("🚀 Script Loaded – No UI – Auto Ladder Enabled")
