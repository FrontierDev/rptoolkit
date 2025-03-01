-- Initialise
local CTSpell = {}
_G.CTSpell = CTSpell

local CTAura = _G.CTAura

-- Move this to Spellbook.Lua later
local spellbook = _G.Spellbook

local weaponDamageFunctions = {
    MAIN_HAND = CTSpell.SpellCheckMainHandWeapon,   -- Gets main hand damage dice and modifier
    OFF_HAND = CTSpell.CheckOffHandWeapon           -- Gets off hand damage and modifier
}

-- Helper function to print a table's keys and values
function PrintTable(t)
    for key, value in pairs(t) do
        if type(value) == "function" then
            -- Print function references in a readable way
            print(key, " = <function>")
        else
            -- Print other values normally
            print(key, " = ", value)
        end
    end
end

local function GetSpellTarget(spell)
    if spell.Requires then
        for _, requirement in ipairs(spell.Requires) do
            if requirement == "TARGET_ALLY" then
                return _G.Targeting.pcTarget
            elseif requirement == "TARGET_ENEMY" then
                return _G.Targeting.npcTarget
            elseif requirement == "SELF" then
                return UnitName("Player")
            end
        end
    end

    return "UNKNOWN"
end

function CTSpell:CheckRequirements(spell)
    -- Define a table that maps requirements to functions
    local requirementFunctions = {
        MAIN_HAND = self.CheckMainHandWeapon,
        OFF_HAND = self.CheckOffHandWeapon,
        LEVEL = self.CheckLevelRequirement,
        TARGET_ENEMY = self.CheckNPCTarget,
        TARGET_ALLY = self.CheckPCTarget,
        NOT_SELF = self.CheckPCTargetNotSelf,
        SELF = self.CheckPCTargetIsSelf,
        HASTE = self.CheckHaste
    }

    -- Check cooldown requirement NYI

    
    -- Check mana cost requirement
    if tonumber(spell.ManaCost) > 0 then
        local playerMana = _G.hiddenStats["Mana"]

        if tonumber(spell.ManaCost) >= playerMana then return false end
    end

    -- Check all other requirements
    if spell.Requires then
        for _, requirement in ipairs(spell.Requires) do
            -- print("Checking requirement: " .. requirement)

            -- Call the appropriate function based on the requirement
            local func = requirementFunctions[requirement]
            if func then
                local passed = func(self)  -- Call the function (using self to preserve method context)

                if not passed then 
                    return passed 
                end
            else
                print("|cffff0000Unknown requirement: " .. requirement.. "|r")
            end
        end
    end

    return true
end

--- MOVE THESE TO THEIR OWN LUA FILE EVENTUALLY
-- Function for checking Main Hand Weapon
function CTSpell:CheckMainHandWeapon()
    if Equipment.equippedItems["Main Hand"] then
        return true
    end
end

function CTSpell:CheckOffHandWeapon()
    if Equipment.equippedItems["Off Hand"] then
        return true
    end
end

function CTSpell:CheckNPCTarget()
    if Targeting.npcTarget == "NONE" then 
        return false
    else 
        return true 
    end
end

function CTSpell:CheckPCTarget()
    if Targeting.pcTarget == "NONE" then 
        return false
    else 
        return true 
    end
end

function CTSpell:CheckPCTargetNotSelf()
    if Targeting.pcTarget == "NONE" or Targeting.pcTarget == UnitName("player") then
        return false
    else
        return true
    end
end

function CTSpell:CheckPCTargetIsSelf()
    if Targeting.pcTarget == UnitName("player") or Targeting.pcTarget == "NONE" then
        return true
    else
        return false
    end
end

function CTSpell:CheckHaste()
    return _G.playerHasHaste
end

 
function CTSpell:Use(guid)
    -- Find the spell by its GUID
    local spellToUse
    for _, spellEntry in pairs(spellbook) do
        if type(spellEntry) == "table" and spellEntry.Guid == guid then
            spellToUse = spellEntry
            break
        end
    end

    if spellToUse then
        local temp = false

        -- Check if the spell requirements are met
        CTSpell:CheckRequirements(spellToUse)

        if temp then
            CTSpell:RunScript(spellToUse)
        else
            -- Handle spells differently depending on their type:
            -- Damage - rolls damage dice, requires a hostile target
            -- General - handles simple messages (like Disengage, Dash)
            -- Statistic - rolls a statistic check
            -- Buff - applies a buff for a certain number of combat turns
            local spellTypeFunctions = {
                General = CTSpell.UseGeneralSpell,   -- Gets main hand damage dice and modifier
                WeaponDamage = CTSpell.UseWeaponDamageSpell,           -- Gets off hand damage and modifier
                Statistic = CTSpell.UseStatisticSpell,
                SpellDamage = CTSpell.UseSpellDamageSpell,
                HealTarget = CTSpell.UseHealTargetSpell,
                Aura_NoTick = CTSpell.Use_AuraNoTick,
                Aura_Tick = CTSpell.Use_AuraTick
            }

            local func = spellTypeFunctions[spellToUse.Type]  
            if func then
                -- Call the appropriate function for the spell type, passing `self` to preserve context
                func(self, spellToUse)  -- Pass `spellToUse` to the function if needed
            else
                print("|cffff0000Unknown spell type: " .. spellToUse.Type.. "|r")
            end
        end


        -- Action costs (action, bonus action, haste action)
        if spellToUse.ActionCost == "Action" then
            _G.playerHasAction = false
        elseif spellToUse.ActionCost == "Bonus Action" then
            _G.playerHasBonusAction = false
        elseif spellToUse.ActionCost == "Haste Attack" then
            _G.playerHasHaste = false
        end

        -- Update health a mana.
        if tonumber(spellToUse.ManaCost) > 0 then
            _G.hiddenStats["Mana"] = _G.hiddenStats["Mana"] - tonumber(spellToUse.ManaCost)
            _G.UpdateHealthAndMana()
        end

        _G.RefreshActionBar()

    else
        print("|cffff0000Error: Spell not found!|r")
    end
end

function CTSpell:RunScript(spellToUse)
    print("🔹 Script ID Found:", spellToUse.ScriptId)

    -- Extract table name and function name from "CTSpell:Test_Function"
    local objectName, functionName = string.match(spellToUse.ScriptId, "([^:]+):([^:]+)")

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

local function CheckForCrit(critModifier, roll)
    -- Ensure critModifiers is valid
    if not critModifier then
        return false
    end

    -- Get the mapped stat name from the first modifier
    local mappedModifierType = STAT_NAME_MAPPING[critModifier]

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


function CTSpell:UseGeneralSpell(spellToUse)
    print(spellToUse.Message)
end

function CTSpell:Use_AuraNoTick(spellToUse)
    local target = GetSpellTarget(spellToUse)
    if target == "UNKNOWN" then
        print("|cffff0000Error: Spell has an unknown target!|r")
        return
    end

    if spellToUse.Auras then
        for _, aura in pairs(spellToUse.Auras) do
            CTSpell:ApplySpellAura(UnitName("player"), target, aura, false)
        end
    end
end

function CTSpell:Use_AuraTick(spellToUse)
    local target = GetSpellTarget(spellToUse)
    if target == "UNKNOWN" then
        print("|cffff0000Error: Spell has an unknown target!|r")
        return
    end

    if spellToUse.Auras then
        for _, aura in pairs(spellToUse.Auras) do
            CTSpell:ApplySpellAura(UnitName("player"), target, aura, true)
        end
    end
end

function CTSpell:UseStatisticSpell(spellToUse)
    -- print("Spell message: " ..spellToUse.Message)
    Dice.Roll("1d20", spellToUse.Message, spellToUse.HitModifiers, false, "ALL")
end

function CTSpell:UseHealTargetSpell(spellToUse)
    local target = GetSpellTarget(spellToUse)
    if target == "UNKNOWN" then
        print("|cffff0000Error: Spell has an unknown target!|r")
        return
    end
    
    local healingModifiers = spellToUse.DamageModifiers
    local critModifier = spellToUse.CritModifier

    -- Check for crit.
    local baseRoll = Dice.Simple("1d20+0")
    local critCheck = CheckForCrit("healCrit", baseRoll)
    local coefficient = 1
    local spellSender = string.format("%s's %s", UnitName("player"), spellToUse.Name)

    if critCheck == "CRIT_SUCCESS" then 
        coefficient = 2 + (_G.hiddenStats.CriticalStrikeDamage/100)
    elseif critCheck == "CRIT_FAIL" then
    else
    end

    -- Calculate and apply the healing done.
    local healingDice = spellToUse.DiceToDamage
    local spellName = spellToUse.Name
    local message = string.format("healing (%s)", spellName)
    if critCheck == "CRIT_SUCCESS" then message = string.format("healing (%s) (Critical, x%.1f)", spellName, coefficient) end

    local healingRoll = coefficient * Dice.Roll(healingDice, message, healingModifiers, false, "HEALING")
    Targeting:ApplyHealing(spellSender, target, math.floor(healingRoll + 0.5), "DIRECT") 

    -- Apply any auras that are set to apply on hit.
    if spellToUse.Auras then
        for _, aura in pairs(spellToUse.Auras) do
            CTSpell:ApplySpellAura(UnitName("player"), GetSpellTarget(spellToUse), aura, false)
        end
    end
end


-- Can only be used on enemy unit frames
function CTSpell:UseSpellDamageSpell(spellToUse)
    local target = GetSpellTarget(spellToUse)
    if target == "UNKNOWN" then
        print("|cffff0000Error: Spell has an unknown target!|r")
        return
    end

    -- If the spell has dynamic modifiers (e.g., main hand attack depends on weapon), then get the actual
    -- modifiers that should be used.
    local hitModifiers = spellToUse.HitModifiers
    local damageModifiers = spellToUse.DamageModifiers
    local critModifier = spellToUse.CritModifier

    if hitModifiers == "DYNAMIC" then
        local mainHand = Equipment.equippedItems["Main Hand"]
        
        if mainHand.handedness == "Ranged" then
            hitModifiers = { "rangedHit" }
            damageModifiers = { "rangedBonus" }
            critModifier = "rangedCrit"
        elseif mainHand.handedness == "Wand" then
            hitModifiers = { "spellHit" }
            damageModifiers = { "spellBonus" }
            critModifier = "spellCrit"
        else
            hitModifiers = { "meleeHit" }
            damageModifiers = { "meleeBonus" }
            critModifier = "meleeCrit"
        end
    end
    
    -- Roll to hit, if needed.
    local hitRoll, baseRoll = Dice.Roll(spellToUse.DiceToHit, string.format("to hit (%s)", spellToUse.Name), hitModifiers, false, "NO_SCROLL")
    
    -- CHECK IF THE UNIT FRAME'S AC WAS BEAT
    local target = GetSpellTarget(spellToUse)

    local function tableContains(tbl, value)
        for _, v in ipairs(tbl) do
            if v == value then return true end
        end
        return false
    end

    -- find the unit frame by cycling through 
    local hit = false
    for _, frame in pairs(UnitFrames.frames) do
        if frame.isVisible and frame.NPCName == target then 
            if tableContains(hitModifiers, "meleeHit") then
                if hitRoll >= tonumber(frame.DefensiveAC.Melee) then hit = true end
            elseif tableContains(hitModifiers, "rangedHit") then
                if hitRoll >= tonumber(frame.DefensiveAC.Ranged) then hit = true end
            elseif tableContains(hitModifiers, "spellHit") then
                if hitRoll >= tonumber(frame.DefensiveAC.Spell) then hit = true end
            end
        end
    end

    -- Exit and print a 'Miss' text if the attack failed.
    if not hit then
        CombatLog:PrintMessage(string.format("Your %s failed to damage %s.", spellToUse.Name, target))
        Common:CreateFloatingText("Miss", 1, 1, 1)
        return
    end

    local critCheck = CheckForCrit(critModifier, baseRoll)
    local coefficient = 1
    local spellSender = string.format("%s's %s", UnitName("player"), spellToUse.Name)

    if critCheck == "CRIT_SUCCESS" then 
        -- print("YOU CRITICALL HIT.") 
        coefficient = 2 + (_G.hiddenStats.CriticalStrikeDamage/100)
    elseif critCheck == "CRIT_FAIL" then
        -- print("Critical fail!")
    else
        -- print("NOT CRIT.")
        -- Do nothing (wasn't a crit!)
    end

    -- Roll to damage, if successful.
    if spellToUse.DiceToDamage:lower() == "mh" then
        local damageDice, weaponName = CTSpell:GetDamageDiceFromWeapon("Main Hand") 
        local message = string.format("damage (%s)", weaponName)
        if critCheck == "CRIT_SUCCESS" then message = string.format("damage (%s) (Critical, x%.1f)", weaponName, coefficient) end

        damageRoll = coefficient * Dice.Roll(damageDice, message, damageModifiers, false, "DAMAGE")
        Targeting:ApplyDamage(spellSender, target, math.floor(damageRoll + 0.5), spellToUse.School or "Physical", "DIRECT")

    elseif spellToUse.DiceToDamage:lower() == "oh" then
        local damageDice, weaponName = CTSpell:GetDamageDiceFromWeapon("Off Hand") 
        local message = string.format("damage (%s)", weaponName)
        if critCheck == "CRIT_SUCCESS" then message = string.format("damage (%s) (Critical, x%.1f)", weaponName, coefficient) end


        damageRoll = coefficient * Dice.Roll(damageDice, message, "ZERO", false, "DAMAGE")
        Targeting:ApplyDamage(spellSender, target, math.floor(damageRoll + 0.5), spellToUse.School or "Physical", "DIRECT")

    else
        local message = string.format("damage (%s)", spellToUse.Name)
        if critCheck == "CRIT_SUCCESS" then message = string.format("damage (%s) (Critical, x%.1f)", weaponName, coefficient) end

        damageRoll = coefficient * Dice.Roll(spellToUse.DiceToDamage, message, damageModifiers, false, "DAMAGE")
        Targeting:ApplyDamage(spellSender, target, math.floor(damageRoll + 0.5), spellToUse.School or "Physical", "DIRECT")
    end    

    -- Trigger any auras that have a TargetHit trigger.
    CTAura:OnEnemyHit(target)

    -- Apply any auras that are set to apply on hit.
    if spellToUse.Auras then
        for _, aura in pairs(spellToUse.Auras) do
            CTSpell:ApplySpellAura(UnitName("player"), GetSpellTarget(spellToUse), aura, false)
        end
    end
end

function CTSpell:GetDamageDiceFromWeapon(hand)
    local dice, weaponName
    if Equipment.equippedItems[hand] then
        dice = Equipment.equippedItems[hand].damageDice or "1d4"
        weaponName = Equipment.equippedItems[hand].name
    end
    return dice, weaponName
end

function CTSpell:ApplySpellAura(caster, target, auraGUID, trigger)
    if target == "UNKNOWN" then
        print("|cffff0000Spell has an unknown target!|r")
        return
    end

    -- Find the aura from any loaded campaign
    local foundAura = nil
    for _, campaign in pairs(_G.Campaigns) do
        if campaign.AuraList then
            for _, aura in ipairs(campaign.AuraList) do
                if aura.Guid == auraGUID then
                    CTAura:ApplyAura(target, caster, aura)

                    -- If the aura should trigger immediately upon being applied.
                    if trigger then
                        if aura.ApplyTo == "Target" then CTAura:Trigger_Tick(aura, target)
                        elseif aura.ApplyTo == "Caster" then CTAura:Trigger_Tick(aura, aura.Caster)
                        end
                    end

                    break               
                end
            end
        end
        if foundAura then break end
    end
end

function CTSpell:EquipSpell(guid, slot)
    -- Ensure Spellbook is a table
    if type(_G.Spellbook) ~= "table" then
        return
    end

    -- Find the spell by its GUID
    local spellToEquip = nil

    -- print("Looking for spell with GUID:", guid)

    for _, spellData in pairs(_G.Spellbook) do
        if type(spellData) == "table" and spellData.Guid == guid then
            spellToEquip = spellData
            break
        end
    end

    -- Error handling if spell is not found
    if not spellToEquip then
        print("|cffff0000Error: Spell with GUID " .. guid .. " not found!|r")
        return
    end

    -- Ensure equippedSpells table exists
    _G.equippedSpells = _G.equippedSpells or {}

    -- Equip the spell in the specified slot
    _G.equippedSpells[slot] = spellToEquip

    -- print(string.format("Equipped spell: %s (%s) in action bar slot %d", spellToEquip.Name, spellToEquip.Guid, slot))
end

function CTSpell:UnequipSpell(guid)
    -- Ensure Spellbook is a table
    if type(_G.Spellbook) ~= "table" then
        return
    end

    -- Find the spell by its GUID
    local slotToClear = nil

    -- print("Looking for spell with GUID:", guid)

    for slot, spellData in pairs(_G.equippedSpells) do
        if spellData.Guid == guid then
            _G.equippedSpells[slot] = nil
            table.remove(_G.equippedSpells, slot)
            break
        end
    end    
end

-- Show the tooltip for a spell
function CTSpell:ShowTooltip(spell, slot)
    -- Ensure the tooltip is properly positioned relative to the slot
    GameTooltip:SetOwner(slot, "ANCHOR_TOP")  -- Anchor the tooltip to the left of the slot
    GameTooltip:SetWidth(150)

    -- Apply the offset to move it further to the right of the slot
    local tooltipOffsetX = 00  -- Small offset to the right of the slot

    -- Set the point of the tooltip to be just to the right of the slot
    GameTooltip:SetPoint("TOP", slot, "BOTTOM", tooltipOffsetX, 0)

    -- Display the spell details in the tooltip
    GameTooltip:SetText(spell.Name, 1, 1, 1)  -- Display spell name

    local manaCost, actionCost = "", ""

    -- If there's a mana cost, set the manaCost text
    if spell.ManaCost then
        manaCost = string.format("%d mana", spell.ManaCost)
    end

    -- If there's an action cost, set the actionCost text
    if spell.ActionCost then
        actionCost = string.format("%s", spell.ActionCost)
    end

    -- If there's no mana cost, we show action cost on the left
    if manaCost == "" then
        GameTooltip:AddDoubleLine(actionCost, "", 1, 1, 1, 1, 1, 1)  -- Only action cost on the left
    else
        -- If there's mana cost, show it on the left and action cost on the right
        GameTooltip:AddDoubleLine(manaCost, actionCost, 1, 1, 1, 1, 1, 1)  -- Mana on the left, action on the right
    end

    -- If there's an action cost, set the actionCost text
    if spell.CastTime then
        castTime = string.format("|cffffffff%s|r", spell.CastTime)
        GameTooltip:AddLine(castTime)  -- Blank line for spacing
    end

    GameTooltip:AddLine(spell.Description, nil, nil, nil, true)  -- Display description
    GameTooltip:AddLine(" ")  -- Blank line for spacing


    -- If the spell is not guaranteed to hit.
    if spell.HitModifiers and spell.HitModifiers ~= "DYNAMIC" then
        local text

        -- Loop through each modifier in spell.HitModifiers
        for _, modifier in ipairs(spell.HitModifiers) do
            -- Look up the stat name from the mapping or use the spell's ModifierToHit directly
            local statName = _G.STAT_TOOLTIP_MAP[modifier] or modifier

            -- Display the modifier in the tooltip
            GameTooltip:AddLine("Success modifier: " .. statName, 1, 1, 0.5)  -- Display modifier
        end
    end

    
    GameTooltip:Show()  -- Show the tooltip
end

-- Hide the tooltip
function CTSpell:HideTooltip()
    GameTooltip:Hide()  -- Hide the tooltip
end

-- Example usage to create a spell
local builtin_mh_attack = {
    guid = "BUILTIN_MH_ATTACK",  -- Unique GUID for the spell
    name = "Main Hand Attack",  -- Spell name
    type = "SpellDamage",
    school = "Physical",
    actionCost = "Action",
    icon = "Interface\\Icons\\inv_sword_27",  -- Icon path
    description = "Attack with your main hand weapon.",  -- Spell description
    builtIn = true,  -- Is this a built-in spell?
    defaultSlot = 1,
    diceToHit = "1d20",  -- Dice for the spell (e.g., damage roll)
    hitModifiers = "DYNAMIC",  -- Modifier (e.g., type of spell or damage modifier)
    diceToDamage = "mh",
    critModifier = "DYNAMIC",
    damageModifiers = "DYNAMIC", -- The modifier to be applied to deal damage (e.g. melee bonus, ranged bonus, fire bonus...)
    scriptId = nil,
    requires = { "MAIN_HAND", "TARGET_ENEMY" }
}

local builtin_haste_attack = {
    guid = "BUILTIN_HASTE_ATTACK",  -- Unique GUID for the spell
    name = "Haste Attack",  -- Spell name
    type = "SpellDamage",
    school = "Physical",
    actionCost = "Free Action",
    icon = "Interface\\Icons\\ability_ardenweald_warrior",  -- Icon path
    description = "Attack with your main hand weapon as a Haste attack.",  -- Spell description
    builtIn = true,  -- Is this a built-in spell?
    defaultSlot = 2,
    diceToHit = "1d20",  -- Dice for the spell (e.g., damage roll)
    hitModifiers = { "hasteHit" },  -- Modifier (e.g., type of spell or damage modifier)
    diceToDamage = "mh",
    critModifier = { "hasteCrit" },
    damageModifiers = { "hasteBonus" }, -- The modifier to be applied to deal damage (e.g. melee bonus, ranged bonus, fire bonus...)
    scriptId = nil,
    requires = { "MAIN_HAND", "TARGET_ENEMY", "HASTE" }
}

local builtin_oh_attack = {
    guid = "BUILTIN_OH_ATTACK",  -- Unique GUID for the spell
    name = "Off Hand Attack",  -- Spell name
    type = "SpellDamage",
    actionCost = "Bonus Action",
    school = "Physical",
    icon = "Interface\\Icons\\trade_archaeology_silverdagger",  -- Icon path
    description = "Attack with your off hand weapon.",  -- Spell description
    builtIn = true,  -- Is this a built-in spell?
    defaultSlot = 6,
    diceToHit = "1d20",  -- Dice for the spell (e.g., damage roll)
    hitModifiers = { "meleeHit" },  -- Modifier (e.g., type of spell or damage modifier)
    diceToDamage = "oh",
    damageModifiers = { "meleeBonus" }, -- The modifier to be applied to deal damage (e.g. melee bonus, ranged bonus, fire bonus...)
    critModifier = "meleeCrit",
    scriptId = nil,
    requires = { "OFF_HAND", "TARGET_ENEMY" }
}

local builtin_disengage = {
    guid = "BUILTIN_DISENGAGE",  -- Unique GUID for the spell
    name = "Disengage",  -- Spell name
    type = "General",
    actionCost = "Action",
    icon = "Interface\\Icons\\ability_hunter_displacement",  -- Icon path
    description = "Disengage from combat, preventing you from taking attacks of opportunity when moving.",  -- Spell description
    message = "disengages from combat.",
    builtIn = true,  -- Is this a built-in spell?
    defaultSlot = 4,
    scriptId = nil
}

local builtin_dash = {
    guid = "BUILTIN_DASH",  -- Unique GUID for the spell
    name = "Dash",  -- Spell name
    type = "General",
    actionCost = "Action",
    icon = "Interface\\Icons\\ability_rogue_sprint_blue",  -- Icon path
    description = "Doubles your |cffffffffmovement speed|r on this turn.",  -- Spell description
    message = "dashes.",
    builtIn = true,  -- Is this a built-in spell?
    defaultSlot = 7,
    scriptId = nil
}

local builtin_hide = {
    guid = "BUILTIN_HIDE",  -- Unique GUID for the spell
    name = "Hide",  -- Spell name
    type = "Statistic",
    actionCost = "Action",
    icon = "Interface\\Icons\\ability_stealth",  -- Icon path
    description = "Attempt to hide from sight.",  -- Spell description
    message = "Stealth (Hide)",
    diceToHit = "1d20",  -- Dice for the spell (e.g., damage roll)
    hitModifiers = { "stealth" },  -- Modifier (e.g., type of spell or damage modifier)
    builtIn = true,  -- Is this a built-in spell?
    defaultSlot = 3,
    scriptId = nil
}

local builtin_aid = {
    guid = "BUILTIN_AID",  -- Unique GUID for the spell
    name = "Aid",  -- Spell name
    type = "Script",
    actionCost = "Action",
    icon = "Interface\\Icons\\ability_shaman_ancestralguidance",  -- Icon path
    description = "Adds your |cffffffffproficiency bonus|r to the target ally's rolls for 1 turn. Does not affect damage rolls.",  -- Spell description
    builtIn = true,
    defaultSlot = 8,
    scriptId = "SCRIPT_BUILTIN_AID",
    requires = { "TARGET_ALLY", "NOT_SELF" }
}

-- Create the spell using the provided data
Spellbook:Add(builtin_mh_attack)
Spellbook:Add(builtin_oh_attack)
Spellbook:Add(builtin_disengage)
Spellbook:Add(builtin_dash)
Spellbook:Add(builtin_hide)
Spellbook:Add(builtin_aid)
Spellbook:Add(builtin_haste_attack)