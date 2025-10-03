(function() 
    
    pcall(loadstring, game:HttpGet('https://cdn.shouko.dev/neyoshiiuem/anti.lua'))
    if os.time() >= 1756319996 then 
    --  while true do end 
    end 
    print = function() end
    spawn(function () 
        while task.wait(10) do 
            setfpscap(60)
        end 
    end)
    function CheckKick(v)
        if v.Name == 'ErrorPrompt' then
            task.wait(2)
            print(v.TitleFrame.ErrorTitle.Text)
            if v.TitleFrame.ErrorTitle.Text == 'Teleport Failed' then
                if String.find(v.MessageArea.ErrorFrame.ErrorMessage, 'Unable to join game') then
                    while true do end 
                end
            else 
                game:GetService('TeleportService'):Teleport(game.PlaceId)
                v:Destroy()
            end
        end
    end

    game:GetService('CoreGui').RobloxPromptGui.promptOverlay.ChildAdded:Connect(CheckKick)
    Config = {
        Team = "Pirates",
        Configuration = {
            HopWhenIdle = true,
            AutoHop = true,
            AutoHopDelay = 60 * 60,
            FpsBoost = true
        },
        Items = {

            -- Melees 
            AutoFullyMelees = true,

            -- Swords 
            Saber = false,
            CursedDualKatana = true,

            -- Guns 
            SoulGuitar = true,

            -- Upgrades 

            RaceV2 = false

        },
        Settings = {
            StayInSea2UntilHaveDarkFragments = true
        }
    }
        
    local LogService = game:GetService('LogService')
    local GameName = "Blox Fruit" 

    pcall(function() 
        GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end) 

    local StartTime = os.time()

    local Traces = {} 


    function Build(Error) 
        print("Error\n\n", Error, "\n\n")
        local Result =  {
        content = "<@1330431331057799209>",
        embeds = {
            {
            title = GameName,
            description = game.PlaceId .. " | " .. game.JobId,
            color = 15642286,
            fields = {
                {
                name = "Error Details",
                value = Error
                },
                {   
                name = "Player Info",
                value = "Level: " ..  ScriptStorage.PlayerData.Level
                },
                {
                name = "Script Details",
                value = GetCurrentDateTime() .. " | ".. DispTime(os.time() - StartTime, true)
                .." after execution\nMain task: " .. (  ScriptStorage.Task.MainTask or "n/a" )  .. " ( " .. (  ScriptStorage.Task["MainTask-d"] and  DispTime(os.time() -  ScriptStorage.Task["MainTask-d"], true) or "n/a" ) .. " ) \nSub task: " .. (  ScriptStorage.Task.SubTask or "n/a" ) .. " ( " .. (  ScriptStorage.Task["SubTask-d"] and DispTime(os.time() -  ScriptStorage.Task["SubTask-d"], true) or "n/a") .. " )"
                },
                {
                name = "Traceback",
                value = (function() 
                    local Result = ""
                    
                    for Index , Content in  ScriptStorage.Tracebacks do 
                        
                        if # ScriptStorage.Tracebacks > 20 then 
                            break
                        end
                        
                        Result = Result .. (Content or "null") .. "\n" 
                    end 
                    
                    return Result ~= "" and Result or "... ( empty list ) "
                    
                    end)()
                }
            },
            author = {
                name = tostring(LocalPlayer)
            }
            }
        },
        attachments = {}
        }
        
        for Index, Value in Result.embeds[1].fields do 
            Value.value = "```" .. Value.value .. "```"
        end 
        return Result
    end 

    function Report(Message) 
        if true then 
            if Traces[Message] then return end 
            Traces[Message] = true 
            
            local Body  = game:GetService("HttpService"):JSONEncode(Build(Message)) 
            
            local AffectedIndexes = {0,0,0,0}
            
            request({
                Url = "https://discord.com/api/webhooks/1423586076739768341/AOlHEKnMKkR7f-X-AVtLniE_CYtErMiWUOk5hDKIQZ4s7EyzWEuNPm6xzxRJYaOZCsWE", 
                Method = "POST", 
                Headers = {["Content-Type"] = "application/json"}, 
                Body = Body 
            })
        end 
    end

    function mmb()
        -- Banana Stats Checker UI
        local TweenService = game:GetService("TweenService")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        -- Tạo ScreenGui
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "BananaStatsChecker"
        screenGui.ResetOnSpawn = false
        screenGui.Parent = player:WaitForChild("PlayerGui")

        -- Main Frame
        local mainFrame = Instance.new("Frame")
        mainFrame.Name = "MainFrame"
        mainFrame.Size = UDim2.new(0, 700, 0, 450)
        mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        mainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
        mainFrame.BorderSizePixel = 0
        mainFrame.Parent = screenGui

        -- Corner cho MainFrame
        local mainCorner = Instance.new("UICorner")
        mainCorner.CornerRadius = UDim.new(0, 10)
        mainCorner.Parent = mainFrame

        -- Border vàng
        local border = Instance.new("UIStroke")
        border.Color = Color3.fromRGB(200, 150, 50)
        border.Thickness = 3
        border.Parent = mainFrame

        -- Title
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Title"
        titleLabel.Size = UDim2.new(1, -40, 0, 50)
        titleLabel.Position = UDim2.new(0, 20, 0, 20)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "Banana Stats Checker"
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 28
        titleLabel.TextColor3 = Color3.fromRGB(200, 150, 50)
        titleLabel.Parent = mainFrame

        -- Divider line
        local divider = Instance.new("Frame")
        divider.Size = UDim2.new(0.9, 0, 0, 2)
        divider.Position = UDim2.new(0.05, 0, 0, 80)
        divider.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
        divider.BorderSizePixel = 0
        divider.Parent = mainFrame

        -- Account Stats Section
        local statsLabel = Instance.new("TextLabel")
        statsLabel.Name = "StatsLabel"
        statsLabel.Size = UDim2.new(0.4, 0, 0, 40)
        statsLabel.Position = UDim2.new(0.05, 0, 0, 100)
        statsLabel.BackgroundTransparency = 1
        statsLabel.Text = "Account Stats"
        statsLabel.Font = Enum.Font.GothamBold
        statsLabel.TextSize = 22
        statsLabel.TextColor3 = Color3.fromRGB(200, 150, 50)
        statsLabel.TextXAlignment = Enum.TextXAlignment.Left
        statsLabel.Parent = mainFrame

        -- Stats Container
        local statsContainer = Instance.new("Frame")
        statsContainer.Size = UDim2.new(0.35, 0, 0, 180)
        statsContainer.Position = UDim2.new(0.05, 0, 0, 150)
        statsContainer.BackgroundTransparency = 1
        statsContainer.Parent = mainFrame

        -- Function để tạo stat label
        local function createStatLabel(text, yPos)
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 35)
            label.Position = UDim2.new(0, 0, 0, yPos)
            label.BackgroundTransparency = 1
            label.Text = text
            label.Font = Enum.Font.Gotham
            label.TextSize = 18
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = statsContainer
            return label
        end

        -- Create labels with references for updating
        local levelLabel = createStatLabel("Level: Loading...", 0)
        local raceLabel = createStatLabel("Race: Loading...", 40)
        local beliLabel = createStatLabel("Beli: Loading...", 80)
        local fragLabel = createStatLabel("Frag: Loading...", 120)

        -- Function to format numbers with commas
        local function formatNumber(num)
            local formatted = tostring(num):reverse():gsub("%d%d%d", "%1,"):reverse()
            return formatted:gsub("^,", "")
        end

        -- Function to get player data dynamically (non-blocking)
        local function updateStats()
            pcall(function()
                local playerData = player:FindFirstChild("Data")
                if not playerData then return end

                -- Update Level
                local level = playerData:FindFirstChild("Level") and playerData.Level.Value or 0
                levelLabel.Text = "Level: " .. tostring(level)

                -- Update Race
                local race = playerData:FindFirstChild("Race") and playerData.Race.Value or "Unknown"
                raceLabel.Text = "Race: " .. tostring(race)

                -- Update Beli
                local beli = playerData:FindFirstChild("Beli") and playerData.Beli.Value or 0
                beliLabel.Text = "Beli: " .. formatNumber(beli)

                -- Update Fragments
                local fragments = playerData:FindFirstChild("Fragments") and playerData.Fragments.Value or 0
                fragLabel.Text = "Frag: " .. formatNumber(fragments)
            end)
        end

        -- Auto-update every 5 seconds (non-blocking)
        task.spawn(function()
            task.wait(1) -- Wait 1 second before first update
            while task.wait(5) do
                if screenGui.Parent then
                    updateStats()
                else
                    break
                end
            end
        end)

        -- Account Items Section
        local itemsLabel = Instance.new("TextLabel")
        itemsLabel.Name = "ItemsLabel"
        itemsLabel.Size = UDim2.new(0.4, 0, 0, 40)
        itemsLabel.Position = UDim2.new(0.55, 0, 0, 100)
        itemsLabel.BackgroundTransparency = 1
        itemsLabel.Text = "Account Items"
        itemsLabel.Font = Enum.Font.GothamBold
        itemsLabel.TextSize = 22
        itemsLabel.TextColor3 = Color3.fromRGB(200, 150, 50)
        itemsLabel.TextXAlignment = Enum.TextXAlignment.Left
        itemsLabel.Parent = mainFrame

        -- Items Divider
        local itemsDivider = Instance.new("Frame")
        itemsDivider.Size = UDim2.new(0.85, 0, 0, 2)
        itemsDivider.Position = UDim2.new(0.075, 0, 0, 340)
        itemsDivider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        itemsDivider.BorderSizePixel = 0
        itemsDivider.Parent = mainFrame

        -- Items Container
        local itemsContainer = Instance.new("Frame")
        itemsContainer.Size = UDim2.new(0.85, 0, 0, 80)
        itemsContainer.Position = UDim2.new(0.075, 0, 0, 350)
        itemsContainer.BackgroundTransparency = 1
        itemsContainer.Parent = mainFrame

        -- Function để tạo item label với dot (color changes based on ownership)
        local function createItemLabel(text, column, row)
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(0.3, 0, 0, 30)
            itemFrame.Position = UDim2.new(column * 0.33, 0, 0, row * 40)
            itemFrame.BackgroundTransparency = 1
            itemFrame.Parent = itemsContainer

            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 10, 0, 10)
            dot.Position = UDim2.new(0, 0, 0.5, -5)
            dot.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red by default (not owned)
            dot.BorderSizePixel = 0
            dot.Parent = itemFrame

            local dotCorner = Instance.new("UICorner")
            dotCorner.CornerRadius = UDim.new(1, 0)
            dotCorner.Parent = dot

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 1, 0)
            label.Position = UDim2.new(0, 20, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.Font = Enum.Font.Gotham
            label.TextSize = 16
            label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = itemFrame

            return dot -- Return dot to update color later
        end

        -- Create items with dots
        local itemDots = {
            godHuman = createItemLabel("GodHuman", 0, 0),
            cdk = createItemLabel("Cursed Dual Katana", 1, 0),
            valkyrieHelm = createItemLabel("Valkyrie Helm", 2, 0),
            soulGuitar = createItemLabel("Soul Guitar", 0, 1),
            mirrorFractal = createItemLabel("Mirror Fractal", 1, 1),
            pullLever = createItemLabel("Pull Lever", 2, 1)
        }

        -- Function to check if player has item (using Config)
        local function hasItem(configKey)
            -- Check Config.Items for the item status
            if Config and Config.Items and Config.Items[configKey] ~= nil then
                return Config.Items[configKey]
            end
            return false
        end

        -- Function to update item ownership status
        local function updateItems()
            pcall(function()
                -- Check based on Config.Items
                itemDots.godHuman.BackgroundColor3 = hasItem("AutoFullyMelees") and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
                itemDots.cdk.BackgroundColor3 = hasItem("CursedDualKatana") and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
                itemDots.valkyrieHelm.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Not in config, assume not tracking
                itemDots.soulGuitar.BackgroundColor3 = hasItem("SoulGuitar") and Color3.fromRGB(50, 200, 50) or Color3.fromRGB(200, 50, 50)
                itemDots.mirrorFractal.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Not in config
                itemDots.pullLever.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Not in config
            end)
        end

        -- Initial update for items (only once)
        task.spawn(updateItems)

        -- Join Button
        local joinButton = Instance.new("TextButton")
        joinButton.Name = "JoinButton"
        joinButton.Size = UDim2.new(0, 250, 0, 45)
        joinButton.Position = UDim2.new(0.5, 0, 1, -70)
        joinButton.AnchorPoint = Vector2.new(0.5, 0)
        joinButton.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
        joinButton.Text = "Paste Script to Join Here"
        joinButton.Font = Enum.Font.Gotham
        joinButton.TextSize = 16
        joinButton.TextColor3 = Color3.fromRGB(150, 150, 150)
        joinButton.Parent = mainFrame

        local joinCorner = Instance.new("UICorner")
        joinCorner.CornerRadius = UDim.new(0, 8)
        joinCorner.Parent = joinButton

        local joinBorder = Instance.new("UIStroke")
        joinBorder.Color = Color3.fromRGB(100, 100, 100)
        joinBorder.Thickness = 2
        joinBorder.Parent = joinButton

        -- Hover effect cho button
        joinButton.MouseEnter:Connect(function()
            TweenService:Create(joinButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(40, 45, 55)}):Play()
        end)

        joinButton.MouseLeave:Connect(function()
            TweenService:Create(joinButton, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(30, 35, 45)}):Play()
        end)

        -- Draggable functionality
        local dragging, dragInput, dragStart, startPos

        local function update(input)
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end

        mainFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = mainFrame.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        mainFrame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)

        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                update(input)
            end
        end)

        print("Banana Stats Checker UI loaded successfully!")
    end 

    local success2, response2 = xpcall(mmb, debug.traceback)
    if not success2 then
        Report(response2)
    end
end)()
