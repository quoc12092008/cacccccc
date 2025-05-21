repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local TeleportService = game:GetService("TeleportService")

-- ✅ Lấy giá trị JobId từ getgenv
local targetPlaceId = game.PlaceId -- Hoặc bạn có thể đặt cứng, ví dụ: 123456789
local targetJobId = getgenv().jobId or "5f4b7a59-4ee2-4a69-b628-b1335659f50b"
joinJobButton.MouseButton1Click:Connect(function()
    if targetJobId == "" then
        warn("⚠️ Chưa có JobId. Đặt getgenv().jobId trước khi join.")
        return
    end

    print("🔁 Đang chuyển đến server với JobId:", targetJobId)
    TeleportService:TeleportToPlaceInstance(targetPlaceId, targetJobId, player)
end)
-- ✅ Cấu hình tên người chơi bị chặn và người nhận quà
local blockedName = getgenv().BlockedPlayerName or "tiger12092008"

-- ❌ Không cho user chạy nếu tên bị chặn
if player.Name == blockedName then
    print("User " .. blockedName .. " nên không chạy script này.")
    return
end

-- 🕓 Đợi leaderstats xuất hiện
local function waitForLeaderstats(timeout)
    local t = 0
    while t < timeout do
        if player:FindFirstChild("leaderstats") then
            return true
        end
        task.wait(1)
        t += 1
    end
    return false
end

-- ✅ Đợi leaderstats và 20 giây
if waitForLeaderstats(5) then
    print("leaderstats đã sẵn sàng. Chờ thêm 10 giây...")
    task.wait(5)
else
    warn("Không tìm thấy leaderstats sau 5 giây.")
    return
end

-- ⚙️ Các giá trị cần thiết
local teleportPosition = Vector3.new(-15361.3496093750, 16.7299995422, -3889.5200195312)
local precision = 5

local function isInPosition(pos1, pos2, tolerance)
    return (pos1 - pos2).Magnitude <= tolerance
end

local function teleportToPosition()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(teleportPosition)
end

-- 🌟 Giao diện đẹp
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "FarmingGUI"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Tạo khung chính
local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 250, 0, 150)
mainFrame.Position = UDim2.new(0, 30, 0, 120)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.05
mainFrame.AnchorPoint = Vector2.new(0, 0)
mainFrame.ClipsDescendants = true

-- Bo góc
local corner = Instance.new("UICorner", mainFrame)
corner.CornerRadius = UDim.new(0, 12)

-- 🆕 Nút join theo JobId
local joinJobButton = Instance.new("TextButton", mainFrame)
joinJobButton.Size = UDim2.new(1, -30, 0, 45)
joinJobButton.Position = UDim2.new(0, 15, 0, 140)
joinJobButton.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
joinJobButton.Text = "🌐 Join Server theo JobId"
joinJobButton.Font = Enum.Font.GothamBold
joinJobButton.TextSize = 20
joinJobButton.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", joinJobButton)

-- Đổ bóng
local shadow = Instance.new("ImageLabel", mainFrame)
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.Position = UDim2.new(0, -15, 0, -15)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageTransparency = 0.6
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.ZIndex = -1

-- Nút bật script
local toggleButton = Instance.new("TextButton", mainFrame)
toggleButton.Size = UDim2.new(1, -30, 0, 45)
toggleButton.Position = UDim2.new(0, 15, 0, 20)
toggleButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
toggleButton.Text = "🔄 Bật Script"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 20
toggleButton.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", toggleButton)

-- Nút kick
local kickButton = Instance.new("TextButton", mainFrame)
kickButton.Size = UDim2.new(1, -30, 0, 45)
kickButton.Position = UDim2.new(0, 15, 0, 80)
kickButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
kickButton.Text = "🚪 Thoát Game"
kickButton.Font = Enum.Font.GothamBold
kickButton.TextSize = 20
kickButton.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", kickButton)

-- Hành động nút Kick
kickButton.MouseButton1Click:Connect(function()
    player:Kick("Bạn đã chọn thoát game.")
end)

-- Hành động bật script
toggleButton.MouseButton1Click:Connect(function()
    toggleButton.Text = "⏳ Đang chạy..."
    toggleButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    toggleButton.TextColor3 = Color3.fromRGB(1, 1, 1)
    toggleButton.AutoButtonColor = false
    toggleButton.Active = false

    -- Teleport khi nhân vật spawn lại
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("HumanoidRootPart")
        teleportToPosition()
    end)

    -- Nếu đã có nhân vật, teleport ngay
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        teleportToPosition()
    end

    -- Kiểm tra vị trí cho đến khi đúng
    while true do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local hrp = character.HumanoidRootPart
            if isInPosition(hrp.Position, teleportPosition, precision) then
                print("✅ Đã đứng đúng vị trí!")
                break
            else
                print("❌ Chưa đúng vị trí. Teleport lại...")
                teleportToPosition()
            end
        end
        wait(1)
    end

    -- Gửi quà cho người chơi mục tiêu
    local targetPlayer = Players:FindFirstChild(blockedName)
    if not targetPlayer then
        warn("Không tìm thấy người chơi: " .. blockedName)
        return
    end

    local farmingGiftEvent = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Farming Gift: Request Send")
    local args = { targetPlayer }

    while true do
        farmingGiftEvent:FireServer(unpack(args))
        wait(3)
    end
end)
