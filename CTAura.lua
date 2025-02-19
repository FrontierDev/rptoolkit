-- CTAura.lua
local CTAura = {}
_G.CTAura = CTAura

-- Table to store active auras placed by the player.
CTAura.activeAuras = {}

-- Function to generate a unique aura GUID
local function GenerateAuraGUID()
    return tostring(math.random(100000, 999999)) .. tostring(GetTime() * 1000)
end

-- Function to apply a buff or debuff
function CTAura:ApplyAura(target, caster, data)
    if not target or not data.Guid or not data.Type then 
        print("ERROR: Missing required aura data! Check AuraGUID, AuraType, and Duration.")
        return 
    end

    if not CTAura.activeAuras[target] then
        CTAura.activeAuras[target] = {}
    end

    if not data.RemainingTurns then data.RemainingTurns = 1 end

    -- Store the aura
    CTAura.activeAuras[target][data.Guid] = {
        Name = data.Name or "Unknown Aura",
        Caster = caster or "Unknown Unit",
        Guid = data.Guid or nil,
        Type = data.Type or "Debuff",  -- Buff or debuff type
        TriggerOn = data.TriggerOn or "Cast",
        Description = data.Description or "This aura has no description.",
        RemainingTurns = tonumber(data.RemainingTurns), -- Duration in turns
        Effects = data.Effects or {}
    }

    Targeting:ApplyAura(target, data.Guid)
    print("Aura " .. data.Guid .. " applied to " .. target .. " for " .. data.RemainingTurns .. " turns.")
end

-- Function to remove an aura
function CTAura:RemoveAura(target, data)
    if CTAura.activeAuras[target] and CTAura.activeAuras[target][data.Guid] then
        CTAura.activeAuras[target][data.Guid] = nil
        print("Aura " .. data.Name .. " faded from " .. target)
    end
end

-- Function to check if an aura is active
function CTAura:IsAuraActive(target, auraGUID)
    if CTAura.activeAuras[target] and CTAura.activeAuras[target][auraGUID] then
        local aura = CTAura.activeAuras[target][auraGUID]
        if aura.RemainingTurns > 0 then
            return true
        else
            self:RemoveAura(target, auraGUID)
        end
    end
    return false
end

function CTAura:CheckConditions(aura, target)
    if not aura.Effects or #aura.Effects == 0 then return true end

    local effects = aura.Effects
    local passed = true

    for _, effect in ipairs(effects) do
        if effect.Condition == "None" then 
            -- do nothing
        elseif effect.Condition == "Main Hand" then
            if not Equipment.equippedItems["Main Hand"] then
                passed = false
            end
        elseif effect.Condition == "Off Hand" then
            if not Equipment.equippedItems["Off Hand"] then
                passed = false
            end
        elseif effect.Condition == "Shield" then
            if not Equipment.equippedItems["Shield"] then
                passed = false
            end
        else
            if not CTAura:IsAuraActive(target, auraGUID) then
                passed = false
            end
        end
    end

    return passed
end

-- Function to progress turns and reduce aura durations.
-- All auras which have the Trigger On = 'Cast' will be ticked.
function CTAura:AdvanceTurn() 
    local hasActiveAuras = false

    for target, auras in pairs(CTAura.activeAuras) do
        for auraGUID, aura in pairs(auras) do
            print("Active aura: " ..aura.Name.. " on target: " ..target)

            if aura.RemainingTurns > 0 and aura.Caster == UnitName("Player") then
                hasActiveAuras = true

                -- Trigger any auras which are triggered on tick.
                if aura.TriggerOn == "Tick" then CTAura:TriggerAura_Tick(aura, target) end

                -- Reduce remaining turns of ALL auras.
                aura.RemainingTurns = aura.RemainingTurns - 1

                -- Remove auras which have completed their final tick.
                if aura.RemainingTurns == 0 then
                    self:RemoveAura(target, aura)
                end
            end
        end
    end

    -- Send a message to all party/raid members informing them to advance the counter on
    -- any aura that the player had cast on them.
    if hasActiveAuras then
        PlayerTurn:SendAuraTickAdvanceMessage()
    end
end

function CTAura:OnEnemyHit()
    print("Triggering aura because an enemy was hit.")

    for target, auras in pairs(CTAura.activeAuras) do
        for auraGUID, aura in pairs(auras) do
            if aura.RemainingTurns > 0 then
                -- Trigger any auras which are triggered on tick.
                print(aura.Name)
                if aura.TriggerOn == "HitTarget" then CTAura:TriggerAura_HitTarget(aura, target) end

                -- Reduce remaining turns of ALL auras.
                aura.RemainingTurns = aura.RemainingTurns - 1
                -- Remove auras which have completed their final tick.
                if aura.RemainingTurns == 0 then
                    self:RemoveAura(target, auraGUID)
                end
            end
        end
    end
end

function CTAura:TriggerAura_Tick(aura, target)
    local canTick = CTAura:CheckConditions(aura, target)

    if not canTick then 
        print("Cannot tick aura: " ..aura.Name.. "; condition not met.") 
        return    
    end

    -- Process aura effects before reducing turns
    if aura.Effects and #aura.Effects > 0 then
        for _, effect in ipairs(aura.Effects) do

            -- Apply damage to a unit.
            if effect.Type == "Damage_Tick" then
                print(string.format("... Applied %s (%s) damage to %s", effect.Value, effect.School, target))
                Targeting:ApplyDamage(target, tonumber(effect.Value), effect.School)
            elseif effect.Type == "Healing_Tick" then
                print(string.format("... Applied %s healing to %s", effect.Value, target))            
            end
        end
    end
end

function CTAura:TriggerAura_HitTarget(aura, target)
    local canTick = CTAura:CheckConditions(aura, target)

    if not canTick then 
        print("Cannot tick aura; condition not met.") 
        return    
    end

    print("Triggered aura because a target was hit.")

    -- Process aura effects before reducing turns
    if aura.Effects and #aura.Effects > 0 then
        for _, effect in ipairs(aura.Effects) do

            -- Apply damage to a unit.
            if effect.Type == "Damage_Tick" then
                print(string.format("... Applied %s (%s) damage to %s", effect.Value, effect.School, target))
                Targeting:ApplyDamage(target, effect.Value, effect.School)
            elseif effect.Type == "Healing_Tick" then
                print(string.format("... Applied %s healing to %s", effect.Value, target))            
            elseif effect.Type == "Script" then
                print("Running script effect: " ..effect.Value)
                CTAura:RunScript(effect.Value)
            end
        end
    end
end

function CTAura:RunScript(scriptId)
    -- Extract table name and function name from "CTSpell:Test_Function"
    local objectName, functionName = string.match(scriptId, "([^:]+):([^:]+)")

    if objectName and functionName then
        local object = _G[objectName] -- Get the table (e.g., `CTSpell`)
        local func = object and object[functionName] -- Get the method reference

        if type(func) == "function" then
            print("✅ Executing:", objectName .. ":" .. functionName)
            func(object, self) -- Call the method with the correct `self`
        else
            print("❌ Error: Function '" .. tostring(functionName) .. "' not found in '" .. tostring(objectName) .. "'!")
        end
    else
        print("❌ Error: Invalid ScriptId format! Expected 'TableName:FunctionName'")
    end
end

-- Show the tooltip for a spell
function CTAura:ShowTooltip(aura, slot)
    -- Ensure the tooltip is properly positioned relative to the slot
    GameTooltip:SetOwner(slot, "ANCHOR_TOP")  -- Anchor the tooltip to the left of the slot
    GameTooltip:SetWidth(150)

    -- Apply the offset to move it further to the right of the slot
    local tooltipOffsetX = 00  -- Small offset to the right of the slot

    -- Set the point of the tooltip to be just to the right of the slot
    GameTooltip:SetPoint("TOP", slot, "BOTTOM", tooltipOffsetX, 0)

    -- Display the aura details in the tooltip
    GameTooltip:SetText(aura.Name, 1, 1, 1)  -- Display aura name

    GameTooltip:AddLine(aura.Description, nil, nil, nil, true)  -- Display description
    
    GameTooltip:Show()  -- Show the tooltip
end

return CTAura
