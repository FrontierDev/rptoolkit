-- UFSpell.lua: Contains functions for handling unit frame spells and storing data

-- UFSpells: A global table to store spell data
UFSpell = {}

-- Function to add a spell to a unit frame's spell list
function UFSpell:AddSpell(unitFrame, data)
    -- Initialize UFSpells if not already created on the unitFrame
    unitFrame.UFSpells = unitFrame.UFSpells or {}

    -- Check if the spell already exists
    for _, spell in ipairs(unitFrame.UFSpells) do
        if spell.Name == data.Name then
            print("Spell " .. data.Name .. " already assigned.")
            return
        end
    end

    -- Add new spell to the unit frame's UFSpells
    table.insert(unitFrame.UFSpells, {
        Name = data.Name,
        Icon = data.Icon,
        Dice = data.Dice,
        School = data.School,
        Type = data.Type,
        DC = data.DC,
        Aura = data.Aura or nil
    })

    print("Added spell: " .. data.Name .. " to unit frame " .. unitFrame.NPCName)
end

-- Function to remove a spell from a unit frame by spellName
function UFSpell:RemoveSpell(unitFrame, spellName)
    if not unitFrame.UFSpells then
        print("No spells assigned to this unit frame.")
        return
    end

    -- Find and remove the spell
    for i, spell in ipairs(unitFrame.UFSpells) do
        if spell.spellName == spellName then
            table.remove(unitFrame.UFSpells, i)
            print("Removed spell: " .. spellName .. " from unit frame " .. unitFrame.NPCName)
            return
        end
    end

    print("Spell " .. spellName .. " not found.")
end

-- Function to list all spells assigned to a unit frame
function UFSpell:ListSpells(unitFrame)
    if not unitFrame.UFSpells or #unitFrame.UFSpells == 0 then
        print("No spells assigned to this unit frame.")
        return
    end

    print("Spells assigned to " .. unitFrame.NPCName .. ":")
    for _, spell in ipairs(unitFrame.UFSpells) do
        print(" - " .. spell.spellName .. " (ID: " .. spell.spellID .. ")")
    end
end

-- Function to execute a spell (for example, to cast or trigger the spell)
function UFSpell:ExecuteSpell(unitFrame, spellName)
    if not unitFrame.UFSpells then
        print("No spells assigned to this unit frame.")
        return
    end

    for _, spell in ipairs(unitFrame.UFSpells) do
        if spell.spellName == spellName then
            -- Execute the spell (for example, cast the spell)
            -- Here we just simulate casting the spell with a print statement
            print("Executing spell: " .. spellName .. " (ID: " .. spell.spellID .. ")")
            -- Simulate spell execution (can be expanded to actual spell casting logic)
            return
        end
    end

    print("Spell " .. spellName .. " not found.")
end
