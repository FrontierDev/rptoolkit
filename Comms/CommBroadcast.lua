local ADDON_PREFIX = "CTUF"

local CommBroadcast = {}
_G.Broadcast = CommBroadcast

function Broadcast:SyncUnitFrame(frame)
    if not IsInGroup() or not UnitIsGroupLeader("player") then return end

    if frame then
        local frameID = frame:GetName() or "Unknown"
        local visibilityState = frame.isVisible and "SHOW" or "HIDE"
        local editButtonState = frame.EditButton and frame.EditButton:IsShown() and "1" or "0"
        local npcID = frame.NPCID or "17227"
        local npcName = frame.NPCName or "Unknown"
        local currentHealth = frame.CurrentHealth or 100
        local maxHealth = frame.MaxHealth or 100
        local modelX = frame.ModelPosition["x"]
        local modelY = frame.ModelPosition["y"]
        local modelZ = frame.ModelPosition["z"]
        local meleeAC = frame.DefensiveAC["Melee"]
        local rangedAC = frame.DefensiveAC["Ranged"]
        local spellAC = frame.DefensiveAC["Spell"]

        local message = string.format("SYNC:%s;%s;%s;%d;%d;%d;%f;%f;%f;%d;%d;%d", 
            frameID, visibilityState, npcName, npcID, currentHealth, maxHealth, modelX, modelY, modelZ,  meleeAC, rangedAC, spellAC)

        local channel = IsInRaid() and "RAID" or "PARTY"
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, channel)
    end
end

-- Prints to the combat log and subtracts health from the damaged player.
function Broadcast:DamagePlayer(source, player, damage, school, type)
    local message = string.format("%s;%s;%s;%s;%s", source, player, damage, school, type)
    local channel = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "DAMAGE_PLAYER:" .. message, channel)
end

function Broadcast:HealPlayer(source, player, damage, school, type)
    local message = string.format("%s;%s;%s;%s", source, player, damage, type or "DIRECT")
    local channel = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "HEAL_PLAYER:" .. message, channel)
end

-- Damages the given unit frame and prints to the combat log.
function Broadcast:DamageUnitFrame(source, targetUnit, damage, school, type)
    if not IsInGroup() then return end
    local message = string.format("%s;%s;%s;%s;%s", source, targetUnit, damage, school, type)
    local channel = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "DAMAGE_NPC:" .. message, channel)
end

-- Adds an aura icon to the given unit frame. Actual functionality of the aura is handled on the 
-- caster's end.
function Broadcast:AddAuraUnitFrame(targetUnit, auraGuid, source)
    if not IsInGroup() then return end

    local message = string.format("%s;%s;%s", targetUnit, auraGuid, UnitName("player"))
    local channel = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "ADDAURA_NPC:" .. message, channel)
end
