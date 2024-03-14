local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local playerName = localPlayer.Name
local plr = game.Players.LocalPlayer
local leaderstats = plr:FindFirstChild("leaderstats")
local diamondsStat = leaderstats and leaderstats:FindFirstChild("\240\159\146\142 Diamonds")
local diamondsValue = diamondsStat and diamondsStat.Value

repeat wait() until game:IsLoaded()
repeat wait() until game.Players.LocalPlayer
local plr = game.Players.LocalPlayer
repeat wait() until plr.Character
repeat wait() until plr.Character:FindFirstChild("HumanoidRootPart")
repeat wait() until plr.Character:FindFirstChild("Humanoid")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Frame = Instance.new("Frame")
Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderSizePixel = 0
Frame.Size = UDim2.new(1, 0, 1, 0) -- Lấp đầy toàn bộ màn hình
Frame.Active = true
Frame.Visible = true

local TextLabel = Instance.new("TextLabel")
TextLabel.Parent = Frame
TextLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextLabel.BorderSizePixel = 0
TextLabel.Position = UDim2.new(0.263433814, 0, 0.175202161, 0)
TextLabel.Size = UDim2.new(0, 359, 0, 47)
TextLabel.Font = Enum.Font.SourceSansBold
TextLabel.Text = "BANANA DIGSITE PET SIMULATER 99"
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextSize = 25.000

local TextLabel_2 = Instance.new("TextLabel")
TextLabel_2.Parent = Frame
TextLabel_2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextLabel_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextLabel_2.BorderSizePixel = 0
TextLabel_2.Position = UDim2.new(0.368283093, 0, 0.458221018, 0)
TextLabel_2.Size = UDim2.new(0, 200, 0, 50)
TextLabel_2.Font = Enum.Font.SourceSansBold
TextLabel_2.Text = "TOTAL DIAMONDS: " .. tostring(diamondsValue)
TextLabel_2.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_2.TextSize = 20.000

local TextLabel_3 = Instance.new("TextLabel")
TextLabel_3.Parent = Frame
TextLabel_3.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextLabel_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextLabel_3.BorderSizePixel = 0
TextLabel_3.Position = UDim2.new(0.368283093, 0, 0.323450148, 0)
TextLabel_3.Size = UDim2.new(0, 200, 0, 50)
TextLabel_3.Font = Enum.Font.SourceSansBold
TextLabel_3.Text = "USERNAME: " .. playerName
TextLabel_3.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_3.TextSize = 20.000

local TextLabel_4 = Instance.new("TextLabel")
TextLabel_4.Parent = Frame
TextLabel_4.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TextLabel_4.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextLabel_4.BorderSizePixel = 0
TextLabel_4.Position = UDim2.new(0.368283093, 0, 0.592991889, 0)
TextLabel_4.Size = UDim2.new(0, 200, 0, 50)
TextLabel_4.Font = Enum.Font.SourceSansBold
TextLabel_4.Text = "Diamonds Per Mins: "
TextLabel_4.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_4.TextSize = 20.000

local function updateDiamondsValue()
    local newDiamonds = game:GetService("Players").LocalPlayer.leaderstats["\240\159\146\142 Diamonds"].Value
    TextLabel_2.Text = "TOTAL DIAMONDS: " .. tostring(newDiamonds)
end

spawn(function()
    while true do
        wait(60)
        pcall(updateDiamondsValue)
    end
end)

local function printDiamondDifference(newDiamonds, oldDiamonds)
    local difference = newDiamonds - oldDiamonds
    local diamondsPerMinute = difference / 2 -- Vì chúng ta đang cập nhật mỗi 60 giây, nên chia cho 2 sẽ ra số kim cương trung bình mỗi phút
    TextLabel_4.Text = "Diamonds Per Mins: " .. diamondsPerMinute
end

spawn(function()
    while wait(60) do 
        pcall(function()
            local currentDiamonds = game:GetService("Players").LocalPlayer.leaderstats["\240\159\146\142 Diamonds"].Value
            wait(60)
            local newDiamonds = game:GetService("Players").LocalPlayer.leaderstats["\240\159\146\142 Diamonds"].Value
            printDiamondDifference(newDiamonds, currentDiamonds)
        end)
    end
end)

local TextButton = Instance.new("TextButton") -- Đưa nó ra khỏi khối Frame
TextButton.Parent = ScreenGui
TextButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
TextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
TextButton.BorderSizePixel = 0
TextButton.Position = UDim2.new(0.368283093, 0, 0.749326169, 0)
TextButton.Size = UDim2.new(0, 200, 0, 50)
TextButton.Font = Enum.Font.SourceSansBold
TextButton.Text = "SEND DIAMONDS"
TextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TextButton.TextSize = 20.000
TextButton.MouseButton1Down:connect(function()
	loadstring(game:HttpGet('https://raw.githubusercontent.com/quoc12092008/toilet.Lua/main/toiletbanana.lua'))()
end)
