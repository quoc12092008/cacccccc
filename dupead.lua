repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- 🛡️ Tên người chơi bị chặn chạy script (gán từ bên ngoài)
getgenv().AllowedPlayerName = getgenv().AllowedPlayerName

if player.Name ~= getgenv().AllowedPlayerName then
    warn("Bạn không được phép sử dụng script này.")
    return
end

-- 📌 Tọa độ dịch chuyển
local teleportPosition = Vector3.new(-15361.35, 16.73, -3889.52)

local function teleportToPosition()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(teleportPosition)
end

-- GUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "GiftScriptGUI"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.new(0, 250, 0, 160)
mainFrame.Position = UDim2.new(0, 30, 0, 100)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Nút bật script
local toggleButton = Instance.new("TextButton", mainFrame)
toggleButton.Size = UDim2.new(1, -30, 0, 40)
toggleButton.Position = UDim2.new(0, 15, 0, 15)
toggleButton.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
toggleButton.Text = "🔄 Bật Script"
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 18
toggleButton.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", toggleButton)

-- Nút hop server
local hopButton = Instance.new("TextButton", mainFrame)
hopButton.Size = UDim2.new(1, -30, 0, 40)
hopButton.Position = UDim2.new(0, 15, 0, 60)
hopButton.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
hopButton.Text = "🌐 Hop Server"
hopButton.Font = Enum.Font.GothamBold
hopButton.TextSize = 18
hopButton.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", hopButton)

-- Nút thoát game
local kickButton = Instance.new("TextButton", mainFrame)
kickButton.Size = UDim2.new(1, -30, 0, 35)
kickButton.Position = UDim2.new(0, 15, 0, 105)
kickButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
kickButton.Text = "🚪 Thoát Game"
kickButton.Font = Enum.Font.GothamBold
kickButton.TextSize = 16
kickButton.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", kickButton)

kickButton.MouseButton1Click:Connect(function()
    player:Kick("Bạn đã chọn thoát game.")
end)

-- Bật Script
toggleButton.MouseButton1Click:Connect(function()
    toggleButton.Text = "⏳ Đang chạy..."
    toggleButton.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    toggleButton.Active = false

    task.spawn(function()
        repeat task.wait() until player:FindFirstChild("leaderstats")
        wait(10)

        player.CharacterAdded:Connect(function(character)
            character:WaitForChild("HumanoidRootPart")
            teleportToPosition()
        end)

        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            teleportToPosition()
        end

        -- Bắt đầu gửi Farming Gift
        local farmingGiftEvent = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Farming Gift: Accept")
        while true do
            farmingGiftEvent:FireServer()
            wait(1)
        end
    end)
end)

-- Hop Server
hopButton.MouseButton1Click:Connect(function()
    hopButton.Text = "⏳ Đang tìm..."
    hopButton.BackgroundColor3 = Color3.fromRGB(155, 89, 182)

    local servers = {}
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

    local success, response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if success and response and response.data then
        for _, server in pairs(response.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server)
            end
        end

        if #servers > 0 then
            table.sort(servers, function(a, b)
                return a.playing < b.playing
            end)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[1].id, player)
        else
            hopButton.Text = "🚫 Không có server!"
            hopButton.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
            wait(2)
            hopButton.Text = "🌐 Hop Server"
            hopButton.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
        end
    else
        hopButton.Text = "❌ Lỗi kết nối"
        hopButton.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
        wait(2)
        hopButton.Text = "🌐 Hop Server"
        hopButton.BackgroundColor3 = Color3.fromRGB(241, 196, 15)
    end
end)
