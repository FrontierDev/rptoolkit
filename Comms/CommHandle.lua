local ADDON_PREFIX = "CTUF"

local CommHandle = {}
_G.Handle = CommHandle

function Handle:SyncUnitFrame(data)
    UnitFrames:Handle_Sync(data)
end

function Handle:SyncUnitFrameRequest(data)
    for _, frame in ipairs(UnitFrames.frames) do
        if frame then
            Broadcast:SyncUnitFrame(frame)
        end
    end    
end

-- Prints to the combat log and subtracts health from the damaged player.
function Handle:DamagePlayer(data)
    -- Split the data string into components using ";" as delimiter
    local args = { strsplit(";", data) }
    local source, player, damage, school, type = args[1], args[2], args[3], args[4], args[5]


    -- Split the player name if it includes a realm (for example, "PlayerName-Realm")
    local playerName, playerRealm = strsplit("-", player)
    playerName = playerName or player -- Fallback in case the split doesn't work

    CombatLog:PrintMessage(string.format("%s deals %s %s damage to %s.", source, damage, school, player))

    -- Check if the current player is the one who was damaged
    if UnitName("player") == playerName then
        -- Subtract health.
        local currentHealth = _G.hiddenStats["Health"]
    
        -- Get mitigation.
        local mitigation = 0
        local coefficient = 1
        if type == "DIRECT" then
            if school == "Physical" then
                mitigation = _G.hiddenStats["Armor"]
            else
                mitigation = tonumber(_G.resistanceFrames[school].mit:GetText())
                print(mitigation)
            end
        else
            coefficient = 0.5
            if school == "Physical" then
                mitigation = math.floor(_G.hiddenStats["Armor"] * coefficient)
            else
                mitigation = math.floor(tonumber(_G.resistanceFrames[school].mit:GetText()) * coefficient)
                print(mitigation)
            end       
        end

        -- Calculate final damage.
        local finalDamage = damage - mitigation

        -- Clamp the final damage between 0 and current health
        finalDamage = math.max(0, math.min(finalDamage, currentHealth))

        -- Apply the final damage to health
        _G.hiddenStats["Health"] = _G.hiddenStats["Health"] - finalDamage
        
        -- Print the damage dealt
        -- print(unitFrame .. " dealt " .. finalDamage .. " (" ..damage.. " -" ..mitigation.. ") " .. school .. " damage to " .. player)

        -- Print the current health and mitigation used
        -- print("Health: " ..currentHealth.. " -> " .. _G.hiddenStats["Health"])

        -- Update health and mana (assuming _G.UpdateHealthAndMana() handles UI updates)
        _G.UpdateHealthAndMana()
    end
end

-- Prints to the combat log and adjusts the player's health while tracking overhealing.
function Handle:HealPlayer(data)
    -- Split the data string into components using ";" as a delimiter
    local args = { strsplit(";", data) }
    local source, player, healing, school, type = args[1], args[2], tonumber(args[3]), args[4], args[5]

    -- Ensure healing is a valid number
    if not healing then
        print("Error: Invalid healing value received.")
        return
    end

    -- Split the player name if it includes a realm (e.g., "PlayerName-Realm")
    local playerName, playerRealm = strsplit("-", player)
    playerName = playerName or player -- Fallback in case the split doesn't work

    CombatLog:PrintMessage(string.format("%s was healed for %s HP by %s.", player, healing, source))

    -- Check if the current player is the one who was healed
    if UnitName("player") == playerName then
        -- Get current and max health values
        local currentHealth = _G.hiddenStats["Health"]
        local maxHealth = _G.hiddenStats["MaxHealth"]

        -- Calculate effective healing and overhealing
        local effectiveHealing = math.min(healing, maxHealth - currentHealth)
        local overhealing = healing - effectiveHealing

        -- Apply healing, ensuring it doesn't exceed max health
        _G.hiddenStats["Health"] = math.min(currentHealth + effectiveHealing, maxHealth)

        -- Update UI or related mechanics
        _G.UpdateHealthAndMana()

        -- Log overhealing if any
        if overhealing > 0 then
            print(string.format("%s overhealed for %s.", source, overhealing))
        end
    end
end


function Handle:DamageUnitFrame(data)
    local args = { strsplit(";", data) }
    local source, targetUnit, damage, school = args[1], args[2], args[3], args[4]

    UnitFrames:ApplyDamage(source, targetUnit, damage, school)
end

-- Called when a unit frame has an aura applied to it. Stores the aura on the unit
-- frame and draws the icon.
function Handle:AddAuraUnitFrame(data)
    local args = { strsplit(";", data) }
    local targetUnit, auraGuid, sender = args[1], args[2], args[3]

    -- Ensure the target unit exists by matching against frame names
    local targetFrame = nil
    for _, frame in pairs(UnitFrames.frames) do
        if frame.NPCNameLabel and frame.NPCNameLabel:GetText() == targetUnit then
            targetFrame = frame
            break
        end
    end

    if not targetFrame then 
        print("|cffff0000Error: Target frame for", targetUnit, "not found in UnitFrames.frames.|r")
        return 
    end

    -- Search for the aura in the campaign's list of auras
    local auraData = nil
    for _, campaign in pairs(_G.CampaignToolkitCampaignsDB) do
        if campaign.AuraList then  -- Ensure the campaign has an AuraList
            for _, aura in pairs(campaign.AuraList) do
                if aura.Guid == auraGuid then
                    auraData = aura
                    break
                end
            end
        end
        if auraData then break end
    end

    -- Break if broken!
    if not auraData then return end

    -- Apply the aura visually
    targetFrame:AddAura({
        {
            Guid = auraData.Guid,
            Icon = auraData.Icon or "Interface\\Icons\\INV_Misc_QuestionMark", -- Default icon if none is set
            Name = auraData.Name,
            Type = auraData.Type,
            Caster = sender,
            Effects = auraData.Effects,
            RemainingTurns = auraData.RemainingTurns,
            Description = auraData.Description
        }
    })

    CombatLog:PrintMessage(string.format("%s gains %s.", targetUnit, auraData.Name))
end

-- Called when a unit frame has an aura prematurely removed. Aura icons will automatically 
-- remove if they reach 0 turns remaining.
function Handle:RemoveAuraUnitFrame(data)
    print("[Comms] - Handle.RemoveAuraUnitFrame called.")
end

function Handle:AddConditionUnitFrame(data)
    local args = { strsplit(";", data) }
    local targetUnit, condition, sender = args[1], args[2], args[3]    

    -- Ensure the target unit exists by matching against frame names
    local targetFrame = nil
    for _, frame in pairs(UnitFrames.frames) do
        if frame.NPCNameLabel and frame.NPCNameLabel:GetText() == targetUnit then
            targetFrame = frame
            break
        end
    end

    table.insert(frame.Conditions, condition)
end

local function OnAddonMessage(self, event, prefix, message, sender)
    if prefix ~= ADDON_PREFIX then return end  -- Ignore unrelated messages

    -- Handle all other inputs.
    local data = message
    if message:find("^DAMAGE_PLAYER:") then
        data = message:sub(15)
        if Handle and Handle.DamagePlayer then
            Handle:DamagePlayer(data)
        end
    elseif message:find("^DAMAGE_NPC:") then
        data = message:sub(12)
        if Handle and Handle.DamageUnitFrame then
            Handle:DamageUnitFrame(data)
        end
    elseif message:find("^ADDAURA_NPC:") then
        data = message:sub(13)  
        if Handle and Handle.AddAuraUnitFrame then
            Handle:AddAuraUnitFrame(data)
        end
    elseif message:find("^REMAURA_NPC:") then
        data = message:sub(13)
        if Handle and Handle.RemoveAuraUnitFrame then
            Handle:RemoveAuraUnitFrame(data)
        end
     elseif message:find("^HEAL_PLAYER:") then
        data = message:sub(13)
        if Handle and Handle.RemoveAuraUnitFrame then
            Handle:HealPlayer(data)
        end
     elseif message:find("^CONDITION_NPC:") then
        data = message:sub(15)
        if Handle and Handle.AddConditionUnitFrame then
            Handle:AddConditionUnitFrame(data)
        end
     elseif message:find("^SYNC:") then
        data = message:sub(6)
        if Handle and Handle.SyncUnitFrame then
            Handle:SyncUnitFrame(data)
        end
     elseif message:find("^SYNCREQ:") then
        data = message:sub(9)
        if Handle and Handle.SyncUnitFrame then
            Handle:SyncUnitFrameRequest(sender)
        end    
    end
end

-- Initialisation for the event listener.
if not eventFrame then
    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        OnAddonMessage(self, event, ...)
    end
end)

