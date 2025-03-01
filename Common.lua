local Common = {}
_G.Common = Common

function Common:CreateFloatingText(text, r, g, b)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(200, 50)

    local fontString = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    fontString:SetText(text)
    fontString:SetPoint("CENTER", frame, "CENTER")
    fontString:SetTextColor(r, g, b) -- Yellow color for visibility

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

function Common:CheckForCrit(critModifier, roll)
    -- Ensure critModifiers is valid
    if not critModifier then
        return false
    end

    -- Get the mapped stat name from the first modifier
    local mappedModifierType = _G.STAT_NAME_MAPPING[critModifier]

    if not mappedModifierType then
        print("Warning: No mapping found for", critModifier)
        return false
    end

    local critThreshold = 20  -- Default critical hit threshold
    local found = false

    -- Check if combatStats table exists
    if _G.combatStats then
        -- Extract statType and statName (e.g., "Melee.crit" → "Melee", "crit")
        local statType, statName = mappedModifierType:match("^(%a+)%.(%a+)$")

        if statType and statName then
            -- Check if nested structure exists
            if _G.combatStats[statType] and _G.combatStats[statType][statName] then
                critThreshold = 20 - _G.combatStats[statType][statName] or 20
                found = true
            else
                print("No combat stat modifier found for " .. mappedModifierType)
            end
        else
            print("Invalid format for combatStats: " .. mappedModifierType)
        end
    end

    -- Check if the roll meets or exceeds the crit threshold
    if (roll >= critThreshold) then return "CRIT_SUCCESS"
    elseif roll == 1 then return "CRIT_FAIL"
    else return "NOT_CRIT" end
end

function Common:TableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end
