--=== CONFIG ===--
local webhookUrl = "https://discord.com/api/webhooks/1378811253765574767/t5lFqOqiM641yFiPN6_GJpiTlzzY3m2UIMIH7g9Jye_lfZUIyXkPQum5IiwPmRWbp7pe"

--=== SUPPORT ===--
function findMyPlot(debug)
    for _, plot in pairs(workspace.Plots:GetChildren()) do
        local owner = plot:FindFirstChild("Owner")
        if owner and owner.Value == game.Players.LocalPlayer then
            if debug then print("Found plot: "..plot.Name) end
            return plot
        end
    end
    return nil
end

function getPetDataFromSpawn(spawn)
    if not spawn then return nil end
    local petModel = spawn:FindFirstChildOfClass("Model")
    if not petModel then return nil end

    local name = petModel.Name
    local mut = petModel:FindFirstChild("Mutation") and petModel.Mutation.Value or "Normal"
    local rar = petModel:FindFirstChild("Rarity") and petModel.Rarity.Value or "Common"
    local price = petModel:FindFirstChild("Price") and petModel.Price.Value or 0

    return {
        name = name,
        mut = mut,
        rar = rar,
        price = price
    }
end

function sendWebhook(content)
    local HttpService = game:GetService("HttpService")
    local data = {
        ["content"] = content
    }
    local jsonData = HttpService:JSONEncode(data)

    syn.request({
        Url = webhookUrl,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = jsonData
    })
end

function listPetsInPlot()
    local plot = findMyPlot(true)
    if not plot then
        warn("Plot not found!")
        return
    end

    local podFolder = plot:FindFirstChild("AnimalPodiums")
    if not podFolder then
        warn("No AnimalPodiums folder in plot")
        return
    end

    local finalLog = "=== Pets in Your Plot ===\n"

    for _, podium in ipairs(podFolder:GetChildren()) do
        local basePart = podium:FindFirstChild("Base")
        local spawn = basePart and basePart:FindFirstChild("Spawn")
        local data = getPetDataFromSpawn(spawn)
        if data then
            local line = string.format(
                ":feet: Name: %s | Mutation: %s | Rarity: %s | Price: $%s",
                data.name,
                data.mut,
                data.rar,
                tostring(data.price)
            )
            print(line)
            finalLog = finalLog .. line .. "\n"
        else
            local line = "[Slot " .. podium.Name .. "] Empty or invalid spawn"
            print(line)
            finalLog = finalLog .. line .. "\n"
        end
    end

    sendWebhook(finalLog)
end

--=== SIMPLE CUSTOM GUI ===--
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Tạo ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MyCustomPetGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

-- Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 120)
frame.Position = UDim2.new(0.5, -100, 0.5, -60)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Tiêu đề
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Text = "Pet Viewer"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 20
title.Parent = frame

-- Button Scan
local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(1, -20, 0, 35)
scanButton.Position = UDim2.new(0,10,0,40)
scanButton.Text = "📝 Quét Pet + Gửi"
scanButton.TextColor3 = Color3.fromRGB(255,255,255)
scanButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
scanButton.Font = Enum.Font.SourceSans
scanButton.TextSize = 18
scanButton.Parent = frame

scanButton.MouseButton1Click:Connect(function()
    listPetsInPlot()
end)

-- Button Đóng
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(1, -20, 0, 30)
closeButton.Position = UDim2.new(0,10,0,80)
closeButton.Text = "❌ Đóng GUI"
closeButton.TextColor3 = Color3.fromRGB(255,255,255)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeButton.Font = Enum.Font.SourceSans
closeButton.TextSize = 18
closeButton.Parent = frame

closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)
