local ADDON_PREFIX = "RPT"

-- Initialisation
local Player = {}
_G.Player = Player

function Player:Broadcast_HealPlayer
    local message = string.format("%s;%s;%s;%s;%s", source, player, type)

    local channel = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "HEAL_PLAYER:" .. message, channel)
end

function Player:Broadcast_DamagePlayer(source, player, damage, school, type)
    local message = string.format("%s;%s;%s;%s;%s", source, player, damage, school, type)

    local channel = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "DAMAGE_PLAYER:" .. message, channel)
end