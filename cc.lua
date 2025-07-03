-- Function to find your plot
local function findMyPlot(shouldWarn)
    local player = game.Players.LocalPlayer
    if not player then
        if shouldWarn then warn("LocalPlayer not found!") end
        return nil
    end
    
    -- Try different common plot folder names
    local plotFolders = {"Plots", "PlayerPlots", "PlotFolder"}
    local workspace = game:GetService("Workspace")
    
    for _, folderName in ipairs(plotFolders) do
        local plotFolder = workspace:FindFirstChild(folderName)
        if plotFolder then
            local myPlot = plotFolder:FindFirstChild(player.Name) or plotFolder:FindFirstChild("Plot_" .. player.Name)
            if myPlot then
                return myPlot
            end
        end
    end
    
    if shouldWarn then warn("Could not find your plot!") end
    return nil
end

-- Function to get pet data from spawn (you'll need to adapt this to your game's structure)
local function getPetDataFromSpawn(spawn)
    if not spawn then return nil end
    
    -- This is a generic example - you'll need to adapt this based on your game's data structure
    local pet = spawn:FindFirstChild("Pet") or spawn:FindFirstChildOfClass("Model")
    if not pet then return nil end
    
    -- Try to find data in different ways
    local data = {}
    
    -- Method 1: Check for StringValues/IntValues
    data.name = pet:FindFirstChild("PetName") and pet.PetName.Value or "Unknown"
    data.mut = pet:FindFirstChild("Mutation") and pet.Mutation.Value or "None"
    data.rar = pet:FindFirstChild("Rarity") and pet.Rarity.Value or "Common"
    data.price = pet:FindFirstChild("Price") and pet.Price.Value or 0
    
    -- Method 2: Check for Configuration folder
    local config = pet:FindFirstChild("Configuration")
    if config then
        data.name = config:FindFirstChild("Name") and config.Name.Value or data.name
        data.mut = config:FindFirstChild("Mutation") and config.Mutation.Value or data.mut
        data.rar = config:FindFirstChild("Rarity") and config.Rarity.Value or data.rar
        data.price = config:FindFirstChild("Price") and config.Price.Value or data.price
    end
    
    return data
end

-- Main function to list pets in plot
local function listPetsInPlot(plot)
    if not plot then
        warn("Plot not found!")
        return
    end
    
    local podFolder = plot:FindFirstChild("AnimalPodiums")
    if not podFolder then
        warn("No AnimalPodiums folder in plot")
        return
    end
    
    print("=== Pets in Your Plot ===")
    local petCount = 0
    
    for _, podium in ipairs(podFolder:GetChildren()) do
        if podium:IsA("Model") or podium:IsA("Part") then
            local basePart = podium:FindFirstChild("Base")
            local spawn = basePart and basePart:FindFirstChild("Spawn")
            
            if not spawn then
                -- Try alternative paths
                spawn = podium:FindFirstChild("Spawn")
            end
            
            local data = getPetDataFromSpawn(spawn)
            if data then
                petCount = petCount + 1
                print(string.format(
                    "🐾 Name: %s | Mutation: %s | Rarity: %s | Price: $%s",
                    data.name,
                    data.mut,
                    data.rar,
                    tostring(data.price)
                ))
            else
                print("[Slot " .. podium.Name .. "] Empty or invalid spawn")
            end
        end
    end
    
    if petCount == 0 then
        print("No pets found in your plot!")
    else
        print("Total pets found: " .. petCount)
    end
end

-- Debug function to help identify the structure
local function debugPlotStructure(plot)
    if not plot then
        print("Plot is nil")
        return
    end
    
    print("=== Plot Structure Debug ===")
    print("Plot name:", plot.Name)
    print("Plot children:")
    for _, child in ipairs(plot:GetChildren()) do
        print("  -", child.Name, "(" .. child.ClassName .. ")")
        if child.Name == "AnimalPodiums" then
            print("    AnimalPodiums children:")
            for _, podium in ipairs(child:GetChildren()) do
                print("      -", podium.Name, "(" .. podium.ClassName .. ")")
            end
        end
    end
end

-- Main execution
local myPlot = findMyPlot(true)
if myPlot then
    print("Found plot:", myPlot.Name)
    
    -- Run debug first to see structure
    debugPlotStructure(myPlot)
    
    -- Then try to list pets
    listPetsInPlot(myPlot)
else
    print("Could not find your plot. Available plots:")
    local workspace = game:GetService("Workspace")
    for _, child in ipairs(workspace:GetChildren()) do
        if string.find(child.Name:lower(), "plot") then
            print("  -", child.Name)
        end
    end
end
