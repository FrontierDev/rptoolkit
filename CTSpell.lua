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
            print(requirement)
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
        NOT_SELF = self.CheckPCTargetNotSelf
    }

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
                print("Unknown requirement: " .. requirement)
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

 
function CTSpell:Use(guid)
    -- Find the spell by its GUID
    local spellToUse
    for _, spell in pairs(spellbook) do
        print(spell.Guid)

        if spell.Guid == guid then
            spellToUse = spell
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
                SpellDamage = CTSpell.UseSpellDamageSpell
            }

            local func = spellTypeFunctions[spellToUse.Type]  
            if func then
                -- Call the appropriate function for the spell type, passing `self` to preserve context
                func(self, spellToUse)  -- Pass `spellToUse` to the function if needed

                -- Apply all effects from the given spell.
                if spellToUse.Auras then
                    for _, aura in pairs(spellToUse.Auras) do                   
                        CTSpell:ApplySpellAura(UnitName("player"), GetSpellTarget(spellToUse), aura, "Tick")
                    end
                end
            else
                print("Unknown spell type: " .. spellToUse.Type)
            end
        end


        -- Action costs
        if spellToUse.ActionCost == "Action" then
            _G.playerHasAction = false
        elseif spellToUse.ActionCost == "Bonus Action" then
            _G.playerHasBonusAction = false
        end

        _G.RefreshActionBar()

    else
        print("Spell not found!")
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

function CTSpell:UseGeneralSpell(spellToUse)
    print(spellToUse.Message)
end

function CTSpell:UseStatisticSpell(spellToUse)
    -- print("Spell message: " ..spellToUse.Message)
    Dice.Roll("1d20", spellToUse.Message, spellToUse.HitModifiers, false, "ALL")
end

function CTSpell:UseWeaponDamageSpell(spellToUse)

end

-- Can only be used on enemy unit frames
function CTSpell:UseSpellDamageSpell(spellToUse)
    local target = GetSpellTarget(spellToUse)
    if target == "UNKNOWN" then
        print("Spell has an unknown target!")
        return
    end
    
    -- Roll to hit, if needed.
    local hitRoll = Dice.Roll(spellToUse.DiceToHit, "Rolled to Hit", spellToUse.HitModifiers, false, "NO_SCROLL")

    -- NYI - CHECK IF THE AC WAS BEAT
    -- ... ... ...

    -- Roll to damage, if successful.
    if spellToUse.DiceToDamage:lower() == "mh" then
        local damageDice, weaponName = CTSpell:GetDamageDiceFromWeapon("Main Hand") 
        damageRoll = Dice.Roll(damageDice, weaponName, spellToUse.DamageModifiers, false, "DAMAGE")
        Targeting:ApplyDamage(target, damageRoll, spellToUse.School)

    elseif spellToUse.DiceToDamage:lower() == "oh" then
        local damageDice, weaponName = CTSpell:GetDamageDiceFromWeapon("Off Hand") 
        damageRoll = Dice.Roll(damageDice, weaponName, "ZERO", false, "DAMAGE")
        Targeting:ApplyDamage(target, damageRoll, spellToUse.School)

    else
        damageRoll = Dice.Roll(spellToUse.DiceToDamage, spellToUse.Name, spellToUse.DamageModifiers, false, "DAMAGE")
        Targeting:ApplyDamage(target, damageRoll, spellToUse.School)
    end    

    -- Trigger any auras that have a TargetHit trigger.
    CTAura:OnEnemyHit()

    -- Apply any auras that are set to apply on hit.
    if spellToUse.Auras then
        for _, aura in pairs(spellToUse.Auras) do
            print("Applying aura: " ..aura)
            CTSpell:ApplySpellAura(UnitName("player"), GetSpellTarget(spellToUse), aura, "HitTarget")
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
        print("Spell has an unknown target!")
        return
    end

    print("Attempting to cast " ..auraGUID.. " on trigger " .. trigger)

    -- Find the aura from any loaded campaign
    local foundAura = nil
    for _, campaign in pairs(_G.Campaigns) do
        if campaign.AuraList then
            for _, aura in ipairs(campaign.AuraList) do
                if aura.Guid == auraGUID and aura.TriggerOn == trigger then
                    print("Applying aura: " .. aura.Name .. " to target: " ..target)
                    CTAura:ApplyAura(target, caster, aura)
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
        print("❌ Error: _G.Spellbook is not a table!")
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
        print("❌ Error: Spell with GUID " .. guid .. " not found!")
        return
    end

    -- Ensure equippedSpells table exists
    _G.equippedSpells = _G.equippedSpells or {}

    -- Equip the spell in the specified slot
    _G.equippedSpells[slot] = spellToEquip

    print(string.format("Equipped spell: %s (%s) in action bar slot %d", spellToEquip.Name, spellToEquip.Guid, slot))
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
    if spell.HitModifiers then
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
    type = "WeaponDamage",
    actionCost = "Action",
    icon = "Interface\\Icons\\inv_sword_27",  -- Icon path
    description = "Attack with your main hand weapon.",  -- Spell description
    builtIn = true,  -- Is this a built-in spell?
    defaultSlot = 1,
    diceToHit = "1d20",  -- Dice for the spell (e.g., damage roll)
    hitModifiers = { "meleeHit" },  -- Modifier (e.g., type of spell or damage modifier)
    diceToDamage = "MAIN_HAND",
    critModifier = "meleeCrit",
    damageModifiers = { "meleeBonus" }, -- The modifier to be applied to deal damage (e.g. melee bonus, ranged bonus, fire bonus...)
    scriptId = nil,
    requires = { "MAIN_HAND", "TARGET_ENEMY" }
}

local builtin_oh_attack = {
    guid = "BUILTIN_OH_ATTACK",  -- Unique GUID for the spell
    name = "Off Hand Attack",  -- Spell name
    type = "WeaponDamage",
    actionCost = "Bonus Action",
    icon = "Interface\\Icons\\trade_archaeology_silverdagger",  -- Icon path
    description = "Attack with your off hand weapon.",  -- Spell description
    builtIn = true,  -- Is this a built-in spell?
    defaultSlot = 6,
    diceToHit = "1d20",  -- Dice for the spell (e.g., damage roll)
    hitModifiers = {"meleeHit"},  -- Modifier (e.g., type of spell or damage modifier)
    diceToDamage = "OFF_HAND",
    damageModifiers = {"meleeBonus"}, -- The modifier to be applied to deal damage (e.g. melee bonus, ranged bonus, fire bonus...)
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
    defaultSlot = 2,
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