local Equipment = {}

local STAT_NAME_MAPPING = {
    -- ✅ Ability Scores
    STR = "STR", DEX = "DEX", CON = "CON", INT = "INT", WIS = "WIS", CHA = "CHA",

    -- ✅ Hidden Stats
    maxHealth = "MaxHealth",
    maxMana = "MaxMana",
    initiative = "Initiative",
    armor = "Armor",
    deflection = "Deflection",
    manaRegen = "ManaRegen",
    healthRegen = "HealthRegen",
    speed = "Speed",
    concentration = "Concentration",

    -- ✅ Combat Stats (Melee, Ranged, Spell, etc.)
    meleeHit = "Melee.hit",
    meleeBonus = "Melee.bonus",
    meleeCrit = "Melee.crit",
    rangedHit = "Ranged.hit",
    rangedBonus = "Ranged.bonus",
    rangedCrit = "Ranged.crit",
    spellHit = "Spell.hit",
    spellBonus = "Spell.bonus",
    spellCrit = "Spell.crit",
    hasteHit = "Haste.hit",
    hasteBonus = "Haste.bonus",
    hasteCrit = "Haste.crit",
    healCrit = "Heal.crit",
    healBonus = "Heal.bonus",
    dodgeBonus = "Dodge.bonus",
    dodgeCrit = "Dodge.crit",
    parryBonus = "Parry.bonus",
    parryCrit = "Parry.crit",
    blockBonus = "Block.bonus",
    blockCrit = "Block.crit",

    -- ✅ Resistances (mod and mit)
    fireResistMod = "Fire.mod",
    fireResistMit = "Fire.mit",
    frostResistMod = "Frost.mod",
    frostResistMit = "Frost.mit",
    natureResistMod = "Nature.mod",
    natureResistMit = "Nature.mit",
    arcaneResistMod = "Arcane.mod",
    arcaneResistMit = "Arcane.mit",
    shadowResistMod = "Shadow.mod",
    shadowResistMit = "Shadow.mit",
    holyResistMod = "Holy.mod",
    holyResistMit = "Holy.mit",

    -- ✅ Magic schools (bonus and crit)
    fireBonus = "Fire.bonus",
    fireCrit = "Fire.crit",
    frostBonus = "Frost.bonus",
    frostCrit = "Frost.crit",
    natureBonus = "Nature.bonus",
    natureCrit = "Nature.crit",
    arcaneBonus = "Arcane.bonus",
    arcaneCrit = "Arcane.crit",
    felBonus = "Fel.bonus",
    felCrit = "Fel.crit",
    shadowBonus = "Shadow.bonus",
    shadowCrit = "Shadow.crit",
    holyBonus = "Holy.bonus",
    holyCrit = "Holy.crit",

    -- ✅ Skills
    athletics = "Athletics",
    acrobatics = "Acrobatics",
    sleightOfHand = "Sleight of Hand",
    stealth = "Stealth",
    arcana = "Arcana",
    history = "History",
    investigation = "Investigation",
    nature = "Nature",
    religion = "Religion",
    animalHandling = "Animal Handling",
    insight = "Insight",
    medicine = "Medicine",
    perception = "Perception",
    survival = "Survival",
    deception = "Deception",
    intimidation = "Intimidation",
    performance = "Performance",
    persuasion = "Persuasion"
}

local STAT_TOOLTIP_MAP = {
    -- ✅ Ability Scores
    STR = "Strength",
    DEX = "Dexterity",
    CON = "Constitution",
    INT = "Intelligence",
    WIS = "Wisdom",
    CHA = "Charisma",

    maxHealth = "Health",
    maxMana = "Mana",
    initiative = "Initiative",
    armor = "Armor",
    deflection = "Deflection",
    manaRegen = "Mana per Turn",
    healthRegen = "Health per Turn",
    speed = "Movement Range",
    concentration = "Concentration",

    -- ✅ Combat Stats
    meleeHit = "Melee Hit Rating",
    meleeBonus = "Melee Attack Power",
    meleeCrit = "Melee Critical Strike",
    rangedHit = "Ranged Hit Rating",
    rangedBonus = "Ranged Attack Power",
    rangedCrit = "Ranged Critical Strike",
    spellHit = "Spell Hit Rating",
    spellBonus = "Spell Power",
    spellCrit = "Spell Critical Strike",
    hasteBonus = "Haste Rating",
    healCrit = "Healing Critical Strike",
    healBonus = "Bonus Healing",
    dodgeBonus = "Dodge Rating",
    dodgeCrit = "Critical Dodge",
    parryBonus = "Parry Rating",
    parryCrit = "Critical Parry",
    blockBonus = "Block Rating",
    blockCrit = "Critical Block",

    -- ✅ Resistances
    fireResistMod = "Fire Resistance",
    fireResistMit = "Fire Damage Mitigation",
    frostResistMod = "Frost Resistance",
    frostResistMit = "Frost Damage Mitigation",
    natureResistMod = "Nature Resistance",
    natureResistMit = "Nature Damage Mitigation",
    arcaneResistMod = "Arcane Resistance",
    arcaneResistMit = "Arcane Damage Mitigation",
    shadowResistMod = "Shadow Resistance",
    shadowResistMit = "Shadow Damage Mitigation",
    holyResistMod = "Holy Resistance",
    holyResistMit = "Holy Damage Mitigation",

    -- ✅ Magic schools (bonus and crit)
    fireBonus = "Fire Damage",
    fireCrit = "Fire Critical Strike",
    frostBonus = "Fire Damage",
    frostCrit = "Frost Critical Strike",
    natureBonus = "Nature Damage",
    natureCrit = "Nature Critical Strike",
    arcaneBonus = "Arcane Damage",
    arcaneCrit = "Arcane Critical Strike",
    felBonus = "Fel Damage",
    felCrit = "Fel Critical Strike",
    shadowBonus = "Shadow Damage",
    shadowCrit = "Shadow Critical Strike",
    holyBonus = "Holy Damage",
    holyCrit = "Holy Critical Strike",

    -- ✅ Skills
    athletics = "Athletics",
    acrobatics = "Acrobatics",
    sleightOfHand = "Sleight of Hand",
    stealth = "Stealth",
    arcana = "Arcana",
    history = "History",
    investigation = "Investigation",
    nature = "Nature",
    religion = "Religion",
    animalHandling = "Animal Handling",
    insight = "Insight",
    medicine = "Medicine",
    perception = "Perception",
    survival = "Survival",
    deception = "Deception",
    intimidation = "Intimidation",
    performance = "Performance",
    persuasion = "Persuasion"
}

_G.STAT_NAME_MAPPING = STAT_NAME_MAPPING
_G.STAT_TOOLTIP_MAP = STAT_TOOLTIP_MAP

-- Define Item Categories
local ITEM_CATEGORIES = { "Main Hand", "Off Hand", "Chest", "Head", "Class Item", "Trinket", "Shield" }

-- Function to generate a simple GUID using math.random and GetTime()
function GenerateGUID()
    local timeStamp = GetTime() * 1000  -- Multiply by 1000 to get milliseconds
    local randomPart = math.random(1000, 9999)  -- Generate a random number to add more uniqueness
    return "item-" .. math.floor(timeStamp) .. "-" .. randomPart
end

-- Make these globally accessible to other parts of the addon
_G.equippedItemGUIDs = _G.equippedItemGUIDs or {}  -- Global storage for equipped item GUIDs
_G.slots = _G.slots or {}  -- Global storage for slots

-- Assuming GetSlotIndexForItem() is defined inside Equipment.lua
_G.GetSlotIndexForItem = GetSlotIndexForItem  -- Make this method globally accessible

-- Define Equipment Storage
_G.items = _G.items or {}
Equipment.equippedItems = {}
_G.equippedItemGUIDs = _G.slots or {}
_G.slots = _G.slots or {}

-- ✅ Function to Update Inventory UI
function Equipment:UpdateInventoryUI()
    if not _G.slots or #_G.slots == 0 then
        return
    end

    for i, item in ipairs(_G.items) do
        if i <= #_G.slots then
            _G.slots[i].item = item
            _G.slots[i].icon:SetTexture(item.icon)
            _G.slots[i].icon:Show()
        end
    end
end

function Equipment:AddItem(data)
    local itemGUID = GenerateGUID()

    -- Prevent duplicate items
    for _, item in ipairs(_G.items) do
        if item.name == data.name and item.category == data.category then
            print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t ⚠ WARNING: Item already exists, skipping duplicate:", data.name)
            return
        end
    end

    -- Calculate weapon damage range if it's a weapon
    local damageMin, damageMax = nil, nil
    if (data.category == "Main Hand" or data.category == "Off Hand") and data.damageDice then
        local num, sides = data.damageDice:match("(%d+)d(%d+)")
        num, sides = tonumber(num), tonumber(sides)
        damageMin = num or 1
        damageMax = (num * sides) or 1
    end

    -- Create the new item structure
    local newItem = {
        guid = itemGUID,
        name = data.name,
        version = data.version or "Common",
        quality = data.quality or "Uncommon",
        category = data.category,
        icon = data.icon,
        damageDice = data.damageDice or nil,
        damageModifiers = data.damageModifier or nil,
        damageMin = damageMin, -- Stores min damage
        damageMax = damageMax, -- Stores max damage
        armorValue = data.armorValue or nil, -- ✅ NEW: Armor value for armor
        deflectionValue = data.deflectionValue or nil, -- ✅ NEW: Deflection value for shields
        equipped = false,
        effects = data.effects or {},  
        bonuses = data.bonuses or {},
        equipEffects = data.equipEffects or {},
        gemSockets = data.gemSockets or "",
        socketBonus = data.socketBonus or "",
        enchant = data.enchant or "",
        flavorText = data.flavorText or "",
        actionType = data.actionType or "Action" -- Default action type
    }

    -- Category-specific details
    if data.category == "Main Hand" or data.category == "Off Hand" then
        newItem.handedness = data.handedness or "One-Handed"
        newItem.weaponType = data.subtype or "Sword"
    elseif data.category == "Armor" then
        newItem.armorType = data.subtype or "Cloth"
    elseif data.category == "Shield" then
        newItem.shieldType = "Shield"  -- Always "Shield" type
    elseif data.category == "Class Item" then
        newItem.classItemType = data.subtype or "Libram"
    end

    -- Add the item to the global list
    table.insert(_G.items, newItem)
    self:UpdateInventoryUI()

    -- Debugging
    -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Added item:", data.name, "GUID:", itemGUID)
end

function Equipment:AddDefaultItems()
    if _G.items and #_G.items > 0 then
        print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t Skipping default item creation: Items already exist.")
        return
    end

    print("✅ Adding default items to Equipment UI...")  

    -- **Weapons**
    self:AddItem({
        name = "Sword of Orman",
        quality = "Heroic",
        category = "Main Hand",
        subtype = "Sword",
        icon = "Interface\\Icons\\INV_Sword_04",
        damageDice = "1d10",
        damageModifier = "meleeBonus",
        damageMin = "1", damageMax = "10",
        handedness = "One-Handed",
        actionType = "Action",
        effects = { STR = 3, holyCrit = 5, meleeHit = 2, fireResistMit = 5, fireResistMod = 2 },
        equipEffects = { "Equip: Increases attack speed by 10%" },
        gemSockets = "Red, Red, Red",
        socketBonus = "+1 Melee Attack Power",
        enchant = "Fiery Weapon",
        flavorText = "Forged in the flames of battle."
    })

    self:AddItem({
        name = "Dragon Slayer Axe",
        version = "Mythic",
        quality = "Legendary",
        category = "Off Hand",
        subtype = "Axe",
        icon = "Interface\\Icons\\INV_Axe_06",
        damageDice = "2d6",
        damageModifier = "meleeBonus",
        handedness = "Two-Handed",
        actionType = "Action",
        effects = { STR = 5, meleeHit = 3, meleeCrit = 2 },
        equipEffects = { "Equip: Increases damage against dragons by 15%" },
        enchant = "Crusader",
        flavorText = "Axe of the last Dragonlord."
    })

    -- **Armor**
    self:AddItem({
        name = "Plate of the Fallen King",
        version = "Mythic",
        quality = "Legendary",
        category = "Chest",
        subtype = "Plate",
        armorValue = 500, -- ✅ NEW: Armor value
        icon = "Interface\\Icons\\INV_Chest_Plate06",
        effects = { CON = 5, fireResistMit = 8, blockBonus = 4, maxHealth = 10 },
        equipEffects = { "Equip: Reduces damage taken by 5%" },
        gemSockets = "Red",
        flavorText = "Worn by the last king before the cataclysm."
    })

    self:AddItem({
        name = "Enchanted Robes",
        version = "Heroic",
        quality = "Epic",
        category = "Chest",
        subtype = "Cloth",
        armorValue = 100, -- ✅ NEW: Armor value
        icon = "Interface\\Icons\\INV_Chest_Cloth_38",
        effects = { INT = 5, spellHit = 2, fireBonus = 1 },
        equipEffects = { "Equip: Restores 2 mana per second" },
        flavorText = "Imbued with arcane energy from another realm."
    })

    -- **Shields**
    self:AddItem({
        name = "Aegis of the Guardian",
        version = "Legendary",
        quality = "Epic",
        category = "Shield",
        subtype = "Shield",
        icon = "Interface\\Icons\\INV_Shield_06",
        deflectionValue = 250, -- ✅ NEW: Deflection value
        effects = { blockBonus = 6, fireResistMit = 5 },
        equipEffects = { "Equip: Reflects 10% of melee damage taken." },
        gemSockets = "Red",
        flavorText = "A shield carried by the immortal guardians."
    })

    -- **Trinkets**
    self:AddItem({
        name = "Orb of Infinite Knowledge",
        version = "Epic",
        quality = "Rare",
        category = "Trinket",
        icon = "Interface\\Icons\\INV_Misc_Orb_04",
        effects = { INT = 6, spellCrit = 3 },
        equipEffects = { "Equip: Increases mana pool by 10%" },
        flavorText = "Contains the wisdom of a thousand scholars."
    })

    -- **Class Items**
    self:AddItem({
        name = "Libram of Holy Light",
        version = "Heroic",
        quality = "Rare",
        category = "Class Item",
        subtype = "Libram",
        icon = "Interface\\Icons\\INV_Relics_LibramofTruth",
        effects = { healBonus = 5, holyResistMit = 3 },
        equipEffects = { "Equip: Healing spells restore 5% more health." },
        flavorText = "A sacred text carried by the devoted."
    })

    print("✅ Default items successfully added.")
end

-- ✅ Function to Create the Equipment UI
function Equipment:Create(parentFrame)
    self.frame = CreateFrame("Frame", "EquipmentTabFrame", parentFrame)
    self.frame:SetSize(360, 500)
    self.frame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 7, -10)

    local SLOT_SIZE, SLOT_PADDING, COLUMNS, ROWS = 64, -16, 7, 8
    local TOTAL_SLOTS = COLUMNS * ROWS
    local startX, startY = 10, -60

    -- Create Slots
    for i = 1, TOTAL_SLOTS do
        local slot = CreateFrame("Button", "EquipmentSlot" .. i, self.frame)
        slot:SetSize(SLOT_SIZE, SLOT_SIZE)

        local row, col = math.floor((i - 1) / COLUMNS), (i - 1) % COLUMNS
        slot:SetPoint("TOPLEFT", self.frame, "TOPLEFT", startX + (col * (SLOT_SIZE + SLOT_PADDING)), startY - (row * (SLOT_SIZE + SLOT_PADDING)))

        slot.texture = slot:CreateTexture(nil, "BACKGROUND")
        slot.texture:SetAllPoints(slot)
        slot.texture:SetTexture("Interface\\Buttons\\UI-EmptySlot")

        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetSize(SLOT_SIZE - 32, SLOT_SIZE - 32)
        slot.icon:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        slot.icon:Hide()

        slot.item = nil  

        -- ✅ Click Handlers for Left & Right Clicks
        slot:SetScript("OnMouseDown", function(_, button)
            if button == "RightButton" then
                -- If right-clicked item is already equipped, unequip it
                if slot.item and slot.item.equipped then
                    Equipment:UnequipItem(slot.item, i)
                else
                    Equipment:EquipItem(slot.item, i)
                end
            elseif button == "LeftButton" then
                if slot.item then
                    Equipment:UseWeapon(slot)
                end
            end
        end)

        -- Tooltip Handling
        slot:SetScript("OnEnter", function(self)
            if self.item then Equipment:ShowTooltip(self) end
        end)

        slot:SetScript("OnLeave", function() Equipment:HideTooltip() end)

        _G.slots[i] = slot
    end

    self.frame:Hide()
end

-- ✅ Function to Use Weapon (Roll Damage)
function Equipment:UseWeapon(slot)
    local item = slot.item
    if not item then return end

    local weaponName = item.name or "Unknown Weapon"
    local damageDice = item.damageDice or "1d6"
    local damageRoll = Dice.Roll(damageDice)

    print("You attack with " .. weaponName .. " and roll " .. damageRoll .. " damage!")

    -- Send roll to chat using Dice utility
    Dice.SendRollMessage(UnitName("player"), "Weapon Attack", damageDice, 0, damageRoll)
end

function Equipment:EquipItem(item, slotIndex)
    -- If item is already equipped in the same slot, unequip it
    if self.equippedItems[item.category] and self.equippedItems[item.category].guid == item.guid then
        -- Unequip the item
        self:UnequipItem(item, slotIndex)
        print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t ✅ Unequipped: " .. item.name .. " from slot " .. slotIndex)
        return
    end

    -- If the slot is already occupied by another item, print a warning
    if self.equippedItems[item.category] then
        print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t " .. item.category .. " slot is already occupied!")
        return
    end

    -- Store Equipped Item
    self.equippedItems[item.category] = item
    item.equipped = true

    -- Add GUID to the equipped list
    table.insert(_G.equippedItemGUIDs, item.guid)
    print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Equipped:", item.name, "in", item.category, "GUID:", item.guid)

    -- Apply Item Effects
    Equipment:ApplyItemEffects(item, true)

    -- Add the visual indicator to show the item is equipped
    local slot = _G.slots[slotIndex]
    if slot and slot.icon then
        print("Slot Index: " .. slotIndex)  -- Debug: Print the slot index
        print("Slot Exists: " .. tostring(slot))  -- Debug: Verify if the slot is correctly retrieved

        -- Ensure no desaturation (we're keeping the item fully colored)
        slot.icon:SetDesaturated(false)
        slot.icon:SetAlpha(1)  -- Ensure full opacity

        -- Add the glow effect if it hasn't been added already
        if not slot.glow then
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
        end
        if slot.glow then
            slot.glow:Show()
        end
    end

    _G.RefreshActionBar()
end

function Equipment:LoadEquippedItems()
    -- Check if the equipped GUIDs were saved in the profile
    if not _G.equippedItemGUIDs or #_G.equippedItemGUIDs == 0 then
        print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t No equipped items to load.")
        return
    end

    print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t Equipping items saved on profile... ")

    -- Loop through the equipped GUIDs and apply the glow border to the slots
    for _, guid in ipairs(_G.equippedItemGUIDs) do
        -- print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t Checking GUID: " .. guid)  -- Debugging GUIDs

        -- Find the item by GUID (assuming the item is in _G.items)
        local itemFound = false
        for _, item in ipairs(_G.items) do
            if item.guid == guid then
                itemFound = true
                -- print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t Found item with GUID: " .. guid)  -- Debugging item found

                -- Loop through the slots and find the matching item GUID
                for slotIndex, slot in ipairs(_G.slots) do
                    if slot.item and slot.item.guid == guid then
                        -- print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t Matching GUID for slot index: " .. slotIndex)  -- Debugging matching slot
                        
                        -- If the glow is not already applied, create it
                        if not slot.glow then
                            local glow = slot:CreateTexture(nil, "ARTWORK")
                            glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")  -- Correct glowing border texture
                            glow:SetBlendMode("ADD")  -- Set blend mode to make it glow
                            glow:SetWidth(slot.icon:GetWidth() * 2.2)  -- Scale the width by 120%
                            glow:SetHeight(slot.icon:GetHeight() * 2.2)  -- Scale the height by 120%
                            glow:SetPoint("CENTER", slot.icon, "CENTER")  -- Center the glow around the icon
                            glow:SetAlpha(0.8)  -- Adjust the glow intensity
                            slot.glow = glow  -- Store the glow texture
                        end
                        slot.glow:Show()  -- Ensure the glow is visible
                    end
                end
            end
        end

        if not itemFound then
            print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t Could not find item with GUID: " .. guid)  -- Debugging item not found
        end
    end
end




-- ✅ Function to Unequip an Item (Removes Effects)
function Equipment:UnequipItem(item, slotIndex)
    if not item.equipped then return end

    -- Remove GUID from the equipped list
    for i, guid in ipairs(_G.equippedItemGUIDs) do
        if guid == item.guid then
            table.remove(_G.equippedItemGUIDs, i)
            break
        end
    end

    -- Remove Equipped Item from the slot (don't delete from inventory)
    self.equippedItems[item.category] = nil
    item.equipped = false

    print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t ❌ Unequipped:", item.name, "GUID:", item.guid)

    -- Remove effects (only for equipped items)
    Equipment:ApplyItemEffects(item, false)

    -- Remove the visual indicator for the unequipped item
    local slot = _G.slots[slotIndex]
    if slot and slot.icon then
        if slot.glow then
            slot.glow:Hide()  -- Hide the glow effect
        end
    end

    _G.RefreshActionBar()
end

-- ✅ Ensure global variables are correctly referenced
local abilityMods = _G.abilityMods or {}  -- Ability score modifiers
local skillTexts = _G.skillTexts or {}    -- Skill UI references
local statFrames = _G.statFrames or {}    -- Combat stat UI references
local resistanceFrames = _G.resistanceFrames or {} -- Resistance UI references

function Equipment:ApplyItemEffects(item, apply)
    local modifier = apply and 1 or -1  -- Apply (+1) or Remove (-1)

    print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Applying item effects...")


    -- Apply changes to ability scores (stored only in _G.abilityTexts)
    for key, value in pairs(item.effects or {}) do
        if type(value) == "number" then
            local mappedKey = STAT_NAME_MAPPING[key] or key
            local adjustedValue = value * modifier

            -- Debugging: show what is being processed
            -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t DEBUG: Processing Effect →", key, "Mapped:", mappedKey, "Value:", value, "Adjusted:", adjustedValue)

            -- ✅ Update hidden stats (stored only in _G.hiddenStats)
            if _G.hiddenStatModifiers[mappedKey] then
                local currentScore = _G.hiddenStatModifiers[mappedKey] or 0
                local newScore = currentScore + adjustedValue
                _G.hiddenStatModifiers[mappedKey] = newScore  -- Update the hidden stat modifier
                -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Updated Hidden Stat Modifier:", mappedKey, "Old:", currentScore, "New:", newScore)
            end


            -- ✅ Update ability scores (stored only in _G.abilityTexts)
            if _G.abilityTexts[mappedKey] and _G.abilityTexts[mappedKey].score then
                local currentScore = tonumber(_G.abilityTexts[mappedKey].score:GetText()) or 10
                local newScore = currentScore + adjustedValue
                _G.abilityTexts[mappedKey].score:SetText(newScore)  -- Update the ability score
                -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Updated Ability Score:", mappedKey, "Old:", currentScore, "New:", newScore)
            end

            -- ✅ Check if the item is modifying a skill (and apply modifier correctly)
            if _G.skillModifiers[mappedKey] ~= nil then
                local currentSkillValue = _G.skillModifiers[mappedKey] or 0
                _G.skillModifiers[mappedKey] = currentSkillValue + adjustedValue
                -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Updated Skill Modifier:", mappedKey, "Old:", currentSkillValue, "New:", _G.skillModifiers[mappedKey])
            elseif skillToAbility[mappedKey] then
                -- ✅ If it's a skill, apply modifier to the skill based on the mapped ability
                local skillKey = mappedKey
                if _G.skillModifiers[skillKey] then
                    local currentSkillValue = _G.skillModifiers[skillKey] or 0
                    _G.skillModifiers[skillKey] = currentSkillValue + adjustedValue
                    -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Updated Skill:", skillKey, "Old:", currentSkillValue, "New:", _G.skillModifiers[skillKey])
                end
            end

            -- ✅ Update resistances (mod and mit) in _G.resistances
            if mappedKey:match("^[A-Za-z]+%.[a-z]+") then
                local statCategory, statType = mappedKey:match("([^%.]+)%.([^%.]+)")

                if statCategory and statType and _G.resistances[statCategory] then
                    local currentValue = _G.resistances[statCategory][statType] or 0
                    _G.resistances[statCategory][statType] = currentValue + adjustedValue
                end
            end

            -- ✅ Update combat stats (stored only in _G.combatStats)
            if mappedKey:match("^[A-Za-z]+%.[a-z]+") then
                local statCategory, statType = mappedKey:match("([^%.]+)%.([^%.]+)")
                
                if statCategory and statType and _G.combatStats[statCategory] then
                    local stat = _G.combatStats[statCategory][statType]
                    -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t " ..stat)

                    if stat then
                        local currentStatValue = stat or 0
                        _G.combatStats[statCategory][statType] = currentStatValue + adjustedValue
                        -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Updated Combat Stat:", mappedKey, "Old:", currentStatValue, "New:", _G.combatStats[statCategory][statType])
                    end
                end
            end
        end
    end

    -- Apply armor and deflection values directly to the hidden stat modifiers
    if item.armorValue then
        -- Apply armor value to the hidden stat modifier for Armor
        _G.hiddenStatModifiers["Armor"] = (_G.hiddenStatModifiers["Armor"] or 0) + (item.armorValue * modifier)
        --print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Updated Armor Modifier:", _G.hiddenStatModifiers["Armor"])
    end

    if item.deflectionValue then
        -- Apply deflection value to the hidden stat modifier for Deflection
        _G.hiddenStatModifiers["Deflection"] = (_G.hiddenStatModifiers["Deflection"] or 0) + (item.deflectionValue * modifier)
        --print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Updated Deflection Modifier:", _G.hiddenStatModifiers["Deflection"])
    end

    -- ✅ Trigger the UI refresh after modifying stored values
    -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t UI Refresh Triggered!")
    UpdateAbilityScores()  -- Let CharacterSheet.lua handle the UI update
    UpdateCombatStats()
    UpdateResistances()
    UpdateSkillModifiers()  -- Let CharacterSheet.lua handle the skill modifier update
    UpdateHiddenStats()

    -- ✅ Save the updated values
    SaveCharacterProfile()

    print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t FINISHED Applying item effects...")
end


-- ✅ Function to Show Weapon Tooltip
function Equipment:ShowTooltip(slot)
    local item = slot.item
    if not item then return end  

    GameTooltip:SetOwner(slot, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    -- ✅ Item Quality Colors
    local qualityColors = {
        ["Poor"] = "|cff9d9d9d",
        ["Common"] = "|cffffffff",
        ["Uncommon"] = "|cff1eff00",
        ["Rare"] = "|cff0070dd",
        ["Epic"] = "|cffa335ee",
        ["Legendary"] = "|cffff8000",
    }
    local color = qualityColors[item.quality] or "|cffffffff"

    -- ✅ Item Name with Quality Color
    GameTooltip:AddLine(color .. item.name .. "|r")

    if item.version then
        GameTooltip:AddLine("|cffffff00" .. item.version .. "|r", 1, 1, 1, true)
    end

    -- ✅ Weapon Type & Damage Range
    if item.category == "Main Hand" or item.category == "Off Hand" then
        local minDamage, maxDamage = 1, 1  -- Default values if parsing fails
        if item.damageDice then
            local num, sides = item.damageDice:match("(%d+)d(%d+)")
            num, sides = tonumber(num), tonumber(sides)
            if num and sides then
                minDamage = num
                maxDamage = num * sides
            end
        end
        local damageText = string.format("%d - %d damage", minDamage, maxDamage)

        if item.category == "Main Hand" then
            GameTooltip:AddDoubleLine(item.handedness or "Main Hand", item.weaponType or "Weapon", 1, 1, 1, 1, 1, 1)
        else
            GameTooltip:AddDoubleLine("Off Hand", item.weaponType or "Weapon", 1, 1, 1, 1, 1, 1)
        end
        GameTooltip:AddDoubleLine(damageText, item.actionType or "Action", 1, 1, 1, 1, 1, 1)
    elseif item.category == "Chest" then
        GameTooltip:AddDoubleLine("Chest", item.armorType or "Cloth", 1, 1, 1, 1, 1, 1)
        if item.armorValue then
            GameTooltip:AddLine("|cffffffff" .. item.armorValue .. " Armor|r")
        end
    -- ✅ Deflection Value Display for Shields
    elseif item.category == "Shield" then
        GameTooltip:AddDoubleLine("Off-hand", "Shield", 1, 1, 1, 1, 1, 1)
        if item.deflectionValue then
            GameTooltip:AddLine("|cffffffff" .. item.deflectionValue .. " Deflection|r")
        end
    elseif item.category == "Class Item" then
        GameTooltip:AddLine(item.classItemType or "Class Item", 1, 1, 1)
    elseif item.category == "Trinket" then
        GameTooltip:AddLine("Trinket", 1, 1, 1)
    end

    -- ✅ Stats (Formatted)
    if item.effects and next(item.effects) then
        local abilityScores = {}
        local otherStats = {}

        -- Separate ability scores and other stats
        for stat, value in pairs(item.effects) do
            if stat == "STR" or stat == "DEX" or stat == "CON" or stat == "INT" or stat == "WIS" or stat == "CHA" then
                table.insert(abilityScores, { stat = stat, value = value })
            else
                table.insert(otherStats, { stat = stat, value = value })
            end
        end

        -- Sort other stats in descending order by value
        table.sort(otherStats, function(a, b) return a.value > b.value end)

        -- Display Ability Scores first (in white)
        for _, entry in ipairs(abilityScores) do
            local statName = STAT_TOOLTIP_MAP[entry.stat] or entry.stat
            GameTooltip:AddLine("|cffffffff+" .. entry.value .. " " .. statName .. "|r")
        end

        -- Display other stats (in green)
        for _, entry in ipairs(otherStats) do
            local statName = STAT_TOOLTIP_MAP[entry.stat] or entry.stat
            GameTooltip:AddLine("|cff1eff00+" .. entry.value .. " " .. statName .. "|r")
        end
    end


    -- ✅ Equip Effects (Green text without subheading)
    if item.equipEffects and #item.equipEffects > 0 then
        GameTooltip:AddLine(" ") -- Add spacing before listing
        for _, effect in ipairs(item.equipEffects) do
            GameTooltip:AddLine("|cff1eff00" .. effect .. "|r") -- Green text effect
        end
    end


    -- ✅ Gem Socket Display (Like WoW Tooltip)
    if item.gemSockets and item.gemSockets ~= "" then
        GameTooltip:AddLine(" ") -- Add spacing before listing sockets

        -- Define socket colors and icons
        local socketIcons = {
            ["Red"] = "|TInterface\\ItemSocketingFrame\\UI-EmptySocket-Red:16|t",
            ["Yellow"] = "|TInterface\\ItemSocketingFrame\\UI-EmptySocket-Yellow:16|t",
            ["Blue"] = "|TInterface\\ItemSocketingFrame\\UI-EmptySocket-Blue:16|t",
            ["Meta"] = "|TInterface\\ItemSocketingFrame\\UI-EmptySocket-Meta:16|t"
        }

        -- Split sockets into individual entries
        for socket in string.gmatch(item.gemSockets, "([^,]+)") do
            local trimmedSocket = socket:match("^%s*(.-)%s*$") -- Trim whitespace
            local icon = socketIcons[trimmedSocket] or "|TInterface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic:16|t"
            GameTooltip:AddLine(icon .. " " .. trimmedSocket .. " Socket", 0.8, 0.8, 0.8)
        end

        -- ✅ Display Socket Bonus if applicable
        if item.socketBonus and item.socketBonus ~= "" then
            GameTooltip:AddLine("Socket Bonus: " .. item.socketBonus, 0.8, 0.8, 0.8)
        end
    end


    -- ✅ Enchantment Display (Styled Like WoW)
    if item.enchant and item.enchant ~= "" then
        GameTooltip:AddLine(" ") -- Add spacing before listing
        GameTooltip:AddLine("|A:Professions-ChatIcon-Quality-Tier3:17:18::1|a |cff1eff00Enchant: " .. item.enchant .. "|r") -- Green text effect
    end

    -- ✅ Flavor Text
    if item.flavorText and item.flavorText ~= "" then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffffd100\"" .. item.flavorText .. "\"|r", 1, 1, 1, true)    
    end

    -- ✅ Instruction to Equip
    GameTooltip:AddLine("|cff00ff00<Right-click to equip>|r", 1, 1, 1)

    GameTooltip:Show()
end

-- ✅ Function to Hide Tooltip
function Equipment:HideTooltip()
    GameTooltip:Hide()
end

-- ✅ Store Equipment globally
_G.LoadEquippedItems = LoadEquippedItems
_G.Equipment = Equipment
