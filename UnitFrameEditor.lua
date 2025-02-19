-- UnitFrameEditor.lua (Handles the Unit Frame Editing Window)

local ADDON_PREFIX = _G.ADDON_PREFIX or "CTUF"  -- Ensure it uses the global prefix

local UnitFrameEditor = {}
_G.UnitFrameEditor = UnitFrameEditor

-- Load Blizzard Panel Templates
local PanelTemplates = _G.PanelTemplates

-- Create Blizzard-Style Tabs
local function CreateTab(parent, index, text)
    local tab = CreateFrame("Button", nil, parent, "PanelTabButtonTemplate")
    tab:SetID(index)
    tab:SetText(text)
    tab:SetSize(80, 25)
    
    -- Position Tabs Horizontally
    if index == 1 then
        tab:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 10, 2)
    else
        tab:SetPoint("LEFT", parent.Tabs[index - 1], "RIGHT", 5, 0)
    end

    return tab
end

-- Create Editor Window
local EditorFrame = CreateFrame("Frame", "UnitFrameEditorWindow", UIParent, "BackdropTemplate")
EditorFrame:SetSize(300, 350)
EditorFrame:SetPoint("CENTER")
EditorFrame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
EditorFrame:Hide()  -- Hide initially

-- Close Button
EditorFrame.CloseButton = CreateFrame("Button", nil, EditorFrame, "UIPanelCloseButton")
EditorFrame.CloseButton:SetPoint("TOPRIGHT", EditorFrame, "TOPRIGHT", -5, -5)
EditorFrame.CloseButton:SetScript("OnClick", function()
    EditorFrame:Hide()
end)

-- Create Tabs
EditorFrame.Tabs = {}
EditorFrame.Tabs[1] = CreateTab(EditorFrame, 1, "Statistics")
EditorFrame.Tabs[2] = CreateTab(EditorFrame, 2, "Spells")
EditorFrame.Tabs[3] = CreateTab(EditorFrame, 3, "Loot")

-- Create Content Frames for Each Tab
EditorFrame.TabFrames = {}
for i = 1, 3 do
    EditorFrame.TabFrames[i] = CreateFrame("Frame", nil, EditorFrame)
    EditorFrame.TabFrames[i]:SetSize(280, 250)
    EditorFrame.TabFrames[i]:SetPoint("TOP", EditorFrame, "TOP", 0, 0)
    EditorFrame.TabFrames[i]:Hide()
end

-- Register Tabs with Blizzard's PanelTemplates
PanelTemplates_SetNumTabs(EditorFrame, 3)
PanelTemplates_SetTab(EditorFrame, 1)

-- Show Statistics Tab by Default
EditorFrame.TabFrames[1]:Show()

-- Function to Switch Tabs
local function SwitchTab(tabIndex)
    for i = 1, 3 do
        EditorFrame.TabFrames[i]:Hide()
    end
    EditorFrame.TabFrames[tabIndex]:Show()
    PanelTemplates_SetTab(EditorFrame, tabIndex)
end

-- Assign Click Handlers for Tabs
for i = 1, 3 do
    EditorFrame.Tabs[i]:SetScript("OnClick", function()
        SwitchTab(i)
    end)
end

-- Create a simple input field function
local function CreateInputField(parent, labelText, yOffset, width, numeric)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)
    label:SetText(labelText)

    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetSize(width or 150, 20)
    input:SetPoint("TOPLEFT", label, "TOPLEFT", 100, 2)
    input:SetAutoFocus(false)
    
    if numeric then
        input:SetNumeric(true)
    end

    return input
end

-- Create Ability Score Modifiers
local function CreateAbilityScoreModifiers(frame)
    local abilities = {
        {name = "STR", icon = 136101},  -- Strength
        {name = "DEX", icon = 135879},  -- Dexterity
        {name = "CON", icon = 136112},  -- Constitution
        {name = "INT", icon = 135932},  -- Intelligence
        {name = "WIS", icon = 136126},  -- Wisdom
        {name = "CHA", icon = 413583}   -- Charisma
    }

    frame.AbilityModifiers = {}

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", frame, "TOP", 0, -100)
    title:SetText("Ability Score Modifiers")

    for i, ability in ipairs(abilities) do
        local iconFrame = CreateFrame("Button", nil, frame)
        iconFrame:SetSize(32, 32)
        iconFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", (i - 1) * 50, -130)

        local abilityText = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        abilityText:SetPoint("BOTTOM", iconFrame, "TOP", 0, 2)
        abilityText:SetText(ability.name)

        local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
        iconTexture:SetAllPoints(iconFrame)
        iconTexture:SetAlpha(0.4)
        iconTexture:SetTexture(ability.icon)

        local modText = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        modText:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
        modText:SetText("+0")
        modText:SetTextColor(1, 1, 1)

        frame.AbilityModifiers[ability.name] = { frame = iconFrame, text = modText, value = 0 }

        iconFrame:SetScript("OnClick", function()
            frame.AbilityModifiers[ability.name].value = frame.AbilityModifiers[ability.name].value + 1
            modText:SetText((frame.AbilityModifiers[ability.name].value >= 0 and "+" or "") .. frame.AbilityModifiers[ability.name].value)
        end)

        iconFrame:SetScript("OnMouseDown", function(_, button)
            if button == "RightButton" then
                frame.AbilityModifiers[ability.name].value = frame.AbilityModifiers[ability.name].value - 1
                modText:SetText((frame.AbilityModifiers[ability.name].value >= 0 and "+" or "") .. frame.AbilityModifiers[ability.name].value)
            end
        end)
    end
end

-- Create Offensive Modifiers with On-Click Popup
local function CreateOffensiveModifiers(frame)
    local offensiveStats = {
        {name = "Melee", icon = 132349},  
        {name = "Ranged", icon = 135498}, 
        {name = "Spell", icon = 136096}   
    }

    frame.OffensiveModifiers = {}

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", frame, "TOP", 0, -170)
    title:SetText("Offensive Modifiers")

    -- Popup Frame for Editing Values
    local PopupFrame = CreateFrame("Frame", "OffensePopup", UIParent, "BackdropTemplate")
    PopupFrame:SetSize(200, 120)
    PopupFrame:SetPoint("TOPLEFT", EditorFrame, "TOPRIGHT", 10, 0)
    PopupFrame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    PopupFrame:Hide()

    -- Popup Title
    PopupFrame.Title = PopupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    PopupFrame.Title:SetPoint("TOP", PopupFrame, "TOP", 0, -10)

    -- Attack Bonus Input
    PopupFrame.BonusLabel = PopupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    PopupFrame.BonusLabel:SetPoint("TOPLEFT", PopupFrame, "TOPLEFT", 15, -30)
    PopupFrame.BonusLabel:SetText("Attack Bonus:")

    PopupFrame.BonusInput = CreateFrame("EditBox", nil, PopupFrame, "InputBoxTemplate")
    PopupFrame.BonusInput:SetSize(50, 20)
    PopupFrame.BonusInput:SetPoint("LEFT", PopupFrame.BonusLabel, "RIGHT", 10, 0)
    PopupFrame.BonusInput:SetAutoFocus(false)
    PopupFrame.BonusInput:SetNumeric(true)

    -- Damage Dice Input
    PopupFrame.DiceLabel = PopupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    PopupFrame.DiceLabel:SetPoint("TOPLEFT", PopupFrame.BonusLabel, "BOTTOMLEFT", 0, -15)
    PopupFrame.DiceLabel:SetText("Damage Dice:")

    PopupFrame.DiceInput = CreateFrame("EditBox", nil, PopupFrame, "InputBoxTemplate")
    PopupFrame.DiceInput:SetSize(70, 20)
    PopupFrame.DiceInput:SetPoint("LEFT", PopupFrame.DiceLabel, "RIGHT", 10, 0)
    PopupFrame.DiceInput:SetAutoFocus(false)

    -- Damage AC Input
    PopupFrame.ACLabel = PopupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    PopupFrame.ACLabel:SetPoint("TOPLEFT", PopupFrame.DiceLabel, "BOTTOMLEFT", 0, -15)
    PopupFrame.ACLabel:SetText("Hit Threshold:")

    PopupFrame.ACInput = CreateFrame("EditBox", nil, PopupFrame, "InputBoxTemplate")
    PopupFrame.ACInput:SetSize(70, 20)
    PopupFrame.ACInput:SetPoint("LEFT", PopupFrame.ACLabel, "RIGHT", 10, 0)
    PopupFrame.ACInput:SetAutoFocus(false)

    -- School Dropdown (Physical, Fire, Frost, Nature, Arcane, Fel, Holy, Shadow)
    PopupFrame.SchoolLabel = PopupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    PopupFrame.SchoolLabel:SetPoint("TOPLEFT", PopupFrame.ACLabel, "BOTTOMLEFT", 0, -15)
    PopupFrame.SchoolLabel:SetText("School:")

    PopupFrame.SchoolDropdown = CreateFrame("Frame", "SchoolDropdown", PopupFrame, "UIDropDownMenuTemplate")
    PopupFrame.SchoolDropdown:SetPoint("LEFT", PopupFrame.SchoolLabel, "RIGHT", 10, 0)
    UIDropDownMenu_SetWidth(PopupFrame.SchoolDropdown, 100)

    -- Populate dropdown with school types
    local selectedSchool
    local function SchoolDropdown_Initialize(self, level)
        local info = UIDropDownMenu_CreateInfo()
    
        local schoolTypes = {
            "Physical", "Fire", "Frost", "Nature", "Arcane", "Fel", "Holy", "Shadow"
        }

        for _, school in ipairs(schoolTypes) do
            info.text = school
            info.value = school
            info.func = function(self)
                selectedSchool = school
                UIDropDownMenu_SetSelectedValue(PopupFrame.SchoolDropdown, self.value)
                print("Selected school: " .. self.value)  -- Debugging message
            end
            UIDropDownMenu_AddButton(info, level)
        end
    
        -- Set the default selected value after the dropdown is initialized
        UIDropDownMenu_SetSelectedValue(PopupFrame.SchoolDropdown, "Physical")  -- Default selection
    end

    UIDropDownMenu_Initialize(PopupFrame.SchoolDropdown, SchoolDropdown_Initialize)


    -- Apply Button
    PopupFrame.ApplyButton = CreateFrame("Button", nil, PopupFrame, "UIPanelButtonTemplate")
    PopupFrame.ApplyButton:SetSize(60, 20)
    PopupFrame.ApplyButton:SetPoint("BOTTOM", PopupFrame, "BOTTOM", 0, 10)
    PopupFrame.ApplyButton:SetText("Apply")

    -- Close Popup
    PopupFrame.CloseButton = CreateFrame("Button", nil, PopupFrame, "UIPanelCloseButton")
    PopupFrame.CloseButton:SetPoint("TOPRIGHT", PopupFrame, "TOPRIGHT", -5, -5)
    PopupFrame.CloseButton:SetScript("OnClick", function() PopupFrame:Hide() end)

    -- Store Selected Stat
    PopupFrame.SelectedStat = nil

    -- Create Icons for Offensive Stats
    for i, stat in ipairs(offensiveStats) do
        local iconFrame = CreateFrame("Button", nil, frame)
        iconFrame:SetSize(32, 32)
        iconFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", (i - 1) * 80 + 40, -200)

        local statText = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        statText:SetPoint("BOTTOM", iconFrame, "TOP", 0, 2)
        statText:SetText(stat.name)

        local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
        iconTexture:SetAllPoints(iconFrame)
        iconTexture:SetAlpha(0.4)
        iconTexture:SetTexture(stat.icon)

        -- Combined Label for Damage Dice + Bonus (e.g., "1d8+2")
        local damageText = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        damageText:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
        damageText:SetText("1d6+0")
        damageText:SetTextColor(1, 1, 1)

        frame.OffensiveModifiers[stat.name] = {
            frame = iconFrame,
            text = damageText, -- Single label for both values
            value = 0,
            damageDice = "1d6",
            ac = 15,
            school = "Physical"
        }

        -- Open Popup on Click
        iconFrame:SetScript("OnClick", function()
            PopupFrame.SelectedStat = stat.name
            PopupFrame.Title:SetText("Edit " .. stat.name)
            PopupFrame.BonusInput:SetText(frame.OffensiveModifiers[stat.name].value)
            PopupFrame.DiceInput:SetText(frame.OffensiveModifiers[stat.name].damageDice)
            PopupFrame.ACInput:SetText(frame.OffensiveModifiers[stat.name].ac)
            UIDropDownMenu_SetSelectedValue(PopupFrame.SchoolDropdown, frame.OffensiveModifiers[stat.name].school or "Physical")  -- Default selection
            PopupFrame:Show()
        end)
    end

    -- Apply Changes from Popup
    PopupFrame.ApplyButton:SetScript("OnClick", function()
        if PopupFrame.SelectedStat then
            local attackBonus = tonumber(PopupFrame.BonusInput:GetText()) or 0
            local damageDice = PopupFrame.DiceInput:GetText() or "1d6"
            local ac = tonumber(PopupFrame.ACInput:GetText()) or 15
            local school = selectedSchool or "Physical"

            -- Format the text as "1d8+2" or "1d6-3"
            local formattedText = damageDice .. (attackBonus >= 0 and "+" or "") .. attackBonus

            -- Update stored values
            frame.OffensiveModifiers[PopupFrame.SelectedStat].value = attackBonus
            frame.OffensiveModifiers[PopupFrame.SelectedStat].damageDice = damageDice
            frame.OffensiveModifiers[PopupFrame.SelectedStat].ac = ac
            frame.OffensiveModifiers[PopupFrame.SelectedStat].school = school
            frame.OffensiveModifiers[PopupFrame.SelectedStat].text:SetText(formattedText)

            PopupFrame:Hide()
        end
    end)
end

-- Create Defensive AC Modifiers with On-Click Functionality
local function CreateDefensiveAC(frame)
    local defensiveStats = {
        {name = "Melee", icon = 132349},  
        {name = "Ranged", icon = 135498}, 
        {name = "Spell", icon = 136096}   
    }

    frame.DefensiveAC = {}

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOP", frame, "TOP", 0, -250)
    title:SetText("Armor Class (AC)")

    -- Popup Frame for Editing AC
    local PopupFrame = CreateFrame("Frame", "ACPopup", UIParent, "BackdropTemplate")
    PopupFrame:SetSize(180, 100)
    PopupFrame:SetPoint("TOPLEFT", EditorFrame, "TOPRIGHT", 10, 0)
    PopupFrame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    PopupFrame:Hide()

    -- Popup Title
    PopupFrame.Title = PopupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    PopupFrame.Title:SetPoint("TOP", PopupFrame, "TOP", 0, -10)

    -- AC Input Label
    PopupFrame.ACLabel = PopupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    PopupFrame.ACLabel:SetPoint("TOPLEFT", PopupFrame, "TOPLEFT", 15, -30)
    PopupFrame.ACLabel:SetText("Armor Class:")

    -- AC Input Field
    PopupFrame.ACInput = CreateFrame("EditBox", nil, PopupFrame, "InputBoxTemplate")
    PopupFrame.ACInput:SetSize(50, 20)
    PopupFrame.ACInput:SetPoint("LEFT", PopupFrame.ACLabel, "RIGHT", 10, 0)
    PopupFrame.ACInput:SetAutoFocus(false)
    PopupFrame.ACInput:SetNumeric(true)

    -- Apply Button
    PopupFrame.ApplyButton = CreateFrame("Button", nil, PopupFrame, "UIPanelButtonTemplate")
    PopupFrame.ApplyButton:SetSize(60, 20)
    PopupFrame.ApplyButton:SetPoint("BOTTOM", PopupFrame, "BOTTOM", 0, 10)
    PopupFrame.ApplyButton:SetText("Apply")

    -- Close Popup
    PopupFrame.CloseButton = CreateFrame("Button", nil, PopupFrame, "UIPanelCloseButton")
    PopupFrame.CloseButton:SetPoint("TOPRIGHT", PopupFrame, "TOPRIGHT", -5, -5)
    PopupFrame.CloseButton:SetScript("OnClick", function() PopupFrame:Hide() end)

    -- Store Selected AC Type
    PopupFrame.SelectedStat = nil

    -- Create Defensive AC Icons
    for i, stat in ipairs(defensiveStats) do
        local iconFrame = CreateFrame("Button", nil, frame)
        iconFrame:SetSize(32, 32)
        iconFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", (i - 1) * 50 + 70, -280)

        local statText = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        statText:SetPoint("BOTTOM", iconFrame, "TOP", 0, 2)
        statText:SetText(stat.name)

        local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
        iconTexture:SetAllPoints(iconFrame)
        iconTexture:SetAlpha(0.4)
        iconTexture:SetTexture(stat.icon)

        local acText = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        acText:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
        acText:SetText("15")
        acText:SetTextColor(1, 1, 1)

        frame.DefensiveAC[stat.name] = { frame = iconFrame, text = acText, value = 15 }

        -- Open Popup on Click
        iconFrame:SetScript("OnClick", function()
            PopupFrame.SelectedStat = stat.name
            PopupFrame.Title:SetText("Edit " .. stat.name .. " AC")
            PopupFrame.ACInput:SetText(frame.DefensiveAC[stat.name].value)
            PopupFrame:Show()
        end)
    end

    -- Apply Changes from Popup
    PopupFrame.ApplyButton:SetScript("OnClick", function()
        if PopupFrame.SelectedStat then
            local newAC = tonumber(PopupFrame.ACInput:GetText()) or 15
            frame.DefensiveAC[PopupFrame.SelectedStat].value = newAC
            frame.DefensiveAC[PopupFrame.SelectedStat].text:SetText(newAC)
            PopupFrame:Hide()
        end
    end)
end

-- Function to create the Position button and open the model position window on click
local function CreatePositionButton(frame)
    -- Create the Position window with sliders for model position
    local PositionWindow = CreateFrame("Frame", "PositionWindow", frame, "BackdropTemplate")
    PositionWindow:SetSize(220, 180)  -- Increased height for the labels
    PositionWindow:SetPoint("LEFT", frame, "RIGHT", 10, 0)
    PositionWindow:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame.PositionWindow = PositionWindow
    PositionWindow:Show()

    -- Position window title
    PositionWindow.Title = PositionWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    PositionWindow.Title:SetPoint("TOP", PositionWindow, "TOP", 0, -10)
    PositionWindow.Title:SetText("Model Position")

    -- Create sliders for x, y, z
    local modelPosition = EditorFrame.SelectedFrame.ModelPosition

    -- X Position Slider
    PositionWindow.XSliderLabel = PositionWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    PositionWindow.XSliderLabel:SetPoint("TOPLEFT", PositionWindow, "TOPLEFT", 15, -25)
    PositionWindow.XSliderLabel:SetText("X Position:")

    PositionWindow.XSlider = CreateFrame("Slider", nil, PositionWindow, "OptionsSliderTemplate")
    PositionWindow.XSlider:SetMinMaxValues(-5, 5)
    PositionWindow.XSlider:SetValueStep(0.1)  -- Set discrete steps of 0.1
    PositionWindow.XSlider:SetValue(modelPosition.x)
    PositionWindow.XSlider:SetPoint("TOPLEFT", PositionWindow.XSliderLabel, "BOTTOMLEFT", 0, 0)

    -- X Position Value Label
    PositionWindow.XPositionValue = PositionWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    PositionWindow.XPositionValue:SetPoint("LEFT", PositionWindow.XSlider, "RIGHT", 10, 0)
    PositionWindow.XPositionValue:SetText(modelPosition.x)

    -- Y Position Slider
    PositionWindow.YSliderLabel = PositionWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    PositionWindow.YSliderLabel:SetPoint("TOPLEFT", PositionWindow.XSliderLabel, "BOTTOMLEFT", 0, -30)
    PositionWindow.YSliderLabel:SetText("Y Position:")

    PositionWindow.YSlider = CreateFrame("Slider", nil, PositionWindow, "OptionsSliderTemplate")
    PositionWindow.YSlider:SetMinMaxValues(-5, 5)
    PositionWindow.YSlider:SetValueStep(0.1)  -- Set discrete steps of 0.1
    PositionWindow.YSlider:SetValue(modelPosition.y)
    PositionWindow.YSlider:SetPoint("TOPLEFT", PositionWindow.YSliderLabel, "BOTTOMLEFT", 0, 0)

    -- Y Position Value Label
    PositionWindow.YPositionValue = PositionWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    PositionWindow.YPositionValue:SetPoint("LEFT", PositionWindow.YSlider, "RIGHT", 10, 0)
    PositionWindow.YPositionValue:SetText(modelPosition.y)

    -- Z Position Slider
    PositionWindow.ZSliderLabel = PositionWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    PositionWindow.ZSliderLabel:SetPoint("TOPLEFT", PositionWindow.YSliderLabel, "BOTTOMLEFT", 0, -30)
    PositionWindow.ZSliderLabel:SetText("Z Position:")

    PositionWindow.ZSlider = CreateFrame("Slider", nil, PositionWindow, "OptionsSliderTemplate")
    PositionWindow.ZSlider:SetMinMaxValues(-5, 5)
    PositionWindow.ZSlider:SetValueStep(0.1)  -- Set discrete steps of 0.1
    PositionWindow.ZSlider:SetValue(modelPosition.z)
    PositionWindow.ZSlider:SetPoint("TOPLEFT", PositionWindow.ZSliderLabel, "BOTTOMLEFT", 0, 0)

    -- Z Position Value Label
    PositionWindow.ZPositionValue = PositionWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    PositionWindow.ZPositionValue:SetPoint("LEFT", PositionWindow.ZSlider, "RIGHT", 10, 0)
    PositionWindow.ZPositionValue:SetText(modelPosition.z)

    -- Create a separate portrait preview window next to the main editor frame
    local PortraitPreviewWindow = CreateFrame("Frame", "PortraitPreviewWindow", frame, "BackdropTemplate")
    PortraitPreviewWindow:SetSize(120, 120)  -- Set the size for the preview window
    PortraitPreviewWindow:SetPoint("TOPLEFT", PositionWindow, "BOTTOMLEFT", 0, -5)  -- Position it next to PositionWindow
    PortraitPreviewWindow:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame.PreviewWindow = PortraitPreviewWindow
    PortraitPreviewWindow:Show()
    
    -- Portrait preview inside the window
    PortraitPreviewWindow.PortraitPreview = CreateFrame("PlayerModel", nil, PortraitPreviewWindow)
    PortraitPreviewWindow.PortraitPreview:SetSize(100, 100)  -- Set the size of the preview
    PortraitPreviewWindow.PortraitPreview:SetPoint("CENTER", PortraitPreviewWindow, "CENTER", 0, 0)

    -- Set the model's position based on the sliders' values
    PortraitPreviewWindow.PortraitPreview:SetDisplayInfo(EditorFrame.SelectedFrame.NPCID)
    PortraitPreviewWindow.PortraitPreview:SetPosition(EditorFrame.SelectedFrame.ModelPosition.x, EditorFrame.SelectedFrame.ModelPosition.y, EditorFrame.SelectedFrame.ModelPosition.z)  -- Default position at the center

    -- Update the position of the portrait preview when sliders change
    PositionWindow.XSlider:SetScript("OnValueChanged", function(self, value)
        EditorFrame.SelectedFrame.ModelPosition.x = value
        PositionWindow.XPositionValue:SetText(string.format("%.1f", value))  -- Update X Position Label
        PortraitPreviewWindow.PortraitPreview:SetPosition(value, EditorFrame.SelectedFrame.ModelPosition.y, EditorFrame.SelectedFrame.ModelPosition.z)  -- Update portrait position
    end)

    PositionWindow.YSlider:SetScript("OnValueChanged", function(self, value)
        EditorFrame.SelectedFrame.ModelPosition.y = value
        PositionWindow.YPositionValue:SetText(string.format("%.1f", value))  -- Update Y Position Label
        PortraitPreviewWindow.PortraitPreview:SetPosition(EditorFrame.SelectedFrame.ModelPosition.x, value, EditorFrame.SelectedFrame.ModelPosition.z)  -- Update portrait position
    end)

    PositionWindow.ZSlider:SetScript("OnValueChanged", function(self, value)
        EditorFrame.SelectedFrame.ModelPosition.z = value
        PositionWindow.ZPositionValue:SetText(string.format("%.1f", value))  -- Update Z Position Label
        PortraitPreviewWindow.PortraitPreview:SetPosition(EditorFrame.SelectedFrame.ModelPosition.x, EditorFrame.SelectedFrame.ModelPosition.y, value)  -- Update portrait position
    end)
end

local function PopulateStatisticsTab()
    local frame = EditorFrame.TabFrames[1]

    -- Create the NameInput field only if it hasn't been created already
    if not frame.NameInput then
        frame.NameInput = CreateInputField(frame, "Unit Name:", -40, 150, false)
    end

    -- Create NPC ID input field if it hasn't been created already
    if not frame.NPCIDInput then
        frame.NPCIDInput = CreateInputField(frame, "NPC ID:", -70, 100, true)
    end

    -- Create UI Sections
    CreateAbilityScoreModifiers(frame)
    CreateOffensiveModifiers(frame)
    CreateDefensiveAC(frame)
end


-- Function to Populate Spells Tab
local function PopulateSpellsTab()
    local text = EditorFrame.TabFrames[2]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", EditorFrame.TabFrames[2], "CENTER", 0, 0)
    text:SetText("Spells Placeholder")
end

-- Function to Populate Loot Tab
local function PopulateLootTab()
    local text = EditorFrame.TabFrames[3]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", EditorFrame.TabFrames[3], "CENTER", 0, 0)
    text:SetText("Loot Placeholder")
end

-- Populate Tabs
PopulateStatisticsTab()
PopulateSpellsTab()
PopulateLootTab()

local function ShowApplyButton()
    EditorFrame.ApplyButton = CreateFrame("Button", nil, EditorFrame, "UIPanelButtonTemplate")
    EditorFrame.ApplyButton:SetSize(80, 25)
    EditorFrame.ApplyButton:SetPoint("BOTTOM", EditorFrame, "BOTTOM", 0, 10)
    EditorFrame.ApplyButton:SetText("Apply")

    EditorFrame.ApplyButton:SetScript("OnClick", function()
        if not EditorFrame.SelectedFrame then
            print("No unit frame selected!")
            return
        end

        local unitFrame = EditorFrame.SelectedFrame

        -- Store Unit Name
        unitFrame.NPCName = EditorFrame.TabFrames[1].NameInput:GetText()

        -- Store NPC ID
        unitFrame.NPCID = tonumber(EditorFrame.TabFrames[1].NPCIDInput:GetText()) or 17227

        -- Store NPC Position in Window
        unitFrame.ModelPosition["x"] = tonumber(EditorFrame.TabFrames[1].PositionWindow.XSlider:GetValue())
        print("Model X Position: " ..unitFrame.ModelPosition["x"])
        unitFrame.ModelPosition["y"] = tonumber(EditorFrame.TabFrames[1].PositionWindow.YSlider:GetValue())
        print("Model Y Position: " ..unitFrame.ModelPosition["y"])
        unitFrame.ModelPosition["z"] = tonumber(EditorFrame.TabFrames[1].PositionWindow.ZSlider:GetValue())
        print("Model Z Position: " ..unitFrame.ModelPosition["z"])


        -- Store Ability Modifiers
        unitFrame.AbilityModifiers = {}
        for ability, data in pairs(EditorFrame.TabFrames[1].AbilityModifiers) do
            unitFrame.AbilityModifiers[ability] = data.value
        end

        -- Store Offensive Modifiers (Attack Bonus & Damage Dice)
        unitFrame.OffensiveModifiers = {}
        for stat, data in pairs(EditorFrame.TabFrames[1].OffensiveModifiers) do
            unitFrame.OffensiveModifiers[stat] = {
                attackBonus = data.value,
                damageDice = data.damageDice,
                ac = data.ac,
                school = data.school
            }
        end

        -- Store Defensive AC
        unitFrame.DefensiveAC = {}
        for stat, data in pairs(EditorFrame.TabFrames[1].DefensiveAC) do
            unitFrame.DefensiveAC[stat] = data.value
        end

        -- Debug Print Output
        print("Unit Frame Updated:", unitFrame.UnitName, "NPC ID:", unitFrame.NPCID)

        print("Ability Modifiers:")
        for ability, value in pairs(unitFrame.AbilityModifiers) do
            print(" - " .. ability .. ": " .. value)
        end

        print("Offensive Modifiers:")
        for stat, values in pairs(unitFrame.OffensiveModifiers) do
            print(" - " .. stat .. ": " .. values.damageDice .. (values.attackBonus >= 0 and "+" or "") .. values.attackBonus .. " | DC " ..values.ac.. " | School: " ..values.school)
        end

        print("Defensive AC:")
        for stat, value in pairs(unitFrame.DefensiveAC) do
            print(" - " .. stat .. " AC: " .. value)
        end

        -- Send the sync message
        print("Sending sync message...")
        UnitFrames:Sync_UnitFrame(unitFrame)

        -- Close the editor after applying changes
        EditorFrame:Hide()
        PositionWindow:Hide()
        PortraitPreviewWindow:Hide()

    end)

    EditorFrame.ApplyButton:Show()
end

ShowApplyButton()

local function UpdateAbilityModifiers(frame, unitFrame)
    -- Update Ability Scores section with values from unitFrame (for example)
    for _, ability in ipairs(unitFrame.AbilityModifiers) do
        local abilityFrame = frame.AbilityModifiers[ability.name]
        if abilityFrame then
            abilityFrame.text:SetText(ability.value)  -- Update the ability modifier value
        end
    end
end

local function UpdateDefensiveAC(frame, unitFrame)
    -- Update Defensive AC section
    for stat, acValue in pairs(unitFrame.DefensiveAC) do
        local acFrame = frame.DefensiveAC[stat]
        if acFrame then
            acFrame.text:SetText(acValue)  -- Update the AC value
        end
    end
end


local function UpdateOffensiveModifiers(frame, unitFrame)
    -- Update Offensive Modifiers section
    for stat, modifiers in pairs(unitFrame.OffensiveModifiers) do
        local modifierFrame = frame.OffensiveModifiers[stat]
        if modifierFrame then
            modifierFrame.text:SetText(modifiers.damageDice .. "+" .. modifiers.attackBonus)  -- Update Damage Dice and Bonus
            modifierFrame.ac = modifiers.ac  -- Update AC value
        end
    end
end

-- Function to update position sliders and the model preview
local function UpdatePositionSlider(frame, unitFrame)
    -- Update sliders with the current position values
    frame.PositionWindow.XSlider:SetValue(unitFrame.ModelPosition["x"])
    frame.PositionWindow.YSlider:SetValue(unitFrame.ModelPosition["y"])
    frame.PositionWindow.ZSlider:SetValue(unitFrame.ModelPosition["z"])

    print(string.format("Updating position: X: %.1f, Y: %.1f, Z: %.1f", 
        unitFrame.ModelPosition["x"], unitFrame.ModelPosition["y"], unitFrame.ModelPosition["z"]))

    -- Ensure PortraitPreviewWindow and PositionWindow are initialized
    if PortraitPreviewWindow and PortraitPreviewWindow.PortraitPreview then
        -- Set the model display info
        PortraitPreviewWindow.PortraitPreview:SetDisplayInfo(unitFrame.NPCID)
        -- Update the model position based on sliders
        PortraitPreviewWindow.PortraitPreview:SetPosition(
            frame.PositionWindow.XSlider:GetValue(),
            frame.PositionWindow.YSlider:GetValue(),
            frame.PositionWindow.ZSlider:GetValue()
        )
    else
        print("PortraitPreviewWindow or PositionWindow not initialized properly.")
    end
end

-- Function to show the editor window and update content
function UnitFrameEditor:ShowEditor(unitFrame)
    if not unitFrame then return end

    EditorFrame.SelectedFrame = unitFrame

    -- Ensure the editor frame is initialized
    if not EditorFrame:IsShown() then
        EditorFrame:Show()  -- Make sure the editor window is visible
    end

    -- Initialize default tables if they don't exist (to avoid `nil` errors)
    unitFrame.AbilityModifiers = unitFrame.AbilityModifiers or {}
    unitFrame.OffensiveModifiers = unitFrame.OffensiveModifiers or {}
    unitFrame.DefensiveAC = unitFrame.DefensiveAC or {}

    -- Update existing input fields with data from unitFrame
    EditorFrame.TabFrames[1].NameInput:SetText(unitFrame.NPCName or "")
    EditorFrame.TabFrames[1].NPCIDInput:SetText(unitFrame.NPCID or "")

    -- Update the Ability Modifiers, Offensive Modifiers, and Defensive AC sections
    UpdateAbilityModifiers(EditorFrame.TabFrames[1], unitFrame)
    UpdateOffensiveModifiers(EditorFrame.TabFrames[1], unitFrame)
    UpdateDefensiveAC(EditorFrame.TabFrames[1], unitFrame)

    -- Ensure the editor is visible
    EditorFrame:Show()

    -- Create the Position Button and Position Window if not created
    if not PositionWindow or not PortraitPreviewWindow then
        CreatePositionButton(EditorFrame.TabFrames[1])
    else
        PositionWindow:Show()
        PortraitPreviewWindow:Show()
    end

    -- Now update the sliders and the portrait preview
    UpdatePositionSlider(EditorFrame.TabFrames[1], unitFrame)

    -- Debug messages for confirming initialization
    print("Opening Unit Frame Editor for:", unitFrame.NPCName, "\nModel ID:", unitFrame.NPCID)
end




