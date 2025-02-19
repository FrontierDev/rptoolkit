-- Addon message prefix registration
C_ChatInfo.RegisterAddonMessagePrefix("CTCINIT")
C_ChatInfo.RegisterAddonMessagePrefix("CTCNEXT")

local CampaignManager = {}
_G.CampaignManager = CampaignManager

-- Ensures the campaigns table exists
_G.Campaigns = _G.Campaigns or {}

local modifierCategories = {
    ["Ability Scores"] = { "Strength", "Dexterity", "Constitution", "Intelligence", "Wisdom", "Charisma" },
    ["Skills"] = { "Arcana", "Animal Handling", "Athletics", "Deception", "History", "Insight", "Intimidation", "Investigation", "Medicine", "Nature", "Perception", "Performance", "Persuasion", "Religion", "Sleight of Hand", "Stealth", "Survival" },
    ["Hit Modifiers"] = { "Melee Hit Rating", "Ranged Hit Rating", "Spell Hit Rating", "Haste Bonus" },
    ["Damage Modifiers"] = { "Melee Attack Power", "Ranged Attack Power", "Spell Power", "Fire Damage", "Frost Damage", "Nature Damage", "Arcane Damage", "Fel Damage", "Holy Damage", "Shadow Damage" },
    ["Defense Modifiers"] = { "Bonus Healing", "Dodge Rating", "Parry Rating", "Block Rating" },
    ["Crit Modifiers"] = { "Melee Critical Strike", "Ranged Critical Strike", "Spell Critical Strike", "Fire Critical Strike", "Frost Critical Strike", "Nature Critical Strike", "Arcane Critical Strike", "Fel Critical Strike", "Holy Critical Strike", "Shadow Critical Strike", "Healing Critical Strike", "Critical Dodge", "Critical Parry", "Critical Block" },
    ["Resistances"] = { "Fire Resistance", "Frost Resistance", "Nature Resistance", "Arcane Resistance", "Fel Resistance", "Holy Resistance", "Shadow Resistance" },
    ["Spell Mitigation"] = { "Fire Damage Mitigation", "Frost Damage Mitigation", "Nature Damage Mitigation", "Arcane Damage Mitigation", "Fel Damage Mitigation", "Holy Damage Mitigation", "Shadow Damage Mitigation" },
    ["Other"] = { "Health", "Mana", "Initiative", "Armor", "Deflection", "Mana per Turn", "Health per Turn", "Movement Range", "Concentration" }
}

local STAT_TOOLTIP_REVERSE = {}
for key, value in pairs(_G.STAT_TOOLTIP_MAP) do
    STAT_TOOLTIP_REVERSE[value] = key  -- Swap key and value
end

-- CampaignManager.lua
local CampaignManager = CreateFrame("Frame", "CampaignManagerFrame", UIParent, "BackdropTemplate")
CampaignManager:SetSize(800, 300)
CampaignManager:SetPoint("CENTER")
CampaignManager:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
CampaignManager:Hide()

-- Close Button
CampaignManager.CloseButton = CreateFrame("Button", nil, CampaignManager, "UIPanelCloseButton")
CampaignManager.CloseButton:SetPoint("TOPRIGHT", CampaignManager, "TOPRIGHT", -5, -5)
CampaignManager.CloseButton:SetScript("OnClick", function()
    CampaignManager:Hide()
end)

-- Title Text
CampaignManager.Title = CampaignManager:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
CampaignManager.Title:SetPoint("TOPLEFT", CampaignManager, "TOPLEFT", 80, -10)
CampaignManager.Title:SetText("Current Campaign")

-- Title Text
CampaignManager.CampaignName = CampaignManager:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
CampaignManager.CampaignName:SetPoint("TOPLEFT", CampaignManager, "TOPLEFT", 80, -25)
CampaignManager.CampaignName:SetText("< No Campaign >")

-- Icon
CampaignManager.Icon = CampaignManager:CreateTexture(nil, "ARTWORK")
CampaignManager.Icon:SetSize(64, 64)
CampaignManager.Icon:SetPoint("TOPLEFT", CampaignManager, "TOPLEFT", 10, -10)
CampaignManager.Icon:SetTexture("Interface/ICONS/INV_Misc_Map_01")

-- ScrollFrame for the campaign list
local CampaignListScrollFrame = CreateFrame("ScrollFrame", "CampaignListScrollFrame", CampaignManagerFrame, "UIPanelScrollFrameTemplate")
CampaignListScrollFrame:SetSize(200, 200)
CampaignListScrollFrame:SetPoint("TOPLEFT", CampaignManagerFrame, "TOPLEFT", 10, -85)

-- ScrollChild Frame (holds buttons for each campaign)
local CampaignListScrollChild = CreateFrame("Frame", nil, CampaignListScrollFrame)
CampaignListScrollChild:SetSize(200, 250)  -- This is a placeholder size; it will adjust dynamically
CampaignListScrollFrame:SetScrollChild(CampaignListScrollChild)

-- Function to create a divider
local function CreateDivider(parent, width, yOffset, text)
    -- Create the divider line
    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetSize(width, 1)  -- Width of the divider
    divider:SetPoint("TOP", parent, "TOP", 0, yOffset)
    divider:SetColorTexture(1, 1, 1, 0.2)  -- White with slight transparency

    -- Create the section heading text
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("TOP", divider, "TOP", 0, 10)  -- Position text above the line
    header:SetText(text)

    return divider, header
end

CreateDivider(CampaignManager, 780, -77.5, "")

-- Tabs & Frames
CampaignManagerFrame.Tabs = {}
CampaignManagerFrame.TabFrames = {}

--== TABS ==--
local function CreateTab(parent, index, texturePath, tooltipText)
    local tab = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    tab:SetSize(32, 32)
    tab:SetNormalTexture(texturePath)

    if index == 1 then
        tab:SetPoint("TOPLEFT", parent, "TOPRIGHT", -40, -85)
    else
        tab:SetPoint("TOP", parent.Tabs[index - 1], "BOTTOM", 0, 0)
    end

    tab:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(tooltipText, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    tab:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return tab
end

-- Tabs Data
local tabData = {
    {icon = "Interface/Icons/inv_scroll_11", tooltip = "Details"},
    {icon = "Interface/Icons/inv_misc_book_09", tooltip = "Spells"},
    {icon = "Interface/Icons/spell_arcane_studentofmagic", tooltip = "Auras"},
    {icon = "Interface/Icons/inv_misc_bag_08", tooltip = "Items (NYI)"},
    {icon = "Interface/Icons/achievement_quests_completed_daily_06", tooltip = "Quests (NYI)"},
    {icon = "Interface/Icons/inv_misc_grouplooking", tooltip = "NPCs (NYI)"},
}

for i, data in ipairs(tabData) do
    CampaignManagerFrame.Tabs[i] = CreateTab(CampaignManagerFrame, i, data.icon, data.tooltip)
    CampaignManagerFrame.TabFrames[i] = CreateFrame("Frame", nil, CampaignManagerFrame)
    CampaignManagerFrame.TabFrames[i]:SetSize(780, 340)
    CampaignManagerFrame.TabFrames[i]:SetPoint("TOPLEFT", CampaignManagerFrame, "TOPLEFT", 240, -80)
    CampaignManagerFrame.TabFrames[i]:Hide()
end

-- Show first tab by default
CampaignManagerFrame.TabFrames[1]:Show()

local function SwitchTab(tabIndex)
    for i, frame in ipairs(CampaignManagerFrame.TabFrames) do
        frame:Hide()
    end
    CampaignManagerFrame.TabFrames[tabIndex]:Show()
    for i, tab in ipairs(CampaignManagerFrame.Tabs) do
        tab:GetNormalTexture():SetVertexColor(i == tabIndex and 1 or 0.5, i == tabIndex and 1 or 0.5, i == tabIndex and 1 or 0.5)
    end

    -- If switching to 'Details' tab, refresh the campaign details UI
    if tabIndex == 1 and CampaignManagerFrame.SelectedCampaign then
        CampaignManager:PopulateCampaignDetails(CampaignManagerFrame.SelectedCampaign)
    elseif tabIndex == 2 and CampaignManagerFrame.SelectedCampaign then
        CampaignManager:PopulateCampaignSpellList(CampaignManagerFrame.SelectedCampaign)
    elseif tabIndex == 3 and CampaignManagerFrame.SelectedCampaign then
        CampaignManager:PopulateCampaignAuraList(CampaignManagerFrame.SelectedCampaign)
    end
end

--== CAMPAIGN EDITOR ==--
function CampaignManager:PopulateCampaignDetails(guid)
    local campaign = _G.Campaigns[guid] -- Retrieve the loaded campaign
    if not campaign then return end

    -- Ensure the 'Details' tab UI elements exist before populating
    if not CampaignManagerFrame.Details then
        -- Create a container for campaign details
        CampaignManagerFrame.Details = CreateFrame("Frame", nil, CampaignManagerFrame.TabFrames[1])
        CampaignManagerFrame.Details:SetSize(780, 160)
        CampaignManagerFrame.Details:SetPoint("TOPLEFT", 10, -10)

        -- Campaign Name EditBox Label
        CampaignManagerFrame.Details.NameEditLabel = CampaignManagerFrame.Details:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        CampaignManagerFrame.Details.NameEditLabel:SetPoint("TOPLEFT", CampaignManagerFrame.Details, "TOPLEFT", 60, 0)
        CampaignManagerFrame.Details.NameEditLabel:SetText("Campaign Name")

        -- Campaign Name EditBox
        CampaignManagerFrame.Details.NameEditBox = CreateFrame("EditBox", nil, CampaignManagerFrame.Details, "InputBoxTemplate")
        CampaignManagerFrame.Details.NameEditBox:SetSize(300, 30)
        CampaignManagerFrame.Details.NameEditBox:SetPoint("TOPLEFT", 60, -10)
        CampaignManagerFrame.Details.NameEditBox:SetAutoFocus(false)

        -- Campaign Icon Button
        CampaignManagerFrame.Details.IconButton = CreateFrame("Button", nil, CampaignManagerFrame.Details, "UIPanelButtonTemplate")
        CampaignManagerFrame.Details.IconButton:SetSize(40, 40)
        CampaignManagerFrame.Details.IconButton:SetPoint("TOPLEFT", CampaignManagerFrame.Details, "TOPLEFT", 10, 0)

        -- Icon Texture inside the button
        CampaignManagerFrame.Details.Icon = CampaignManagerFrame.Details.IconButton:CreateTexture(nil, "ARTWORK")
        CampaignManagerFrame.Details.Icon:SetAllPoints(CampaignManagerFrame.Details.IconButton)
        CampaignManagerFrame.Details.Icon:SetTexture(campaign.Icon) -- Default icon

        -- Clickable function for changing the icon
        CampaignManagerFrame.Details.IconButton:SetScript("OnClick", function()
            StaticPopupDialogs["CHANGE_CAMPAIGN_ICON"] = {
                text = "Enter the new icon path:",
                button1 = "OK",
                button2 = "Cancel",
                hasEditBox = true,
                OnAccept = function(self)
                    local newIcon = self.editBox:GetText()
                    _G.Campaigns[guid].Icon = string.format("interface/icons/%s", newIcon)
                    CampaignManagerFrame.Details.Icon:SetTexture(_G.Campaigns[guid].Icon)
                    CTCampaign:SaveCampaign(guid)
                end,
                EditBoxOnEnterPressed = function(self)
                    local newIcon = self:GetParent().editBox:GetText()
                    _G.Campaigns[guid].Icon = string.format("interface/icons/%s", newIcon)
                    CampaignManagerFrame.Details.Icon:SetTexture(_G.Campaigns[guid].Icon)
                    CTCampaign:SaveCampaign(guid)
                    self:GetParent():Hide()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("CHANGE_CAMPAIGN_ICON")
        end)

        -- Campaign Description Label
        CampaignManagerFrame.Details.DescriptionLabel = CampaignManagerFrame.Details:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        CampaignManagerFrame.Details.DescriptionLabel:SetPoint("TOPLEFT", CampaignManagerFrame.Details.IconButton, "BOTTOMLEFT", 0, -10)
        CampaignManagerFrame.Details.DescriptionLabel:SetText("Description:")

        -- Scroll Frame for the Description Box
        CampaignManagerFrame.Details.DescriptionScroll = CreateFrame("ScrollFrame", nil, CampaignManagerFrame.Details, "UIPanelScrollFrameTemplate, BackdropTemplate")
        CampaignManagerFrame.Details.DescriptionScroll:SetSize(400, 90)
        CampaignManagerFrame.Details.DescriptionScroll:SetPoint("TOPLEFT", CampaignManagerFrame.Details.DescriptionLabel, "BOTTOMLEFT", 0, -5)
        CampaignManagerFrame.Details.DescriptionScroll:SetBackdrop({
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        CampaignManagerFrame.Details.DescriptionScroll:SetBackdropColor(0, 0, 0, 0.8)

        -- Editable Text Area
        CampaignManagerFrame.Details.DescriptionBox = CreateFrame("EditBox", nil, CampaignManagerFrame.Details.DescriptionScroll)
        CampaignManagerFrame.Details.DescriptionBox:SetMultiLine(true)
        CampaignManagerFrame.Details.DescriptionBox:SetFontObject(GameFontNormal)
        CampaignManagerFrame.Details.DescriptionBox:SetWidth(390) -- Slightly smaller than ScrollFrame
        CampaignManagerFrame.Details.DescriptionBox:SetAutoFocus(false)
        CampaignManagerFrame.Details.DescriptionBox:SetMaxLetters(1000)
        CampaignManagerFrame.Details.DescriptionBox:SetTextInsets(5, 5, 5, 5)
        CampaignManagerFrame.Details.DescriptionBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        CampaignManagerFrame.Details.DescriptionBox:SetText(campaign.Description)

        -- Assign EditBox to ScrollFrame
        CampaignManagerFrame.Details.DescriptionScroll:SetScrollChild(CampaignManagerFrame.Details.DescriptionBox)


        -- Save Button
        CampaignManagerFrame.Details.SaveButton = CreateFrame("Button", nil, CampaignManagerFrame.Details, "UIPanelButtonTemplate")
        CampaignManagerFrame.Details.SaveButton:SetSize(100, 25)
        CampaignManagerFrame.Details.SaveButton:SetPoint("TOPLEFT", CampaignManagerFrame.Details, "BOTTOMLEFT", 10, 0)
        CampaignManagerFrame.Details.SaveButton:SetText("Save")
        
        -- Save function
        CampaignManagerFrame.Details.SaveButton:SetScript("OnClick", function()
            local newName = CampaignManagerFrame.Details.NameEditBox:GetText()
            local newDescription = CampaignManagerFrame.Details.DescriptionBox:GetText()
            _G.Campaigns[guid].Name = newName
            _G.Campaigns[guid].Description = newDescription
            _G.Campaigns[guid].Author = UnitName("Player")
            CampaignManagerFrame.CampaignName:SetText(newName)
            CTCampaign:SaveCampaign(guid)
            _G.UpdateCampaignList() -- Refresh list with updated name
        end)

        CampaignManagerFrame.Details.SendButton = CreateFrame("Button", nil, CampaignManagerFrame.Details, "UIPanelButtonTemplate")
        CampaignManagerFrame.Details.SendButton:SetSize(150, 25)
        CampaignManagerFrame.Details.SendButton:SetPoint("TOPLEFT", CampaignManagerFrame.Details.SaveButton, "TOPLEFT", 100, 0)
        CampaignManagerFrame.Details.SendButton:SetText("Send Campaign")
        CampaignManagerFrame.Details.SendButton:Show() -- Hide by default

        CampaignManagerFrame.Details.SendButton:SetScript("OnClick", function()
            if not UnitIsGroupLeader("player") then return end

            CampaignManager:SendCampaign(guid)
        end)

        -- Function to update button visibility
        local function UpdateSendCampaignButton()
            if UnitIsGroupLeader("player") then
                CampaignManagerFrame.Details.SendButton:Show()
            else
                CampaignManagerFrame.Details.SendButton:Hide()
            end
        end
    end

    -- Populate the edit box with the campaign name
    CampaignManagerFrame.Details.NameEditBox:SetText(campaign.Name)
end

--== SPELL EDITOR ==--
function CampaignManager:CreateSpellFrame(parentFrame)
    parentFrame.SpellList = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    parentFrame.SpellList:SetSize(750, 320)
    parentFrame.SpellList:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, 0)

    -- Define grid layout for spell slots
    local SLOT_SIZE, SLOT_PADDING, COLUMNS, ROWS = 48, -16, 14, 5
    local TOTAL_SLOTS = COLUMNS * ROWS
    local startX, startY = 10, -20

    parentFrame.SpellSlots = {}

    -- Create Spell Slots
    for i = 1, TOTAL_SLOTS do
        local slot = CreateFrame("Button", nil, parentFrame.SpellList, "BackdropTemplate")
        slot:SetSize(SLOT_SIZE, SLOT_SIZE)

        local row, col = math.floor((i - 1) / COLUMNS), (i - 1) % COLUMNS
        slot:SetPoint("TOPLEFT", parentFrame.SpellList, "TOPLEFT", startX + (col * (SLOT_SIZE + SLOT_PADDING)), startY - (row * (SLOT_SIZE + SLOT_PADDING)))

        -- Background texture
        slot.texture = slot:CreateTexture(nil, "BACKGROUND")
        slot.texture:SetAllPoints(slot)
        slot.texture:SetTexture("Interface\\Buttons\\UI-EmptySlot")

        -- Spell icon placeholder
        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetSize(SLOT_SIZE - 24, SLOT_SIZE - 24)
        slot.icon:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        slot.icon:Hide()

        slot.spell = nil

        -- Tooltip on hover (Replace existing `OnEnter` script)
        slot:SetScript("OnEnter", function(self)
            if self.spell then
                CTSpell:ShowTooltip(self.spell, self)  -- Use the custom tooltip from CTSpell.lua
            end
        end)

        slot:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- Right-click to remove spell from campaign
        slot:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                if self.spell then
                    -- Open the edit UI for an existing spell
                    CampaignManager:AddSpellWindow(self.spell)
                else
                    -- Open the spell creation UI with a blank template
                    local newSpell = {
                        Name = "New Spell",
                        Description = "",
                        Type = "General",
                        Class = "General",
                        Specialisation = "General",
                        ActionCost = "None",
                        Message = "",
                        ManaCost = 0,
                        DiceToHit = "",
                        DiceToDamage = "",
                        HitModifiers = {},
                        DamageModifiers = {},
                        CritModifiers = {},
                        Icon = "Interface/ICONS/INV_Misc_QuestionMark"
                    }
                    CampaignManager:AddSpellWindow(newSpell)
                end
            elseif button == "RightButton" and self.spell then
                print(string.format("Removed spell: %s from campaign", self.spell.Name))
                CampaignManager:RemoveSpellFromCampaign(parentFrame.SelectedCampaign, self.spell.Guid)
                CampaignManager:PopulateCampaignSpellList(parentFrame.SelectedCampaign) -- Refresh UI
            end
        end)


        table.insert(parentFrame.SpellSlots, slot)
    end
end

function CampaignManager:RemoveSpellFromCampaign(guid, spellGuid)
    print(guid)

    print("Attempting to remove spell from campaign...")
    local campaign = _G.Campaigns[guid]
    if not campaign then return end

    print("... found campaign")


    for index, spell in ipairs(campaign.SpellList) do
        if spell.Guid == spellGuid then
            print("Removing " ..spell.Name)
            table.remove(campaign.SpellList, index)
            CTCampaign:SaveCampaign(guid) -- Save changes
            return
        end
    end
end

function CampaignManager:PopulateCampaignSpellList(guid)
    local campaign = _G.Campaigns[guid] -- Retrieve the loaded campaign
    if not campaign then return end


    -- Ensure the 'Spells' tab UI exists
    if not CampaignManagerFrame.Spells then
        CampaignManagerFrame.Spells = CreateFrame("Frame", nil, CampaignManagerFrame.TabFrames[2])
        CampaignManagerFrame.Spells:SetSize(780, 340)
        CampaignManagerFrame.Spells:SetPoint("TOPLEFT", 10, -10)

        CampaignManagerFrame.Spells.SelectedCampaign = guid

        -- Spell List Label
        CampaignManagerFrame.Spells.NameEditLabel = CampaignManagerFrame.Spells:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        CampaignManagerFrame.Spells.NameEditLabel:SetPoint("TOPLEFT", CampaignManagerFrame.Spells, "TOPLEFT", 10, 0)
        CampaignManagerFrame.Spells.NameEditLabel:SetText("Spell List")

        -- Create the Spell Grid
        CampaignManager:CreateSpellFrame(CampaignManagerFrame.Spells)
    end

    -- Clear all existing spell slots
    for _, slot in ipairs(CampaignManagerFrame.Spells.SpellSlots) do
        slot.icon:Hide()
        slot.spell = nil
    end

    -- Populate slots with spells
    for i, spell in ipairs(campaign.SpellList or {}) do
        local slot = CampaignManagerFrame.Spells.SpellSlots[i]
        if slot then
            slot.spell = spell
            slot.icon:SetTexture(spell.Icon)
            slot.icon:Show()
        end
    end
end

function CampaignManager:AddSpellWindow(spell)
    -- Prevent duplicate windows
    if self.AddSpellFrame then
        self.AddSpellFrame:Hide()
    end

    -- Create the Main Frame
    self.AddSpellFrame = CreateFrame("Frame", "AddSpellFrame", UIParent, "BackdropTemplate")
    self.AddSpellFrame:SetSize(400, 600)
    self.AddSpellFrame:SetPoint("TOPLEFT", CampaignManagerFrame, "TOPRIGHT", -10, 0)  -- Positioned to the right of CampaignManager
    self.AddSpellFrame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    self.AddSpellFrame:SetMovable(true)
    self.AddSpellFrame:EnableMouse(true)
    self.AddSpellFrame:RegisterForDrag("LeftButton")
    self.AddSpellFrame:SetScript("OnDragStart", self.AddSpellFrame.StartMoving)
    self.AddSpellFrame:SetScript("OnDragStop", self.AddSpellFrame.StopMovingOrSizing)

    -- Close Button
    self.AddSpellFrame.CloseButton = CreateFrame("Button", nil, self.AddSpellFrame, "UIPanelCloseButton")
    self.AddSpellFrame.CloseButton:SetPoint("TOPRIGHT", self.AddSpellFrame, "TOPRIGHT", -5, -5)
    self.AddSpellFrame.CloseButton:SetScript("OnClick", function()
        self.AddSpellFrame:Hide()
    end)

    -- Spell Icon Button (Clickable)
    self.AddSpellFrame.IconButton = CreateFrame("Button", nil, self.AddSpellFrame)
    self.AddSpellFrame.IconButton:SetSize(32, 32)
    self.AddSpellFrame.IconButton:SetPoint("TOPLEFT", self.AddSpellFrame, "TOPLEFT", 10, -10)

    -- Spell Icon Texture Inside Button
    self.AddSpellFrame.Icon = self.AddSpellFrame.IconButton:CreateTexture(nil, "ARTWORK")
    self.AddSpellFrame.Icon:SetAllPoints(self.AddSpellFrame.IconButton)
    self.AddSpellFrame.Icon:SetTexture(spell.Icon or "Interface/ICONS/INV_Misc_QuestionMark")

    -- Left-Click to Change Icon
    self.AddSpellFrame.IconButton:SetScript("OnClick", function()
        StaticPopupDialogs["CHANGE_SPELL_ICON"] = {
            text = "Enter the new icon path:",
            button1 = "OK",
            button2 = "Cancel",
            hasEditBox = true,
            OnAccept = function(self)
                local newIcon = string.format("interface/icons/%s", self.editBox:GetText())
                if newIcon and newIcon ~= "" then
                    spell.Icon = newIcon
                    CampaignManager.AddSpellFrame.Icon:SetTexture(newIcon) -- Update UI Immediately
                end
            end,
            EditBoxOnEnterPressed = function(self)
                local newIcon = string.format("interface/icons/%s", self:GetParent().editBox:GetText())
                if newIcon and newIcon ~= "" then
                    spell.Icon = newIcon
                    CampaignManager.AddSpellFrame.Icon:SetTexture(newIcon) -- Update UI Immediately
                    self:GetParent():Hide()
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("CHANGE_SPELL_ICON")
    end)


    -- Spell Name EditBox
    self.AddSpellFrame.SpellNameBox = CreateFrame("EditBox", nil, self.AddSpellFrame, "InputBoxTemplate")
    self.AddSpellFrame.SpellNameBox:SetSize(200, 30)
    self.AddSpellFrame.SpellNameBox:SetPoint("TOPLEFT", self.AddSpellFrame.Icon, "TOPRIGHT", 10, 0)
    self.AddSpellFrame.SpellNameBox:SetAutoFocus(false)
    self.AddSpellFrame.SpellNameBox:SetText(spell.Name or "Unknown Spell")

    ----- CLASS and Specialisation
    -- Class/Spec Label
    self.AddSpellFrame.SpellDescriptionLabel = self.AddSpellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddSpellFrame.SpellDescriptionLabel:SetPoint("TOPLEFT", self.AddSpellFrame.Icon, "BOTTOMLEFT", 5, -5)
    self.AddSpellFrame.SpellDescriptionLabel:SetText("Class and\nSpecialisation")

    -- Class Dropdown
    local selectedClass = spell.Class

    self.AddSpellFrame.ClassDropdown = CreateFrame("Frame", "ClassDropdown", self.AddSpellFrame, "UIDropDownMenuTemplate")
    self.AddSpellFrame.ClassDropdown:SetPoint("TOPLEFT", self.AddSpellFrame.SpellDescriptionLabel, "TOPLEFT", 80, 0)

    local classes = { "General", "Death Knight", "Demon Hunter", "Druid", "Evoker", "Hunter", "Mage", "Monk", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior" }
    local classDropdown = self.AddSpellFrame.ClassDropdown
    local function OnClassSelected(self, value)
        selectedClass = value
        spell.Class = value
        UIDropDownMenu_SetText(classDropdown, value)
    end

    UIDropDownMenu_Initialize(self.AddSpellFrame.ClassDropdown, function(self, level, menuList)
        for _, cost in ipairs(classes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = cost
            info.func = function() OnClassSelected(self, cost) end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(self.AddSpellFrame.ClassDropdown, spell.Class or "None")

    ----- SPECIALISATION -----
    -- Specialisation Dropdown
    local selectedSpecialisation = spell.Specialisation

    self.AddSpellFrame.SpecialisationDropdown = CreateFrame("Frame", "SpecialisationDropdown", self.AddSpellFrame, "UIDropDownMenuTemplate")
    self.AddSpellFrame.SpecialisationDropdown:SetPoint("TOPLEFT", self.AddSpellFrame.ClassDropdown, "TOPRIGHT", 100, 0)

    -- List of Specializations by Class
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

    local specialisationDropdown = self.AddSpellFrame.SpecialisationDropdown
    local function OnSpecialisationSelected(self, value)
        selectedSpecialisation = value
        spell.Specialisation = value
        UIDropDownMenu_SetText(specialisationDropdown, value)
    end

    UIDropDownMenu_Initialize(self.AddSpellFrame.SpecialisationDropdown, function(self, level, menuList)
        local selectedClassSpecs = specialisations[selectedClass] or { "None" }
        for _, spec in ipairs(selectedClassSpecs) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = spec
            info.func = function() OnSpecialisationSelected(self, spec) end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(self.AddSpellFrame.SpecialisationDropdown, spell.Specialisation or "None")


    -- Scroll Frame for the Text Area
    -- Spell Description Label
    self.AddSpellFrame.SpellDescriptionLabel = self.AddSpellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddSpellFrame.SpellDescriptionLabel:SetPoint("TOPLEFT", self.AddSpellFrame.Icon, "BOTTOMLEFT", 15, -40)
    self.AddSpellFrame.SpellDescriptionLabel:SetText("Description:")

    self.AddSpellFrame.SpellDescriptionScroll = CreateFrame("ScrollFrame", nil, self.AddSpellFrame, "UIPanelScrollFrameTemplate, BackdropTemplate")
    self.AddSpellFrame.SpellDescriptionScroll:SetSize(340, 80)
    self.AddSpellFrame.SpellDescriptionScroll:SetPoint("TOPLEFT", self.AddSpellFrame.SpellDescriptionLabel, "BOTTOMLEFT", 0, -5)
    self.AddSpellFrame.SpellDescriptionScroll:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    self.AddSpellFrame.SpellDescriptionScroll:SetBackdropColor(0, 0, 0, 0.8)

    -- Editable Multi-Line Text Area
    self.AddSpellFrame.SpellDescriptionBox = CreateFrame("EditBox", nil, self.AddSpellFrame.SpellDescriptionScroll, "BackdropTemplate")
    self.AddSpellFrame.SpellDescriptionBox:SetMultiLine(true)
    self.AddSpellFrame.SpellDescriptionBox:SetSize(350, 100)
    self.AddSpellFrame.SpellDescriptionBox:SetAutoFocus(false)
    self.AddSpellFrame.SpellDescriptionBox:SetTextInsets(5, 5, 5, 5)
    self.AddSpellFrame.SpellDescriptionBox:SetFontObject(GameFontNormal)
    self.AddSpellFrame.SpellDescriptionBox:SetJustifyH("LEFT")
    self.AddSpellFrame.SpellDescriptionBox:SetJustifyV("TOP")
    self.AddSpellFrame.SpellDescriptionBox:SetText(spell.Description or "No Description Available")

    -- Enable Scrolling
    self.AddSpellFrame.SpellDescriptionScroll:SetScrollChild(self.AddSpellFrame.SpellDescriptionBox)

    -- Prevent Auto-Focus when opening the window
    self.AddSpellFrame.SpellDescriptionBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    ----- ACTION COST
    -- Action Cost Label
    self.AddSpellFrame.ActionCostLabel = self.AddSpellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddSpellFrame.ActionCostLabel:SetPoint("TOPLEFT", self.AddSpellFrame.SpellDescriptionScroll, "BOTTOMLEFT", 5, -10)
    self.AddSpellFrame.ActionCostLabel:SetText("Action Cost")

    
    -- Action Cost Dropdown
    local selectedActionCost = spell.ActionCost

    self.AddSpellFrame.ActionCostDropdown = CreateFrame("Frame", "ActionCostDropdown", self.AddSpellFrame, "UIDropDownMenuTemplate")
    self.AddSpellFrame.ActionCostDropdown:SetPoint("TOPLEFT", self.AddSpellFrame.ActionCostLabel, "TOPLEFT", 100, 5)

    local actionCosts = { "Action", "Bonus Action", "Reaction", "Free Action" }
    local actionDropdown = self.AddSpellFrame.ActionCostDropdown
    local function OnActionCostSelected(self, value)
        spell.ActionCost = value
        selectedActionCost = value
        UIDropDownMenu_SetText(actionDropdown, value)
    end

    UIDropDownMenu_Initialize(self.AddSpellFrame.ActionCostDropdown, function(self, level, menuList)
        for _, cost in ipairs(actionCosts) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = cost
            info.func = function() OnActionCostSelected(self, cost) end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(self.AddSpellFrame.ActionCostDropdown, spell.ActionCost or "None")

    ----- Cast Time
    -- Action Cost Label
    self.AddSpellFrame.CastTimeLabel = self.AddSpellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddSpellFrame.CastTimeLabel:SetPoint("TOPLEFT", self.AddSpellFrame.ActionCostLabel, "BOTTOMLEFT", 0, -20)
    self.AddSpellFrame.CastTimeLabel:SetText("Cast Time")

    -- Action Cost Dropdown
    local selectedCastTime = spell.CastTime
    self.AddSpellFrame.CastTimeDropdown = CreateFrame("Frame", "CastTimeDropdown", self.AddSpellFrame, "UIDropDownMenuTemplate")
    self.AddSpellFrame.CastTimeDropdown:SetPoint("TOPLEFT", self.AddSpellFrame.CastTimeLabel, "TOPLEFT", 100, 5)

    local castTimes = { "Instant", "1 turn cast", "Channelled" }
    local actionDropdown = self.AddSpellFrame.CastTimeDropdown
    local function OnCastTimeSelected(self, value)
        spell.CastTime = value
        selectedCastTime = value
        UIDropDownMenu_SetText(actionDropdown, value)
    end

    UIDropDownMenu_Initialize(self.AddSpellFrame.CastTimeDropdown, function(self, level, menuList)
        for _, cost in ipairs(castTimes) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = cost
            info.func = function() OnCastTimeSelected(self, cost) end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(self.AddSpellFrame.CastTimeDropdown, spell.CastTime or "None")

    -- Spell Type
    -- Spell Type Label
    self.AddSpellFrame.TypeLabel = self.AddSpellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddSpellFrame.TypeLabel:SetPoint("TOPLEFT", self.AddSpellFrame.CastTimeLabel, "BOTTOMLEFT", 0, -20)
    self.AddSpellFrame.TypeLabel:SetText("Spell Type")

    local selectedType = spell.Type

    self.AddSpellFrame.TypeDropdown = CreateFrame("Frame", "TypeDropdown", self.AddSpellFrame, "UIDropDownMenuTemplate")
    self.AddSpellFrame.TypeDropdown:SetPoint("TOPLEFT", self.AddSpellFrame.TypeLabel, "TOPLEFT", 100, 5)

    local types = { "General", "Statistic", "WeaponDamage", "SpellDamage", "HealTarget", "HealSelf", "Script" }
    local actionDropdown = self.AddSpellFrame.TypeDropdown
    local function OnTypeSelected(self, value)
        spell.Type = value
        selectedType = value
        UIDropDownMenu_SetText(actionDropdown, value)

        -- Dynamically update UI fields based on spell type
        CampaignManager:UpdateSpellTypeFields(spell)
    end

    UIDropDownMenu_Initialize(self.AddSpellFrame.TypeDropdown, function(self, level, menuList)
        for _, cost in ipairs(types) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = cost
            info.func = function() OnTypeSelected(self, cost) end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(self.AddSpellFrame.TypeDropdown, spell.Type or "None")

    ---- MANA COST ----
    self.AddSpellFrame.ManaCostLabel = self.AddSpellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddSpellFrame.ManaCostLabel:SetPoint("TOPLEFT", self.AddSpellFrame.TypeLabel, "BOTTOMLEFT", 0, -20)
    self.AddSpellFrame.ManaCostLabel:SetText("Mana Cost")

    self.AddSpellFrame.ManaCostBox = CreateFrame("EditBox", nil, self.AddSpellFrame, "InputBoxTemplate")
    self.AddSpellFrame.ManaCostBox:SetSize(120, 30)
    self.AddSpellFrame.ManaCostBox:SetPoint("TOPLEFT", self.AddSpellFrame.ManaCostLabel, "TOPLEFT", 125, 5)
    self.AddSpellFrame.ManaCostBox:SetAutoFocus(false)
    self.AddSpellFrame.ManaCostBox:SetText(spell.ManaCost or "0")

    ---- MESSAGE ----
    self.AddSpellFrame.MessageLabel = self.AddSpellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddSpellFrame.MessageLabel:SetPoint("TOPLEFT", self.AddSpellFrame.ManaCostLabel, "BOTTOMLEFT", 0, -20)
    self.AddSpellFrame.MessageLabel:SetText("On-Use Message")

    self.AddSpellFrame.MessageBox = CreateFrame("EditBox", nil, self.AddSpellFrame, "InputBoxTemplate")
    self.AddSpellFrame.MessageBox:SetSize(180, 30)
    self.AddSpellFrame.MessageBox:SetPoint("TOPLEFT", self.AddSpellFrame.MessageLabel, "TOPLEFT", 125, 5)
    self.AddSpellFrame.MessageBox:SetAutoFocus(false)
    self.AddSpellFrame.MessageBox:SetText(spell.Message)

    -- Auras Multi-Selection Dropdown
    self.AddSpellFrame.AuraDropdownLabel = self.AddSpellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddSpellFrame.AuraDropdownLabel:SetPoint("TOPLEFT", self.AddSpellFrame.MessageLabel, "BOTTOMLEFT", 0, -20)
    self.AddSpellFrame.AuraDropdownLabel:SetText("Apply Auras")

    self.AddSpellFrame.AuraDropdown = CreateFrame("Frame", "AuraDropdown", self.AddSpellFrame, "UIDropDownMenuTemplate")
    self.AddSpellFrame.AuraDropdown:SetPoint("TOPLEFT", self.AddSpellFrame.AuraDropdownLabel, "TOPLEFT", 100, 5)

    local selectedAuras = spell.Auras or {}

    local function UpdateAuraDropdownText()
        if #selectedAuras == 0 then
            UIDropDownMenu_SetText(self.AddSpellFrame.AuraDropdown, "None")
        else
            UIDropDownMenu_SetText(self.AddSpellFrame.AuraDropdown, string.format("%s Auras", #selectedAuras))
        end
    end

    local function ToggleAuraSelection(value)
        local found = false
        for i, selected in ipairs(selectedAuras) do
            if selected == value then
                table.remove(selectedAuras, i)
                found = true
                break
            end
        end
        if not found then
            table.insert(selectedAuras, value)
        end
        spell.Auras = selectedAuras
        UpdateAuraDropdownText()
    end

    UIDropDownMenu_Initialize(self.AddSpellFrame.AuraDropdown, function(self, level, menuList)
        local auraList = _G.Campaigns[CampaignManager.SelectedCampaign].AuraList or {}

        for _, aura in ipairs(auraList) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = aura.Name
            info.isNotRadio = true  -- Allow multi-selection
            info.keepShownOnClick = true
            info.checked = false

            for _, selected in ipairs(selectedAuras) do
                if selected == aura.Guid then
                    info.checked = true
                    break
                end
            end

            info.func = function()
                ToggleAuraSelection(aura.Guid)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UpdateAuraDropdownText()

    ---- CUSTOM FUNCTION ----
    self.AddSpellFrame.ScriptLabel = self.AddSpellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddSpellFrame.ScriptLabel:SetPoint("TOPLEFT", self.AddSpellFrame.AuraDropdownLabel, "BOTTOMLEFT", 0, -20)
    self.AddSpellFrame.ScriptLabel:SetText("Custom Function")

    self.AddSpellFrame.ScriptBox = CreateFrame("EditBox", nil, self.AddSpellFrame, "InputBoxTemplate")
    self.AddSpellFrame.ScriptBox:SetSize(180, 30)
    self.AddSpellFrame.ScriptBox:SetPoint("TOPLEFT", self.AddSpellFrame.ScriptLabel, "TOPLEFT", 125, 5)
    self.AddSpellFrame.ScriptBox:SetAutoFocus(false)
    self.AddSpellFrame.ScriptBox:SetText(spell.ScriptId or "")

    -- Requires Label
    self.AddSpellFrame.RequiresLabel = self.AddSpellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddSpellFrame.RequiresLabel:SetPoint("TOPLEFT", self.AddSpellFrame.ScriptLabel, "BOTTOMLEFT", 0, -20)
    self.AddSpellFrame.RequiresLabel:SetText("Requires")

    -- Multi-selection dropdown setup
    local requiresOptions = { 
        "MAIN_HAND", 
        "OFF_HAND", 
        "TARGET_ENEMY", 
        "TARGET_ALLY", 
        "NOT_SELF" 
    }

    local requiresDropdown = CreateFrame("Frame", "RequiresDropdown", self.AddSpellFrame, "UIDropDownMenuTemplate")
    requiresDropdown:SetPoint("TOPLEFT", self.AddSpellFrame.RequiresLabel, "TOPLEFT", 100, 5)
    self.AddSpellFrame.RequiresDropdown = requiresDropdown

    local selectedRequires = type(spell.Requires) == "table" and spell.Requires or {}

    local function UpdateDropdownText()
        local numSelected = #selectedRequires
        local selectedText = numSelected > 0 and (numSelected .. " Requirements") or "None"
        UIDropDownMenu_SetText(requiresDropdown, selectedText)
    end


    local function ToggleSelection(value)
        -- Check if the value is already selected
        local foundIndex = nil
        for i, v in ipairs(selectedRequires) do
            if v == value then
                foundIndex = i
                break
            end
        end

        if foundIndex then
            -- Remove from selection
            table.remove(selectedRequires, foundIndex)
        else
            -- Add to selection
            table.insert(selectedRequires, value)
        end

        -- Update spell.Requires and dropdown text
        spell.Requires = selectedRequires
        UpdateDropdownText()
    end

    UIDropDownMenu_Initialize(requiresDropdown, function(self, level, menuList)
        for _, option in ipairs(requiresOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.keepShownOnClick = true  -- Keeps the dropdown open for multi-selection
            info.isNotRadio = true  -- Allow checkbox-style selection
            info.func = function()
                ToggleSelection(option)
            end

            -- Check if this option is selected
            info.checked = false
            for _, selected in ipairs(selectedRequires) do
                if selected == option then
                    info.checked = true
                    break
                end
            end

            UIDropDownMenu_AddButton(info)
        end
    end)

    -- Initialize the dropdown with selected values
    UpdateDropdownText()


    -- SPELL-SPECIFIC ATTRIBUTES
    CampaignManager:UpdateSpellTypeFields(spell)

    -- Save Button
    self.AddSpellFrame.SaveButton = CreateFrame("Button", nil, self.AddSpellFrame, "UIPanelButtonTemplate")
    self.AddSpellFrame.SaveButton:SetSize(120, 25)
    self.AddSpellFrame.SaveButton:SetPoint("BOTTOMLEFT", self.AddSpellFrame, "BOTTOMLEFT", 0, 10)
    self.AddSpellFrame.SaveButton:SetText("Save Changes")

    -- Save Button Functionality
    self.AddSpellFrame.SaveButton:SetScript("OnClick", function()
        -- Ensure the spell has a GUID (if new)
        if not spell.Guid then
            spell.Guid = "SPELL-" .. math.random(100000, 999999)  -- Generate a random GUID
        end

        -- Get the selected campaign
        local campaign = _G.Campaigns[CampaignManager.SelectedCampaign]
        if not campaign then
            print("❌ Error: No selected campaign found!")
            return
        end

        -- Ensure the campaign has a spell list
        campaign.SpellList = campaign.SpellList or {}

        -- Convert HitModifiers, DamageModifiers, and CritModifiers to Internal Keys
        local function ConvertModifiers(modifierList)
            local converted = {}
            for _, mod in ipairs(modifierList or {}) do
                local internalKey = STAT_TOOLTIP_REVERSE[mod] or mod  -- Convert to key format or leave as-is
                table.insert(converted, internalKey)
            end
            return converted
        end

        spell.HitModifiers = ConvertModifiers(spell.HitModifiers)
        spell.DamageModifiers = ConvertModifiers(spell.DamageModifiers)
        spell.CritModifiers = ConvertModifiers(spell.CritModifiers)

        spell.Name = self.AddSpellFrame.SpellNameBox:GetText()
        spell.Description = self.AddSpellFrame.SpellDescriptionBox:GetText()
        spell.ManaCost = self.AddSpellFrame.ManaCostBox:GetText()
        spell.Message = self.AddSpellFrame.MessageBox:GetText()
        spell.ScriptId = self.AddSpellFrame.ScriptBox:GetText()

        if self.AddSpellFrame.DiceToHitBox then
            spell.DiceToHit = self.AddSpellFrame.DiceToHitBox:GetText() or "1d20"
        else
            spell.DiceToHit = "1d20"
        end
        
        if self.AddSpellFrame.DiceToDamageBox then
            spell.DiceToDamage = self.AddSpellFrame.DiceToDamageBox:GetText() or "1d8"
        else
            spell.DiceToDamage = "1d8"
        end

        -- Check if the spell already exists in the spell list
        local spellExists = false
        for i, existingSpell in ipairs(campaign.SpellList) do
            if existingSpell.Guid == spell.Guid then
                -- Overwrite existing spell data
                campaign.SpellList[i] = spell
                spellExists = true
                print(string.format("✅ Spell Updated: %s", spell.Name))
                break
            end
        end

        -- If spell does not exist, add it to the list
        if not spellExists then
            table.insert(campaign.SpellList, spell)
            print(string.format("✅ New Spell Added: %s", spell.Name))
        end

        -- Save changes and refresh UI
        CTCampaign:SaveCampaign(CampaignManager.SelectedCampaign)
        CampaignManager:PopulateCampaignSpellList(CampaignManager.SelectedCampaign)

        -- Close the spell creation window
        self.AddSpellFrame:Hide()
    end)

    -- Show the window
    self.AddSpellFrame:Show()
end

function CampaignManager:CreateMultiSelectDropdown(parent, label, point, selectedValues, categories, onSelect, offset)
    -- Label
    local dropdownLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownLabel:SetPoint("TOPLEFT", point, "BOTTOMLEFT", 0, offset)
    dropdownLabel:SetText(label)
    table.insert(parent.DynamicFields, dropdownLabel)


    -- Dropdown Frame
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", dropdownLabel, "TOPLEFT", 100, 5)

    -- Function to Update Dropdown Text
    local function UpdateDropdownText()
        if #selectedValues == 0 then
            UIDropDownMenu_SetText(dropdown, "None")
        else
            UIDropDownMenu_SetText(dropdown, string.format("%s selected", #selectedValues))
        end
    end

    -- Function to Toggle Selection
    local function ToggleSelection(value)
        local found = false
        for i, selected in ipairs(selectedValues) do
            if selected == value then
                table.remove(selectedValues, i)
                found = true
                break
            end
        end
        if not found then
            table.insert(selectedValues, value)
        end
        onSelect(selectedValues) -- Callback function to update external data
        UpdateDropdownText()
    end

    -- Initialize Dropdown with Submenus
    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        if level == 1 then
            -- First Level: Show Categories
            for category, _ in pairs(categories) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = category
                info.hasArrow = true
                info.notCheckable = true
                info.menuList = category
                UIDropDownMenu_AddButton(info, level)
            end
        elseif menuList then
            -- Second Level: Show Modifiers under Each Category
            for _, value in ipairs(categories[menuList]) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = value
                info.isNotRadio = true
                info.keepShownOnClick = true
                info.checked = false
                for _, selected in ipairs(selectedValues) do
                    if selected == value then
                        info.checked = true
                        break
                    end
                end
                info.func = function()
                    ToggleSelection(value)
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end)

    -- Set Initial Dropdown Text
    UpdateDropdownText()

    return dropdown
end

function CampaignManager:UpdateSpellTypeFields(spell)
    -- Ensure the frame exists
    if not self.AddSpellFrame then return end

    -- Fully Remove Any Existing Dynamic Fields
    if self.AddSpellFrame.DynamicFields then
        for _, field in ipairs(self.AddSpellFrame.DynamicFields) do
            field:Hide()               -- Hide UI Element
            field:ClearAllPoints()     -- Remove Anchors
            field:SetParent(nil)       -- Remove from Parent
        end
    end

    -- Reset the DynamicFields table
    self.AddSpellFrame.DynamicFields = {}

    local lastElement = self.AddSpellFrame.RequiresLabel -- Start placement below TypeDropdown
    local yOffset = -20

    -- Create a helper function to add new fields
    local function CreateInputField(label, value, width)
        local labelFrame = self.AddSpellFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        labelFrame:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 0, yOffset)
        labelFrame:SetText(label)

        local inputBox = CreateFrame("EditBox", nil, self.AddSpellFrame, "InputBoxTemplate")
        inputBox:SetSize(width or 120, 30)
        inputBox:SetPoint("TOPLEFT", labelFrame, "TOPLEFT", 125, 5)
        inputBox:SetAutoFocus(false)
        inputBox:SetText(value or "")

        table.insert(self.AddSpellFrame.DynamicFields, labelFrame)
        table.insert(self.AddSpellFrame.DynamicFields, inputBox)

        lastElement = labelFrame
        yOffset = -20

        return inputBox
    end

    local spellType = spell.Type
    print(spellType)
    -- Generate fields based on spell type
    if spellType == "SpellDamage" then
        spell.DiceToHit = "1d20"

        self.AddSpellFrame.DiceToDamageBox = CreateInputField("Damage Dice", spell.DiceToDamage, 100)
        self.AddSpellFrame.DiceToDamageBox:SetText(spell.DiceToDamage or "1d8")
        self.AddSpellFrame.DiceToDamageBox:SetSize(60, 20)


        -- Spell School
        local selectedSchool = spell.School

        self.AddSpellFrame.SchoolDropdown = CreateFrame("Frame", "SchoolDropdown", self.AddSpellFrame, "UIDropDownMenuTemplate")
        self.AddSpellFrame.SchoolDropdown:SetPoint("TOPLEFT", self.AddSpellFrame.DiceToDamageBox, "TOPLEFT", 80, 2)

        local schools = { "Physical", "Fire", "Frost", "Nature", "Arcane", "Fel", "Shadow", "Holy" }
        local actionDropdown = self.AddSpellFrame.SchoolDropdown
        local function OnSchoolSelected(self, value)
            spell.School = value
            selectedSchool = value
            UIDropDownMenu_SetText(actionDropdown, value)
        end

        UIDropDownMenu_Initialize(self.AddSpellFrame.SchoolDropdown, function(self, level, menuList)
            for _, cost in ipairs(schools) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = cost
                info.func = function() OnSchoolSelected(self, cost) end
                UIDropDownMenu_AddButton(info)
            end
        end)

        UIDropDownMenu_SetText(self.AddSpellFrame.SchoolDropdown, spell.School or "Physical")

        -- Hit modifier dropdown.
        self.AddSpellFrame.HitModifiersDropdown = self:CreateMultiSelectDropdown(
            self.AddSpellFrame, "Hit Modifiers", lastElement, spell.HitModifiers or {}, modifierCategories,
            function(selectedValues) spell.HitModifiers = selectedValues end, -20)
        table.insert(self.AddSpellFrame.DynamicFields, self.AddSpellFrame.HitModifiersDropdown)

        -- Damagge modifier dropdown.
        self.AddSpellFrame.DamageModifiersDropdown = self:CreateMultiSelectDropdown(
            self.AddSpellFrame, "Damage Modifiers", lastElement, spell.DamageModifiers or {}, modifierCategories,
            function(selectedValues) spell.DamageModifiers = selectedValues end, -50)
        table.insert(self.AddSpellFrame.DynamicFields, self.AddSpellFrame.DamageModifiersDropdown)

        -- Crit modifier dropdown.
        self.AddSpellFrame.CritModifiersDropdown = self:CreateMultiSelectDropdown(
            self.AddSpellFrame, "Crit Modifiers", lastElement, spell.CritModifiers or {}, modifierCategories,
            function(selectedValues) spell.CritModifiers = selectedValues end, -80)
        table.insert(self.AddSpellFrame.DynamicFields, self.AddSpellFrame.CritModifiersDropdown)
    elseif spellType == "WeaponDamage" then
        spell.DiceToHit = "1d20"

        -- Main / Off / Both dropdown

        -- Hit modifier dropdown.
        self.AddSpellFrame.HitModifiersDropdown = self:CreateMultiSelectDropdown(
            self.AddSpellFrame, "Hit Modifiers", lastElement, spell.HitModifiers or {}, modifierCategories,
            function(selectedValues) spell.HitModifiers = selectedValues end, -20)
        table.insert(self.AddSpellFrame.DynamicFields, self.AddSpellFrame.HitModifiersDropdown)

        -- Damagge modifier dropdown.
        self.AddSpellFrame.DamageModifiersDropdown = self:CreateMultiSelectDropdown(
            self.AddSpellFrame, "Damage Modifiers", lastElement, spell.DamageModifiers or {}, modifierCategories,
            function(selectedValues) spell.DamageModifiers = selectedValues end, -50)
        table.insert(self.AddSpellFrame.DynamicFields, self.AddSpellFrame.DamageModifiersDropdown)

        -- Crit modifier dropdown.
        self.AddSpellFrame.CritModifiersDropdown = self:CreateMultiSelectDropdown(
            self.AddSpellFrame, "Crit Modifiers", lastElement, spell.CritModifiers or {}, modifierCategories,
            function(selectedValues) spell.CritModifiers = selectedValues end, -80)
        table.insert(self.AddSpellFrame.DynamicFields, self.AddSpellFrame.CritModifiersDropdown)

    elseif spell.Type == "Statistic" then
        -- Automatically set the dice to roll to 1d20.
        spell.DiceToHit = "1d20"

        -- Skill modifier dropdown.
        self.AddSpellFrame.HitModifiersDropdown = self:CreateMultiSelectDropdown(
            self.AddSpellFrame, "Skill Modifiers:", lastElement, spell.HitModifiers or {}, modifierCategories,
            function(selectedValues) spell.HitModifiers = selectedValues end, -20)

        table.insert(self.AddSpellFrame.DynamicFields, self.AddSpellFrame.HitModifiersDropdown)

    elseif spell.Type == "Heal" then
        self.AddSpellFrame.HealDiceBox = CreateInputField("Healing Dice", spell.DiceToDamage, 100)
    end
end

--== AURAS ==--
function CampaignManager:CreateAuraFrame(parentFrame)
    parentFrame.AuraList = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    parentFrame.AuraList:SetSize(750, 320)
    parentFrame.AuraList:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, 0)

    -- Define grid layout for aura slots
    local SLOT_SIZE, SLOT_PADDING, COLUMNS, ROWS = 48, -16, 14, 5
    local TOTAL_SLOTS = COLUMNS * ROWS
    local startX, startY = 10, -20

    parentFrame.AuraSlots = {}

    -- Create Aura Slots
    for i = 1, TOTAL_SLOTS do
        local slot = CreateFrame("Button", nil, parentFrame.AuraList, "BackdropTemplate")
        slot:SetSize(SLOT_SIZE, SLOT_SIZE)

        local row, col = math.floor((i - 1) / COLUMNS), (i - 1) % COLUMNS
        slot:SetPoint("TOPLEFT", parentFrame.AuraList, "TOPLEFT", startX + (col * (SLOT_SIZE + SLOT_PADDING)), startY - (row * (SLOT_SIZE + SLOT_PADDING)))

        -- Background texture
        slot.texture = slot:CreateTexture(nil, "BACKGROUND")
        slot.texture:SetAllPoints(slot)
        slot.texture:SetTexture("Interface\\Buttons\\UI-EmptySlot")

        -- Aura icon placeholder
        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetSize(SLOT_SIZE - 24, SLOT_SIZE - 24)
        slot.icon:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        slot.icon:Hide()

        slot.aura = nil

        -- Tooltip on hover (Replace existing `OnEnter` script)
        slot:SetScript("OnEnter", function(self)
            if self.aura then
                CTAura:ShowTooltip(self.aura, self)  -- Use the custom tooltip from CTAura.lua
            end
        end)

        slot:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- Right-click to remove aura from campaign
        slot:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                if self.aura then
                    -- Open the edit UI for an existing aura
                    CampaignManager:AddAuraWindow(self.aura)
                else
                    -- Open the aura creation UI with a blank template
                    local newAura = {
                        Name = "New Aura",
                        Description = "Enter a description here.",
                        Type = "Buff",
                        Icon = "Interface/ICONS/INV_Misc_QuestionMark",
                        TriggerOn = "Tick",
                        RemainingTurns = "3",
                        Effects = {}
                    }
                    CampaignManager:AddAuraWindow(newAura)
                end
            elseif button == "RightButton" and self.aura then
                print(string.format("Removed aura: %s from campaign", self.aura.Name))
                CampaignManager:RemoveAuraFromCampaign(parentFrame.SelectedCampaign, self.aura.Guid)
                CampaignManager:PopulateCampaignAuraList(parentFrame.SelectedCampaign) -- Refresh UI
            end
        end)


        table.insert(parentFrame.AuraSlots, slot)
    end
end

function CampaignManager:RemoveAuraFromCampaign(guid, auraGuid)
    print(guid)

    print("Attempting to remove aura from campaign...")
    local campaign = _G.Campaigns[guid]
    if not campaign then return end

    print("... found campaign")


    for index, aura in ipairs(campaign.AuraList) do
        if aura.Guid == auraGuid then
            print("Removing " ..aura.Name)
            table.remove(campaign.AuraList, index)
            CTCampaign:SaveCampaign(guid) -- Save changes
            return
        end
    end
end

function CampaignManager:PopulateCampaignAuraList(guid)
    local campaign = _G.Campaigns[guid] -- Retrieve the loaded campaign
    if not campaign then return end


    -- Ensure the 'Spells' tab UI exists
    if not CampaignManagerFrame.Auras then
        CampaignManagerFrame.Auras = CreateFrame("Frame", nil, CampaignManagerFrame.TabFrames[3])
        CampaignManagerFrame.Auras:SetSize(780, 340)
        CampaignManagerFrame.Auras:SetPoint("TOPLEFT", 10, -10)

        CampaignManagerFrame.Auras.SelectedCampaign = guid

        -- Spell List Label
        CampaignManagerFrame.Auras.NameEditLabel = CampaignManagerFrame.Auras:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        CampaignManagerFrame.Auras.NameEditLabel:SetPoint("TOPLEFT", CampaignManagerFrame.Auras, "TOPLEFT", 10, 0)
        CampaignManagerFrame.Auras.NameEditLabel:SetText("Aura List")

        -- Create the Spell Grid
        CampaignManager:CreateAuraFrame(CampaignManagerFrame.Auras)
    end

    -- Clear all existing spell slots
    for _, slot in ipairs(CampaignManagerFrame.Auras.AuraSlots) do
        slot.icon:Hide()
        slot.aura = nil
    end

    -- Populate slots with spells
    for i, aura in ipairs(campaign.AuraList or {}) do
        local slot = CampaignManagerFrame.Auras.AuraSlots[i]
        if slot then
            slot.aura = aura
            slot.icon:SetTexture(aura.Icon)
            slot.icon:Show()
        end
    end
end

function CampaignManager:AddAuraWindow(aura)
    -- Prevent duplicate windows
    if self.AddAuraFrame then
        self.AddAuraFrame:Hide()
    end

    -- Create the Main Frame
    self.AddAuraFrame = CreateFrame("Frame", "AddAuraFrame", UIParent, "BackdropTemplate")
    self.AddAuraFrame:SetSize(400, 600)
    self.AddAuraFrame:SetPoint("TOPLEFT", CampaignManagerFrame, "TOPRIGHT", -10, 0)  -- Positioned to the right of CampaignManager
    self.AddAuraFrame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    self.AddAuraFrame:SetMovable(true)
    self.AddAuraFrame:EnableMouse(true)
    self.AddAuraFrame:RegisterForDrag("LeftButton")
    self.AddAuraFrame:SetScript("OnDragStart", self.AddAuraFrame.StartMoving)
    self.AddAuraFrame:SetScript("OnDragStop", self.AddAuraFrame.StopMovingOrSizing)

    -- Close Button
    self.AddAuraFrame.CloseButton = CreateFrame("Button", nil, self.AddAuraFrame, "UIPanelCloseButton")
    self.AddAuraFrame.CloseButton:SetPoint("TOPRIGHT", self.AddAuraFrame, "TOPRIGHT", -5, -5)
    self.AddAuraFrame.CloseButton:SetScript("OnClick", function()
        self.AddAuraFrame:Hide()
    end)

    -- Aura Icon Button (Clickable)
    self.AddAuraFrame.IconButton = CreateFrame("Button", nil, self.AddAuraFrame)
    self.AddAuraFrame.IconButton:SetSize(32, 32)
    self.AddAuraFrame.IconButton:SetPoint("TOPLEFT", self.AddAuraFrame, "TOPLEFT", 10, -10)

    -- Aura Icon Texture Inside Button
    self.AddAuraFrame.Icon = self.AddAuraFrame.IconButton:CreateTexture(nil, "ARTWORK")
    self.AddAuraFrame.Icon:SetAllPoints(self.AddAuraFrame.IconButton)
    self.AddAuraFrame.Icon:SetTexture(aura.Icon or "Interface/ICONS/INV_Misc_QuestionMark")

    -- Left-Click to Change Icon
    self.AddAuraFrame.IconButton:SetScript("OnClick", function()
        StaticPopupDialogs["CHANGE_AURA_ICON"] = {
            text = "Enter the new icon path:",
            button1 = "OK",
            button2 = "Cancel",
            hasEditBox = true,
            OnAccept = function(self)
                local newIcon = string.format("interface/icons/%s", self.editBox:GetText())
                if newIcon and newIcon ~= "" then
                    aura.Icon = newIcon
                    CampaignManager.AddAuraFrame.Icon:SetTexture(newIcon) -- Update UI Immediately
                end
            end,
            EditBoxOnEnterPressed = function(self)
                local newIcon = string.format("interface/icons/%s", self:GetParent().editBox:GetText())
                if newIcon and newIcon ~= "" then
                    aura.Icon = newIcon
                    CampaignManager.AddAuraFrame.Icon:SetTexture(newIcon) -- Update UI Immediately
                    self:GetParent():Hide()
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("CHANGE_AURA_ICON")
    end)

    -- Aura Name EditBox
    self.AddAuraFrame.AuraNameBox = CreateFrame("EditBox", nil, self.AddAuraFrame, "InputBoxTemplate")
    self.AddAuraFrame.AuraNameBox:SetSize(200, 30)
    self.AddAuraFrame.AuraNameBox:SetPoint("TOPLEFT", self.AddAuraFrame.Icon, "TOPRIGHT", 10, 0)
    self.AddAuraFrame.AuraNameBox:SetAutoFocus(false)
    self.AddAuraFrame.AuraNameBox:SetText(aura.Name or "Unknown Aura")

    -- Save Button
    self.AddAuraFrame.SaveButton = CreateFrame("Button", nil, self.AddAuraFrame, "UIPanelButtonTemplate")
    self.AddAuraFrame.SaveButton:SetSize(120, 25)
    self.AddAuraFrame.SaveButton:SetPoint("BOTTOMLEFT", self.AddAuraFrame, "BOTTOMLEFT", 0, 10)
    self.AddAuraFrame.SaveButton:SetText("Save Changes")

    -- Scroll Frame for the Text Area
    -- Aura Description Label
    self.AddAuraFrame.AuraDescriptionLabel = self.AddAuraFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddAuraFrame.AuraDescriptionLabel:SetPoint("TOPLEFT", self.AddAuraFrame.Icon, "BOTTOMLEFT", 15, -20)
    self.AddAuraFrame.AuraDescriptionLabel:SetText("Description:")

    self.AddAuraFrame.AuraDescriptionScroll = CreateFrame("ScrollFrame", nil, self.AddAuraFrame, "UIPanelScrollFrameTemplate, BackdropTemplate")
    self.AddAuraFrame.AuraDescriptionScroll:SetSize(340, 80)
    self.AddAuraFrame.AuraDescriptionScroll:SetPoint("TOPLEFT", self.AddAuraFrame.AuraDescriptionLabel, "BOTTOMLEFT", 0, -5)
    self.AddAuraFrame.AuraDescriptionScroll:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    self.AddAuraFrame.AuraDescriptionScroll:SetBackdropColor(0, 0, 0, 0.8)

    -- Editable Multi-Line Text Area
    self.AddAuraFrame.AuraDescriptionBox = CreateFrame("EditBox", nil, self.AddAuraFrame.AuraDescriptionScroll, "BackdropTemplate")
    self.AddAuraFrame.AuraDescriptionBox:SetMultiLine(true)
    self.AddAuraFrame.AuraDescriptionBox:SetSize(350, 100)
    self.AddAuraFrame.AuraDescriptionBox:SetAutoFocus(false)
    self.AddAuraFrame.AuraDescriptionBox:SetTextInsets(5, 5, 5, 5)
    self.AddAuraFrame.AuraDescriptionBox:SetFontObject(GameFontNormal)
    self.AddAuraFrame.AuraDescriptionBox:SetJustifyH("LEFT")
    self.AddAuraFrame.AuraDescriptionBox:SetJustifyV("TOP")
    self.AddAuraFrame.AuraDescriptionBox:SetText(aura.Description or "No Description Available")

    -- Enable Scrolling
    self.AddAuraFrame.AuraDescriptionScroll:SetScrollChild(self.AddAuraFrame.AuraDescriptionBox)

    -- Prevent Auto-Focus when opening the window
    self.AddAuraFrame.AuraDescriptionBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    -- Aura Type
    -- Aura Type Label
    self.AddAuraFrame.TypeLabel = self.AddAuraFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddAuraFrame.TypeLabel:SetPoint("TOPLEFT", self.AddAuraFrame.AuraDescriptionLabel, "BOTTOMLEFT", 0, -100)
    self.AddAuraFrame.TypeLabel:SetText("Aura Type")

    local selectedType = aura.Type

    self.AddAuraFrame.TypeDropdown = CreateFrame("Frame", "TypeDropdown", self.AddAuraFrame, "UIDropDownMenuTemplate")
    self.AddAuraFrame.TypeDropdown:SetPoint("TOPLEFT", self.AddAuraFrame.TypeLabel, "TOPLEFT", 100, 5)

    local types = { "Buff", "Debuff" }
    local actionDropdown = self.AddAuraFrame.TypeDropdown
    local function OnTypeSelected(self, value)
        aura.Type = value
        selectedType = value
        UIDropDownMenu_SetText(actionDropdown, value)
    end

    UIDropDownMenu_Initialize(self.AddAuraFrame.TypeDropdown, function(self, level, menuList)
        for _, cost in ipairs(types) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = cost
            info.func = function() OnTypeSelected(self, cost) end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(self.AddAuraFrame.TypeDropdown, aura.Type or "None")

    -- Aura TriggerOn
    -- Aura TriggerOn Label
    self.AddAuraFrame.TriggerOnLabel = self.AddAuraFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddAuraFrame.TriggerOnLabel:SetPoint("TOPLEFT", self.AddAuraFrame.TypeLabel, "BOTTOMLEFT", 0, -20)
    self.AddAuraFrame.TriggerOnLabel:SetText("Aura TriggerOn")

    local selectedTriggerOn = aura.TriggerOn

    self.AddAuraFrame.TriggerOnDropdown = CreateFrame("Frame", "TriggerOnDropdown", self.AddAuraFrame, "UIDropDownMenuTemplate")
    self.AddAuraFrame.TriggerOnDropdown:SetPoint("TOPLEFT", self.AddAuraFrame.TriggerOnLabel, "TOPLEFT", 100, 5)

    local triggerons = { "Tick", "HitTarget", "CritTarget", "HealTarget", "HitSelf", "CritSelf", "HealSelf", "OnDeath" }
    local actionDropdown = self.AddAuraFrame.TriggerOnDropdown
    local function OnTriggerOnSelected(self, value)
        aura.TriggerOn = value
        selectedTriggerOn = value
        UIDropDownMenu_SetText(actionDropdown, value)
    end

    UIDropDownMenu_Initialize(self.AddAuraFrame.TriggerOnDropdown, function(self, level, menuList)
        for _, cost in ipairs(triggerons) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = cost
            info.func = function() OnTriggerOnSelected(self, cost) end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(self.AddAuraFrame.TriggerOnDropdown, aura.TriggerOn or "None")

    -- Aura Duration Label
    self.AddAuraFrame.AuraDurationLabel = self.AddAuraFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddAuraFrame.AuraDurationLabel:SetPoint("TOPLEFT", self.AddAuraFrame.TriggerOnLabel, "TOPLEFT", 0, -30)
    self.AddAuraFrame.AuraDurationLabel:SetText("Duration")

    -- Aura Duration EditBox
    self.AddAuraFrame.AuraDurationBox = CreateFrame("EditBox", nil, self.AddAuraFrame, "InputBoxTemplate")
    self.AddAuraFrame.AuraDurationBox:SetSize(100, 30)
    self.AddAuraFrame.AuraDurationBox:SetPoint("TOPLEFT", self.AddAuraFrame.AuraDurationLabel, "TOPLEFT", 125, 7)
    self.AddAuraFrame.AuraDurationBox:SetAutoFocus(false)
    self.AddAuraFrame.AuraDurationBox:SetText(aura.RemainingTurns or "1")

    -- Effects Label
    self.AddAuraFrame.EffectsLabel = self.AddAuraFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.AddAuraFrame.EffectsLabel:SetPoint("TOPLEFT", self.AddAuraFrame.AuraDurationLabel, "BOTTOMLEFT", 0, -20)
    self.AddAuraFrame.EffectsLabel:SetText("Effects")

    -- Scroll Frame for Effects List
    self.AddAuraFrame.EffectsScrollFrame = CreateFrame("ScrollFrame", nil, self.AddAuraFrame, "UIPanelScrollFrameTemplate")
    self.AddAuraFrame.EffectsScrollFrame:SetSize(340, 240)
    self.AddAuraFrame.EffectsScrollFrame:SetPoint("TOPLEFT", self.AddAuraFrame.EffectsLabel, "BOTTOMLEFT", 0, -5)

    -- Child Frame for Scroll
    self.AddAuraFrame.EffectsListFrame = CreateFrame("Frame", nil, self.AddAuraFrame.EffectsScrollFrame)
    self.AddAuraFrame.EffectsListFrame:SetSize(340, 240)
    self.AddAuraFrame.EffectsScrollFrame:SetScrollChild(self.AddAuraFrame.EffectsListFrame)

    -- Function to Refresh the Effects List
    local function RefreshEffectsList()
        -- Clear existing UI elements
        for _, effectEntry in ipairs(self.AddAuraFrame.EffectEntries or {}) do
            effectEntry:Hide()
        end
        self.AddAuraFrame.EffectEntries = {}

        -- Iterate through the effects
        for index, effect in ipairs(aura.Effects or {}) do
            local entry = CreateFrame("Frame", nil, self.AddAuraFrame.EffectsListFrame, "BackdropTemplate")
            entry:SetSize(380, 120) -- Increased height to fit new layout
            entry:SetPoint("TOPLEFT", self.AddAuraFrame.EffectsListFrame, "TOPLEFT", 5, -((index - 1) * 120))

            -- Background for hover effect (like campaign list)
            local bg = entry:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(entry)
            bg:SetColorTexture(0.1, 0.1, 0.1, 0)  -- Dark transparent background

            entry:SetScript("OnEnter", function()
                bg:SetColorTexture(0.2, 0.2, 0.2, 0.8) -- Highlight on hover
            end)
            entry:SetScript("OnLeave", function()
                bg:SetColorTexture(0.1, 0.1, 0.1, 0)
            end)

            -- **Row 1: Effect Type & Value**
            -- Effect Type Label
            local effectTypeLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            effectTypeLabel:SetPoint("TOPLEFT", entry, "TOPLEFT", 10, -5)
            effectTypeLabel:SetText("Effect Type")

            -- Effect Type Dropdown
            local effectTypeDropdown = CreateFrame("Frame", nil, entry, "UIDropDownMenuTemplate")
            effectTypeDropdown:SetPoint("TOPLEFT", effectTypeLabel, "TOPLEFT", 0, -20)

            local effectTypes = { "None", "Damage_Tick", "Healing_Tick", "Stat Modifier", "Script" }
            local function OnEffectTypeSelected(self, value)
                effect.Type = value
                UIDropDownMenu_SetText(effectTypeDropdown, value)
                RefreshEffectsList()
            end

            UIDropDownMenu_Initialize(effectTypeDropdown, function(self, level, menuList)
                for _, effectType in ipairs(effectTypes) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = effectType
                    info.func = function() OnEffectTypeSelected(self, effectType) end
                    UIDropDownMenu_AddButton(info)
                end
            end)
            UIDropDownMenu_SetText(effectTypeDropdown, effect.Type or "None")

            -- Value Label (Now Properly Aligned)
            local valueLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            valueLabel:SetPoint("TOPLEFT", effectTypeLabel, "TOPLEFT", 170, 0)
            valueLabel:SetText("Value")

            -- Value Input Box
            local valueBox = CreateFrame("EditBox", nil, entry, "InputBoxTemplate")
            valueBox:SetSize(100, 20)
            valueBox:SetPoint("TOPLEFT", valueLabel, "TOPLEFT", 5, -22)
            valueBox:SetAutoFocus(false)
            valueBox:SetText(effect.Value or "")
            valueBox:SetScript("OnTextChanged", function(self)
                effect.Value = self:GetText() or "0"
            end)

            -- **Row 2: Damage School & Condition**
            -- Damage School Label
            local schoolLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            schoolLabel:SetPoint("TOPLEFT", effectTypeDropdown, "BOTTOMLEFT", 0, -5)
            schoolLabel:SetText("Damage School")
            schoolLabel:Hide()

            -- Damage School Dropdown
            local schoolDropdown = CreateFrame("Frame", nil, entry, "UIDropDownMenuTemplate")
            schoolDropdown:SetPoint("TOPLEFT", schoolLabel, "TOPLEFT", 0, -20)
            schoolDropdown:Hide() -- Initially hidden

            local schools = { "Fire", "Frost", "Arcane", "Nature", "Shadow", "Holy", "Physical" }
            local function OnSchoolSelected(self, value)
                effect.School = value
                UIDropDownMenu_SetText(schoolDropdown, value)
            end

            UIDropDownMenu_Initialize(schoolDropdown, function(self, level, menuList)
                for _, school in ipairs(schools) do
                    local info = UIDropDownMenu_CreateInfo()
                    info.text = school
                    info.func = function() OnSchoolSelected(self, school) end
                    UIDropDownMenu_AddButton(info)
                end
            end)

            UIDropDownMenu_SetText(schoolDropdown, effect.School or "None")

            if effect.Type == "Damage_Tick" then
                schoolDropdown:Show()
                schoolLabel:Show()
            end

            -- Function to resolve the aura GUID to its name
            local function GetAuraNameFromGUID(guid)
                if not guid then return "None" end

                if guid == "Main Hand" or guid == "Off Hand" or guid == "Shield" then return guid end

                for _, campaign in pairs(_G.Campaigns or {}) do
                    if campaign.AuraList then
                        for _, aura in ipairs(campaign.AuraList) do
                            if aura.Guid == guid then
                                print("returning " ..aura.Name)
                                return aura.Name
                            end
                        end
                    end
                end
                return "None" -- Default if GUID is not found
            end

            -- Condition Label
            local conditionLabel = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            conditionLabel:SetPoint("TOPLEFT", schoolLabel, "TOPLEFT", 170, 0)
            conditionLabel:SetText("Requires Effect")

            -- Condition Dropdown
            local conditionDropdown = CreateFrame("Frame", nil, entry, "UIDropDownMenuTemplate")
            conditionDropdown:SetPoint("TOPLEFT", conditionLabel, "TOPLEFT", -20, -20)

            local function OnConditionSelected(self, value, guid)
                if not effect then
                    print("❌ ERROR: Effect is nil, cannot save condition!")
                    return
                end

                effect.Condition = guid  -- Store GUID instead of Name
                print("✅ Condition Saved for Effect: ", effect.Type, " | GUID:", effect.Condition)
                UIDropDownMenu_SetText(conditionDropdown, GetAuraNameFromGUID(effect.Condition))
            end

            -- **Set Initial Text for Dropdown**
            UIDropDownMenu_SetText(conditionDropdown, GetAuraNameFromGUID(effect.Condition))
            print(GetAuraNameFromGUID(effect.Condition))

            -- Initialize Dropdown
            UIDropDownMenu_Initialize(conditionDropdown, function(self, level, menuList)
                if level == 1 then
                    -- Global Conditions (Always Available)
                    local globalConditions = { "Main Hand", "Off Hand", "Shield" }

                    for _, condition in ipairs(globalConditions) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = condition
                        info.func = function() OnConditionSelected(conditionDropdown, condition, condition) end
                        UIDropDownMenu_AddButton(info, level)
                    end

                    -- Separator for better UI clarity
                    local separator = UIDropDownMenu_CreateInfo()
                    separator.text = ""
                    separator.disabled = true
                    separator.notCheckable = true
                    UIDropDownMenu_AddButton(separator, level)

                    -- Debug Output to Check Campaigns
                    print("🔍 Searching for Auras in Loaded Campaigns...")

                    -- Store Auras by Campaign
                    local campaignAuras = {}

                    for campaignGUID, campaign in pairs(_G.Campaigns or {}) do
                        print("🗂 Checking Campaign:", campaign.Name)

                        if campaign.AuraList and #campaign.AuraList > 0 then
                            print("✅ Found Auras in", campaign.Name)
                            campaignAuras[campaignGUID] = { Name = campaign.Name, Auras = campaign.AuraList }
                        end
                    end

                    -- Create Campaign Submenus
                    for campaignGUID, data in pairs(campaignAuras) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = data.Name
                        info.hasArrow = true  -- Enables the submenu
                        info.notCheckable = true
                        info.menuList = campaignGUID  -- Store GUID instead of Name
                        UIDropDownMenu_AddButton(info, level)
                    end

                    -- If No Auras Found
                    if next(campaignAuras) == nil then
                        print("⚠️ No Auras Found in Loaded Campaigns")
                        local emptyInfo = UIDropDownMenu_CreateInfo()
                        emptyInfo.text = "No Auras Found"
                        emptyInfo.disabled = true
                        emptyInfo.notCheckable = true
                        UIDropDownMenu_AddButton(emptyInfo, level)
                    end

                elseif menuList then
                    -- Fetch campaign using GUID
                    local campaign = _G.Campaigns[menuList]

                    if campaign and campaign.AuraList then
                        for _, aura in ipairs(campaign.AuraList) do
                            print("🔹 Adding Aura:", aura.Name)
                            local auraInfo = UIDropDownMenu_CreateInfo()
                            auraInfo.text = aura.Name
                            auraInfo.func = function()
                                OnConditionSelected(conditionDropdown, aura.Name, aura.Guid)
                            end                            
                            UIDropDownMenu_AddButton(auraInfo, level)
                        end
                    end
                end
            end)


            -- Change to Right-Click Removal
            entry:SetScript("OnMouseUp", function(self, button)
                if button == "RightButton" then
                    table.remove(aura.Effects, index)
                    RefreshEffectsList() -- Refresh UI after removal
                end
            end)

            -- Store Elements
            table.insert(self.AddAuraFrame.EffectEntries, entry)
        end
    end





    -- Add Effect Button
    self.AddAuraFrame.AddEffectButton = CreateFrame("Button", nil, self.AddAuraFrame, "UIPanelButtonTemplate")
    self.AddAuraFrame.AddEffectButton:SetSize(100, 20)
    self.AddAuraFrame.AddEffectButton:SetPoint("TOPLEFT", self.AddAuraFrame.EffectsScrollFrame, "BOTTOMLEFT", 0, -5)
    self.AddAuraFrame.AddEffectButton:SetText("Add Effect")
    self.AddAuraFrame.AddEffectButton:SetScript("OnClick", function()
        aura.Effects = aura.Effects or {}  -- Ensure Effects is a table
        table.insert(aura.Effects, { Type = "Damage", Value = "0", School = "None", Condition = "None" })
        RefreshEffectsList()
    end)

    -- Initialize Effects List
    RefreshEffectsList()

    -- Save Button Functionality
    self.AddAuraFrame.SaveButton:SetScript("OnClick", function()
        -- Ensure the aura has a GUID (if new)
        if not aura.Guid then
            aura.Guid = "AURA-" .. math.random(100000, 999999)  -- Generate a random GUID
        end

        -- Get the selected campaign
        local campaign = _G.Campaigns[CampaignManager.SelectedCampaign]
        if not campaign then
            print("❌ Error: No selected campaign found!")
            return
        end

        -- Ensure the campaign has a aura list
        campaign.AuraList = campaign.AuraList or {}

        -- Convert HitModifiers, DamageModifiers, and CritModifiers to Internal Keys
        local function ConvertModifiers(modifierList)
            local converted = {}
            for _, mod in ipairs(modifierList or {}) do
                local internalKey = STAT_TOOLTIP_REVERSE[mod] or mod  -- Convert to key format or leave as-is
                table.insert(converted, internalKey)
            end
            return converted
        end

        aura.Name = self.AddAuraFrame.AuraNameBox:GetText()
        aura.Description = self.AddAuraFrame.AuraDescriptionBox:GetText()
        aura.RemainingTurns = self.AddAuraFrame.AuraDurationBox:GetText()

        aura.Effects = aura.Effects or {}  -- Ensure Effects exists

        local convertedEffects = {}
        for _, effect in ipairs(aura.Effects) do
            table.insert(convertedEffects, {
                Type = effect.Type,
                Value = effect.Value,
                School = effect.School,
                Condition = effect.Condition
            })
        end
        aura.Effects = convertedEffects

        -- Check if the aura already exists in the aura list
        local auraExists = false
        for i, existingAura in ipairs(campaign.AuraList) do
            if existingAura.Guid == aura.Guid then
                -- Overwrite existing aura data
                campaign.AuraList[i] = aura
                auraExists = true
                print(string.format("Aura Updated: %s", aura.Name))
                break
            end
        end

        -- If aura does not exist, add it to the list
        if not auraExists then
            table.insert(campaign.AuraList, aura)
            print(string.format("New Aura Added: %s", aura.Name))
        end

        -- Save changes and refresh UI
        CTCampaign:SaveCampaign(CampaignManager.SelectedCampaign)
        CampaignManager:PopulateCampaignAuraList(CampaignManager.SelectedCampaign)

        -- Close the aura creation window
        self.AddAuraFrame:Hide()
    end)

    -- Show the window
    self.AddAuraFrame:Show()
end


for i, tab in ipairs(CampaignManagerFrame.Tabs) do
    tab:SetScript("OnClick", function() SwitchTab(i) end)
end

CampaignManagerFrame:SetScript("OnShow", function()
    SwitchTab(1)
end)

-- Function to update the list of campaigns in the scroll frame
local function UpdateCampaignList()
    local campaigns = CTCampaign:GetSavedCampaigns()
    
    -- Ensure previous entries are removed
    if CampaignListScrollChild.entries then
        for _, entry in ipairs(CampaignListScrollChild.entries) do
            entry:Hide()
            entry:SetParent(nil)
        end
    end

    -- Create an entry for each loaded campaign
    CampaignListScrollChild.entries = {}
    for index, guid in ipairs(campaigns) do
        local campaign = _G.CampaignToolkitCampaignsDB[guid]
        local entry = CreateFrame("Frame", nil, CampaignListScrollChild, "BackdropTemplate")
        entry:SetWidth(180)
        entry:SetPoint("TOP", CampaignListScrollChild, "TOP", 0, -((index - 1) * 30))

        -- Background texture
        local bg = entry:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(entry)
        bg:SetColorTexture(0.1, 0.1, 0.1, 0) -- Dark background
    
        -- Highlight on mouseover
        entry:SetScript("OnEnter", function()
            bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        end)
        entry:SetScript("OnLeave", function()
            bg:SetColorTexture(0.1, 0.1, 0.1, 0)
        end)

        -- Icon for campaign
        local icon = entry:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("TOPLEFT", entry, "TOPLEFT", 5, -5)
        icon:SetTexture(campaign.Icon) -- Example icon, customize as needed

        -- Campaign Name Text
        local nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, 0)
        nameText:SetWidth(150) -- Set a fixed width for wrapping
        nameText:SetJustifyH("LEFT")
        nameText:SetJustifyV("TOP")
        nameText:SetWordWrap(true)
        nameText:SetText(campaign.Name)

        -- Dynamically adjust the entry height based on text size
        local textHeight = nameText:GetStringHeight()
        local entryHeight = math.max(25, textHeight + 10) -- Ensure minimum height
        entry:SetHeight(entryHeight)

        -- Adjust icon alignment if entry is taller
        icon:SetPoint("TOPLEFT", entry, "TOPLEFT", 5, -((entryHeight - 20) / 2))

        -- Click action (select campaign)
        entry:SetScript("OnMouseUp", function()
            CampaignManagerFrame.CampaignName:SetText(campaign.Name)

            -- Store the selected campaign GUID for editing
            CampaignManagerFrame.SelectedCampaign = guid

            -- Switch to the 'Details' tab
            SwitchTab(1)

            -- Populate the details tab with campaign data
            CampaignManager:PopulateCampaignDetails(guid)
        end)

        -- Store entry for future reference
        table.insert(CampaignListScrollChild.entries, entry)
    end
end

-- Adds the default campaign containing built-in spells
local function AddDefault()
    local builtinSpells = {}

    CTCampaign:SetData({
        Name = "Epic Adventure 3.0 REDUX",
        Guid = "TEST",
        Description = "Insert description here.",
        Author = "Unknown Author",
        LastUpdated = GetServerTime(),
        SpellList = builtinSpells
    })
end

local function UpdateProgressBar(guid, received, total)
    -- Ensure the frame exists
    if not _G.CTCampaignProgressBar then
        local bar = CreateFrame("StatusBar", "CTCampaignProgressBar", UIParent)
        bar:SetSize(300, 20)
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
        bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        bar:SetStatusBarColor(0, 1, 0) -- Green color (RGB: 0,1,0)
        bar:SetMinMaxValues(0, total)
        bar:SetValue(received)
        bar:Show()

        -- Background
        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(true)
        bg:SetColorTexture(0, 0, 0, 0.5)

        -- Border
        local border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12
        })

        -- Text
        local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("CENTER", bar, "CENTER", 0, 0)
        bar.text = text
        text:SetFontObject("GameFontHighlightOutline") -- Adds an outline to text

        _G.CTCampaignProgressBar = bar
    end

    -- Update progress bar
    local progressBar = _G.CTCampaignProgressBar
    progressBar:SetMinMaxValues(0, total)
    progressBar:SetValue(received)
    local percent = (received / total) * 100
    progressBar.text:SetText(string.format("Receiving Campaign: %.1f%%", percent))

    -- Hide when done
    if received >= total then
        C_Timer.After(1, function()
            progressBar:Hide()
        end)
    end
end


function CampaignManager:SendCampaign(guid)
    if not _G.Campaigns[guid] then
        print("|cffff0000Error: No campaign selected!|r")
        return
    end

    print(guid)

    local chunks, totalChunks = CampaignManager:SerializeCampaign(guid)
    if not chunks then return end

    local channel = IsInRaid() and "RAID" or (IsInGroup() and "PARTY" or nil)
    
    if not channel then
        print("|cffff0000Error: You are not in a group or raid!|r")
        return
    end

    -- Send initial message with total chunk count
    local initMessage = guid .. ":" .. totalChunks
    -- print("|cff00ff00[Debug] Sending INIT: " .. initMessage .. " via " .. channel .. "|r")
    C_ChatInfo.SendAddonMessage("CTCINIT", initMessage, channel)

    -- Send each chunk with a 0.2-second delay to prevent message loss
    for i, chunk in ipairs(chunks) do
        C_Timer.After(i * 1, function()  -- Delays each message by 0.2 seconds
            local chunkMessage = guid .. ":" .. i .. ":" .. chunk
            --print("|cff00ff00[Debug] Sending CHUNK " .. i .. " / " .. totalChunks .. "|r")
            C_ChatInfo.SendAddonMessage("CTCNEXT", chunkMessage, channel)
        end)
    end

    print("|cff00ff00Sent campaign '" .. _G.Campaigns[guid].Name .. "' in " .. totalChunks .. " chunks.|r")
end


local incomingCampaigns = {} -- Store incoming campaign data per guid

local function HandleCampaignInit(prefix, message, channel, sender)
    local senderName = strsplit("-", sender) -- Removes realm name
    if UnitName("player") == senderName then return end

    if prefix == "CTCINIT" then
        local guid, totalChunks = strsplit(":", message)
        totalChunks = tonumber(totalChunks)

        if guid and totalChunks then
            incomingCampaigns[guid] = { totalChunks = totalChunks, receivedChunks = {}, receivedCount = 0 }
            -- print("|cff00ff00[Debug] Receiving INIT for '" .. guid .. "' from " .. sender .. " (" .. totalChunks .. " chunks).|r")
        end
    end
end

local function HandleCampaignChunk(prefix, message, channel, sender)
    local senderName = strsplit("-", sender) -- Removes realm name
    if UnitName("player") == senderName then return end

    if prefix == "CTCNEXT" then
        local guid, chunkIndex, chunkData = strsplit(":", message, 3)
        chunkIndex = tonumber(chunkIndex)

        if guid and chunkIndex and chunkData and incomingCampaigns[guid] then
            incomingCampaigns[guid].receivedChunks[chunkIndex] = chunkData
            incomingCampaigns[guid].receivedCount = incomingCampaigns[guid].receivedCount + 1


            UpdateProgressBar(guid, incomingCampaigns[guid].receivedCount, incomingCampaigns[guid].totalChunks)

            -- print("|cff00ff00[Debug] Received CHUNK " .. chunkIndex .. " / " .. incomingCampaigns[guid].totalChunks .. " from " .. sender .. "|r")

            -- If all chunks received, reassemble
            if incomingCampaigns[guid].receivedCount == incomingCampaigns[guid].totalChunks then
                local fullData = table.concat(incomingCampaigns[guid].receivedChunks)
                local campaign = CampaignManager:DeserializeCampaign(fullData)

                if campaign then
                    -- Ensure we apply the campaign data correctly using `SetData`
                    if not _G.Campaigns[guid] then
                        _G.Campaigns[guid] = {} -- Create an empty table if it doesn't exist
                    end
                    
                    -- Use `CTCampaign:SetData()` to properly apply and save data
                    CTCampaign.SetData(_G.Campaigns[guid], campaign)

                    -- Store in the database
                    _G.CampaignToolkitCampaignsDB[guid] = CopyTable(_G.Campaigns[guid])

                    print("|cff00ff00Successfully received and stored campaign: " .. _G.Campaigns[guid].Name .. "|r")

                    UpdateCampaignList() -- Update UI
                else
                    print("|cffff0000Error: Failed to deserialize campaign!|r")
                end

                incomingCampaigns[guid] = nil
            end
        end
    end
end

local function SerializeSpells(spellList)
    if not spellList or #spellList == 0 then return "[]" end -- Return empty if no Spells exist

    local serialized = "["

    for _, spell in ipairs(spellList) do
        local spellData = "{"
        spellData = spellData .. "Name=" .. (spell.Name or "Unknown Spell") .. "@"
        spellData = spellData .. "Guid=" .. (spell.Guid or "nil") .. "@"
        spellData = spellData .. "Type=" .. (spell.Type or "Spell") .. "@"
        spellData = spellData .. "Icon=" .. (spell.Icon) .. "@"
        spellData = spellData .. "CastTime=" .. (spell.CastTime or "Instant") .. "@"
        spellData = spellData .. "Icon=" .. (spell.Icon or "Interface/Icons/INV_Misc_QuestionMark") .. "@"
        spellData = spellData .. "Description=" .. (spell.Description or "No description available.") .. "@"
        spellData = spellData .. "ManaCost=" .. tostring(spell.ManaCost or 0) .. "@"
        spellData = spellData .. "ActionCost=" .. (spell.ActionCost or "Action") .. "@"
        spellData = spellData .. "Message=" .. (spell.Message or "") .. "@"
        spellData = spellData .. "DiceToHit=" .. (spell.DiceToHit or "") .. "@"
        spellData = spellData .. "School=" .. (spell.School or "Physical") .. "@"
        spellData = spellData .. "DiceToDamage=" .. (spell.DiceToDamage or "") .. "@"
        spellData = spellData .. "Class=" .. (spell.Class or "General") .. "@"
        spellData = spellData .. "Specialisation=" .. (spell.Specialisation or "") .. "@"

        -- Serialize Requires using `$` delimiter
        if spell.Requires and #spell.Requires > 0 then
            spellData = spellData .. "Requires=[" .. table.concat(spell.Requires, "$") .. "]@"
        else
            spellData = spellData .. "Requires=[]@"
        end

        -- Serialize HitModifiers using `$` delimiter
        if spell.HitModifiers and #spell.HitModifiers > 0 then
            spellData = spellData .. "HitModifiers=[" .. table.concat(spell.HitModifiers, "$") .. "]@"
        else
            spellData = spellData .. "HitModifiers=[]@"
        end

        -- Serialize DamageModifiers using `$` delimiter
        if spell.DamageModifiers and #spell.DamageModifiers > 0 then
            spellData = spellData .. "DamageModifiers=[" .. table.concat(spell.DamageModifiers, "$") .. "]@"
        else
            spellData = spellData .. "DamageModifiers=[]@"
        end

        -- Serialize CritModifiers using `$` delimiter
        if spell.CritModifiers and #spell.CritModifiers > 0 then
            spellData = spellData .. "CritModifiers=[" .. table.concat(spell.CritModifiers, "$") .. "]@"
        else
            spellData = spellData .. "CritModifiers=[]@"
        end

        -- Serialize Auras using `$` delimiter
        if spell.Auras and #spell.Auras > 0 then
            spellData = spellData .. "Auras=[" .. table.concat(spell.Auras, "$") .. "]@"
        else
            spellData = spellData .. "Auras=[]@"
        end

        spellData = spellData:sub(1, -2) .. "}" -- Remove last `@` and close Spell entry
        serialized = serialized .. spellData .. "#" -- Use `#` to separate Spells
    end

    serialized = serialized:sub(1, -2) .. "]" -- Remove last `#` and close SpellList

    return serialized
end


local function SerializeAuras(auraList)
    if not auraList or #auraList == 0 then return "[]" end -- Return empty if no Auras exist

    local serialized = "["

    for _, aura in ipairs(auraList) do
        local auraData = "{"
        auraData = auraData .. "Name=" .. (aura.Name or "Unknown Aura") .. "@"
        auraData = auraData .. "Guid=" .. (aura.Guid or "nil") .. "@"
        auraData = auraData .. "Type=" .. (aura.Type or "Debuff") .. "@"
        auraData = auraData .. "TriggerOn=" .. (aura.TriggerOn or "Cast") .. "@"
        auraData = auraData .. "Icon=" .. (aura.Icon) .. "@"
        auraData = auraData .. "Description=" .. (aura.Description or "This aura has no description.") .. "@"
        auraData = auraData .. "RemainingTurns=" .. tostring(aura.RemainingTurns or 1) .. "@"

        -- Serialize Effects list using £ delimiter
        if aura.Effects and #aura.Effects > 0 then
            local effectsData = "["
            for _, effect in ipairs(aura.Effects) do
                local effectData = "{"
                for k, v in pairs(effect) do
                    effectData = effectData .. k .. "=" .. tostring(v).. "~"
                end
                effectData = effectData:sub(1, -2) .. "}" -- Remove last £ and close Effect
                effectsData = effectsData .. effectData .. "$"
            end
            effectsData = effectsData:sub(1, -2) .. "]" -- Remove last £ and close Effects list
            auraData = auraData .. "Effects=" .. effectsData .. "@"
        else
            auraData = auraData .. "Effects=[]@" -- Empty list if no Effects exist
        end

        auraData = auraData:sub(1, -2) .. "}" -- Remove last @ and close Aura entry
        serialized = serialized .. auraData .. "#" -- Use § to separate Auras
    end

    serialized = serialized:sub(1, -2) .. "]" -- Remove last § and close AuraList

    return serialized
end

function CampaignManager:SerializeCampaign(guid)
    local campaign = _G.Campaigns[guid] -- Retrieve from database
    if not campaign then
        print("|cffff0000Error: Campaign not found!|r")
        return
    end

    -- Construct a table with only the required campaign data
    local campaignData = "{"
    campaignData = campaignData .. "Guid=" .. campaign.Guid .. "^"
    campaignData = campaignData .. "Name=" .. campaign.Name .. "^"
    campaignData = campaignData .. "Description=" .. campaign.Description .. "^"
    campaignData = campaignData .. "LastUpdated=" .. tostring(campaign.LastUpdated) .. "^"
    campaignData = campaignData .. "Icon=" .. campaign.Icon .. "^"
    campaignData = campaignData .. "Author=" .. campaign.Author .. "^"

    -- Include serialized AuraList
    campaignData = campaignData .. "AuraList=" .. SerializeAuras(campaign.AuraList) .. "^"
    campaignData = campaignData .. "SpellList=" .. SerializeSpells(campaign.SpellList) .. "^"

    campaignData = campaignData:sub(1, -2) .. "}" -- Remove trailing comma and close table

    -- Split into 200-byte chunks
    local chunkSize = 240
    local totalChunks = math.ceil(#campaignData / chunkSize)
    local chunks = {}

    for i = 1, totalChunks do
        local startIdx = (i - 1) * chunkSize + 1
        local chunk = campaignData:sub(startIdx, startIdx + chunkSize - 1)
        table.insert(chunks, chunk)
    end

    return chunks, totalChunks
end

local function DeserializeEffects(data)
    print("Deserializing effects...")

    local effects = {}

    -- Ensure input is valid
    if not data or type(data) ~= "string" or data == "[]" then
        return effects -- Return empty list if no effects exist
    end

    -- **Remove surrounding brackets `[]` if present**
    if data:sub(1, 1) == "[" and data:sub(-1) == "]" then
        data = data:sub(2, -2)
    end

    -- **Split Effects using `$` delimiter**
    for effectData in data:gmatch("{(.-)}") do  -- Extract everything inside `{}` blocks
        local effect = {}

        print("Processing Effect: " .. effectData) -- Debugging output

        -- **Extract key-value pairs inside Effect using `~` delimiter**
        for epair in effectData:gmatch("([^~]+)") do
            local ek, ev = strsplit("=", epair, 2)
            if ek and ev then
                -- **Remove leading/trailing quotes and unescape characters**
                ev = ev:gsub("^'(.-)'$", "%1"):gsub("\\'", "'")
                effect[ek] = tonumber(ev) or ev -- Convert numbers properly

                print("Parsed Effect Key-Value: " .. ek .. " = " .. tostring(ev)) -- Debug output
            end
        end

        table.insert(effects, effect) -- Store effect data
    end

    return effects
end


local function DeserializeAuras(data)
    print("Deserializing aura data...")

    local auras = {}

    -- Ensure input is valid
    if not data or type(data) ~= "string" or data == "[]" then
        return auras -- Return empty list if no Auras exist
    end

    -- **Remove surrounding brackets `[]` if present**
    data = data:sub(2, -2)

    -- **Extract each Aura using `#` delimiter**
    for auraData in data:gmatch("([^#]+)") do
        local aura = {}

        -- **Trim leading `{` from the start of `auraData`**
        auraData = auraData:gsub("^{", "")

        -- **Extract key-value pairs inside the Aura using `@` delimiter**
        for pair in auraData:gmatch("([^@]+)") do
            local k, v = strsplit("=", pair, 2)
            if k and v then
                -- **Ensure `{` is removed from first key**
                k = k:gsub("^{", ""):match("^%s*(.-)%s*$") -- Trim spaces
                v = v:match("^%s*(.-)%s*$") -- Trim spaces

                print("Extracted Key: " .. k .. " | Value: " .. v) -- Debugging output

                if k == "RemainingTurns" then
                    aura[k] = tonumber(v) -- Convert numeric values
                elseif k == "Effects" then
                    aura[k] = DeserializeEffects(v) -- Deserialize Effects separately
                else
                    aura[k] = v:gsub("\\'", "'") -- Unescape single quotes
                end
            end
        end

        table.insert(auras, aura) -- Store deserialized Aura
    end

    return auras
end

local function DeserializeSpellList(data)
    -- Ensure valid list format
    if not data or type(data) ~= "string" or data == "[]" then
        return {}
    end

    -- **Remove surrounding brackets `[]` only if present**
    if data:sub(1, 1) == "[" and data:sub(-1) == "]" then
        data = data:sub(2, -2)
    end

    local list = {}

    -- **Ensure data isn't empty after trimming brackets**
    if #data > 0 then
        -- **Split list by `$` delimiter**
        for entry in data:gmatch("([^$]+)") do
            entry = entry:match("^%s*(.-)%s*$") -- Trim leading/trailing spaces
            entry = entry:gsub("[%[%]{}]", "") -- **Remove any unwanted `[]` or `{}`**
            print("... " .. entry) -- Debugging output
            table.insert(list, entry)
        end
    end

    print(#list)

    return list
end





local function DeserializeSpells(data)
    print("Deserializing spell data...")

    local spells = {}

    -- Ensure input is valid
    if not data or type(data) ~= "string" or data == "[]" then
        return spells -- Return empty list if no Spells exist
    end

    -- **Remove surrounding brackets `[]` if present**
    data = data:sub(2, -2)

    -- **Extract each Spell using `#` delimiter**
    for spellData in data:gmatch("([^#]+)") do
        local spell = {}

        -- **Trim leading `{` from the start of `spellData`**
        spellData = spellData:gsub("^{", "")

        -- **Extract key-value pairs inside the Spell using `@` delimiter**
        for pair in spellData:gmatch("([^@]+)") do
            local k, v = strsplit("=", pair, 2)
            if k and v then
                -- **Ensure `{` is removed from first key**
                k = k:gsub("^{", ""):match("^%s*(.-)%s*$") -- Trim spaces
                v = v:match("^%s*(.-)%s*$") -- Trim spaces

                print("Extracted Key: " .. k .. " | Value: " .. v) -- Debugging output

                -- **Convert numeric values where applicable**
                if k == "ManaCost" then
                    spell[k] = tonumber(v)
                -- **Deserialize lists using `$` delimiter**
                elseif k == "HitModifiers" or k == "CritModifiers" or k == "DamageModifiers" or k == "Auras" or k == "Requires" then
                    print("List " ..k.. " | v: " ..v)
                    spell[k] = DeserializeSpellList(v)
                    print(spell[k])
                else
                    spell[k] = v:gsub("\\'", "'") -- Unescape single quotes
                end
            end
        end

        table.insert(spells, spell) -- Store deserialized Spell
    end

    return spells
end


function CampaignManager:DeserializeCampaign(data)
    print("Deserializing campaign data...")

    local campaign = {}

    -- Ensure input is valid
    if not data or type(data) ~= "string" or data == "{}" then
        print("|cffff0000Error: Invalid campaign data!|r")
        return nil
    end

    -- Remove surrounding brackets {}
    data = data:sub(2, -2)

    -- Extract key-value pairs using `^` delimiter
    for pair in data:gmatch("([^%^]+)") do
        local k, v = strsplit("=", pair, 2)
        if k and v then
            k = k:match("^%s*(.-)%s*$") -- Trim spaces
            v = v:match("^%s*(.-)%s*$") -- Trim spaces

            print("Extracted Key: " .. k .. " | Value: " .. v) -- Debugging output

            if k == "LastUpdated" then
                campaign[k] = tonumber(v) -- Convert numeric values
            elseif k == "AuraList" then
                campaign[k] = DeserializeAuras(v) -- Deserialize AuraList separately
            elseif k == "SpellList" then
                campaign[k] = DeserializeSpells(v)
            else
                print("Setting " ..k.. " to " ..v)
                campaign[k] = v:gsub("\\'", "'") -- Unescape single quotes
            end
        end
    end

    -- Ensure campaign has a GUID
    if not campaign.Guid or campaign.Guid == "nil" then
        print("|cffff0000Error: Cannot save campaign with no GUID.|r")
        return nil
    end

    return campaign
end


local receiveFrame = CreateFrame("Frame")
receiveFrame:RegisterEvent("CHAT_MSG_ADDON")
receiveFrame:SetScript("OnEvent", function(_, _, prefix, message, channel, sender)
    -- print("|cff00ff00[Debug] Received Addon Message - Prefix: " .. prefix .. " | Message: " .. message .. " | From: " .. sender .. "|r")
    
    if prefix == "CTCINIT" and UnitName("player") ~= sender then
        -- print("|cff00ff00[Debug] Received Addon Message - Prefix: " .. prefix .. " | Message: " .. message .. " | From: " .. sender .. "|r")
        HandleCampaignInit(prefix, message, channel, sender)
    elseif prefix == "CTCNEXT" and UnitName("player") ~= sender then
        print("|cff00ff00[Debug] Received Addon Message - Prefix: " .. prefix .. " | Message: " .. message .. " | From: " .. sender .. "|r")
        HandleCampaignChunk(prefix, message, channel, sender)
    end
end)


-- Hook the campaign list update whenever campaigns are loaded or saved
local function UpdateCampaignsOnEvents()
    -- Update the campaign list whenever a campaign is saved or loaded
    UpdateCampaignList()
end

-- Hooking Campaign Manager to the game events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD") -- Ensures save on reload
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- Ensures data is available on login
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        UpdateCampaignList()  -- Update the UI list of campaigns
    end
end)

-- Slash Command
SLASH_CTM1 = "/ctm"
SlashCmdList["CTM"] = function()
    if CampaignManager:IsShown() then
        CampaignManager:Hide()
    else
        CampaignManager:Show()
    end
end

_G.UpdateCampaignList = UpdateCampaignList