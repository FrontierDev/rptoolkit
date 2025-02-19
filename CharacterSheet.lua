-- CharacterSheet.lua
local ADDON_PREFIX = "CTDICE"
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

-- ✅ Ensure Global Tables Exist Before UI Loads
_G.CharacterSheet = CharacterSheet

_G.abilityTexts = _G.abilityTexts or {}  -- Stores UI text references for ability scores
_G.abilityMods = _G.abilityMods or {}    -- Stores ability score modifiers
_G.abilityBaseScores = _G.abilityBaseScores or {} -- Stores base ability scores

_G.skillTexts = _G.skillTexts or {}       -- Stores UI elements for skill modifiers
_G.skillModifiers = _G.skillModifiers or {} 
_G.statFrames = _G.statFrames or {}       -- Stores combat stat UI references
_G.resistanceFrames = _G.resistanceFrames or {} -- Stores spell resistance UI references

-- Define hidden stats
_G.hiddenStats = _G.hiddenStats or {
    Health = 15,
    MaxHealth = 15,
    Mana = 10,
    MaxMana = 10,
    Armor = 0,
    Deflection = 0,
    Initiative = 0,
    ManaRegen = 0,
    HealthRegen = 0,
    Speed = 30,
    Concentration = 0,
    Absorption = 0
}

-- Initialize hiddenStatModifiers properly using pairs to loop through the keys
_G.hiddenStatModifiers = _G.hiddenStatModifiers or {}

for stat, _ in pairs(_G.hiddenStats) do
    _G.hiddenStatModifiers[stat] = _G.hiddenStatModifiers[stat] or 0  -- Set to 0 if it doesn't exist
end


-- Define skills grouped by ability
local skills = {
    "Athletics", "Acrobatics", "Sleight of Hand", "Stealth",
    "Arcana", "History", "Investigation", "Nature", "Religion",
    "Animal Handling", "Insight", "Medicine", "Perception", "Survival",
    "Deception", "Intimidation", "Performance", "Persuasion"
}

for _, skill in ipairs(skills) do
    _G.skillModifiers[skill] = _G.skillModifiers[skill] or 0  -- Set to 0 if it doesn't exist
end

_G.combatStats = _G.combatStats or {
    Melee = { hit = 0, bonus = 0, crit = 0 },
    Ranged = { hit = 0, bonus = 0, crit = 0 },
    Spell = { hit = 0, bonus = 0, crit = 0 },
    Fire = { bonus = 0, crit = 0 },
    Frost = { bonus = 0, crit = 0 },
    Nature = { bonus = 0, crit = 0 },
    Arcane = { bonus = 0, crit = 0 },
    Fel = { bonus = 0, crit = 0 },
    Shadow = { bonus = 0, crit = 0 },
    Holy = { bonus = 0, crit = 0 },
    Block = { bonus = 0, crit = 0},
    Dodge = { bonus = 0, crit = 0},
    Parry = { bonus = 0, crit = 0},
    Heal = { bonus = 0, crit = 0}
}


_G.resistances = _G.resistances or {
    Fire = { mod = 0, mit = 0 },
    Frost = { mod = 0, mit = 0 },
    Nature = { mod = 0, mit = 0 },
    Arcane = { mod = 0, mit = 0 },
    Fel = { mod = 0, mit = 0 },
    Shadow = { mod = 0, mit = 0 },
    Holy = { mod = 0, mit = 0 }
}

-- ✅ Ensure resistanceFrames is initialized properly
local resistances = {"Fire", "Frost", "Nature", "Arcane", "Fel", "Shadow", "Holy"}
for _, resist in ipairs(resistances) do
    _G.resistanceFrames[resist] = _G.resistanceFrames[resist] or { mod = nil, mit = nil }
end

-- ✅ Ensure statFrames is initialized properly
local combatStats = { "Melee", "Ranged", "Spell", "Dodge", "Block", "Haste", "Heal", "Parry" }
for _, stat in ipairs(combatStats) do
    _G.statFrames[stat] = _G.statFrames[stat] or { hit = nil, bonus = nil, crit = nil }
end


-- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t CharacterSheet.lua: Global tables initialized")

-- ✅ Define Ability Scores (STR, DEX, etc.) & Ensure UI Elements Exist
local abilities = {"STR", "DEX", "CON", "INT", "WIS", "CHA"}
for _, ability in ipairs(abilities) do
    _G.abilityTexts[ability] = _G.abilityTexts[ability] or { score = nil, mod = nil }
    _G.abilityMods[ability] = _G.abilityMods[ability] or 0
    _G.abilityBaseScores[ability] = _G.abilityBaseScores[ability] or 10
end

-- ✅ Load Saved Character Data
local storedScores, storedProficiencies = LoadCharacterProfile()
if not storedScores then
    storedScores = { STR = 10, DEX = 10, CON = 10, INT = 10, WIS = 10, CHA = 10 }
end

for ability, texts in pairs(_G.abilityTexts) do
    if texts.score then
        texts.score:SetText(storedScores[ability])
        -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Ability Loaded:", ability, "→", storedScores[ability])
    else
        -- print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t ERROR: abilityTexts["..ability.."].score is NIL. Check UI initialization.")
    end
end

_G.playerProficiencies = storedProficiencies or {}
_G.maxProficiencies = 4
_G.availableProficiencies = _G.maxProficiencies - (table.getn(_G.playerProficiencies) or 0)

-- ✅ Debugging Output
-- print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t Loaded Available Proficiencies:", _G.availableProficiencies)


-- ✅ Assign Global Update Functions (Used in Equipment.lua & Other Scripts)
_G.UpdateSkillModifiers = UpdateSkillModifiers
_G.UpdateProficiencyIndicators = UpdateProficiencyIndicators
_G.UpdateAbilityScores = UpdateAbilityScores
_G.UpdateCombatStats = UpdateCombatStats
_G.UpdateResistances = UpdateResistances

-- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t CharacterSheet.lua: Initialization complete.")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Create the window --
local CharacterSheet = CreateFrame("Frame", "CharacterSheetFrame", UIParent)
CharacterSheet:SetSize(400, 550)
CharacterSheet:SetPoint("CENTER")
CharacterSheet:SetMovable(true)
CharacterSheet:EnableMouse(true)
CharacterSheet:RegisterForDrag("LeftButton")
CharacterSheet:SetScript("OnDragStart", CharacterSheet.StartMoving)
CharacterSheet:SetScript("OnDragStop", CharacterSheet.StopMovingOrSizing)
CharacterSheet:Hide()

-- Initialise the other tabs.
if EquipmentTab then
    -- Ensure the tab is initialized when the script runs
    EquipmentTab:Create(CharacterSheet.TabFrames[2])  
    CharacterSheet.EquipmentTab = EquipmentTab

    -- Force the frame to be hidden initially
    CharacterSheet.EquipmentTab.frame:Hide()
end

-- Initialise the other tabs.
if SpellbookTab then
    -- Ensure the tab is initialized when the script runs
    SpellbookTab:Create(CharacterSheet.TabFrames[2])  
    CharacterSheet.SpellbookTab = SpellbookTab

    -- Force the frame to be hidden initially
    CharacterSheet.SpellbookTab.frame:Hide()
end


local bg = CharacterSheet:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(CharacterSheet)
bg:SetColorTexture(0, 0, 0, 0.8)

-- ✅ Add a Border around the Character Sheet
local border = CreateFrame("Frame", nil, CharacterSheet, "BackdropTemplate")
border:SetPoint("TOPLEFT", -5, 5)
border:SetPoint("BOTTOMRIGHT", 5, -5)
border:SetBackdrop({
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 16,
})

-- ✅ Function to Create an Icon-Based Vertical Tab
local function CreateTab(parent, index, texturePath, tooltipText)
    local tab = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    tab:SetSize(40, 40)  -- Make it a square button
    tab:SetNormalTexture(texturePath)  -- Set the tab icon

    -- Position Tabs Vertically on the Right Side
    if index == 1 then
        tab:SetPoint("TOPLEFT", parent, "TOPRIGHT", 5, -30)  -- Tabs outside the window
    else
        tab:SetPoint("TOP", parent.Tabs[index - 1], "BOTTOM", 0, -5)
    end


    -- Add Tooltip on Mouseover
    tab:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(tooltipText, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    tab:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return tab
end

-- ✅ Create Blizzard-Style Vertical Tabs with Icons
local tabData = {
    {icon = "Interface\\Icons\\ui_promotion_characterboost", tooltip = "Statistics"},
    {icon = "Interface\\Icons\\INV_Chest_Chain", tooltip = "Equipment"},
    {icon = "Interface\\Icons\\INV_Misc_Book_09", tooltip = "Spellbook"},
    {icon = "Interface\\Icons\\INV_Potion_93", tooltip = "Consumables"},
    {icon = "Interface\\Icons\\INV_Misc_Bag_10_Blue", tooltip = "Inventory"}
}

CharacterSheet.Tabs = {}
CharacterSheet.TabFrames = {}

for i, data in ipairs(tabData) do
    -- Create the tab with an icon
    CharacterSheet.Tabs[i] = CreateTab(CharacterSheet, i, data.icon, data.tooltip)

    -- Create the corresponding content frame
    CharacterSheet.TabFrames[i] = CreateFrame("Frame", nil, CharacterSheet)
    CharacterSheet.TabFrames[i]:SetSize(380, 540)
    CharacterSheet.TabFrames[i]:SetPoint("TOP", CharacterSheet, "TOP", 0, -10)
    CharacterSheet.TabFrames[i]:Hide()
end

-- ✅ Ensure the first tab (Statistics) is visible by default
CharacterSheet.TabFrames[1]:Show()


-- ✅ Function to Switch Tabs with Icon-Based Highlighting
local function SwitchTab(tabIndex)
    for i, frame in ipairs(CharacterSheet.TabFrames) do
        frame:Hide()
    end

    CharacterSheet.TabFrames[tabIndex]:Show()

    -- Highlight the selected tab
    for i, tab in ipairs(CharacterSheet.Tabs) do
        if i == tabIndex then
            tab:GetNormalTexture():SetVertexColor(1, 1, 1)  -- Brighten active tab
        else
            tab:GetNormalTexture():SetVertexColor(0.6, 0.6, 0.6)  -- Dim inactive tabs
        end
    end

    -- ✅ Show Equipment UI if Equipment Tab is clicked
    if tabIndex == 2 and CharacterSheet.EquipmentTab then
        CharacterSheet.EquipmentTab.frame:Show()
        --print("✅ Equipment Tab is now visible!") -- Debug message
    else
        if CharacterSheet.EquipmentTab then
            CharacterSheet.EquipmentTab.frame:Hide()
        end
    end

    -- ✅ Show Equipment UI if Equipment Tab is clicked
    if tabIndex == 3 and CharacterSheet.SpellbookTab then
        CharacterSheet.SpellbookTab.frame:Show()
        --print("✅ Spellbook Tab is now visible!") -- Debug message
    else
        if CharacterSheet.SpellbookTab then
            CharacterSheet.SpellbookTab.frame:Hide()
        end
    end
end


-- ✅ Register Click Events for Tabs
for i, tab in ipairs(CharacterSheet.Tabs) do
    tab:SetScript("OnClick", function() SwitchTab(i) end)
end


CharacterSheet:HookScript("OnShow", function()
    SwitchTab(1) -- ✅ Default to Statistics tab
end)


-- Character portrait, name and guild.
local portrait = CharacterSheet:CreateTexture(nil, "ARTWORK")
portrait:SetSize(64, 64)
portrait:SetPoint("TOPLEFT", 10, -10)
portrait:SetTexCoord(0.05, 0.95, 0.05, 0.95)
portrait:SetTexture("Interface\TargetingFrame\UI-Player-portrait")

local nameText = CharacterSheet:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
nameText:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 10, -10)

local guildText = CharacterSheet:CreateFontString(nil, "OVERLAY", "GameFontNormal")
guildText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -5)

targetCloseButton = CreateFrame("Button", nil, CharacterSheet, "UIPanelCloseButton")
targetCloseButton:SetPoint("TOPRIGHT", CharacterSheet, "TOPRIGHT", -5, -5)
targetCloseButton:SetScript("OnClick", function()
    SaveCharacterProfile() -- Save before closing
    CharacterSheet:Hide()
end)

local closeButtonSize = targetCloseButton:GetWidth()  -- Get the close button's size

-- ✅ Create the Randomize Button with a Dice Icon 🎲
local randomizeButton = CreateFrame("Button", nil, CharacterSheet, "UIPanelButtonTemplate")
randomizeButton:SetSize(closeButtonSize, closeButtonSize)
randomizeButton:SetPoint("RIGHT", targetCloseButton, "LEFT", 23, 30)  -- Position left of close button

local diceIcon = randomizeButton:CreateTexture(nil, "ARTWORK")
diceIcon:SetSize(closeButtonSize - 6, closeButtonSize - 6)  -- Adjust icon size for padding
diceIcon:SetPoint("CENTER", randomizeButton, "CENTER", 0, 0)
diceIcon:SetTexture("Interface\\Icons\\inv_misc_dice_02")  -- 🎲 Dice Icon

randomizeButton:SetScript("OnClick", function()
    print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t Randomizing Ability Scores...")

    -- Define the rolling function (4d6, drop lowest)
    local function RollAbilityScore()
        local rolls = {math.random(1,6), math.random(1,6), math.random(1,6), math.random(1,6)}
        table.sort(rolls)
        return rolls[2] + rolls[3] + rolls[4]  -- Drop lowest roll
    end

    -- Assign new random scores
    for _, ability in ipairs({"STR", "DEX", "CON", "INT", "WIS", "CHA"}) do
        local newScore = RollAbilityScore()
        _G.abilityTexts[ability].score:SetText(newScore)
        _G.abilityTexts[ability].mod:SetText(math.floor((newScore - 10) / 2))
        -- print("→", ability, "rolled:", newScore)
    end

    -- ✅ Save the new ability scores
    SaveCharacterProfile()

    -- ✅ Update All Statistics
    UpdateAbilityScores()
    UpdateSkillModifiers()
    UpdateCombatStats()
    UpdateResistances()
    UpdateProficiencyIndicators()
    UpdateHiddenStats()

    -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t All statistics updated!")
end)

-- ✅ Create the Reset Button with a Reset Icon 🔄
local resetButton = CreateFrame("Button", "ResetProfileButton", CharacterSheet, "UIPanelButtonTemplate")
resetButton:SetSize(closeButtonSize, closeButtonSize)
resetButton:SetPoint("RIGHT", randomizeButton, "LEFT", -5, 0)  -- Position left of the dice button

local resetIcon = resetButton:CreateTexture(nil, "ARTWORK")
resetIcon:SetSize(closeButtonSize - 6, closeButtonSize - 6)  -- Adjust icon size for padding
resetIcon:SetPoint("CENTER", resetButton, "CENTER", 0, 0)
resetIcon:SetTexture("Interface\\Icons\\spell_nature_nullifydisease")  -- 🔄 Reset Icon

-- Function to reset the profile
local function ResetProfile()
    print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t Resetting character sheet and inventory!")

    -- ✅ Reset Ability Scores
    for ability, texts in pairs(_G.abilityTexts) do
        texts.score:SetText("10")
        texts.mod:SetText("0")
    end

    -- ✅ Reset Hidden Stats with default values
    _G.hiddenStats.Health = 15
    _G.hiddenStats.MaxHealth = 15
    _G.hiddenStats.Mana = 10
    _G.hiddenStats.MaxMana = 10
    _G.hiddenStats.Armor = 0
    _G.hiddenStats.Deflection = 0
    _G.hiddenStats.Initiative = 0
    _G.hiddenStats.ManaRegen = 0
    _G.hiddenStats.HealthRegen = 0
    _G.hiddenStats.Speed = 30

    _G.hiddenStatModifiers.Health = 0
    _G.hiddenStatModifiers.MaxHealth = 0
    _G.hiddenStatModifiers.Mana = 0
    _G.hiddenStatModifiers.MaxMana = 0
    _G.hiddenStatModifiers.Armor = 0
    _G.hiddenStatModifiers.Deflection = 0
    _G.hiddenStatModifiers.Initiative = 0
    _G.hiddenStatModifiers.ManaRegen = 0
    _G.hiddenStatModifiers.HealthRegen = 0
    _G.hiddenStatModifiers.Speed = 0

    -- ✅ Reset Skill Modifiers
    for skill, _ in pairs(_G.skillModifiers) do
        _G.skillModifiers[skill] = 0
    end

    -- ✅ Reset Combat Stats
    for category, stats in pairs(_G.combatStats) do
        for statType, _ in pairs(stats) do
            _G.combatStats[category][statType] = 0
        end
    end

    -- ✅ Reset Resistances
    for resist, stats in pairs(_G.resistances) do
        stats.mod = 0
        stats.mit = 0
    end

    -- ✅ Reset Proficiencies
    _G.playerProficiencies = {}

    -- ✅ Reset Inventory & Equipped Items
    _G.items = {}
    _G.equippedItemGUIDs = {}
    print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t Inventory and equipped items have been reset!")

    UpdateAbilityScores()
    UpdateSkillModifiers()
    UpdateCombatStats()
    UpdateResistances()
    UpdateProficiencyIndicators()

    -- If the inventory is not refreshing properly:
    if Equipment and Equipment.UpdateInventoryUI then
        Equipment:UpdateInventoryUI()
    end

    if Spellbook and Spellbook.UpdateSpellbookUI then
        Spellbook:UpdateSpellbookUI()
    end


    -- ✅ Save the reset state
    SaveCharacterProfile()
end

-- Set the script for the button to reset the profile
resetButton:SetScript("OnClick", function()
    ResetProfile()
end)

-- Create a frame to hold the ability scores
local abilityFrame = CreateFrame("Frame", nil, CharacterSheet.TabFrames[1])
abilityFrame:SetSize(360, 50)
abilityFrame:SetPoint("TOP", nameText, "BOTTOM", 80, -50)

-- ✅ DEBUG OUTPUT TO CHECK INITIALIZATION
_G.abilityTexts = _G.abilityTexts or {}  -- ✅ Ensure `_G.abilityTexts` is initialized globally

local abilityTexts = {}
local abilityIcons = {
    STR = 136101,  -- Replace these with actual WoW texture IDs
    DEX = 135879,
    CON = 136112,
    INT = 135932,
    WIS = 136126,
    CHA = 413583,
}

-- ✅ Ensure abilityTexts exists BEFORE loading profiles
_G.abilityTexts = _G.abilityTexts or {}

local abilities = {"STR", "DEX", "CON", "INT", "WIS", "CHA"}

for _, ability in ipairs(abilities) do
    _G.abilityTexts[ability] = { score = nil, mod = nil } -- ✅ Initialize empty structure
end

local abilityFrame = CreateFrame("Frame", nil, CharacterSheet.TabFrames[1])
abilityFrame:SetSize(360, 50)
abilityFrame:SetPoint("TOP", nameText, "BOTTOM", 80, -50)

local abilityIcons = {
    STR = 136101, DEX = 135879, CON = 136112,
    INT = 135932, WIS = 136126, CHA = 413583
}

-- ✅ UI Creation Now Guarantees Values Exist
for i, ability in ipairs(abilities) do
    local column = CreateFrame("Frame", nil, abilityFrame)
    column:SetSize(50, 50)
    column:SetPoint("LEFT", abilityFrame, "LEFT", (i - 1) * 60, 0)

    -- Ability icon
    local icon = column:CreateTexture(nil, "BACKGROUND")
    icon:SetAllPoints(column)
    icon:SetTexture(abilityIcons[ability])
    icon:SetAlpha(0.25)

    -- Ability label
    local abilityText = column:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    abilityText:SetPoint("TOP", column, "TOP", 0, -5)
    abilityText:SetText(ability)

    -- ✅ Create Ability Score UI Elements
    local scoreText = column:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    scoreText:SetPoint("TOP", abilityText, "BOTTOM", 0, -2)
    scoreText:SetText("10") -- Default score

    local modText = column:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    modText:SetPoint("TOP", scoreText, "BOTTOM", 0, -1)
    modText:SetText("0") -- Default modifier

    -- ✅ Store references to scoreText & modText globally
    _G.abilityTexts[ability].score = scoreText
    _G.abilityTexts[ability].mod = modText
end

-- ✅ Ensure Ability Scores are Updated AFTER UI is Ready
function UpdateAbilityScores()
    for ability, texts in pairs(_G.abilityTexts) do
        if texts.score and texts.mod then
            -- ✅ Read directly from the UI instead of `abilityBaseScores`
            local baseScore = tonumber(texts.score:GetText()) or 10 -- the old score
            local modValue = math.floor((baseScore - 10) / 2)

            -- ✅ Update UI elements
            texts.score:SetText(baseScore)
            texts.mod:SetText(modValue)

            -- ✅ Store the modifier globally for other calculations
            _G.abilityMods[ability] = modValue

            -- print("DEBUG: Updated", ability, "-> Score:", baseScore, "Mod:", modValue)
        end
    end
end

_G.UpdateAbilityScores = UpdateAbilityScores

---- SKILLS ----
-- Create a frame to hold the skill list
local skillsFrame = CreateFrame("Frame", nil, CharacterSheet.TabFrames[1])
skillsFrame:SetSize(360, 200)
skillsFrame:SetPoint("TOP", abilityFrame, "BOTTOM", 0, -20)

-- ✅ Ensure Global Table Exists Before UI Loads
_G.skillTexts = _G.skillTexts or {}

-- Ensure each skill entry exists to avoid nil errors
for _, skill in ipairs(skills) do
    _G.skillTexts[skill] = _G.skillTexts[skill] or { modText = nil, profIndicator = nil }
end

-- Skill-to-Ability Mapping
_G.skillToAbility = {
    ["Athletics"] = "STR",
    ["Acrobatics"] = "DEX", ["Sleight of Hand"] = "DEX", ["Stealth"] = "DEX",
    ["Arcana"] = "INT", ["History"] = "INT", ["Investigation"] = "INT", 
    ["Nature"] = "INT", ["Religion"] = "INT",
    ["Animal Handling"] = "WIS", ["Insight"] = "WIS", ["Medicine"] = "WIS",
    ["Perception"] = "WIS", ["Survival"] = "WIS",
    ["Deception"] = "CHA", ["Intimidation"] = "CHA", ["Performance"] = "CHA", ["Persuasion"] = "CHA"
}

local columnWidth = 170 -- Space for two columns
local yOffset = 0
local halfPoint = math.ceil(#skills / 2)

local playerProficiencies = {} -- Stores selected proficiencies
local availableProficiencies = _G.maxProficiencies -- Remaining slots

-- ✅ Create Skill UI Elements
for i, skill in ipairs(skills) do
    local column = (i <= halfPoint) and "LEFT" or "RIGHT"
    local xOffset = (i <= halfPoint) and 10 or columnWidth + 10
    local rowOffset = ((i - 1) % halfPoint) * -16

    -- Proficiency Indicator (Default Red)
    local profIndicator = skillsFrame:CreateTexture(nil, "ARTWORK")
    profIndicator:SetSize(12, 12)
    profIndicator:SetPoint("TOPLEFT", skillsFrame, "TOPLEFT", xOffset, rowOffset + 2)
    profIndicator:SetTexture("Interface\\COMMON\\Indicator-Red") -- Default to Red

    -- Skill Name (Label)
    local skillText = skillsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    skillText:SetPoint("LEFT", profIndicator, "RIGHT", 5, 0)
    skillText:SetText(skill)

    -- Skill Modifier
    local skillModText = skillsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    skillModText:SetPoint("TOPLEFT", skillsFrame, "TOPLEFT", xOffset + 130, rowOffset + 2)
    skillModText:SetText("+0") -- Default modifier

    -- ✅ Store UI References Globally
    _G.skillTexts[skill].modText = skillModText
    _G.skillTexts[skill].profIndicator = profIndicator

    -- ✅ Proficiency Toggle on Click (Indicator Only)
    profIndicator:SetScript("OnMouseDown", function()
        -- print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t DEBUG: Clicked on skill:", skill)

        if not _G.playerProficiencies then _G.playerProficiencies = {} end -- Ensure it exists

        local charKey = GetCharacterKey()
        if not _G.CampaignToolkitProfilesDB[charKey] then
            _G.CampaignToolkitProfilesDB[charKey] = { Proficiencies = {} }
        end

        -- ✅ Toggle Proficiency
        if _G.playerProficiencies[skill] then
            -- print("Removing proficiency for:", skill)
            _G.playerProficiencies[skill] = nil
            _G.CampaignToolkitProfilesDB[charKey]["Proficiencies"][skill] = nil
        elseif _G.availableProficiencies > 0 then
            -- print("Adding proficiency for:", skill)
            _G.playerProficiencies[skill] = true
            _G.CampaignToolkitProfilesDB[charKey]["Proficiencies"][skill] = true
        end

        -- ✅ Correctly Recalculate Available Proficiencies
        local count = 0
        for _ in pairs(_G.playerProficiencies) do
            count = count + 1
        end
        _G.availableProficiencies = _G.maxProficiencies - count

        -- ✅ Print Debugging Output
        -- print("Updated Available Proficiencies:", _G.availableProficiencies)

        -- ✅ Update UI and Save Data
        UpdateSkillModifiers()
        UpdateProficiencyIndicators()
        SaveCharacterProfile()
    end)

    -- ✅ Left-click on Skill Name to Roll 1d20 + Modifier
    skillText:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then
            if not Dice or not Dice.Roll then
                print("|cffff0000Error: Dice.Roll() is missing! Make sure Dice.lua is loaded first.|r")
                return
            end

            local skillname
            if skill == "Sleight of Hand" then skillname = "sleightOfHand"
            elseif skill == "Animal Handling" then skillname = "animalHandling"
            else skillname = skill:lower()
            end

            local modifier = tonumber(skillModText:GetText()) or 0
            local total = Dice.Roll("1d20", skill, skillname, false, "ALL") 
        end
    end)
end


---- PROFICIENCY MECHANICS
-- Proficiency Bonus Display
local profBonusLabel = CharacterSheet.TabFrames[1]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
profBonusLabel:SetPoint("TOPLEFT", guildText, "BOTTOMLEFT", 0, -10)
profBonusLabel:SetText("Proficiency Bonus: ")

local profBonusValue = CharacterSheet.TabFrames[1]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
profBonusValue:SetPoint("LEFT", profBonusLabel, "RIGHT", 5, 1)
profBonusValue:SetText("+2")  -- Default starting proficiency bonus

-- Proficiency Slots (Green Circles)
local profCircles = {}

for i = 1, maxProficiencies do
    local circle = CharacterSheet:CreateTexture(nil, "ARTWORK")
    circle:SetSize(10, 10)
    circle:SetPoint("LEFT", profBonusValue, "RIGHT", (i - 1) * 10 + 5, 0)
    circle:SetTexture("Interface\\COMMON\\Indicator-Green") -- Green Circle
    profCircles[i] = circle
end

---- COMBAT STATS
-- Create a frame for Combat Stats
local combatStatsFrame = CreateFrame("Frame", nil, CharacterSheet.TabFrames[1])
combatStatsFrame:SetSize(360, 150)
combatStatsFrame:SetPoint("TOP", skillsFrame, "BOTTOM", -5, 45)

-- Combat Stats Data
local combatStats = {
    {name = "Melee", icon = 132349, showHit = true, showBonus = true, bonusLabel = "+dmg"},
    {name = "Ranged", icon = 135498, showHit = true, showBonus = true, bonusLabel = "+dmg"}, 
    {name = "Spell", icon = 136096, showHit = true, showBonus = true, bonusLabel = "+dmg"}, 
    {name = "Haste", icon = 136047, showHit = true, showBonus = true, bonusLabel = "+dmg"},
    {name = "Heal", icon = 135913, showHit = false, showBonus = true, bonusLabel = "Bonus"}, 
    {name = "Dodge", icon = 132293, showHit = false, showBonus = true, bonusLabel = "Bonus"}, 
    {name = "Parry", icon = 132269, showHit = false, showBonus = true, bonusLabel = "Bonus"}, 
    {name = "Block", icon = 132110, showHit = false, showBonus = true, bonusLabel = "Bonus"}
}

-- ✅ Ensure `_G.statFrames` is initialized properly
for _, stat in ipairs(combatStats) do
    _G.statFrames[stat.name] = _G.statFrames[stat.name] or { hit = nil, bonus = nil, crit = nil }
end

for i, stat in ipairs(combatStats) do
    local column = (i <= 4) and "LEFT" or "RIGHT"
    local xOffset = (i <= 4) and 10 or 190
    local rowOffset = ((i - 1) % 4) * -35

    -- Create Frame for Each Stat
    local statFrame = CreateFrame("Frame", nil, combatStatsFrame)
    statFrame:SetSize(170, 40)
    statFrame:SetPoint("TOPLEFT", combatStatsFrame, "TOPLEFT", xOffset, rowOffset)

    -- Stat Icon
    local statIcon = statFrame:CreateTexture(nil, "ARTWORK")
    statIcon:SetSize(20, 20)
    statIcon:SetPoint("LEFT", statFrame, "LEFT", 0, 0)
    statIcon:SetTexture(stat.icon)

    -- ✅ Store the icon reference inside _G.statFrames
    _G.statFrames[stat.name].icon = statIcon

    -- Stat Name
    local statName = statFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statName:SetPoint("LEFT", statIcon, "RIGHT", 5, 0)
    statName:SetText(stat.name)

    local lastElement = statName  -- Used for alignment

    -- ✅ Store in `_G.statFrames`
    _G.statFrames[stat.name] = {}

    -- Hit (for Melee, Ranged, Spell, Haste)
    if stat.showHit then
        local hitLabel = statFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hitLabel:SetPoint("LEFT", statIcon, "RIGHT", 60, 7)
        hitLabel:SetText("Hit")

        local hitValue = statFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hitValue:SetPoint("TOP", hitLabel, "BOTTOM", 0, -2)
        hitValue:SetText("0")

        lastElement = hitLabel  -- Align the next elements properly

        _G.statFrames[stat.name].hit = hitValue
    end

    -- Bonus / +dmg
    if stat.showBonus then
        local bonusLabel = statFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

        -- Ensure no gap for Heal, Dodge, Parry, Block
        local labelOffset = 85
        if (stat.name == "Heal" or stat.name == "Dodge" or stat.name == "Parry" or stat.name == "Block") then
            labelOffset = 60
        end

        bonusLabel:SetPoint("LEFT", statIcon, "RIGHT", labelOffset, 7)
        bonusLabel:SetText(stat.bonusLabel)

        local bonusValue = statFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bonusValue:SetPoint("TOP", bonusLabel, "BOTTOM", 0, -2)
        bonusValue:SetText("0")

        lastElement = bonusLabel  -- Align the next elements properly

        _G.statFrames[stat.name].bonus = bonusValue

        -- ✅ Attach Tooltip for Spell Bonus
        if stat.name == "Spell" then
            bonusValue:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine("Spell Bonus Damage", 1, 0.82, 0)
                GameTooltip:AddLine(" ")

                -- Define spell schools with their respective resistance icons
                local spellSchools = {
                    { name = "Fire", icon = 135807 },
                    { name = "Frost", icon = 135848 },
                    { name = "Nature", icon = 136006 },
                    { name = "Arcane", icon = 136096 },
                    { name = "Fel", icon = 135799 },
                    { name = "Shadow", icon = 136123 },
                    { name = "Holy", icon = 135920 },
                }

                -- Loop through spell schools and display bonus damage
                for _, school in ipairs(spellSchools) do
                    local stats = _G.combatStats[school.name] or { bonus = 0 } -- Ensure defaults

                    GameTooltip:AddDoubleLine(
                        string.format("|T%d:16|t %-8s", school.icon, school.name),  -- Icon + Name
                        string.format("|cffffffff+%-4d|r", stats.bonus),  -- Bonus Damage
                        1, 1, 1, 0, 1, 0
                    )
                end

                GameTooltip:Show()
            end)

            bonusValue:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end
    end


    -- Crit (Always shown)
    local labelOffset = 125
    if (stat.name == "Heal" or stat.name == "Dodge" or stat.name == "Parry" or stat.name == "Block") then
        labelOffset = 100
    end

    local critLabel = statFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    critLabel:SetPoint("LEFT", statIcon, "RIGHT", labelOffset, 7)
    critLabel:SetText("Crit")

    local critValue = statFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    critValue:SetPoint("TOP", critLabel, "BOTTOM", 0, -2)
    critValue:SetText("20")

    _G.statFrames[stat.name].crit = critValue

    -- ✅ Attach Tooltip for Spell Crit with Corrected Threshold Calculation
    if stat.name == "Spell" then
        critValue:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("Spell Crit Thresholds", 1, 0.82, 0)
            GameTooltip:AddLine(" ")

            -- Get the base Spell.crit value
            local baseSpellCrit = _G.combatStats["Spell"].crit or 0

            -- Define spell schools with their respective resistance icons
            local spellSchools = {
                { name = "Fire", icon = 135807 },
                { name = "Frost", icon = 135848 },
                { name = "Nature", icon = 136006 },
                { name = "Arcane", icon = 136096 },
                { name = "Fel", icon = 135799 },
                { name = "Shadow", icon = 136123 },
                { name = "Holy", icon = 135920 },
            }

            -- Loop through spell schools and display adjusted crit thresholds
            for _, school in ipairs(spellSchools) do
                local stats = _G.combatStats[school.name] or { crit = 0 } -- Ensure defaults
                local critThreshold = 20 - stats.crit - baseSpellCrit -- Corrected threshold calculation

                GameTooltip:AddDoubleLine(
                    string.format("|T%d:16|t %-8s", school.icon, school.name),  -- Icon + Name
                    string.format("|cffffffff%-4d|r", critThreshold), -- Corrected Crit Threshold
                    1, 1, 1, 1, 0, 0
                )
            end

            GameTooltip:Show()
        end)

        critValue:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
end

---- SPELL RESISTANCES
-- Spell Resistances Data
local spellResistances = {
    {name = "Fire", icon = 135807},
    {name = "Frost", icon = 135848},
    {name = "Nature", icon = 136006},
    {name = "Arcane", icon = 136096},
    {name = "Fel", icon = 135799},
    {name = "Shadow", icon = 136123},
    {name = "Holy", icon = 135920}
}

-- ✅ Correctly Initialize `_G.resistanceFrames`
for _, resist in ipairs(spellResistances) do
    _G.resistanceFrames[resist.name] = _G.resistanceFrames[resist.name] or { mod = nil, mit = nil }
end

-- Create a frame for Spell Resistances
local resistancesFrame = CreateFrame("Frame", nil, CharacterSheet.TabFrames[1])
resistancesFrame:SetSize(360, 40)
resistancesFrame:SetPoint("TOP", combatStatsFrame, "BOTTOM", 5, -10)

local resistanceFrames = {}

for i, res in ipairs(spellResistances) do
    local column = CreateFrame("Frame", nil, resistancesFrame)
    column:SetSize(40, 40)  -- Reduced icon size
    column:SetPoint("LEFT", resistancesFrame, "LEFT", (i - 1) * 50, 0)

    -- Resistance Icon (Smaller)
    local icon = column:CreateTexture(nil, "ARTWORK")
    icon:SetSize(30, 30)  -- Reduced size
    icon:SetPoint("TOP", column, "TOP", 0, 0)
    icon:SetTexture(res.icon)

    -- Resist Modifier (Top, Below Icon)
    local resistMod = column:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resistMod:SetPoint("TOP", icon, "BOTTOM", 0, -2)
    resistMod:SetText("0") -- Default value

    -- Mitigation (Below Modifier)
    local mitigation = column:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mitigation:SetPoint("TOP", resistMod, "BOTTOM", 0, -2)
    mitigation:SetText("0") -- Default value

    -- ✅ Store UI Elements in `_G.resistanceFrames`
    _G.resistanceFrames[res.name] = {mod = resistMod, mit = mitigation}
end


-- Function to create a divider
local function CreateDivider(parent, yOffset, text)
    -- Create the divider line
    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetSize(360, 1)  -- Width of the divider
    divider:SetPoint("TOP", parent, "TOP", 0, yOffset)
    divider:SetColorTexture(1, 1, 1, 0.2)  -- White with slight transparency

    -- Create the section heading text
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOP", divider, "TOP", 0, 10)  -- Position text above the line
    header:SetText(text)

    return divider, header
end


-- Example usage:
local abilityDivider, abilityHeading = CreateDivider(CharacterSheet.TabFrames[1], -137, "Skills")
local skillDivider, skillHeading = CreateDivider(CharacterSheet.TabFrames[1], -305, "Combat Stats")
local combatDivider, combatHeading = CreateDivider(CharacterSheet.TabFrames[1], -452, "Resistances")


-- ✅ Update Combat Stats Dynamically Based on Ability Scores
function UpdateCombatStats()
    local abilityMods = _G.abilityMods or {}  -- ✅ Ensure abilityMods exist
    local combatStatMappings = {
        STR = {"Melee.bonus"},
        DEX = {"Ranged.bonus", "Dodge.bonus"},
        CON = {}, -- No direct combat impact
        INT = {"Spell.bonus"},
        WIS = {"Heal.bonus"},
        CHA = {}  -- No direct combat impact
    }

    -- Recalculate ability modifiers dynamically
    for ability, texts in pairs(_G.abilityTexts) do
        local scoreText = tonumber(texts.score:GetText()) or 10
        abilityMods[ability] = math.floor((scoreText - 10) / 2)
    end

    -- Apply ability modifiers to combat stats
    for ability, affectedStats in pairs(combatStatMappings) do
        local baseMod = abilityMods[ability] or 0
        for _, stat in ipairs(affectedStats) do
            local category, statType = stat:match("([^%.]+)%.([^%.]+)")
            if _G.combatStats[category] and _G.combatStats[category][statType] then
                _G.combatStats[category][statType] = baseMod
                -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t DEBUG: Updated Combat Stat:", category, statType, "→", baseMod)
            else
                -- print("⚠️ ERROR: No combat stat found for", category, statType)
            end
        end
    end

    -- Refresh UI
    for stat, data in pairs(_G.combatStats) do
        if _G.statFrames[stat] then
            if data.hit and _G.statFrames[stat].hit then
                _G.statFrames[stat].hit:SetText((data.hit >= 0 and "+" or "") .. data.hit)
            end
            if data.bonus and _G.statFrames[stat].bonus then
                _G.statFrames[stat].bonus:SetText((data.bonus >= 0 and "+" or "") .. data.bonus)
            end
            if data.crit and _G.statFrames[stat].crit then
                _G.statFrames[stat].crit:SetText(20 - data.crit)
            end
        else
            -- print("⚠️ ERROR: No stat frame found for", stat)
        end
    end
end




-- ✅ Resistances are already dynamically updated in this method
function UpdateResistances()
    local abilityMods = _G.abilityMods  -- Use directly updated ability modifiers

    -- Resistances mapped to abilities
    local resistanceMappings = {
        CON = {"Fire", "Frost", "Nature"},
        INT = {"Arcane", "Fel"},
        WIS = {"Shadow", "Holy"}
    }

    -- Loop through the mapped abilities to update corresponding resistances
    for ability, resistances in pairs(resistanceMappings) do
        local modValue = abilityMods[ability] or 0
        -- print("  → " .. ability .. " Modifier:", modValue)

        -- Loop through each resistance (e.g., Fire, Frost)
        for _, resist in ipairs(resistances) do
            if _G.resistanceFrames[resist] then
                -- Retrieve the updated mod and mit values from _G.resistances
                local mod = _G.resistances[resist].mod or 0
                local mit = _G.resistances[resist].mit or 0

                -- Update mod and mit based on both ability modifier and item effect
                local finalMod = mod + modValue
                local finalMit = mit + modValue

                -- Apply the final values to the UI
                _G.resistanceFrames[resist].mod:SetText((finalMod >= 0 and "+" or "") .. finalMod)
                _G.resistanceFrames[resist].mit:SetText((finalMit >= 0 and "+" or "") .. finalMit)

                -- Debugging: Print out the updated values for mod and mit
                -- print("    - Updating", resist, "Final Mod →", finalMod, "Final Mit →", finalMit)
            else
                print("    ⚠️ ERROR: Resistance frame missing for", resist)
            end
        end
    end
end



-- Add a function to update green circles for unspent proficiency points
local function UpdateProficiencyIndicators()
    -- ✅ Ensure `_G.playerProficiencies` exists
    _G.playerProficiencies = _G.playerProficiencies or {}

    -- ✅ Recalculate available proficiency points
    local count = 0
    for _ in pairs(_G.playerProficiencies) do
        count = count + 1
    end
    _G.availableProficiencies = _G.maxProficiencies - count

    -- ✅ Update skill proficiency indicators
    for skill, data in pairs(_G.skillTexts) do
        if _G.playerProficiencies[skill] then
            data.profIndicator:SetTexture("Interface\\COMMON\\Indicator-Green")
        else
            data.profIndicator:SetTexture("Interface\\COMMON\\Indicator-Red")
        end
    end

    -- ✅ Update proficiency circles
    for i, circle in ipairs(profCircles) do
        if i <= _G.availableProficiencies then
            circle:Show()
        else
            circle:Hide()
        end
    end
end

-- ✅ Update Hidden Stats based on Ability Modifiers
function UpdateHiddenStats()
    local abilityMods = _G.abilityMods  -- Use directly updated ability modifiers
    _G.hiddenStatModifiers = _G.hiddenStatModifiers or {}  -- Ensure hiddenStatModifiers exists, initializing if needed

    -- Mapping of stats to abilities
    local statMappings = {
        MaxHealth = { ability = "CON", multiplier = 3, base = 15 },  -- MaxHealth is modified by 3x Constitution
        MaxMana = { ability = "INT", multiplier = 1, base = 10 },   -- MaxMana is modified by 1x Intelligence
        Armor = { ability = "DEX", multiplier = 0.5, base = 0 },     -- Armor is modified by 0.5x Dexterity
        Initiative = { ability = "DEX", multiplier = 1, base = 0 },
        Deflection = { ability = "STR", multiplier = 0.5, base = 0 },
        ManaRegen = { ability = "WIS", multiplier = 0.25, base = 0 },
        HealthRegen = { ability = "WIS", multiplier = 0.25, base = 0 },
        Speed = { ability = "DEX", multiplier = 1, base = 0},
        Concentration = { ability = "INT", multiplier = 1, base = 0}
    }

    -- Loop through the mapped abilities to update the corresponding hidden stats
    for stat, data in pairs(statMappings) do
        local abilityModValue = abilityMods[data.ability] or 0  -- Get the ability modifier (e.g., CON, INT, DEX)
        
        -- Ensure hidden stat modifier is initialized (if it's missing, default to 0)
        local hiddenStatModifier = _G.hiddenStatModifiers[stat] or 0  -- Get the ability modifier (e.g., CON, INT, DEX)

        -- Calculate the final value by applying the base value, hidden stat modifier, and the ability modifier
        local finalValue = data.base + hiddenStatModifier + (abilityModValue * data.multiplier)

        -- Update the corresponding hidden stat
        _G.hiddenStats[stat] = finalValue
    end

    -- ✅ Clamp Health between 0 and MaxHealth
    _G.hiddenStats.Health = math.max(0, math.min(_G.hiddenStats.Health or 0, _G.hiddenStats.MaxHealth or 0))

    -- ✅ Clamp Mana between 0 and MaxMana
    _G.hiddenStats.Mana = math.max(0, math.min(_G.hiddenStats.Mana or 0, _G.hiddenStats.MaxMana or 0))

end



-- ✅ Update Skill Modifiers Based on Ability Scores
function UpdateSkillModifiers()
    local abilityMods = _G.abilityMods or {}  -- ✅ Ensure abilityMods exist
    local skillModifiers = _G.skillModifiers or {}  -- ✅ Ensure skillModifiers exist

    -- Recalculate ability modifiers dynamically
    for ability, texts in pairs(_G.abilityTexts) do
        local scoreText = tonumber(texts.score:GetText()) or 10
        abilityMods[ability] = math.floor((scoreText - 10) / 2)
    end

    local proficiencyBonus = tonumber(profBonusValue:GetText():match("%d+")) or 2

    -- ✅ Ensure skills are updated with both ability mods AND stored item effects
    for skill, ability in pairs(skillToAbility) do
        local baseMod = abilityMods[ability] or 0
        local itemBonus = skillModifiers[skill] or 0  -- Use stored item-modified value
        local finalMod = baseMod + itemBonus

        if _G.playerProficiencies[skill] then
            finalMod = finalMod + proficiencyBonus
        end

        -- ✅ Update skill modifier text
        if _G.skillTexts[skill] ~= nil then
            _G.skillTexts[skill].modText:SetText((finalMod >= 0 and "+" or "") .. finalMod)
        end

        -- print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t DEBUG: Updated Skill Modifier:", skill, "→", finalMod)
    end
end


-- ✅ Equipment Tab Integration
if _G.Equipment then
    _G.Equipment:Create(CharacterSheet.TabFrames[2])
    CharacterSheet.EquipmentTab = _G.Equipment
    -- print("✅ Equipment.lua has been successfully loaded!") -- Debug Output to Chat
else
    print("❌ Equipment.lua did not load!") -- If Equipment.lua is missing
end

-- ✅ Integrate Spellbook into CharacterSheet just like Equipment.lua
if _G.Spellbook then
    _G.Spellbook:Create(CharacterSheet.TabFrames[3])  -- Attach to Spells tab
    CharacterSheet.SpellbookTab = _G.Spellbook
    Spellbook:UpdateSpellbookUI()
    -- print("✅ Spellbook.lua has been successfully loaded!")
else
    print("❌ Spellbook.lua did not load!")
end

-- ✅ Items Tab Placeholder
local inventoryText = CharacterSheet.TabFrames[4]:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
inventoryText:SetPoint("CENTER", CharacterSheet.TabFrames[4], "CENTER", 0, 0)
inventoryText:SetText("Items Goes Here")

function CharacterSheet:Open()
    CharacterSheet:Load()

    self:Show()
end

function CharacterSheet:Load()
    SetPortraitTexture(portrait, "player")
    nameText:SetText(UnitName("player"))
    guildText:SetText(GetGuildInfo("player") or "No Guild")

    -- ✅ Get stored Ability Scores & Proficiencies
    local storedScores, storedProficiencies = LoadCharacterProfile()

    -- ✅ Apply stored Ability Scores
    for ability, texts in pairs(abilityTexts) do
        local score = storedScores and storedScores[ability] or 10
        texts.score:SetText(score)
        texts.mod:SetText(math.floor((score - 10) / 2))
        abilityMods[ability] = math.floor((score - 10) / 2)
    end

    -- ✅ Apply stored Proficiencies safely
    playerProficiencies = storedProficiencies or {}

    -- ✅ Fix available proficiency count (correctly count keys)
    local count = 0
    for _, _ in pairs(playerProficiencies) do count = count + 1 end
    availableProficiencies = maxProficiencies - count

    -- ✅ Refresh UI
    UpdateAbilityScores()
    UpdateSkillModifiers()
    UpdateCombatStats()
    UpdateResistances()
    UpdateProficiencyIndicators()
    UpdateHiddenStats()
end

-- Slash command for opening the character sheet.
SLASH_CharacterSheet1 = "/ct"
SlashCmdList["CharacterSheet"] = function()
    if CharacterSheet:IsShown() then
        CharacterSheet:Hide()
    else
        CharacterSheet:Open()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        CharacterSheet:Load()
    end
end)

_G.UpdateSkillModifiers = UpdateSkillModifiers
_G.UpdateProficiencyIndicators = UpdateProficiencyIndicators
_G.UpdateAbilityScores = UpdateAbilityScores
_G.UpdateCombatStats = UpdateCombatStats
_G.UpdateResistances = UpdateResistances
_G.UpdateHiddenStats = UpdateHiddenStats
_G.UpdateHiddenStats = UpdateHiddenStats
