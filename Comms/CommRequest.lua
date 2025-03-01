local ADDON_PREFIX = "CTUF"

local CommRequest = {}
_G.Request = CommRequest

local ADDON_PREFIX = "CTUF"

local CommRequest = {}
_G.Request = CommRequest

local function GetGroupLeader()
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name, rank = GetRaidRosterInfo(i)
            if rank == 2 then -- 2 indicates the raid leader
                return name
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local unit = "party" .. i
            if UnitIsGroupLeader(unit) then
                return UnitName(unit)
            end
        end
    end
    return nil
end

function Request:SyncUnitFrame()
    if IsInGroup() and not UnitIsGroupLeader("player") then
        local leader = GetGroupLeader()
        if leader then
            C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "SYNCREQ:", "WHISPER", leader)
        end
    end
end
