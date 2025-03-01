local CharacterSetup = {}
_G.CharacterSetup = CharacterSetup

-- Tooltip Data for Ability Scores
local abilityTooltips = {
    STR = { 
        name = "Strength", 
        desc = "Strength measures bodily power, athletic training, and the extent to which you can exert raw physical force. A Strength check can model any attempt to lift, push, pull, or break something, to force your body through a space, or to otherwise apply brute force to a situation.",
        skills = "Athletics",
        combat = "Melee Attack Power, Parry Chance, Block Chance, Deflection"
    },
    DEX = { 
        name = "Dexterity", 
        desc = "Dexterity measures agility, reflexes, and balance. A Dexterity check can model any attempt to move nimbly, quickly, or quietly, or to keep from falling on tricky footing.",
        skills = "Acrobatics, Sleight of Hand, Stealth",
        combat = "Ranged Attack Power, Dodge Chance, Initiative Bonus, Armor, Movement Range"
    },
    CON = { 
        name = "Constitution", 
        desc = "Constitution measures health, stamina, and vital force. Constitution checks are uncommon, and no skills apply to Constitution checks, because the endurance this ability represents is largely passive rather than involving a specific effort on the part of a character or monster. A Constitution check can model your attempt to push beyond normal limits, however.",
        skills = "None",
        combat = "Max Health",
        resistances = "Fire, Frost, Nature"
    },
    INT = { 
        name = "Intelligence", 
        desc = "Intelligence measures mental acuity, accuracy of recall, and the ability to reason. An Intelligence check comes into play when you need to draw on logic, education, memory, or deductive reasoning.",
        skills = "Arcana, History, Investigation, Nature, Religion",
        combat = "Spell Power, Max Mana, Concentration",
        resistances = "Arcane, Fel"
    },
    WIS = { 
        name = "Wisdom", 
        desc = "Wisdom reflects how attuned you are to the world around you and represents perceptiveness and intuition. A Wisdom check might reflect an effort to read body language, understand someone’s feelings, notice things about the environment, or care for an injured person.",
        skills = "Animal Handling, Insight, Medicine, Perception, Survival",
        combat = "Healing Power, Mana Regeneration, Health Regeneration",
        resistances = "Holy, Shadow"
    },
    CHA = { 
        name = "Charisma", 
        desc = "Charisma measures your ability to interact effectively with others. It includes such factors as confidence and eloquence, and it can represent a charming or commanding personality. A Charisma check might arise when you try to influence or entertain others, when you try to make an impression or tell a convincing lie, or when you are navigating a tricky social situation.",
        skills = "Deception, Intimidation, Performance, Persuasion",
        combat = "None",
        resistances = "None"
    }
}


-- Setup Frame
local SetupFrame = CreateFrame("Frame", "SetupFrameFrame", UIParent)
SetupFrame:SetSize(400, 180)
SetupFrame:SetPoint("CENTER")
SetupFrame:SetMovable(true)
SetupFrame:EnableMouse(true)
SetupFrame:RegisterForDrag("LeftButton")
SetupFrame:SetScript("OnDragStart", SetupFrame.StartMoving)
SetupFrame:SetScript("OnDragStop", SetupFrame.StopMovingOrSizing)
SetupFrame:Hide()

local title = SetupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
title:SetPoint("TOP", SetupFrame, "TOP", 0, -10)
title:SetText("Assign Ability Scores")

-- Ability Scores to Assign
local abilityScores = {16, 15, 14, 12, 10, 8}
local stage = 1
local selectedAbilities = {}

-- Ability List
local abilities = {"STR", "DEX", "CON", "INT", "WIS", "CHA"}
local abilityButtons = {}

-- Load ability icons from CharacterSheet.lua
local abilityIcons = {
    STR = 136101,  -- Replace these with actual WoW texture IDs
    DEX = 135879,
    CON = 136112,
    INT = 135932,
    WIS = 136126,
    CHA = 413583,
}

-- Display the current assignment
local instructionText = SetupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
instructionText:SetPoint("TOP", SetupFrame, "TOP", 0, -40)
instructionText:SetText("Choose an ability score to set to " .. abilityScores[stage])

-- Apply Button (Defined BEFORE ability buttons to prevent nil reference)
local applyButton = CreateFrame("Button", nil, SetupFrame, "GameMenuButtonTemplate")
applyButton:SetSize(120, 30)
applyButton:SetPoint("BOTTOM", SetupFrame, "BOTTOM", 60, 10)
applyButton:SetText("Apply")
applyButton:Disable() -- Disabled until all scores are assigned

applyButton:SetScript("OnClick", function()
    for _, data in ipairs(selectedAbilities) do
        _G.abilityBaseScores[data.ability] = tonumber(data.score)
    end
    
    _G.UpdateAbilityScores()
    SetupFrame:Hide()

    -- Apply Racial Bonuses After Ability Assignment
    local racialAbilityBonuses = {
        ["Human"] = "Choice", -- Choose +2 and +1 in any ability
        ["Dwarf"] = { STR = 2, CON = 2 },
        ["Night Elf"] = { DEX = 2, WIS = 1 },
        ["Gnome"] = { INT = 2, DEX = 1 },
        ["Draenei"] = { WIS = 2, CHA = 1 },
        ["Worgen"] = { DEX = 2, STR = 1 },
        ["Orc"] = { STR = 2, CON = 1 },
        ["Undead"] = { CON = 2, WIS = 1 },
        ["Tauren"] = { STR = 2, CON = 1 },
        ["Troll"] = { DEX = 2, WIS = 1 },
        ["Blood Elf"] = { DEX = 2, CHA = 1 },
        ["Goblin"] = { DEX = 2, INT = 1 },
        ["Pandaren"] = "Choice", -- Choose +2 and +1 (WIS +2, STR +1 recommended)
        ["Void Elf"] = { INT = 2, DEX = 1 },
        ["Lightforged Draenei"] = { STR = 2, WIS = 1 },
        ["Highmountain Tauren"] = { CON = 2, STR = 1 },
        ["Nightborne"] = { INT = 2, CHA = 1 },
        ["Zandalari Troll"] = "Choice", -- Choose +2 and +1 (DEX +2, WIS +1 recommended)
        ["Kul Tiran"] = { CON = 2, STR = 1 },
        ["Dark Iron Dwarf"] = { CON = 2, STR = 1 },
        ["Mag'har Orc"] = { STR = 2, CON = 1 },
        ["Mechagnome"] = { INT = 2, DEX = 1 },
        ["Dracthyr"] = "Choice", -- Choose +2 and +1 (STR +2, CHA +1 recommended)
    }

    local playerRace = UnitRace("player") or "Human"

    local bonuses = racialAbilityBonuses[playerRace]
    if type(bonuses) == "table" then
        for ability, bonus in pairs(bonuses) do
            _G.abilityBaseScores[ability] = _G.abilityBaseScores[ability] + bonus
        end
        _G.UpdateAbilityScores()
    else
        ShowRacialBonusSelection() -- Call function if race has a choice
    end
end)

-- Back Button (Allows user to go back through stages)
local backButton = CreateFrame("Button", nil, SetupFrame, "GameMenuButtonTemplate")
backButton:SetSize(120, 30)
backButton:SetPoint("BOTTOM", SetupFrame, "BOTTOM", -60, 10)
backButton:SetText("Back")
backButton:Disable() -- Initially disabled

backButton:SetScript("OnClick", function()
    if stage > 1 then
        -- Move back one stage
        stage = stage - 1
        local lastSelection = selectedAbilities[stage]

        -- Re-enable the last selected ability
        if lastSelection then
            local button = abilityButtons[lastSelection.ability]
            if button then
                button.icon:SetVertexColor(1, 1, 1) -- Restore original color
                button:SetButtonState("NORMAL") -- Re-enable interaction
                button.isSelected = false
            end
            selectedAbilities[stage] = nil -- Remove the previous selection
        end

        instructionText:SetText("Choose an ability score to set to " .. abilityScores[stage])
        applyButton:Disable() -- Prevent applying until all are assigned
    end

    -- Disable back button if at the start
    if stage == 1 then
        backButton:Disable()
    end
end)

-- Create ability buttons with icons
for i, ability in ipairs(abilities) do
    local button = CreateFrame("Button", nil, SetupFrame, "UIPanelButtonTemplate")
    button:SetSize(60, 60)
    button:SetPoint("LEFT", SetupFrame, "LEFT", 10 + ((i - 1) * 65), 0)

    -- Ability Icon
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(button)
    icon:SetTexture(abilityIcons[ability])

    button.icon = icon
    button.ability = ability
    button.isSelected = false

    button:SetScript("OnEnter", function(self)
        local info = abilityTooltips[self.ability]

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("|cffffff00" .. info.name .. "|r", 1, 1, 1) -- Ability Name

        GameTooltip:AddLine(info.desc, 1, 1, 1, true) -- Description
        GameTooltip:AddLine(" ")

        -- Apply color formatting dynamically
        if info.skills and info.skills ~= "None" then
            GameTooltip:AddLine("|cff00ff00Skills Affected:|r " .. "|cffffffff" .. info.skills .. "|r", 1, 1, 1, true)
        end

        if info.combat then
            GameTooltip:AddLine("|cffff8000Combat Stats Affected:|r " .. "|cffffffff" .. info.combat .. "|r", 1, 1, 1, true)
        end

        if info.resistances then
            GameTooltip:AddLine("|cff0080ffResistances Affected:|r " .. "|cffffffff" .. info.resistances .. "|r", 1, 1, 1, true)
        end

        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnClick", function(self)
        if self.isSelected then return end -- Prevent re-selection

        -- Store the chosen ability score
        selectedAbilities[stage] = { ability = self.ability, score = abilityScores[stage] }

        -- Grey out and disable the button
        self.icon:SetVertexColor(0.5, 0.5, 0.5)
        self.isSelected = true

        -- Enable back button after the first selection
        if stage == 1 then
            backButton:Enable()
        end

        -- Move to the next stage
        stage = stage + 1
        if stage > #abilityScores then
            instructionText:SetText("Click Apply to finalize selections.")
            applyButton:Enable() -- Now `applyButton` is guaranteed to exist
        else
            instructionText:SetText("Choose an ability score to set to " .. abilityScores[stage])
        end
    end)

    abilityButtons[ability] = button
end

function ShowRacialBonusSelection()
    SetupFrame:Hide()

    local RaceBonusFrame = CreateFrame("Frame", "RaceBonusFrame", UIParent)
    RaceBonusFrame:SetSize(400, 180)
    RaceBonusFrame:SetPoint("CENTER")
    RaceBonusFrame:Show()

    local raceTitle = RaceBonusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    raceTitle:SetPoint("TOP", RaceBonusFrame, "TOP", 0, -10)
    raceTitle:SetText("Select Racial Bonuses")

    local instructionText = RaceBonusFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    instructionText:SetPoint("TOP", RaceBonusFrame, "TOP", 0, -40)
    instructionText:SetText("Choose an ability score to add +2 to")

    local selectedBonuses = {}

    -- Apply Racial Bonus Button (Define FIRST)
    local applyRacialBonusButton = CreateFrame("Button", nil, RaceBonusFrame, "GameMenuButtonTemplate")
    applyRacialBonusButton:SetSize(100, 30)
    applyRacialBonusButton:SetPoint("BOTTOM", RaceBonusFrame, "BOTTOM", 0, 10)
    applyRacialBonusButton:SetText("Apply")
    applyRacialBonusButton:Disable() -- Disabled until both selections are made

    -- Function to handle selections
    local function SelectBonus(ability, bonus)
        if not selectedBonuses[1] then
            selectedBonuses[1] = { ability = ability, bonus = 2 }
            instructionText:SetText("Choose an ability score to add +1 to")
        elseif not selectedBonuses[2] and ability ~= selectedBonuses[1].ability then
            selectedBonuses[2] = { ability = ability, bonus = 1 }
            instructionText:SetText("Click Apply to confirm racial bonuses")
            applyRacialBonusButton:Enable() -- Now button is guaranteed to exist
        end
    end

    -- Create ability buttons for racial bonus selection
    local racialAbilityButtons = {}
    for i, ability in ipairs(abilities) do
        local button = CreateFrame("Button", nil, RaceBonusFrame, "UIPanelButtonTemplate")
        button:SetSize(60, 60)
        button:SetPoint("LEFT", RaceBonusFrame, "LEFT", 10 + ((i - 1) * 65), 0)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(button)
        icon:SetTexture(abilityIcons[ability])

        button.icon = icon
        button.ability = ability
        button.isSelected = false

        button:SetScript("OnEnter", function(self)
            local info = abilityTooltips[self.ability]

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("|cffffff00" .. info.name .. "|r", 1, 1, 1) -- Ability Name

            GameTooltip:AddLine(info.desc, 1, 1, 1, true) -- Description
            GameTooltip:AddLine(" ")

            -- Apply color formatting dynamically
            if info.skills and info.skills ~= "None" then
                GameTooltip:AddLine("|cff00ff00Skills Affected:|r " .. "|cffffffff" .. info.skills .. "|r", 1, 1, 1, true)
            end

            if info.combat then
                GameTooltip:AddLine("|cffff8000Combat Stats Affected:|r " .. "|cffffffff" .. info.combat .. "|r", 1, 1, 1, true)
            end

            if info.resistances then
                GameTooltip:AddLine("|cff0080ffResistances Affected:|r " .. "|cffffffff" .. info.resistances .. "|r", 1, 1, 1, true)
            end

            GameTooltip:Show()
        end)

        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        button:SetScript("OnClick", function(self)
            if self.isSelected then return end
            SelectBonus(self.ability, 2)
            self.icon:SetVertexColor(0.5, 0.5, 0.5)
            self.isSelected = true
        end)

        racialAbilityButtons[ability] = button
    end

    applyRacialBonusButton:SetScript("OnClick", function()
        if selectedBonuses[1] and selectedBonuses[2] then
            for _, bonusData in ipairs(selectedBonuses) do
                _G.abilityBaseScores[bonusData.ability] = _G.abilityBaseScores[bonusData.ability] + bonusData.bonus
                print("    |cff00ff00[RPT] Applying racial bonus|r: +" .. bonusData.bonus .. " +" .. bonusData.ability)
            end
            _G.UpdateAbilityScores()
            RaceBonusFrame:Hide()
            SaveCharacterProfile()
        end
    end)
end



function CharacterSetup:ShowUI()
    -- Reset selections
    stage = 1
    selectedAbilities = {}
    instructionText:SetText("Choose an ability score to set to " .. abilityScores[stage])
    applyButton:Disable()
    backButton:Disable()

    -- Reset ability buttons
    for _, button in pairs(abilityButtons) do
        button.icon:SetVertexColor(1, 1, 1) -- Reset colors
        button:SetButtonState("NORMAL") -- Ensure button is re-enabled
        button.isSelected = false
    end

    SetupFrame:Show()
end

-- Function that runs only on first load
function RunFirstTimeSetup()
    -- Example: Show the character setup UI
    CharacterSetup:ShowUI()
    
    -- Example: Initialize something else for first-time users
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "RPToolkit" then  -- Change this to your addon name
        if not _G.PlayerSettingsDB then
            _G.PlayerSettingsDB = {} -- Initialize Saved Variables table if missing
        end
        
        print("|ccff00ff00 Welcome to RPToolkit (RPT)!|r |cff808080This addon is under development by Ortellus on Argent Dawn EU. Please join discord.gg/jM7Tb79R for support.|r")

        if not _G.PlayerSettingsDB.firstLoad or not _G.PlayerSettingsDB then
            _G.PlayerSettingsDB.firstLoad = true

            print("|cff00ff00[RPT] Profile Setup|r - Please follow the popup in the middle of your screen!")
            
            -- Call the function that should run on first load
            RunFirstTimeSetup()
        end
    end
end)
