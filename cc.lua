-- Function to find your plot
local function findMyPlot(shouldWarn)
    local player = game.Players.LocalPlayer
    if not player then
        if shouldWarn then warn("LocalPlayer not found!") end
        return nil
    end
    
    local workspace = game:GetService("Workspace")
    local plotsFolder = workspace:FindFirstChild("Plots")
    if not plotsFolder then
        if shouldWarn then warn("No Plots folder found!") end
        return nil
    end
    
    -- In this game, plots seem to be named with UUIDs
    -- We need to find the plot that belongs to us
    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if plot:IsA("Model") or plot:IsA("Folder") then
            -- Check if this plot belongs to us (you might need to adjust this logic)
            local ownerValue = plot:FindFirstChild("Owner")
            if ownerValue and ownerValue.Value == player.Name then
                return plot
            end
            
            -- Alternative: check if we can find our pets in this plot
            local animalPodiums = plot:FindFirstChild("AnimalPodiums")
            if animalPodiums then
                -- This might be our plot - return the first one we find for now
                return plot
            end
        end
    end
    
    if shouldWarn then warn("Could not find your plot!") end
    return nil
end

-- Function to get pet data from podium
local function getPetDataFromPodium(podium)
    if not podium then return nil end
    
    -- Based on the error, the structure seems to be:
    -- podium -> claim -> Main (Part)
    local claim = podium:FindFirstChild("claim")
    if not claim then return nil end
    
    local main = claim:FindFirstChild("Main")
    if not main then return nil end
    
    -- Look for pet data in various places
    local data = {}
    
    -- Try to find data in the claim or main part
    local function findValue(parent, valueName)
        local value = parent:FindFirstChild(valueName)
        if value and (value:IsA("StringValue") or value:IsA("IntValue") or value:IsA("NumberValue")) then
            return value.Value
        end
        return nil
    end
    
    -- Check in claim first
    data.name = findValue(claim, "PetName") or findValue(claim, "Name") or "Unknown"
    data.mut = findValue(claim, "Mutation") or findValue(claim, "Mut") or "None"
    data.rar = findValue(claim, "Rarity") or findValue(claim, "Rar") or "Common"
    data.price = findValue(claim, "Price") or findValue(claim, "Value") or 0
    
    -- If not found in claim, try main
    if data.name == "Unknown" then
        data.name = findValue(main, "PetName") or findValue(main, "Name") or "Unknown"
    end
    if data.mut == "None" then
        data.mut = findValue(main, "Mutation") or findValue(main, "Mut") or "None"
    end
    if data.rar == "Common" then
        data.rar = findValue(main, "Rarity") or findValue(main, "Rar") or "Common"
    end
    if data.price == 0 then
        data.price = findValue(main, "Price") or findValue(main, "Value") or 0
    end
    
    -- Try to get data from GUI elements if they exist
    local gui = main:FindFirstChild("BillboardGui") or main:FindFirstChild("SurfaceGui")
    if gui then
        for _, frame in ipairs(gui:GetDescendants()) do
            if frame:IsA("TextLabel") then
                local text = frame.Text
                if text:find("Name:") then
                    data.name = text:gsub("Name: ", "")
                elseif text:find("Rarity:") then
                    data.rar = text:gsub("Rarity: ", "")
                elseif text:find("Price:") then
                    data.price = text:gsub("Price: %$", ""):gsub(",", "")
                end
            end
        end
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
        if podium:IsA("Model") or podium:IsA("Folder") then
            local data = getPetDataFromPodium(podium)
            if data and data.name ~= "Unknown" then
                petCount = petCount + 1
                print(string.format(
                    "🐾 [Slot %s] Name: %s | Mutation: %s | Rarity: %s | Price: $%s",
                    podium.Name,
                    data.name,
                    data.mut,
                    data.rar,
                    tostring(data.price)
                ))
            else
                print("[Slot " .. podium.Name .. "] Empty or no pet data found")
            end
        end
    end
    
    if petCount == 0 then
        print("No pets found in your plot!")
    else
        print("Total pets found: " .. petCount)
    end
end

-- Debug function to explore the structure
local function debugPlotStructure(plot)
    if not plot then
        print("Plot is nil")
        return
    end
    
    print("=== Plot Structure Debug ===")
    print("Plot name:", plot.Name)
    
    local podFolder = plot:FindFirstChild("AnimalPodiums")
    if podFolder then
        print("Found AnimalPodiums folder")
        for _, podium in ipairs(podFolder:GetChildren()) do
            print("  Podium:", podium.Name, "(" .. podium.ClassName .. ")")
            
            local claim = podium:FindFirstChild("claim")
            if claim then
                print("    - claim found (" .. claim.ClassName .. ")")
                local main = claim:FindFirstChild("Main")
                if main then
                    print("      - Main found (" .. main.ClassName .. ")")
                    
                    -- List all children of Main
                    for _, child in ipairs(main:GetChildren()) do
                        print("        - " .. child.Name .. " (" .. child.ClassName .. ")")
                    end
                end
            end
        end
    else
        print("No AnimalPodiums folder found")
        print("Available children:")
        for _, child in ipairs(plot:GetChildren()) do
            print("  -", child.Name, "(" .. child.ClassName .. ")")
        end
    end
end

-- Main execution
wait(1) -- Wait a moment for everything to load

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
    local plotsFolder = workspace:FindFirstChild("Plots")
    if plotsFolder then
        for _, plot in ipairs(plotsFolder:GetChildren()) do
            print("  -", plot.Name)
        end
    end
end
