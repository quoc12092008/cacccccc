-- Roblox FPS Booster Script
-- Giúp tối ưu hóa hiệu suất game

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Tối ưu hóa đồ họa
local function optimizeGraphics()
    -- Giảm chất lượng ánh sáng
    if Lighting then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 0
        
        -- Xóa các hiệu ứng ánh sáng không cần thiết
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect.Enabled = false
            end
        end
    end
    
    -- Tối ưu hóa Workspace
    if Workspace then
        Workspace.StreamingEnabled = true
        if Workspace.Terrain then
            Workspace.Terrain.WaterWaveSize = 0
            Workspace.Terrain.WaterWaveSpeed = 0
            Workspace.Terrain.WaterReflectance = 0
            Workspace.Terrain.WaterTransparency = 0
        end
    end
end

-- Xóa các part không cần thiết để tăng FPS
local function removeUnnecessaryParts()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") then
            -- Tắt Shadows
            obj.CastShadow = false
            
            -- Giảm chất lượng material
            if obj.Material == Enum.Material.Grass then
                obj.Material = Enum.Material.Plastic
            elseif obj.Material == Enum.Material.Concrete then
                obj.Material = Enum.Material.Plastic
            end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            -- Xóa decal và texture không quan trọng (tùy chọn)
            if not obj.Parent:IsA("Tool") and not obj.Parent.Parent == player.Character then
                obj.Transparency = 1
            end
        elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
            -- Xóa hiệu ứng particle
            if obj.Parent ~= player.Character then
                obj:Destroy()
            end
        end
    end
end

-- Tối ưu hóa camera
local function optimizeCamera()
    local camera = Workspace.CurrentCamera
    if camera then
        camera.FieldOfView = 70 -- Giảm FOV để tăng FPS
    end
end

-- Tối ưu hóa âm thanh
local function optimizeAudio()
    for _, sound in pairs(Workspace:GetDescendants()) do
        if sound:IsA("Sound") then
            sound.Volume = sound.Volume * 0.5 -- Giảm âm lượng
        end
    end
end

-- Tối ưu hóa rendering
local function optimizeRendering()
    -- Giảm render distance
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local humanoidRootPart = player.Character.HumanoidRootPart
        
        for _, part in pairs(Workspace:GetPartBoundsInRegion(
            Region3.new(
                humanoidRootPart.Position - Vector3.new(500, 500, 500),
                humanoidRootPart.Position + Vector3.new(500, 500, 500)
            ), 1000)) do
            
            if part and part.Parent ~= player.Character then
                local distance = (part.Position - humanoidRootPart.Position).Magnitude
                if distance > 300 then
                    part.CanCollide = false
                    if part:IsA("BasePart") then
                        part.CastShadow = false
                    end
                end
            end
        end
    end
end

-- Cleanup memory
local function cleanupMemory()
    collectgarbage("collect")
end

-- Chạy tối ưu hóa
print("Đang khởi động FPS Booster...")

optimizeGraphics()
optimizeCamera()
optimizeAudio()
removeUnnecessaryParts()

print("FPS Booster đã được kích hoạt!")

-- Chạy tối ưu hóa liên tục
local optimizeConnection
optimizeConnection = RunService.Heartbeat:Connect(function()
    optimizeRendering()
    
    -- Cleanup memory mỗi 30 giây
    if tick() % 30 < 0.1 then
        cleanupMemory()
    end
end)

-- Cleanup khi player leave
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        if optimizeConnection then
            optimizeConnection:Disconnect()
        end
    end
end)

-- Thông báo FPS hiện tại (tùy chọn)
spawn(function()
    while true do
        wait(5)
        local fps = math.floor(1 / RunService.Heartbeat:Wait())
        print("FPS hiện tại: " .. fps)
    end
end)
