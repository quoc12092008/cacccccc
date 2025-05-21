repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

-- ✅ Cấu hình tên người chơi bị chặn và người nhận quà
local blockedName = getgenv().BlockedPlayerName or "tiger12092008"
-- 🔄 Tên người chơi để join vào server của họ
local joinPlayerName = getgenv().JoinPlayerName or ""

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

-- ✅ Đợi leaderstats và 5 giây
if waitForLeaderstats(5) then
    print("leaderstats đã sẵn sàng. Chờ thêm 5 giây...")
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

-- 🌍 Hàm tham gia vào server của người chơi khác
local function joinPlayerServer(targetUsername)
    -- Kiểm tra nếu tên người chơi trống
    if not targetUsername or targetUsername == "" then
        warn("Tên người chơi để join không được để trống!")
        return
    end
    
    print("Đang tìm kiếm " .. targetUsername .. "...")
    
    -- Sử dụng UserInfoQuery để lấy UserID từ tên người dùng
    local userId
    pcall(function()
        userId = Players:GetUserIdFromNameAsync(targetUsername)
    end)
    
    if not userId then
        warn("Không tìm thấy người chơi: " .. targetUsername)
        return
    end
    
    print("Đã tìm thấy UserID: " .. userId .. ". Đang tìm server...")
    
    -- Tìm game để join
    local success, errorMsg = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end)
    
    if not success then
        warn("Không thể tham gia server: " .. tostring(errorMsg))
    end
end

-- 🌟 Giao diện đẹp
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "FarmingGUI"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Tạo khung chính
local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 250, 0, 220) -- Tăng kích thước để thêm nút join
mainFrame.Position = UDim2.new(0, 30, 0, 120)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.05
mainFrame.AnchorPoint = Vector2.new(0, 0)
mainFrame.ClipsDescendants = true

-- Bo góc
local corner = Instance.new("UICorner", mainFrame)
corner.CornerRadius = UDim.new(0, 12)

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

-- Nút join
local joinButton = Instance.new("TextButton", mainFrame)
joinButton.Size = UDim2.new(1, -30, 0, 45)
joinButton.Position = UDim2.new(0, 15, 0, 80)
joinButton.BackgroundColor3 = Color3.fromRGB(155, 89, 182)
joinButton.Text = "👥 Join Player"
joinButton.Font = Enum.Font.GothamBold
joinButton.TextSize = 20
joinButton.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", joinButton)

-- Nút kick
local kickButton = Instance.new("TextButton", mainFrame)
kickButton.Size = UDim2.new(1, -30, 0, 45)
kickButton.Position = UDim2.new(0, 15, 0, 140)
kickButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
kickButton.Text = "🚪 Thoát Game"
kickButton.Font = Enum.Font.GothamBold
kickButton.TextSize = 20
kickButton.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", kickButton)

-- Hộp nhập tên người chơi
local playerNameInput = Instance.new("TextBox", mainFrame)
playerNameInput.Size = UDim2.new(1, -30, 0, 30)
playerNameInput.Position = UDim2.new(0, 15, 1, -40)
playerNameInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
playerNameInput.TextColor3 = Color3.new(1, 1, 1)
playerNameInput.Font = Enum.Font.Gotham
playerNameInput.TextSize = 14
playerNameInput.PlaceholderText = "Nhập tên người chơi để join..."
playerNameInput.Text = joinPlayerName
playerNameInput.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
playerNameInput.ClearTextOnFocus = false
Instance.new("UICorner", playerNameInput)

-- Hành động nút Kick
kickButton.MouseButton1Click:Connect(function()
    player:Kick("Bạn đã chọn thoát game.")
end)

-- Hành động nút Join
joinButton.MouseButton1Click:Connect(function()
    local targetName = playerNameInput.Text
    if targetName and targetName ~= "" then
        joinButton.Text = "⏳ Đang tìm kiếm..."
        joinButton.BackgroundColor3 = Color3.fromRGB(86, 64, 122)
        
        -- Lưu tên người chơi vào getgenv để sử dụng sau này
        getgenv().JoinPlayerName = targetName
        
        -- Thực hiện join
        joinPlayerServer(targetName)
    else
        playerNameInput.PlaceholderText = "Nhập tên người chơi trước!"
        wait(2)
        playerNameInput.PlaceholderText = "Nhập tên người chơi để join..."
    end
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
