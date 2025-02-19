-- Init
local UnitFrameTurn = {}
_G.UnitFrameTurn = UnitFrameTurn
local ADDON_PREFIX = "CTUF"

-- Frames
local TurnFrame = nil
local TargetPopup = nil

-- Variables
local unit = nil
local actionsRemaining = 0
UnitFrameTurn.actionsRemaining = actionsRemaining

UnitFrameTurn.AwaitingPlayers = {}

local function DisplayBasicActions()
    -- Basic Action Icons
    TurnFrame.BasicActionIcons = {}

    local actionIcons = {
        { name = "Melee", icon = 132349 },     -- Swords icon
        { name = "Ranged", icon = 135498 },    -- Bow icon
        { name = "Spell", icon = 136096 },     -- Magic swirl icon
        { name = "Dash", icon = 237559 },      -- Running figure icon
        { name = "Disengage", icon = 132293 }  -- Jumping back icon
    }

    for i, action in ipairs(actionIcons) do
        local iconFrame = CreateFrame("Button", nil, TurnFrame)
        iconFrame:SetSize(32, 32)
        iconFrame:SetPoint("TOPLEFT", TurnFrame, "TOPLEFT", ((i - 1) % 5) * 34 + 10, -60 - math.floor((i - 1) / 5) * 40)

        local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
        iconTexture:SetAllPoints(iconFrame)
        iconTexture:SetTexture(action.icon)
        iconTexture:SetAlpha(0.8)  -- Set normal opacity for active icon

        -- Store the icon in BasicActionIcons
        TurnFrame.BasicActionIcons[action.name] = iconFrame

        -- Set the click event for the icon, which will be updated later
        iconFrame:SetScript("OnClick", function()
            print(UnitFrameTurn.actionsRemaining)
            if UnitFrameTurn.actionsRemaining == 0 then return end

            local maxTargets = 1  -- Modify maxTargets if necessary for each action
            -- Show the target popup based on the action type
            if action.name == "Melee" then
                UnitFrameTurn:ShowTargetPopup("Melee", maxTargets)
            elseif action.name == "Ranged" then
                UnitFrameTurn:ShowTargetPopup("Ranged", maxTargets)
            elseif action.name == "Spell" then
                UnitFrameTurn:ShowTargetPopup("Spell", maxTargets)
            end
        end)
    end
end

-- Function to update the action icons' state based on actionsRemaining
local function UpdateBasicActions()
    for actionName, iconFrame in pairs(TurnFrame.BasicActionIcons) do
        local iconTexture = iconFrame:CreateTexture(nil, "ARTWORK")
        iconTexture:SetAllPoints(iconFrame)
        local action = nil

        -- Find the action based on its name
        for _, actionData in ipairs({
            { name = "Melee", icon = 132349 },
            { name = "Ranged", icon = 135498 },
            { name = "Spell", icon = 136096 },
            { name = "Dash", icon = 237559 },
            { name = "Disengage", icon = 132293 }
        }) do
            if actionData.name == actionName then
                action = actionData
                iconTexture:SetTexture(action.icon)  -- Set the icon texture once here
                break
            end
        end

        -- Check if actionsRemaining is 0, if so, grey out and disable the icon
        if UnitFrameTurn.actionsRemaining == 0 then
            iconTexture:SetVertexColor(0.5, 0.5, 0.5)  -- Grey out the icon using vertex color
            iconFrame:EnableMouse(false)  -- Disable mouse interaction (clicking)
        else
            iconTexture:SetVertexColor(1, 1, 1)  -- Restore normal color using vertex color
            iconFrame:EnableMouse(true)  -- Enable mouse interaction (clicking)
        end
    end
end




function UnitFrameTurn:ShowTargetPopup(action, maxTargets)
    maxTargets = maxTargets or 1  -- Default to 1 target if not provided
    print("Showing target popup for "  .. action.. " (Max Targets: " .. maxTargets .. ")")

    -- Clear previous elements
    for _, element in pairs(TargetPopup.Elements or {}) do
        element:Hide()
    end
    TargetPopup.Elements = {}
    TargetPopup.SelectedTargets = {}

    -- Gather all units from GroupMembers
    local allUnits = _G.GetGroupMembers()
    local columns = 5  -- 5 units per row
    local iconSize = 32
    local spacing = 5

    -- Calculate rows needed
    local rows = math.ceil(#allUnits / columns)
    local popupWidth = (iconSize + spacing) * columns + 10
    local popupHeight = (iconSize + spacing) * rows + 60  -- Extra space for confirm button

    -- Resize and reposition the popup
    TargetPopup:SetSize(popupWidth, popupHeight)
    TargetPopup:SetPoint("TOPLEFT", TurnFrame, "TOPRIGHT", 10, 0) -- Anchor to right of TurnFrame

    -- Header: Display Remaining Target Count
    if not TargetPopup.Header then
        TargetPopup.Header = TargetPopup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        TargetPopup.Header:SetPoint("TOP", TargetPopup, "TOP", 0, -10)
    end
    TargetPopup.Header:SetText("Select " .. maxTargets .. " target(s)")

    -- Create portraits/raid markers for each unit
    for i, unitName in ipairs(allUnits) do
        local col = (i - 1) % columns
        local row = math.floor((i - 1) / columns)

        local frame = CreateFrame("Button", nil, TargetPopup)
        frame:SetSize(iconSize, iconSize)
        frame:SetPoint("TOPLEFT", TargetPopup, "TOPLEFT", col * (iconSize + spacing) + 10, -row * (iconSize + spacing) - 30)

        local icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(frame)

        -- Check if the unit is a player
        local unitID = _G.FindUnitIDByName(unitName)
        if unitID and UnitIsPlayer(unitID) then
            -- Display player portrait
            SetPortraitTexture(icon, unitID)

            -- If the unitName is in UnitFrameTurn.AwaitingPlayers, turn it red.
            local isAwaiting = false
            for _, awaitingPlayer in ipairs(UnitFrameTurn.AwaitingPlayers) do
                if awaitingPlayer == unitName then
                    isAwaiting = true
                    break
                end
            end

            -- Change the icon color to red if the player is in AwaitingPlayers
            if isAwaiting then
                icon:SetVertexColor(1, 0, 0)  -- Red color
            else
                icon:SetVertexColor(1, 1, 1)  -- Restore normal color
            end
        else
            -- Display raid marker for NPCs
            local raidMarker = nil
            for _, unitFrame in pairs(_G.CampaignToolkit_UnitFrames.frames or {}) do
                if unitFrame.NPCName and unitFrame.NPCName:GetText() == unitName then
                    raidMarker = unitFrame.RaidMarker and unitFrame.RaidMarker:GetTexture()
                    break
                end
            end

            if raidMarker then
                icon:SetTexture(raidMarker)
            else
                icon:SetTexture("Interface\\ICONS\\INV_Misc_QuestionMark") -- Default icon if no marker found
            end
        end

        -- Click event for selecting a target (toggle selection)
        frame:SetScript("OnClick", function()
            local isAwaiting = false
            for _, awaitingPlayer in ipairs(UnitFrameTurn.AwaitingPlayers) do
                if awaitingPlayer == unitName then
                    isAwaiting = true
                    break
                end
            end

            if isAwaiting then return end

            -- Count current selections
            local selectedCount = 0
            for _ in pairs(TargetPopup.SelectedTargets) do
                selectedCount = selectedCount + 1
            end

            -- If already at max targets, prevent further selection
            if selectedCount >= maxTargets and not TargetPopup.SelectedTargets[unitName] then
                print("Maximum targets selected!")
                return
            end

            -- Toggle selection
            if TargetPopup.SelectedTargets[unitName] then
                -- Deselect target
                TargetPopup.SelectedTargets[unitName] = nil
                frame:SetAlpha(1)  -- Reset transparency
                print("Deselected:", unitName)
            else
                -- Select target
                TargetPopup.SelectedTargets[unitName] = true
                frame:SetAlpha(0.5)  -- Dim to indicate selection
                print("Selected:", unitName)
            end

            -- Recalculate selected count
            selectedCount = 0
            for _ in pairs(TargetPopup.SelectedTargets) do
                selectedCount = selectedCount + 1
            end

            -- Update header to reflect remaining selections
            local remaining = maxTargets - selectedCount
            TargetPopup.Header:SetText("Select " .. remaining .. " target(s)")
        end)

        -- Store elements
        TargetPopup.Elements[i] = frame
    end

    -- Confirm Selection Button
    if not TargetPopup.ConfirmButton then
        TargetPopup.ConfirmButton = CreateFrame("Button", nil, TargetPopup, "UIPanelButtonTemplate")
        TargetPopup.ConfirmButton:SetSize(120, 20)
        TargetPopup.ConfirmButton:SetPoint("BOTTOM", TargetPopup, "BOTTOM", 0, 10)
        TargetPopup.ConfirmButton:SetText("Confirm Selection")

        TargetPopup.ConfirmButton:SetScript("OnClick", function()
            local selectedUnits = {}
            for unitName, _ in pairs(TargetPopup.SelectedTargets) do
                table.insert(selectedUnits, unitName)
            end

            print("Action: " ..action)
            UnitFrameTurn:UseBasicAction(action, TargetPopup.SelectedTargets)
            TargetPopup:Hide()
        end)
    else
        TargetPopup.ConfirmButton:SetScript("OnClick", function()
            local selectedUnits = {}
            for unitName, _ in pairs(TargetPopup.SelectedTargets) do
                table.insert(selectedUnits, unitName)
            end

            print("Action: " ..action)
            UnitFrameTurn:UseBasicAction(action, TargetPopup.SelectedTargets)
            TargetPopup:Hide()
        end)
    end

    -- Show the popup
    TargetPopup:Show()
end

function UnitFrameTurn:UseBasicAction(action, selectedTargets)
    if action == "Melee" or action == "Ranged" or action == "Spell" then
        print("Action: " ..action)
        UnitFrameTurn:Action_BasicAttack(selectedTargets, action)
    end

    unit.ActionsRemaining = unit.ActionsRemaining  - 1
    UnitFrameTurn:UpdateActionsRemaining()

    if unit.ActionsRemaining == 0 then
        print("Locking portrait; no actions remaining...")
        UnitFrameTurn:Send_LockPortrait(unit.NPCName:GetText())
    end
end

function UnitFrameTurn:Action_BasicAttack(selectedTargets, type)
    for unitName, _ in pairs(selectedTargets) do
        print(TurnFrame.UnitName:GetText().. " used a basic " ..type.. " attack on " ..unitName)

        -- Request a roll from the player.
        PlayerReaction:Request_Defensive(TurnFrame.UnitName:GetText(), unitName, unit.OffensiveModifiers[type].ac, type:upper(), unit.OffensiveModifiers[type].school)
        table.insert(UnitFrameTurn.AwaitingPlayers, unitName)
        print("Now awaiting player " ..unitName)
    end
end

-- Create the UnitFrameTurn UI
TurnFrame = CreateFrame("Frame", "UnitFrameTurnWindow", UIParent, "BackdropTemplate")
TurnFrame:SetSize(300, 200)
TurnFrame:SetPoint("CENTER")
TurnFrame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
TurnFrame:SetMovable(true)
TurnFrame:EnableMouse(true)
TurnFrame:RegisterForDrag("LeftButton")
TurnFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
TurnFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
TurnFrame:Hide()

-- Unit Name (Top Left)
TurnFrame.UnitName = TurnFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TurnFrame.UnitName:SetPoint("TOPLEFT", TurnFrame, "TOPLEFT", 30, -10)

-- Raid Marker Icon
TurnFrame.RaidMarker = TurnFrame:CreateTexture(nil, "ARTWORK")
TurnFrame.RaidMarker:SetSize(16, 16)
TurnFrame.RaidMarker:SetPoint("RIGHT", TurnFrame.UnitName, "LEFT", -5, -1)

-- Actions Remaining Display
TurnFrame.ActionsRemainingText = TurnFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TurnFrame.ActionsRemainingText:SetPoint("TOPRIGHT", TurnFrame, "TOPRIGHT", -40, -10)
TurnFrame.ActionsRemainingText:SetText("Actions: 0") -- Default

-- Basic Actions Header
TurnFrame.BasicActionsHeader = TurnFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
TurnFrame.BasicActionsHeader:SetPoint("TOPLEFT", TurnFrame, "TOPLEFT", 10, -40)
TurnFrame.BasicActionsHeader:SetText("Basic Actions")

-- Display the NPC's basic actions (basic melee, ranged, spell attack; dash; disengage)
DisplayBasicActions()

-- Close Button
TurnFrame.CloseButton = CreateFrame("Button", nil, TurnFrame, "UIPanelCloseButton")
TurnFrame.CloseButton:SetPoint("TOPRIGHT", TurnFrame, "TOPRIGHT", -5, -5)
TurnFrame.CloseButton:SetScript("OnClick", function()
    TurnFrame:Hide()
end)


local function DrawTargetSelectionPopup()
    -- Target Target Selection Popup
    TargetPopup = CreateFrame("Frame", "TargetTargetPopup", UIParent, "BackdropTemplate")
    TargetPopup:SetSize(200, 150)
    TargetPopup:SetPoint("TOP", TurnFrame, "BOTTOM", 0, -10)
    TargetPopup:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    TargetPopup:Hide()

    -- Close Button
    TargetPopup.CloseButton = CreateFrame("Button", nil, TargetPopup, "UIPanelCloseButton")
    TargetPopup.CloseButton:SetPoint("TOPRIGHT", TargetPopup, "TOPRIGHT", -5, -5)
    TargetPopup.CloseButton:SetScript("OnClick", function() TargetPopup:Hide() end)
end

DrawTargetSelectionPopup()

function UnitFrameTurn:UpdateActionsRemaining() 
    -- Update Actions Remaining
    UnitFrameTurn.actionsRemaining = unit.ActionsRemaining or 0
    TurnFrame.ActionsRemainingText:SetText("Actions: " .. UnitFrameTurn.actionsRemaining)

    UpdateBasicActions()
end

-- Function to Show the UnitFrameTurn UI
function UnitFrameTurn:ShowTurnUI(unitFrame)
    if not unitFrame then return end

    unit = unitFrame

    -- Ensure UI is visible
    TurnFrame:Show()

    -- Update Unit Name
    TurnFrame.UnitName:SetText(unitFrame.NPCName:GetText())

    -- Update Raid Marker (Retrieve texture from frame)
    if unitFrame.RaidMarker and unitFrame.RaidMarker:GetTexture() then
        TurnFrame.RaidMarker:SetTexture(unitFrame.RaidMarker:GetTexture())
        TurnFrame.RaidMarker:Show()
    else
        TurnFrame.RaidMarker:Hide()
    end

    UnitFrameTurn:UpdateActionsRemaining()
    UpdateBasicActions()

    -- Debug Message
    print("UnitFrameTurn opened for:", unitFrame.NPCName:GetText())
end

function UnitFrameTurn:Send_LockPortrait(unitFrame)
    local message = string.format("LOCK:%s", unitFrame)

    -- Send the message to the appropriate channel (RAID or PARTY)
    local channel = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, channel)
end

local function Handle_LockPortrait(unitFrame)
    _G.LockPortrait(unitFrame)
end

local function OnAddonMessage(message, sender)
    if string.sub(message, 1, 5) == "LOCK:" then
        unitFrame = string.sub(message, 6)
        Handle_LockPortrait(unitFrame)
    end
end

-- Set up the event listener for receiving addon messages
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")  -- Listen for addon messages

frame:SetScript("OnEvent", function(_, event, prefix, message, _, sender)
    -- Ensure it's from the correct addon prefix
    if prefix ~= ADDON_PREFIX then return end

    OnAddonMessage(message, sender)
end)
