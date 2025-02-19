-- Dice.lua (Global Dice Rolling Utility)
local Dice = {}

Dice.rollResults = {}

-- Function to generate a shorter GUID for the roll
local function GenerateGUID()
    return string.format("G%d-%d", time() % 100000, math.random(1000, 9999))
end

-- Function to create a floating text frame for dice rolls
local function CreateFloatingText(text)
    -- Only create floating text if not silent
    if not Dice.silent then
        local frame = CreateFrame("Frame", nil, UIParent)
        frame:SetSize(200, 50)

        local fontString = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        fontString:SetText(text)
        fontString:SetPoint("CENTER", frame, "CENTER")
        fontString:SetTextColor(1, 1, 0) -- Yellow color for visibility

        -- Generate a random X offset (-50 to 50)
        local randomX = math.random(-50, 50)
        local randomY = math.random(-5, 5)

        -- Position near the player with a random X-axis shift
        frame:SetPoint("CENTER", UIParent, "CENTER", randomX, 10 + randomY)
        frame:SetScale(2.0)

        -- Animate upwards slowly like floating combat text
        local anim = frame:CreateAnimationGroup()
        
        local move = anim:CreateAnimation("Translation")
        move:SetOffset(0, 80) -- Moves the text upward
        move:SetDuration(5)  -- Slower animation (was 1s, now 2s)
        move:SetSmoothing("OUT")

        local fade = anim:CreateAnimation("Alpha")
        fade:SetFromAlpha(1)
        fade:SetToAlpha(0)
        fade:SetDuration(5)  -- Fade-out also slower
        fade:SetSmoothing("OUT")

        -- Destroy frame after animation
        anim:SetScript("OnFinished", function() frame:Hide() end)

        -- Start animation
        anim:Play()
    end
end

-- Function to request a roll from either one player or all players.
-- This is typically done on the party leader's side.
function Dice.RequestRoll(playerID, modifier, rollName, rollGuid)
    -- Generate a request GUID.
    if rollGuid == nil then
        rollGuid = GenerateGUID()
    end
    
    -- Send a roll request to the target player or all players
    local rollMessage = string.format("ROLL_REQUEST:%s:%s:%s:%s", modifier, playerID or "ALL", rollName, rollGuid)

    -- Send the message to all players in the group
    local channel = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage("CTDICE", rollMessage, channel)
    print("[Dice] Sent roll request:", rollMessage)

    return rollGuid
end

function Dice.Simple(dice)
    -- Match the dice string using a pattern
    local numDice, numSides, modifier = dice:match("^(%d+)d(%d+)([+-]?%d*)$")

    -- If the string format is invalid, return an error
    if not numDice or not numSides then
        print("Invalid dice format: " .. dice)
        return 0
    end
    
    -- Convert values to numbers
    numDice = tonumber(numDice)
    numSides = tonumber(numSides)
    
    -- If modifier exists and is not empty, convert it to a number, otherwise set it to 0
    modifier = modifier == "" and 0 or tonumber(modifier) or 0

    -- Roll the dice
    local total = 0
    for i = 1, numDice do
        total = total + math.random(1, numSides)
    end

    -- Apply the modifier
    total = total + modifier

    -- Return the result
    return total
end

function Dice.Roll(dice, rollName, modifierTypes, silent, display)
    local displayType
    if not display then 
        displayType = "ALL"
    else
        displayType = display
    end

    Dice.silent = silent  -- Set the silent flag based on input

    local num, sides = dice:match("(%d+)d(%d+)")  -- Parse dice format, e.g., "1d20"
    num, sides = tonumber(num), tonumber(sides)

    -- Now, handle the modifier lookup inside Dice.Roll using STAT_NAME_MAPPING
    local modifier = 0

    if type(modifierTypes) == "string" then
        -- If it's a string, process it as a single modifier type
        local modifierType = modifierTypes
        -- Use STAT_NAME_MAPPING to get the corresponding modifier
        if _G.STAT_NAME_MAPPING[modifierType] then
            -- Look for the modifier based on the mapping
            local mappedModifierType = _G.STAT_NAME_MAPPING[modifierType]
            local found = false

            -- Check if it's in abilityMods, skillModifiers, hiddenStats, or combatStats
            if _G.abilityMods and _G.abilityMods[mappedModifierType] then
                modifier = modifier + _G.abilityMods[mappedModifierType]
            elseif _G.skillModifiers and _G.skillModifiers[mappedModifierType] then
            -- If the UI element exists for the skill modifier
                local skillTextValue = _G.skillTexts[mappedModifierType].modText:GetText()

                -- Check if we have a valid value, and convert it to a number if possible
                if skillTextValue then
                    modifier = modifier + tonumber(skillTextValue) or modifier + 0  -- Convert the text value to a number (default to 0 if invalid)
                    print("Found skill modifier from UI: " .. mappedModifierType .. " = " .. modifier)
                else
                    print("No value found for skill modifier: " .. mappedModifierType)
                end
            elseif _G.hiddenStats and _G.hiddenStats[mappedModifierType] then
                modifier = modifier + _G.hiddenStats[mappedModifierType]
            end

            if _G.combatStats and not found then
                -- Check if the modifier exists in the combatStats table (nested structure)
                local statType, statName = mappedModifierType:match("^(%a+)%.(%a+)$")  -- Try to extract type and stat (e.g., Melee.bonus)

                if statType and statName then
                    -- Ensure that the correct combat stat exists
                    if _G.combatStats[statType] and _G.combatStats[statType][statName] then
                        modifier = modifier + _G.combatStats[statType][statName] or modifier + 0
                        found = true
                    else
                        print("No combat stat modifier found for " .. mappedModifierType)
                    end
                else
                    print("Invalid format for combatStats: " .. mappedModifierType)
                end
            end

            if _G.resistances and not found then
                -- Check if the modifier exists in the combatStats table (nested structure)
                print("Searching for modifier in resistances...")

                local statType, statName = mappedModifierType:match("^(%a+)%.(%a+)$")  -- Try to extract type and stat (e.g., Melee.bonus)
                if statType and statName then
                    -- Ensure that the correct combat stat exists
                    if _G.resistances[statType] and _G.resistances[statType][statName] then
                        modifier = modifier + _G.resistanceFrames[statType][statName]:GetText()
                        found = true
                    else
                        print("No resistance modifier found for " .. mappedModifierType)
                    end
                else
                    print("Invalid format for resistances: " .. mappedModifierType)
                end        
            else
                print("No modifier found for mapped type: " .. mappedModifierType)
            end
        else
            print("Modifier type not found in STAT_NAME_MAPPING: " .. modifierType)
        end
    elseif type(modifierTypes) == "table" then
        print("Multiple modifiers detected...")

        for _, modifierType in ipairs(modifierTypes) do
            -- Use STAT_NAME_MAPPING to get the corresponding modifier
            if _G.STAT_NAME_MAPPING[modifierType] then
                -- Look for the modifier based on the mapping
                local mappedModifierType = _G.STAT_NAME_MAPPING[modifierType]
                local found = false

                -- Check if it's in abilityMods, skillModifiers, hiddenStats, or combatStats
                if _G.abilityMods and _G.abilityMods[mappedModifierType] then
                    modifier = modifier + _G.abilityMods[mappedModifierType]
                elseif _G.skillModifiers and _G.skillModifiers[mappedModifierType] then
                -- If the UI element exists for the skill modifier
                    local skillTextValue = _G.skillTexts[mappedModifierType].modText:GetText()

                    -- Check if we have a valid value, and convert it to a number if possible
                    if skillTextValue then
                        modifier = modifier + tonumber(skillTextValue) or modifier + 0  -- Convert the text value to a number (default to 0 if invalid)
                        print("Found skill modifier from UI: " .. mappedModifierType .. " = " .. modifier)
                    else
                        print("No value found for skill modifier: " .. mappedModifierType)
                    end
                elseif _G.hiddenStats and _G.hiddenStats[mappedModifierType] then
                    modifier = modifier + _G.hiddenStats[mappedModifierType]
                end

                if _G.combatStats and not found then
                    -- Check if the modifier exists in the combatStats table (nested structure)
                    local statType, statName = mappedModifierType:match("^(%a+)%.(%a+)$")  -- Try to extract type and stat (e.g., Melee.bonus)

                    if statType and statName then
                        -- Ensure that the correct combat stat exists
                        if _G.combatStats[statType] and _G.combatStats[statType][statName] then
                            modifier = modifier + _G.combatStats[statType][statName] or modifier + 0
                            found = true
                        else
                            print("No combat stat modifier found for " .. mappedModifierType)
                        end
                    else
                        print("Invalid format for combatStats: " .. mappedModifierType)
                    end
                end

                if _G.resistances and not found then
                    -- Check if the modifier exists in the combatStats table (nested structure)
                    print("Searching for modifier in resistances...")

                    local statType, statName = mappedModifierType:match("^(%a+)%.(%a+)$")  -- Try to extract type and stat (e.g., Melee.bonus)
                    if statType and statName then
                        -- Ensure that the correct combat stat exists
                        if _G.resistances[statType] and _G.resistances[statType][statName] then
                            modifier = modifier + _G.resistanceFrames[statType][statName]:GetText()
                            found = true
                        else
                            print("No resistance modifier found for " .. mappedModifierType)
                        end
                    else
                        print("Invalid format for resistances: " .. mappedModifierType)
                    end        
                else
                    print("No modifier found for mapped type: " .. mappedModifierType)
                end
            else
                print("Modifier type not found in STAT_NAME_MAPPING: " .. modifierType)
            end
        end
    end

    if not num or not sides then
        print("Invalid dice format:", dice)
        return 0
    end

    local baseRoll = 0
    for i = 1, num do
        baseRoll = baseRoll + math.random(1, sides)
    end

    print(baseRoll)

    -- Only send the message and show floating text if not silent
    if not Dice.silent then
        Dice.SendRollMessage(UnitName("player"), rollName or "Roll", dice, modifier, baseRoll)

        print (displayType)
        if displayType == "ALL" then
            local displayText = string.format("%s %d", rollName or "Roll", baseRoll + modifier)
            CreateFloatingText(displayText)
        elseif displayType == "DAMAGE" then
            local displayText = string.format("%d", baseRoll + modifier)          
            CreateFloatingText(displayText)
        elseif displayType == "NO_SCROLL" then
            -- Do nothing
        end
    end

    return baseRoll + modifier
end



-- Function to print the results of a given roll GUID
function Dice.PrintRollResults(rollGUID)
    -- Check if the rollGUID exists in the rollResults table
    if Dice.rollResults[rollGUID] then
        print(string.format("Results for Roll GUID: %s", rollGUID))

        -- Iterate through each player and print their result
        for playerName, result in pairs(Dice.rollResults[rollGUID]) do
            print(string.format("  %s rolled: %d", playerName, result))
        end
    else
        -- If the rollGUID doesn't exist, print a message indicating no results
        print(string.format("No results found for Roll GUID: %s", rollGUID))
    end
end

-- Function to send nicely formatted dice rolls to the rest of the party/raid.
function Dice.SendRollMessage(playerName, rollType, dice, modifier, baseRoll)
    -- Only send message if not silent
    if Dice.silent then return end

    local total = baseRoll + modifier
    local rollMessage = string.format(
        "|cffffff00[%s]|r %s rolled %s: %d + %d = |cff00ff00%d|r",
        rollType, playerName, dice, baseRoll, modifier, total
    )

    -- Determine the appropriate channel
    local chatChannel = "PARTY"
    if IsInRaid() then
        chatChannel = "RAID"
    elseif not IsInGroup() then
        chatChannel = "WHISPER"
    end

    -- Debug: Print message before sending
    print("📢 Sending Roll Message:", rollMessage, "via", chatChannel)

    -- Send addon message with proper formatting
    C_ChatInfo.SendAddonMessage("CTDICE", rollMessage, chatChannel)
end

local function OnAddonMessage(self, event, prefix, message, _, sender)
    if prefix ~= "CTDICE" then return end  -- Ignore unrelated messages

    print(message)

    -- Determine the appropriate channel
    local chatChannel = "PARTY"
    if IsInRaid() then
        chatChannel = "RAID"
    elseif not IsInGroup() then
        chatChannel = "WHISPER"
    end

    -- Handle roll request
    if string.sub(message, 1, 12) == "ROLL_REQUEST" then
        local event, modifierType, playerID, rollName, rollGuid = strsplit(":", message)
    
        -- Debug print to verify the parsed message
        print("Event: " .. event)
        print("Modifier Type: " .. modifierType)
        print("PlayerID: " .. playerID)
        print("Roll GUID: " .. rollGuid)

        if not Dice.rollResults[rollGuid] then
            print("Received request for roll " .. rollGuid .. " and initialised storage.")
            Dice.rollResults[rollGuid] = {}
        end

        -- Pass the parsed modifierType to Dice.Roll
        local roll = Dice.Roll("1d20", rollName, modifierType, false)
        
        local message = string.format("ROLL_RESULT:%s:%d:%s", UnitName("player"), tonumber(roll), rollGuid)
        C_ChatInfo.SendAddonMessage("CTDICE", message, chatChannel)

        -- You may choose to return or send a response here if needed
        return
    end

    -- Handle roll result (when the client sends the result back)
    if string.sub(message, 1, 11) == "ROLL_RESULT" then
        local event, playerID, result, rollGuid = strsplit(":", message)
        result = tonumber(result)
        -- Process the result as needed, e.g., display in the UI or log it
        print(string.format("ROLL_RESULT (%s): %s rolled %d", rollGuid, playerID, result))

        -- Store the result in the rollResults table
        if Dice.rollResults[rollGuid] then
            print("Roll stored to " ..rollGuid)
            Dice.rollResults[rollGuid][playerID] = result
        else
            print("No roll found with GUID:", rollGuid)
        end
    end
end



-- **Event Listener to Receive Roll Messages**
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON") -- Listen for addon messages
frame:SetScript("OnEvent", function(_, event, prefix, message, _, sender)
    if event == "CHAT_MSG_ADDON" and prefix == "CTDICE" then
        -- Call OnAddonMessage to handle the message
        OnAddonMessage(frame, event, prefix, message, _, sender)
    end
end)


-- Store Dice globally so it can be used anywhere
_G.Dice = Dice