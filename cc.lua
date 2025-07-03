local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")

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
    local info = Animals[name] or {}
    return {name=name, mut=mut, rar=info.Rarity or "Unknown", price=info.Price or 0}
end

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

local myPlot = findMyPlot(true)
if myPlot then
    local pets = listPetsInPlot(myPlot)
    for i, pet in ipairs(pets) do
        print(string.format(
            "🐾 [%d] Name: %s | Mutation: %s | Rarity: %s | Price: $%s",
            i, pet.name, pet.mut, pet.rar, tostring(pet.price)
        ))
    end
else
    warn("Could not locate your plot.")
end
