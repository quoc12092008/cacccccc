-- FPS Booster CỰC MẠNH + GUI ẩn/hiện bằng phím F
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local guiVisible = true

-- GUI
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "FPSBoosterUI"
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0.7, 0, 0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 8)

local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1, 0, 1, 0)
label.Text = "FPS Booster: Đang hoạt động"
label.TextColor3 = Color3.new(1, 1, 1)
label.BackgroundTransparency = 1
label.Font = Enum.Font.Gotham
label.TextSize = 14
label.TextWrapped = true

-- Tối ưu ánh sáng
local function optimizeGraphics()
    if Lighting then
        Lighting.GlobalShadows = false
        Lighting.Brightness = 0
        Lighting.FogEnd = 1e10
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then
                v.Enabled = false
            end
        end
    end
    if Workspace.Terrain then
        Workspace.Terrain.WaterWaveSize = 0
        Workspace.Terrain.WaterWaveSpeed = 0
        Workspace.Terrain.WaterReflectance = 0
        Workspace.Terrain.WaterTransparency = 0
    end
end

-- Tối ưu part
local function optimizeParts()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
            obj.CastShadow = false
            obj.Material = Enum.Material.SmoothPlastic
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Beam") or obj:IsA("Trail") then
            obj:Destroy()
        end
    end
end

-- Tắt âm thanh
local function muteAudio()
    for _, s in pairs(Workspace:GetDescendants()) do
        if s:IsA("Sound") then
            s.Volume = 0
        end
    end
end

-- Tối ưu camera
local function optimizeCamera()
    local cam = Workspace.CurrentCamera
    if cam then
        cam.FieldOfView = 70
    end
end

-- Thu dọn bộ nhớ
local function cleanup()
    collectgarbage("collect")
end

-- Tự động tối ưu liên tục
RunService.Heartbeat:Connect(function()
    optimizeParts()
end)

-- Tự động cleanup mỗi 20s
task.spawn(function()
    while true do
        wait(20)
        cleanup()
    end
end)

-- Tự chạy khi load game
task.defer(function()
    print("🔧 Đang khởi động FPS Booster...")
    optimizeGraphics()
    optimizeCamera()
    muteAudio()
    optimizeParts()
    print("✅ FPS Booster CỰC MẠNH đang chạy!")
end)

-- Ẩn/hiện GUI bằng phím F
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        guiVisible = not guiVisible
        screenGui.Enabled = guiVisible
    end
end)
