-- CampaignToolkitProfiles.lua
_G.CampaignToolkitProfilesDB = _G.CampaignToolkitProfilesDB or {}

local function GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

function SaveCharacterProfile()
    local key = GetCharacterKey()

    -- Ensure the global database exists
    _G.CampaignToolkitProfilesDB = _G.CampaignToolkitProfilesDB or {}

    -- Ensure the profile exists for the current player
    _G.CampaignToolkitProfilesDB[key] = _G.CampaignToolkitProfilesDB[key] or {
        AbilityScores = {},
        HiddenStatModifiers = {},
        Proficiencies = {},
        SkillModifiers = {},
        CombatStats = {},
        Resistances = {},
        EquippedItemGUIDs = {},
        Items = {},
    }

    local profile = _G.CampaignToolkitProfilesDB[key]

    -- Save equipped item GUIDs
    profile.EquippedItemGUIDs = _G.equippedItemGUIDs  -- Save the list of equipped item GUIDs

    -- Save ability scores
    for ability, texts in pairs(_G.abilityTexts) do
        local score = tonumber(texts.score:GetText()) or 10
        profile.AbilityScores[ability] = score
    end

    -- Save skill modifiers
    for skill, modifier in pairs(_G.skillModifiers) do
        profile.SkillModifiers[skill] = modifier
    end

    -- Save combat stats
    profile.combatStats = profile.combatStats or {}
    for category, stats in pairs(_G.combatStats) do
        profile.combatStats[category] = profile.combatStats[category] or {} -- Preserve existing data
        for statType, statValue in pairs(stats) do
            profile.combatStats[category][statType] = statValue or profile.combatStats[category][statType] or 0
        end
    end

    -- Save hidden stats (ensure they are included)
    profile.HiddenStatModifiers = _G.hiddenStatModifiers or {}
    for stat, value in pairs(_G.hiddenStatModifiers) do
        profile.HiddenStatModifiers[stat] = value  -- Save hidden stats like Health, MaxHealth, etc.
    end

    -- Save resistances
    for resist, stats in pairs(_G.resistances) do
        profile.Resistances[resist] = {
            mod = stats.mod or 0,
            mit = stats.mit or 0
        }
    end

    -- Save proficiencies
    for skill, _ in pairs(_G.playerProficiencies) do
        profile.Proficiencies[skill] = true
    end

    -- ✅ Reset profile.Items before saving to prevent duplicates
    profile.Items = {}

    -- ✅ **Ensure items are saved correctly**
    print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t 🔄 Saving items to profile...")

    if not _G.items or #_G.items == 0 then
        print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t No items found in _G.items!")
    else
        for _, item in ipairs(_G.items) do
            -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Saving item: " .. item.name .. " | GUID: " .. item.guid)
            profile.Items[item.guid] = {
                guid = item.guid,
                name = item.name,
                version = item.version,  -- ✅ Ensure version is saved
                quality = item.quality,  -- ✅ Ensure quality is saved
                category = item.category,
                subtype = item.subtype,  -- ✅ Ensure subtype (e.g., Sword, Libram) is saved
                icon = item.icon,
                damageDice = item.damageDice,
                handedness = item.handedness,  -- ✅ Ensure handedness (One/Two-Handed) is saved
                actionType = item.actionType,  -- ✅ Ensure action type (Action/Bonus Action) is saved
                armorValue = item.armorValue, -- ✅ NEW
                deflectionValue = item.deflectionValue, -- ✅ NEW
                equipped = item.equipped,
                effects = item.effects or {},
                equipEffects = item.equipEffects or {},  -- ✅ Ensure equip effects are saved
                gemSockets = item.gemSockets or "",
                socketBonus = item.socketBonus or "",
                enchant = item.enchant or "",
                flavorText = item.flavorText or ""
            }
        end
    end

    _G.CampaignToolkitProfilesDB[key] = profile  -- Ensure it's saved persistently
    print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t ✅ Campaign Toolkit: Profile saved for " .. key)
end




function LoadCharacterProfile()
    local key = GetCharacterKey()

    -- ✅ Ensure `_G.CampaignToolkitProfilesDB` exists
    _G.CampaignToolkitProfilesDB = _G.CampaignToolkitProfilesDB or {}

    -- ✅ Ensure the profile exists but DO NOT OVERWRITE it if it already exists
    if not _G.CampaignToolkitProfilesDB[key] then
        _G.CampaignToolkitProfilesDB[key] = {
            AbilityScores = { STR = 10, DEX = 10, CON = 10, INT = 10, WIS = 10, CHA = 10 },
            Proficiencies = {},
            SkillModifiers = {},
            CombatStats = {},
            Resistances = {},
            EquippedItemGUIDs = {},
            Items = {},  -- Ensure Items table exists
            HiddenStatModifiers = {} -- Ensure HiddenStatModifiers table exists
        }
    end

    -- ✅ Now safely reference the profile without resetting it
    local profile = _G.CampaignToolkitProfilesDB[key]
    profile.AbilityScores = profile.AbilityScores or { STR = 10, DEX = 10, CON = 10, INT = 10, WIS = 10, CHA = 10 }
    profile.Proficiencies = profile.Proficiencies or {}
    profile.SkillModifiers = profile.SkillModifiers or {}
    profile.CombatStats = profile.CombatStats or {}
    profile.Resistances = profile.Resistances or {}
    profile.Items = profile.Items or {}
    profile.HiddenStatModifiers = profile.HiddenStatModifiers or {}

    -- ✅ Load ability scores
    for ability, texts in pairs(_G.abilityTexts) do
        if texts.score then
            local storedScore = profile.AbilityScores[ability] or 10
            texts.score:SetText(storedScore)
            texts.mod:SetText((math.floor((storedScore - 10) / 2) >= 0 and "+" or "") .. math.floor((storedScore - 10) / 2))
        end
    end

    -- Load Hidden Stat Modifiers
    _G.hiddenStatModifiers = profile.HiddenStatModifiers or {}

    -- Ensure modifiers are initialized if missing
    for stat, _ in pairs(_G.hiddenStats) do
        _G.hiddenStatModifiers[stat] = _G.hiddenStatModifiers[stat] or 0
    end

    -- ✅ Load skill modifiers
    for skill, modifier in pairs(profile.SkillModifiers) do
        _G.skillModifiers[skill] = modifier
    end

    -- ✅ Load combat stats
     for category, stats in pairs(_G.combatStats) do
        profile.CombatStats[category] = profile.CombatStats[category] or {}
        for statType, _ in pairs(stats) do
            profile.CombatStats[category][statType] = profile.CombatStats[category][statType] or _G.combatStats[category][statType] or 0
        end
    end

    for category, stats in pairs(profile.CombatStats) do
        for statType, statValue in pairs(stats) do
            _G.combatStats[category] = _G.combatStats[category] or {}
            _G.combatStats[category][statType] = statValue
        end
    end


    -- ✅ Load resistances
    for resist, stats in pairs(_G.resistances) do
        if profile.Resistances[resist] then
            _G.resistances[resist].mod = profile.Resistances[resist].mod or 0
            _G.resistances[resist].mit = profile.Resistances[resist].mit or 0
        end
    end

    -- ✅ Load proficiencies
    _G.playerProficiencies = profile.Proficiencies or {}

    -- ✅ Load Items (Ensuring items are stored the same way as AbilityScores)
    _G.items = {}

    local itemCount = 0
    for _ in pairs(profile.Items) do
        itemCount = itemCount + 1
    end

    if not profile.Items or itemCount == 0 then
        print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t No items found in saved profile!")
    else
        for guid, savedItem in pairs(profile.Items) do
            table.insert(_G.items, {
                guid = savedItem.guid,
                name = savedItem.name,
                version = savedItem.version,  -- ✅ Ensure version is restored
                quality = savedItem.quality,  -- ✅ Ensure quality is restored
                category = savedItem.category,
                subtype = savedItem.subtype,  -- ✅ Ensure subtype (e.g., Sword, Libram) is restored
                icon = savedItem.icon,
                damageDice = savedItem.damageDice,
                handedness = savedItem.handedness,  -- ✅ Ensure handedness (One/Two-Handed) is restored
                actionType = savedItem.actionType,  -- ✅ Ensure action type (Action/Bonus Action) is restored
                armorValue = savedItem.armorValue, -- ✅ NEW
                deflectionValue = savedItem.deflectionValue, -- ✅ NEW
                equipped = savedItem.equipped,
                effects = savedItem.effects or {},
                equipEffects = savedItem.equipEffects or {},  -- ✅ Ensure equip effects are restored
                gemSockets = savedItem.gemSockets or "",
                socketBonus = savedItem.socketBonus or "",
                enchant = savedItem.enchant or "",
                flavorText = savedItem.flavorText or ""
            })
            -- print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t ✅ Loaded item: " .. savedItem.name .. " | GUID: " .. guid)
        end
    end

    -- ✅ Load Equipped Items
    _G.equippedItemGUIDs = profile.EquippedItemGUIDs or {}

    -- ✅ Step 1: Remove all equipped item effects first to prevent stacking
    if _G.equippedItemGUIDs and Equipment and Equipment.ApplyItemEffects then
        for _, guid in ipairs(_G.equippedItemGUIDs) do
            for _, item in ipairs(_G.items) do
                if item.guid == guid then  -- No need to check .equipped, as it's being reset
                    -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Removing previous effects for equipped item: " .. item.name)
                    Equipment:ApplyItemEffects(item, false)  -- Remove previous effects
                end
            end
        end
    end

    -- ✅ Step 2: Load profile data (restore AbilityScores, CombatStats, etc.)
    for category, stats in pairs(profile.CombatStats) do
        for statType, statValue in pairs(stats) do
            _G.combatStats[category] = _G.combatStats[category] or {}
            _G.combatStats[category][statType] = statValue
        end
    end

    -- ✅ Step 3: Reapply effects from equipped items (after restoring the profile)
    if _G.equippedItemGUIDs and Equipment and Equipment.ApplyItemEffects then
        for _, guid in ipairs(_G.equippedItemGUIDs) do
            for _, item in ipairs(_G.items) do
                if item.guid == guid then  -- Ensure item exists before applying
                    item.equipped = true  -- ✅ Explicitly mark as equipped to avoid issues
                    -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Reapplying effects for equipped item: " .. item.name)
                    Equipment:ApplyItemEffects(item, true)  -- Correctly reapply item effects
                end
            end
        end
    end

    -- ✅ Update inventory UI after loading
    if Equipment and Equipment.UpdateInventoryUI then
        Equipment:UpdateInventoryUI()
    else
        print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t ❌ ERROR: Equipment UI update function missing!")
    end
        
    -- Select which items are already equipped.
    Equipment:LoadEquippedItems()

    -- ✅ If no items were loaded, add default items
    if not _G.items or #_G.items == 0 then
        print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t ❌ No items found in profile! Adding default items...")
        if Equipment and Equipment.AddDefaultItems then
            Equipment:AddDefaultItems()
        else
            print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t ❌ ERROR: Equipment:AddDefaultItems() function missing!")
        end
    end

    return profile.AbilityScores, profile.Proficiencies
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD") -- ✅ Ensures save on reload
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- ✅ Ensures data is available on login
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGOUT" or event == "PLAYER_LEAVING_WORLD" then
        SaveCharacterProfile()
        print("💾 Profile saved before logout/reload.")
    end
end)


_G.GetCharacterKey = GetCharacterKey




