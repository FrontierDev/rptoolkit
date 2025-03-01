local CombatLog = {}
_G.CombatLog = CombatLog

function CombatLog:PrintMessage(message)
    -- Grey color for the entire message
    local formattedMessage = "|cff808080" .. message .. "|r"

    -- Define color codes for each spell school
    local schoolColors = {
        Physical = "|cff8B5A2B",  -- Brown
        Fire = "|cffFF4500",      -- Orange-Red
        Frost = "|cff00BFFF",     -- Light Blue
        Nature = "|cff32CD32",    -- Green
        Arcane = "|cff9370DB",    -- Purple
        Fel = "|cff228B22",       -- Dark Green
        Shadow = "|cff4B0082",    -- Dark Purple
        Holy = "|cffFFD700"       -- Gold
    }

    -- Apply color formatting to spell schools and the number before them
    for school, color in pairs(schoolColors) do
        formattedMessage = string.gsub(formattedMessage, "(%d+)(%s" .. school .. ")", color .. "%1%2|r")
    end

    -- Replace any instance of "x HP" (where x is an integer) with light red coloring
    formattedMessage = formattedMessage:gsub("(%d+) HP", function(hitpoints)
        return "|cffff6060" .. hitpoints .. " HP|r"
    end)


    print(formattedMessage)
end

function CombatLog:PrintRollMessage(message)
    -- Replace "(Critical, xN.NN)" with a green-colored version
    local formattedMessage = message:gsub("%(Critical, x[%d%.]+%)", function(criticalText)
        return "|cff00ff00" .. criticalText .. "|r"
    end)

    -- Apply grey color to the entire message while keeping the green and red parts
    formattedMessage = "|cff808080" .. formattedMessage .. "|r"

    print(formattedMessage)
end


