repeat task.wait(.5) until game.PlaceId ~= nil
repeat task.wait(.5) until game:GetService("Players") and game:GetService("Players").LocalPlayer
repeat task.wait(.5) until not game.Players.LocalPlayer.PlayerGui:FindFirstChild("__INTRO")
local Player = game:GetService("Players").LocalPlayer
local RepStor = game:GetService("ReplicatedStorage")
local Library = require(RepStor.Library)
local saveMod = require(RepStor.Library.Client.Save)

function Info(name)
    return saveMod.Get()[name]
end 

function getDiamonds()
    return Player.leaderstats["💎 Diamonds"].Value
end

for Index, User in pairs(getgenv().KiTTYWARE.autoPrepare.Usernames) do
    for _, Current in pairs(getgenv().KiTTYWARE.autoPrepare.mailConfig) do
        if getDiamonds() >= 10000 then -- kiểm tra xem có đủ kim cương để gửi không
            for ID, itemTable in pairs(Info("Inventory")[Current.Class]) do
                -- kiểm tra tên vật phẩm
                if itemTable.id == Current.Name then
                    -- kiểm tra tier/type của vật phẩm
                    if (not itemTable.sh or itemTable.sh and Current.Shiny) then
                        if (not itemTable.pt or itemTable.tn and not Current.Tier) or
                            (itemTable.pt and itemTable.pt == Current.Tier) or
                            (itemTable.tn and itemTable.tn == Current.Tier) then
                            -- kiểm tra số lượng vật phẩm
                            local amountToSend = (not itemTable._am and 1) or
                                                 (itemTable._am and itemTable._am >= Current.Amount and Current.Amount) or
                                                 (itemTable._am and itemTable._am < Current.Amount and itemTable._am)
                            
                            -- nếu có số lượng vật phẩm để gửi
                            if amountToSend > 0 then
                                repeat 
                                    local success = Library.Network.Invoke("Mailbox: Send", User, "i<3Kittys", Current.Class, ID, amountToSend)
                                until success
                                -- print("Sent", amountToSend, Current.Name, "to", User)
                            end
                        end
                    end
                end
            end
        end
    end
end
