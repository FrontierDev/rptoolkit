-- Initialise
_G.Spellbook = _G.Spellbook or {}

_G.spellbookSlots = _G.spellbookSlots or {}

function Spellbook:LoadSpellsFromCampaign(guid)
    -- Ensure the spellbook is a table, not a function
    if type(_G.Spellbook) ~= "table" then
        _G.Spellbook = {}
    end

    -- Ensure the spell slots exist
    _G.spellbookSlots = _G.spellbookSlots or {}

    -- Get the campaign using the provided GUID
    local campaign = _G.CampaignToolkitCampaignsDB[guid]
    if not campaign then
        print("❌ Error: Could not find campaign data for GUID: " .. tostring(guid))
        return
    end

    print("📌 Loading Spells from Campaign: " .. campaign.Name)

    -- Ensure the campaign has a spell list
    if not campaign.SpellList then
        print("⚠️ No SpellList found for " .. campaign.Name)
        return
    end

    -- Track available spell slots
    local slotIndex = 1

    -- Iterate through the campaign's spells
    for _, spell in ipairs(campaign.SpellList) do
        -- Ensure the spell isn't already in the spellbook
        local spellExists = false
        for _, existingSpell in ipairs(_G.Spellbook) do
            if type(existingSpell) == "table" and existingSpell.Guid == spell.Guid then
                spellExists = true
                break
            end
        end

        -- Add spell if it doesn't already exist
        if not spellExists then
            table.insert(_G.Spellbook, spell)
            print(string.format("✅ Loaded Spell: %s from Campaign: %s", spell.Name, campaign.Name))

            -- Assign the spell to the next available spell slot
            if _G.spellbookSlots[slotIndex] then
                _G.spellbookSlots[slotIndex].spell = spell
                _G.spellbookSlots[slotIndex].icon:SetTexture(spell.Icon)
                _G.spellbookSlots[slotIndex].icon:Show()
                slotIndex = slotIndex + 1
            end
        end
    end
end



-- Function to create a new spell
function Spellbook:Add(data)
    -- Create a new spell object
    local newSpell = {
        Guid = data.guid or "UNKNOWN_GUID",
        Name = data.name or "Unknown Spell",
        FromCampaign = data.campaign or "Unknown Campaign",
        Class = data.class or "General",
        Specialisation = data.specialisation or "General",
        ActionCost = data.actionCost or "Action",
        ManaCost = data.manaCost or "0",
        CastTime = data.castTime or "Instant",
        Icon = data.icon or "Interface\\Icons\\INV_Misc_QuestionMark",
        Type = data.type or "Unknown",
        Description = data.description or "No description available.",
        BuiltIn = data.builtIn == true,  -- Ensure this is a boolean
        DefaultSlot = data.defaultSlot or 1,
        Message = data.message or "used a spell.",
        DiceToHit = data.diceToHit or nil,
        HitModifiers = data.hitModifiers or {},
        DiceToDamage = data.diceToDamage or nil,  -- Either specific dice (1d6, 2d8, etc.) or MAIN_HAND/OFF_HAND
        School = data.school or "Physical",
        DamageModifiers = data.damageModifiers or {},
        CritModifier = data.critModifier or nil,
        ScriptId = data.scriptId or nil,
        Requires = data.requires or {},
        Auras = data.auras or {}
    }

    -- Store the spell in the spellbook table
    table.insert(_G.Spellbook, newSpell)

    -- Debugging Output
    -- print(string.format("Created spell: %s with GUID: %s", newSpell.Name, newSpell.Guid))

    if newSpell.BuiltIn then
        CTSpell:EquipSpell(newSpell.Guid, newSpell.DefaultSlot)
    end
end


-- ✅ Create the Spellbook UI inside the CharacterSheet frame
function Spellbook:Create(parentFrame)
    self.frame = CreateFrame("Frame", "SpellbookTabFrame", parentFrame)
    self.frame:SetSize(360, 500)
    self.frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 7, -10)

    -- Define grid layout for spell slots
    local SLOT_SIZE, SLOT_PADDING, COLUMNS, ROWS = 64, -16, 7, 8
    local TOTAL_SLOTS = COLUMNS * ROWS
    local startX, startY = 10, -60

    self.slots = {}

    -- Create Spell Slots
    for i = 1, TOTAL_SLOTS do
        local slot = CreateFrame("Button", "SpellSlot" .. i, self.frame)
        slot:SetSize(SLOT_SIZE, SLOT_SIZE)

        local row, col = math.floor((i - 1) / COLUMNS), (i - 1) % COLUMNS
        slot:SetPoint("TOPLEFT", self.frame, "TOPLEFT", startX + (col * (SLOT_SIZE + SLOT_PADDING)), startY - (row * (SLOT_SIZE + SLOT_PADDING)))

        -- Background texture
        slot.texture = slot:CreateTexture(nil, "BACKGROUND")
        slot.texture:SetAllPoints(slot)
        slot.texture:SetTexture("Interface\\Buttons\\UI-EmptySlot")

        -- Spell icon placeholder
        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetSize(SLOT_SIZE - 32, SLOT_SIZE - 32)
        slot.icon:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        slot.icon:Hide()

        -- Glow border effect (from PlayerTurn.lua)
        slot.glowBorder = slot:CreateTexture(nil, "OVERLAY")
        slot.glowBorder:SetSize(SLOT_SIZE + 16, SLOT_SIZE + 16)  -- Slightly larger for the glow effect
        slot.glowBorder:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.glowBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        slot.glowBorder:SetBlendMode("ADD")
        slot.glowBorder:SetAlpha(0.4)  -- Initially hidden
        slot.glowBorder:Hide()

        slot.spell = nil

        -- ✅ Use CTSpell Tooltip on Hover & Glow Border
        slot:SetScript("OnEnter", function(self)
            if self.spell then
                CTSpell:ShowTooltip(self.spell, slot)  -- Use tooltip from CTSpell.lualot.glowBorder:SetAlpha(0.5)  -- Make glow visible
                slot.glowBorder:Show()
            end
        end)

        slot:SetScript("OnLeave", function(self)
            CTSpell:HideTooltip()
            slot.glowBorder:Hide()
        end)

        -- ✅ Right-click to Equip Spell to First Available Action Bar Slot (Starting at 11)
        slot:SetScript("OnMouseDown", function(self, button)
            if button == "RightButton" and self.spell then
                local firstAvailableSlot = Spellbook:FindFirstAvailableActionSlot()
                if firstAvailableSlot then
                    CTSpell:EquipSpell(self.spell.Guid, firstAvailableSlot)  -- Equip spell&#8203;:contentReference[oaicite:0]{index=0}
                    -- print(string.format("✅ Equipped spell: %s in action bar slot %d", self.spell.Name, firstAvailableSlot))
                    _G.RefreshActionBar()
                else
                    print("❌ No available action bar slots!")
                end
            end
        end)

        _G.spellbookSlots[i] = slot
    end

    self.frame:Hide()
end

-- ✅ Find First Available Action Bar Slot (Starting from Index 11)
function Spellbook:FindFirstAvailableActionSlot()
    _G.equippedSpells = _G.equippedSpells or {}

    for slotIndex = 11, 20 do  -- Checking slots 11 to 20
        if not _G.equippedSpells[slotIndex] then
            return slotIndex  -- Return the first empty slot
        end
    end
    return nil  -- No available slots
end

-- ✅ Add a spell to the first available slot
function Spellbook:AddToSlots(spellData)
    if not _G.spellbookSlots or #_G.spellbookSlots == 0 then
        return
    end

    for _, slot in ipairs(_G.spellbookSlots) do
        if not slot.spell then  -- Find the first empty slot
            slot.spell = spellData
            slot.icon:SetTexture(spellData.Icon or "Interface\\Icons\\INV_Misc_QuestionMark")  -- Default icon if none is set
            slot.icon:Show()

            -- print(">>> Added spell: " .. spellData.Name .. " (" .. spellData.Guid .. ") to the first available slot.")
            return
        end
    end
    -- print("❌ No available spell slots!")
end

function Spellbook:UpdateSpellbookUI()
    if not _G.spellbookSlots or #_G.spellbookSlots == 0 then
        return
    end

    local slotIndex = 1  -- Track available slot index

    for _, spell in ipairs(_G.Spellbook) do
        if not spell.BuiltIn and slotIndex <= #_G.spellbookSlots then  -- Only add non built-in spells
            _G.spellbookSlots[slotIndex].spell = spell
            _G.spellbookSlots[slotIndex].icon:SetTexture(spell.Icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            _G.spellbookSlots[slotIndex].icon:Show()

            slotIndex = slotIndex + 1  -- Move to the next available slot
        end
    end
end


