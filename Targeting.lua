-- Initialise
local Targeting = {}
_G.Targeting = Targeting

local npcTarget = "NONE"
Targeting.npcTarget = npcTarget
local pcTarget = "NONE"
Targeting.pcTarget = pcTarget

function Targeting:ChangeNpcTarget(unitID)
    if unitID ~= "NONE" then
        Targeting.npcTarget = unitID
        -- print("NPC target is now: " .. Targeting.npcTarget)  -- Use Targeting.npcTarget here
    else
        Targeting.npcTarget = "NONE"
        -- print("Reset NPC target.")
    end

    _G.RefreshActionBar()  -- Call to refresh the action bar (assuming this function is defined elsewhere)
end


function Targeting:ChangePcTarget()
    local targetUnit = "target"  -- Default target unit ID

    -- Check if the target exists
    if not UnitExists(targetUnit) then
        Targeting.pcTarget = "NONE"
        -- print("Reset PC target.")
        return
    end

    -- Get the unit's base name (without realm)
    local fullName = GetUnitName(targetUnit, true) -- Includes realm if available
    local baseName = strsplit("-", fullName) -- Removes realm name

    if not baseName then
        print("Failed to retrieve target name.")
        return
    end

    -- Check if the selected target is in the player's party or raid
    if UnitInParty(targetUnit) or UnitInRaid(targetUnit) then
        Targeting.pcTarget = baseName
    elseif UnitExists(targetUnit) and not UnitIsPlayer(targetUnit) then
        local displayID = select(6, strsplit("-", UnitGUID("target")))

        -- Handle interactions with in-game npcs...?
    end

    _G.RefreshActionBar()
end

function GetTargetNPCDisplayID(target)
    if UnitExists(target) and not UnitIsPlayer(target) then
        return UnitCreatureDisplayID(target)
    end
    return nil  -- Returns nil if no valid target or the target is a player
end

function Targeting:UnitIsPlayer(name)
    if not IsInGroup() then return false end  -- Not in a group, return false

    -- Check player's own name
    if UnitName("player") == name then
        return true
    end

    -- Scan all group members
    local groupType = IsInRaid() and "raid" or "party"
    local numMembers = GetNumGroupMembers()

    for i = 1, numMembers do
        local unitID = groupType .. i
        if UnitExists(unitID) then
            local baseName = GetUnitName(unitID, true) -- Get name (with realm if available)
            baseName = strsplit("-", baseName) -- Remove realm name
            if baseName == name then
                return true
            end
        end
    end

    return false
end




function Targeting:ApplyDamage(target, damage, school)
    if not damage or damage <= 0 then
        -- print("Invalid damage value.")
        return
    end

    local targetUnit = Targeting.npcTarget
    if targetUnit == "NONE" then
        -- print("No NPC target selected.")
        return
    end

    if Targeting:UnitIsPlayer(targetUnit) then
        -- friendly logic
    else
        UnitFrames:Broadcast_ApplyDamage(targetUnit, damage, school)
    end
end

function Targeting:ApplyAura(target, auraGuid)
    if not auraGuid then
        print("Invalid aura GUID value.")
        return
    end

    if Targeting:UnitIsPlayer(target) then
        PlayerTurn:SendAddAuraMessage(target, auraGuid)
    else
        UnitFrames:Broadcast_ApplyAura(target, auraGuid)
    end
end

function Targeting:RemoveAura(target, auraGuid)
    if not auraGuid then
        print("Invalid aura GUID value.")
        return
    end

    local targetUnit = Targeting.npcTarget
    if targetUnit == "NONE" then
        print("No NPC target selected.")
        return
    end

    if Targeting:UnitIsPlayer(targetUnit) then
        -- friendly logic
    else
        UnitFrames:Broadcast_RemoveAura(targetUnit, auraGuid)
    end
end



-- Listen for the PLAYER_TARGET_CHANGED event
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")

-- Update pcTarget when the event is fired
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_TARGET_CHANGED" then
        Targeting:ChangePcTarget()
    end
end)