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
        TriggerOn = data.TriggerOn or "Tick",
        ApplyTo = data.ApplyTo or "Target",
        Description = data.Description or "This aura has no description.",
        RemainingTurns = tonumber(data.RemainingTurns), -- Duration in turns
        Effects = data.Effects or {}
    }

    if data.ApplyTo == "Target" then
        Targeting:ApplyAura(target, data.Guid)
    else
        Targeting:ApplyAura(caster, data.Guid)
    end
end

-- Function to remove an aura
function CTAura:RemoveAura(target, data)
    if CTAura.activeAuras[target] and CTAura.activeAuras[target][data.Guid] then
        CTAura.activeAuras[target][data.Guid] = nil
        CombatLog:PrintMessage(string.format("Your %s fades from %s.", data.Name, target))
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
            -- Is your auraGUID active on the target?
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
            -- print("Active aura: " ..aura.Name.. " on target: " ..target.. " | Remaining turns: " ..aura.RemainingTurns)

            if aura.RemainingTurns > 0 and aura.Caster == UnitName("Player") then
                hasActiveAuras = true

                -- Trigger any auras which are triggered on tick.
                if aura.TriggerOn == "Tick" then 
                    if aura.ApplyTo == "Target" then 
                        CTAura:Trigger_Tick(aura, target)     
                    else
                        CTAura:Trigger_Tick(aura, aura.Caster)     
                    end
                end

                -- Reduce remaining turns of ALL auras.
                aura.RemainingTurns = aura.RemainingTurns - 1

                -- Remove auras which have completed their final tick.
                if aura.RemainingTurns == 0 then
                    self:RemoveAura(target, aura)
                end
            elseif aura.RemainingTurns <= 0 and aura.Caster == UnitName("Player") then
                self:RemoveAura(target, aura)
            end
        end
    end

    -- Send a message to all party/raid members informing them to advance the counter on
    -- any aura that the player had cast on them.
    if hasActiveAuras then
        PlayerTurn:SendAuraTickAdvanceMessage()
    end
end

-- Called when the caster succeeds an attack roll.
function CTAura:OnEnemyHit(targetHit)
    for auraUnit, auras in pairs(CTAura.activeAuras) do
        for auraGUID, aura in pairs(auras) do
            if aura.RemainingTurns > 0  and aura.TriggerOn == "OnEnemyHit" then
                if aura.ApplyTo == "Target" then 
                    CTAura:Trigger_OnEnemyHit(aura, auraUnit, targetHit)     
                else
                    CTAura:Trigger_OnEnemyHit(aura, aura.Caster, targetHit)     
                end
            end
        end
    end
end

-- Called when the caster succeeds an attack roll.
function CTAura:OnHitTaken(hitBy)
    for auraUnit, auras in pairs(CTAura.activeAuras) do
        for auraGUID, aura in pairs(auras) do
            if aura.RemainingTurns > 0  and aura.TriggerOn == "OnHitTaken" then
                if aura.ApplyTo == "Target" then 
                    CTAura:Trigger_OnHitTaken(aura, auraUnit, hitBy)     
                else
                    CTAura:Trigger_OnHitTaken(aura, aura.Caster, hitBy)     
                end
            end
        end
    end
end

-- Calls when the caster's turn begins, i.e., the 'tick'.
function CTAura:Trigger_Tick(aura, target)
    if not CTAura:CheckConditions(aura, target) then 
        print("Cannot tick aura: " ..aura.Name.. "; condition not met.") 
        return    
    end

    -- Process aura effects before reducing turns/
    if aura.Effects and #aura.Effects > 0 then
        for _, effect in ipairs(aura.Effects) do

            -- Apply damage to a unit.
            if effect.Type == "DamageTarget" then                               -- When the aura ticks, damage [target]         ✅
                AuraEffect:DamageTick(target, aura, effect)
            elseif effect.Type == "HealTarget" then                             -- When the aura ticks, heal [target]           ✅
                AuraEffect:HealingTick(target, aura, effect)
            elseif effect.Type == "HealCaster" then                             -- When the aura ticks, heal the caster.        ✅
                AuraEffect:HealingTick(aura.Caster, aura, effect)
            end
        end
    end
end

function CTAura:Trigger_OnEnemyHit(aura, auraUnit, targetHit)
    if not CTAura:CheckConditions(aura, auraUnit) then 
        print("Cannot trigger aura; condition not met.") 
        return    
    end

    -- Process aura effects before reducing turns
    if aura.Effects and #aura.Effects > 0 then
        for _, effect in ipairs(aura.Effects) do
            if effect.Type == "DamageTarget" then                               -- When [auraUnit] hits an enemy, deal damage to [targetHit].   ✅ 
                AuraEffect:DamageTick(targetHit, aura, effect)                     
            elseif effect.Type == "HealTarget" then                             -- When [auraUnit] hits an enemy, heal [targetHit].             ✅ 
                AuraEffect:HealingTick(targetHit, aura, effect)                    
            elseif effect.Type == "HealCaster" then                             -- When [auraUnit] hits an enemy, heal the caster.              ❌
                AuraEffect:HealingTick(aura.Caster, aura, effect)                       -- does not work because OnEnemyHit() is called locally on auraUnit.
            end
        end
    end
end

function CTAura:Trigger_OnHitTaken(aura, auraUnit, hitEnemy)
    if not CTAura:CheckConditions(aura, auraUnit) then 
        print("Cannot trigger aura; condition not met.") 
        return    
    end

    -- Process aura effects before reducing turns
    if aura.Effects and #aura.Effects > 0 then
        for _, effect in ipairs(aura.Effects) do
            if effect.Type == "DamageTarget" then                               -- When [auraUnit] is hit by [hitEnemy], deal damage to [hitEnemy]. 
                AuraEffect:DamageTick(hitEnemy, aura, effect)                     
            elseif effect.Type == "HealTarget" then                             -- When [auraUnit] is hit by [hitEnemy], heal [hitEnemy]. 
                AuraEffect:HealingTick(hitEnemy, aura, effect)                    
            elseif effect.Type == "HealCaster" then                             -- When [auraUnit] is hit by [hitEnemy], heal the aura caster. 
                AuraEffect:HealingTick(aura.Caster, aura, effect)               
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
