local allAmount = "all" -- Định nghĩa biến allAmount để đại diện cho tất cả số lượng

repeat task.wait(.5) until game.PlaceId ~= nil
repeat task.wait(.5) until game:GetService("Players") and game:GetService("Players").LocalPlayer
repeat task.wait(.5) until not game.Players.LocalPlayer.PlayerGui:FindFirstChild("__INTRO")
local Player = game:GetService("Players").LocalPlayer
local RepStor = game:GetService("ReplicatedStorage")
local Library = require(RepStor.Library)
local saveMod = require(RepStor.Library.Client.Save)
function Info(name) return saveMod.Get()[name] end 
function getDiamonds() return Player.leaderstats["💎 Diamonds"].Value end

for Index,User in pairs(getgenv().KiTTYWARE.autoPrepare.Usernames) do
    for _,Current in pairs(getgenv().KiTTYWARE.autoPrepare.mailConfig) do
        if getDiamonds() >= 10000 then -- has enough to mail check
            for ID,itemTable in pairs(Info("Inventory")[Current.Class]) do
                -- item name check
                if itemTable.id == Current.Name then
                    -- item tier/type checks
                    if (not itemTable.sh or itemTable.sh and Current.Shiny) then
                        if (not itemTable.pt or itemTable.tn and not Current.Tier) or
                            (itemTable.pt and itemTable.pt == Current.Tier) or
                            (itemTable.tn and itemTable.tn == Current.Tier) then
                            -- item amount checks
                            local amountToSend = Current.Amount
                            if amountToSend == allAmount then
                                -- If Amount is "all", set it to the maximum available
                                amountToSend = itemTable._am or 1
                            end
                            repeat
                                local success = Library.Network.Invoke("Mailbox: Send", User, "i<3Kittys", Current.Class, ID, amountToSend)
                                task.wait(0.5)
                            until success
                            --print("Sent", amountToSend, Current.Name, "to", User)
                        end
                    end
                end
            end
        end
    end
end
