local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- Ví dụ Animals, sửa cho đúng pet của bạn
local Animals = {
    ["La Vacca Saturno Saturnita"] = true,
    ["Los Tralaleritos"] = true,
    ["Graipuss Medussi"] = true,
    ["La Grande Combinasion"] = true,
}
-- Tìm plot của bạn
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
            local label = sign and sign:FindFirstChildWhichIsA("SurfaceGui", true)
            if label then
                local txtLabel = label:FindFirstChild("TextLabel", true)
                if txtLabel then
                    local txt = txtLabel.Text:lower()
                    if txt:match(localPlayer.Name:lower()) or txt:match(localPlayer.DisplayName:lower()) then
                        return plot
                    end
                end
            end
        end
        RunService.RenderStepped:Wait()
    until tick() > deadline
    return nil
end

-- Lấy thông tin pet từ Spawn
local function getPetDataFromSpawn(spawn)
    if not spawn then return nil end
    local attach = spawn:FindFirstChild("Attachment")
    local overhead = attach and attach:FindFirstChild("AnimalOverhead")
    local lbl = overhead and overhead:FindFirstChild("DisplayName")
    local name = lbl and lbl.Text
    if not name or name == "" then return nil end

    -- kiểm tra có nằm trong Animals không
    if not Animals[name] then
        return nil
    end

    local mut = "Normal"
    local mutVal = spawn:FindFirstChild("Mutation") or spawn:FindFirstChild("MutateLevel")
    if mutVal then
        if mutVal:IsA("StringValue") then
            mut = mutVal.Value
        elseif mutVal:IsA("IntValue") then
            mut = ({[0]="Normal",[1]="Golden",[2]="Diamond",[3]="Rainbow"})[mutVal.Value] or mut
        end
    end

    return {name=name, mut=mut}
end

-- Liệt kê pet trong plot
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

local function createPetUI(petList)
    -- Xóa UI cũ nếu có
    if CoreGui:FindFirstChild("PetDisplayGUI") then
        CoreGui.PetDisplayGUI:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PetDisplayGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.2
    frame.Size = UDim2.new(0, 300, 0, 20 + (#petList * 25))
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Text = "🐾 Your Pets 🐾"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1,0,0,25)
    title.Parent = frame

    for i, pet in ipairs(petList) do
        local label = Instance.new("TextLabel")
        label.Text = string.format("[%d] %s | %s", i, pet.name, pet.mut)
        label.Font = Enum.Font.SourceSans
        label.TextSize = 16
        label.TextColor3 = Color3.fromRGB(255,255,255)
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Position = UDim2.new(0,5,0,(i * 20) + 5)
        label.Size = UDim2.new(1,-10,0,20)
        label.Parent = frame
    end
end

-- Chạy
local myPlot = findMyPlot(true)
if myPlot then
    local pets = listPetsInPlot(myPlot)
    createPetUI(pets)
else
    warn("Could not locate your plot.")
end
