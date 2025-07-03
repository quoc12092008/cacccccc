local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- Tạo GUI chính
local function createPetGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PetDisplayGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui
    
    -- Frame chính
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
    mainFrame.Position = UDim2.new(0, 50, 0, 50)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Bo tròn góc
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    -- Tiêu đề
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    titleLabel.Text = "🐾 MY PETS"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleLabel
    
    -- Nút đóng
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 15)
    closeCorner.Parent = closeButton
    
    -- ScrollingFrame cho danh sách pets
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -10, 1, -50)
    scrollFrame.Position = UDim2.new(0, 5, 0, 45)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.Parent = mainFrame
    
    -- Layout cho scroll frame
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    listLayout.Parent = scrollFrame
    
    -- Nút refresh
    local refreshButton = Instance.new("TextButton")
    refreshButton.Size = UDim2.new(0, 80, 0, 30)
    refreshButton.Position = UDim2.new(1, -90, 0, 5)
    refreshButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    refreshButton.Text = "🔄"
    refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshButton.TextScaled = true
    refreshButton.Font = Enum.Font.Gotham
    refreshButton.Parent = mainFrame
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 15)
    refreshCorner.Parent = refreshButton
    
    return screenGui, mainFrame, scrollFrame, closeButton, refreshButton
end

-- Tạo pet item trong list
local function createPetItem(petData, index)
    local petFrame = Instance.new("Frame")
    petFrame.Size = UDim2.new(1, -10, 0, 60)
    petFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    petFrame.BorderSizePixel = 0
    petFrame.LayoutOrder = index
    
    local petCorner = Instance.new("UICorner")
    petCorner.CornerRadius = UDim.new(0, 8)
    petCorner.Parent = petFrame
    
    -- Số thứ tự
    local numberLabel = Instance.new("TextLabel")
    numberLabel.Size = UDim2.new(0, 40, 1, 0)
    numberLabel.Position = UDim2.new(0, 0, 0, 0)
    numberLabel.BackgroundTransparency = 1
    numberLabel.Text = "#" .. index
    numberLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    numberLabel.TextScaled = true
    numberLabel.Font = Enum.Font.GothamBold
    numberLabel.Parent = petFrame
    
    -- Tên pet
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 120, 0, 25)
    nameLabel.Position = UDim2.new(0, 45, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = petData.name
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = petFrame
    
    -- Mutation
    local mutationLabel = Instance.new("TextLabel")
    mutationLabel.Size = UDim2.new(0, 80, 0, 15)
    mutationLabel.Position = UDim2.new(0, 45, 0, 30)
    mutationLabel.BackgroundTransparency = 1
    mutationLabel.Text = "Mutation: " .. petData.mut
    mutationLabel.TextColor3 = petData.mut == "Normal" and Color3.fromRGB(150, 150, 150) or 
                                petData.mut == "Golden" and Color3.fromRGB(255, 215, 0) or
                                petData.mut == "Diamond" and Color3.fromRGB(185, 242, 255) or
                                petData.mut == "Rainbow" and Color3.fromRGB(255, 105, 180) or
                                Color3.fromRGB(255, 255, 255)
    mutationLabel.TextScaled = true
    mutationLabel.Font = Enum.Font.Gotham
    mutationLabel.TextXAlignment = Enum.TextXAlignment.Left
    mutationLabel.Parent = petFrame
    
    -- Rarity
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Size = UDim2.new(0, 80, 0, 15)
    rarityLabel.Position = UDim2.new(0, 45, 0, 45)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = "Rarity: " .. petData.rar
    rarityLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    rarityLabel.TextScaled = true
    rarityLabel.Font = Enum.Font.Gotham
    rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
    rarityLabel.Parent = petFrame
    
    -- Price
    local priceLabel = Instance.new("TextLabel")
    priceLabel.Size = UDim2.new(0, 100, 1, 0)
    priceLabel.Position = UDim2.new(1, -105, 0, 0)
    priceLabel.BackgroundTransparency = 1
    priceLabel.Text = "$" .. tostring(petData.price)
    priceLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    priceLabel.TextScaled = true
    priceLabel.Font = Enum.Font.GothamBold
    priceLabel.TextXAlignment = Enum.TextXAlignment.Right
    priceLabel.Parent = petFrame
    
    return petFrame
end

-- Cập nhật danh sách pets trong GUI
local function updatePetList(scrollFrame, pets)
    -- Xóa tất cả items cũ
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Thêm pets mới
    for i, pet in ipairs(pets) do
        local petItem = createPetItem(pet, i)
        petItem.Parent = scrollFrame
    end
    
    -- Cập nhật canvas size
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #pets * 65)
end

-- Hàm tìm plot (giữ nguyên)
local function findMyPlot(waitForSpawn)
    local localPlayer = Players.LocalPlayer
    local deadline = tick() + (waitForSpawn and 10 or 0)
    repeat
        for _, plot in ipairs(workspace.Plots:GetChildren()) do
            local ownerTag = plot:FindFirstChild("Owner")
            if ownerTag and ownerTag.Value == localPlayer then
                return plot
            end
            local sign = plot:FindFirstChild("PlotSign")
            local label = sign and sign.SurfaceGui and sign.SurfaceGui.Frame:FindFirstChild("TextLabel")
            if label then
                local txt = label.Text:lower()
                if txt:match(localPlayer.Name:lower()) or txt:match(localPlayer.DisplayName:lower()) then
                    return plot
                end
            end
        end
        RunService.RenderStepped:Wait()
    until tick() > deadline
    return nil
end

-- Hàm lấy dữ liệu pet (giữ nguyên)
local function getPetDataFromSpawn(spawn)
    if not spawn then return nil end
    local attach = spawn:FindFirstChild("Attachment")
    local overhead = attach and attach:FindFirstChild("AnimalOverhead")
    local lbl = overhead and overhead:FindFirstChild("DisplayName")
    local name = lbl and lbl.Text
    if not name or name == "" then return nil end
    local mut = "Normal"
    local mutVal = spawn:FindFirstChild("Mutation") or spawn:FindFirstChild("MutateLevel")
    if mutVal then
        if mutVal:IsA("StringValue") then
            mut = mutVal.Value
        elseif mutVal:IsA("IntValue") then
            mut = ({[0]="Normal",[1]="Golden",[2]="Diamond",[3]="Rainbow"})[mutVal.Value] or mut
        end
    end
    local info = Animals and Animals[name] or {}
    return {name=name, mut=mut, rar=info.Rarity or "Unknown", price=info.Price or 0}
end

-- Hàm liệt kê pets trong plot (giữ nguyên)
local function listPetsInPlot(plot)
    local pets = {}
    local podFolder = plot and plot:FindFirstChild("AnimalPodiums")
    if not podFolder then return pets end
    for _, podium in ipairs(podFolder:GetChildren()) do
        local spawn = podium:FindFirstChild("Base") and podium.Base:FindFirstChild("Spawn")
        local data = getPetDataFromSpawn(spawn)
        if data then
            table.insert(pets, data)
        end
    end
    return pets
end

-- Hàm load và hiển thị pets
local function loadAndDisplayPets(scrollFrame)
    local myPlot = findMyPlot(true)
    if myPlot then
        local pets = listPetsInPlot(myPlot)
        updatePetList(scrollFrame, pets)
        
        -- In ra console (tùy chọn)
        print("=== PET LIST ===")
        for i, pet in ipairs(pets) do
            print(string.format(
                "🐾 [%d] Name: %s | Mutation: %s | Rarity: %s | Price: $%s",
                i, pet.name, pet.mut, pet.rar, tostring(pet.price)
            ))
        end
        print("================")
    else
        warn("Could not locate your plot.")
        -- Hiển thị thông báo lỗi trong GUI
        local errorLabel = Instance.new("TextLabel")
        errorLabel.Size = UDim2.new(1, 0, 0, 50)
        errorLabel.BackgroundTransparency = 1
        errorLabel.Text = "❌ Could not find your plot!"
        errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        errorLabel.TextScaled = true
        errorLabel.Font = Enum.Font.Gotham
        errorLabel.Parent = scrollFrame
    end
end

-- Tạo GUI và thiết lập events
local screenGui, mainFrame, scrollFrame, closeButton, refreshButton = createPetGUI()

-- Event cho nút đóng
closeButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Event cho nút refresh
refreshButton.MouseButton1Click:Connect(function()
    loadAndDisplayPets(scrollFrame)
end)

-- Load pets lần đầu
loadAndDisplayPets(scrollFrame)

-- Làm cho GUI có thể kéo được
local dragging = false
local dragStart = nil
local startPos = nil

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
