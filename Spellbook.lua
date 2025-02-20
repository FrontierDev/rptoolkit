-- Initialise
_G.Spellbook = _G.Spellbook or {}

_G.spellbookSlots = _G.spellbookSlots or {}

local specialisations = {
    ["General"] = { "General" },
    ["Death Knight"] = { "Blood", "Frost", "Unholy" },
    ["Demon Hunter"] = { "Havoc", "Vengeance" },
    ["Druid"] = { "Balance", "Feral", "Guardian", "Restoration" },
    ["Evoker"] = { "Devastation", "Preservation", "Augmentation" },
    ["Hunter"] = { "Beast Mastery", "Marksmanship", "Survival" },
    ["Mage"] = { "Arcane", "Fire", "Frost" },
    ["Monk"] = { "Brewmaster", "Mistweaver", "Windwalker" },
    ["Paladin"] = { "Holy", "Protection", "Retribution" },
    ["Priest"] = { "Discipline", "Holy", "Shadow" },
    ["Rogue"] = { "Assassination", "Outlaw", "Subtlety" },
    ["Shaman"] = { "Elemental", "Enhancement", "Restoration" },
    ["Warlock"] = { "Affliction", "Demonology", "Destruction" },
    ["Warrior"] = { "Arms", "Fury", "Protection" }
}

function Spellbook:CreateDropdowns(parentFrame)
    -- Class Dropdown
    local selectedClass = "General"
    self.ClassDropdown = CreateFrame("Frame", "ClassDropdown", parentFrame, "UIDropDownMenuTemplate")
    self.ClassDropdown:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 50, -35)

    UIDropDownMenu_Initialize(self.ClassDropdown, function(self, level, menuList)
        for className, _ in pairs(specialisations) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = className
            info.func = function()
                selectedClass = className
                UIDropDownMenu_SetText(self, className)
                Spellbook:UpdateSpecialisationDropdown(className)
                Spellbook:UpdateSpellbookUI()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(self.ClassDropdown, "Any Class")

    -- Specialisation Dropdown
    self.SpecialisationDropdown = CreateFrame("Frame", "SpecialisationDropdown", parentFrame, "UIDropDownMenuTemplate")
    self.SpecialisationDropdown:SetPoint("TOPLEFT", self.ClassDropdown, "TOPRIGHT", 100, 0)
    UIDropDownMenu_SetText(self.SpecialisationDropdown, "Any Specialisation")
    
    self:UpdateSpecialisationDropdown("Any")
end

function Spellbook:UpdateSpecialisationDropdown(className)
    UIDropDownMenu_Initialize(self.SpecialisationDropdown, function(self, level, menuList)
        for _, spec in ipairs(specialisations[className] or { "Any" }) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = spec
            info.func = function()
                UIDropDownMenu_SetText(self, spec)
                Spellbook:UpdateSpellbookUI()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(self.SpecialisationDropdown, "Any Specialisation")
end


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
        print("|cffff0000Error: Could not find campaign data for GUID: " .. tostring(guid).. "|r")
        return
    end

    -- Ensure the campaign has a spell list
    if not campaign.SpellList then
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

    if newSpell.BuiltIn then
        CTSpell:EquipSpell(newSpell.Guid, newSpell.DefaultSlot)
    end
end


-- ✅ Create the Spellbook UI inside the CharacterSheet frame
function Spellbook:Create(parentFrame)
    self.frame = CreateFrame("Frame", "SpellbookTabFrame", parentFrame)
    self.frame:SetSize(360, 500)
    self.frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 7, -10)

    self:CreateDropdowns(self.frame)

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
        slot.equipped = false

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
                if not slot.equipped then
                    local firstAvailableSlot = Spellbook:FindFirstAvailableActionSlot()
                    if firstAvailableSlot then
                        CTSpell:EquipSpell(self.spell.Guid, firstAvailableSlot)
                        slot.equipped = true
                        Spellbook:HighlightEquippedSpell(slot, true)
                        _G.RefreshActionBar()
                    else
                        print("|cffff0000No available action bar slots!|r")
                    end
                else
                    CTSpell:UnequipSpell(self.spell.Guid)
                    slot.equipped = false
                    Spellbook:HighlightEquippedSpell(slot, false)
                    _G.RefreshActionBar()
                end
            end
        end)

        _G.spellbookSlots[i] = slot
    end

    self.frame:Hide()
end

function Spellbook:HighlightEquippedSpell(slot, highlighted)
    -- Add the glow effect if it hasn't been added already
    if not slot.glow and highlighted then
        -- Create a new glow texture
        local glow = slot:CreateTexture(nil, "ARTWORK")  -- Use ARTWORK to ensure it sits above other textures
        glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")  -- A simple, standard border texture
        glow:SetBlendMode("ADD")  -- Set blend mode to make it glow

        -- Manually adjust the size of the glow texture
        glow:SetWidth(slot.icon:GetWidth() * 2.2)  -- Increase the width by 20% (or adjust to your preference)
        glow:SetHeight(slot.icon:GetHeight() * 2.2)  -- Increase the height by 20% (or adjust to your preference)

        glow:SetPoint("CENTER", slot.icon, "CENTER")  -- Center the glow around the icon
        glow:SetAlpha(0.8)  -- Adjust the glow intensity (feel free to tweak this value)

        -- Store the glow texture for later removal
        slot.glow = glow
    elseif slot.glow and highlighted then
        slot.glow:Show()
    elseif slot.glow and not highlighted then
        slot.glow:Hide()
    end    
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
    local selectedClass = UIDropDownMenu_GetText(self.ClassDropdown)
    local selectedSpecialisation = UIDropDownMenu_GetText(self.SpecialisationDropdown)
    
    for _, slot in ipairs(_G.spellbookSlots) do
        slot.icon:Hide()
        slot.spell = nil
    end

    local slotIndex = 1
    for _, spell in ipairs(_G.Spellbook) do
        if not spell.BuiltIn and 
           (spell.Class == selectedClass or selectedClass == "Any Class") and
           (spell.Specialisation == selectedSpecialisation or selectedSpecialisation == "Any Specialisation") then
            local slot = _G.spellbookSlots[slotIndex]
            if slot then
                slot.spell = spell
                slot.icon:SetTexture(spell.Icon)
                slot.icon:Show()
                slotIndex = slotIndex + 1
            end
        end
    end
end



