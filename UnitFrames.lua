_G.ADDON_PREFIX = "CTUF"  -- Unique Prefix for Messages
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

-- UnitFrames.lua (Full Lua-Based Solution)
local UnitFrames = CreateFrame("Frame", "CampaignToolkit_UnitFrames", UIParent)
_G.UnitFrames = UnitFrames
UnitFrames:SetSize(300, 400)
UnitFrames:SetPoint("CENTER")

UnitFrames.frames = {}

local unnamedNPCCount = 0 -- Counter for unnamed NPCs
local function CreateUnitFrame(index)
    local frame = CreateFrame("Frame", "UnitFrame"..index, UnitFrames, "BackdropTemplate")
    frame:SetSize(250, 60)
    frame:SetPoint("TOP", UnitFrames, "TOP", 0, -((index - 1) * 65))

    -- Set up unit frame variables and their default values.
    frame.NPCName = ""          -- The name of the npc.
    frame.NPCID = 17227         -- The display model of the npc. Defaults to 17227
    frame.ModelPosition = {
        x = 2,
        y = 0,
        z = -0.5
    }

    frame.CurrentHealth = 100
    frame.MaxHealth = 100
    frame.ActionsRemaining = 2
    frame.MaxActions = 2

    frame.OffensiveModifiers = {
        Melee = { attackBonus = 0, damageDice = "1d6", ac = 12, school = "Physical" },
        Ranged = { attackBonus = 0, damageDice = "1d8", ac = 12, school = "Physical" },
        Spell = { attackBonus = 0, damageDice = "1d10", ac = 12, school = "Arcane" },
    }

    frame.DefensiveAC = {
        Melee = 10,
        Ranged = 10,
        Spell = 10
    }

    frame.Auras = {}
    frame.BuffCount = 0
    frame.DebuffCount = 0

    -- Background
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    -- Portrait
    frame.Portrait = CreateFrame("PlayerModel", nil, frame)
    frame.Portrait:SetSize(40, 40)
    frame.Portrait:SetPoint("LEFT", frame, "LEFT", 10, 10)
    frame.Portrait:SetDisplayInfo(17227)  -- Placeholder NPC ID
    frame.Portrait:SetPosition(frame.ModelPosition["x"], frame.ModelPosition["y"], frame.ModelPosition["z"])  -- Adjust model positioning

    -- Raid Marker
    frame.RaidMarker = frame:CreateTexture(nil, "ARTWORK")
    frame.RaidMarker:SetSize(16, 16)
    frame.RaidMarker:SetPoint("TOPLEFT", frame.Portrait, "TOPRIGHT", 5, -10)

    -- Click Event for Portrait (Opens Pop-Up Window)
    frame.Portrait:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            UnitFrameInspect_Show(frame)
        end
    end)

    -- Health Frame (Parent for all Health Elements)
    frame.HealthFrame = CreateFrame("Frame", nil, frame)
    frame.HealthFrame:SetSize(50, 5)
    frame.HealthFrame:SetPoint("TOP", frame.Portrait, "BOTTOM", 0, -5)
    frame.HealthFrame:SetFrameStrata("LOW")  -- Base Layer

    -- Health Bar Background (Always Full, Dark Red)
    frame.HealthBarBG = CreateFrame("Frame", nil, frame.HealthFrame, "BackdropTemplate")
    frame.HealthBarBG:SetSize(50, 5)
    frame.HealthBarBG:SetPoint("CENTER")
    frame.HealthBarBG:SetBackdrop({
        bgFile = "Interface\\TargetingFrame\\UI-StatusBar"
    })
    frame.HealthBarBG:SetBackdropColor(0.5, 0, 0, 1)  -- Dark Red
    frame.HealthBarBG:SetFrameStrata("LOW")  -- Background Layer

    -- Health Bar Foreground (Shrinks with Health, Lighter Red)
    frame.HealthBar = CreateFrame("StatusBar", nil, frame.HealthFrame)
    frame.HealthBar:SetSize(50, 5)
    frame.HealthBar:SetPoint("CENTER")
    frame.HealthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.HealthBar:SetStatusBarColor(1, 0, 0)  -- Lighter Red
    frame.HealthBar:SetMinMaxValues(0, 100)
    frame.HealthBar:SetValue(100)
    frame.HealthBar:SetFrameStrata("MEDIUM")  -- Above Background

    -- CURRENT HEALTH TEXT (Always Above the Health Bar)
    frame.HealthTextFrame = CreateFrame("Frame", nil, frame.HealthFrame)
    frame.HealthTextFrame:SetAllPoints(frame.HealthBar)  -- Same size as health bar
    frame.HealthTextFrame:SetFrameStrata("HIGH")  -- Ensure it's above everything

    frame.HealthText = frame.HealthTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.HealthText:SetPoint("CENTER")
    frame.HealthText:SetText("100")  -- Default Placeholder
    frame.HealthText:SetTextColor(1, 1, 1, 1)  -- White Color

    -- NPC Name (Above Health Bar)
    frame.NPCNameLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.NPCNameLabel:SetPoint("LEFT", frame.RaidMarker, "RIGHT", 5, 1)

    -- Assign Default Name if No Name is Provided
    if not frame.NPCNameLabel:GetText() or frame.NPCNameLabel:GetText() == "" then
        unnamedNPCCount = unnamedNPCCount + 1
        frame.NPCNameLabel:SetText("Unit Frame [" .. unnamedNPCCount .. "]")
        frame.NPCName = "Unit Frame [" .. unnamedNPCCount .. "]"
    end

    -- Aura Container
    frame.AuraContainer = CreateFrame("Frame", nil, frame)
    frame.AuraContainer:SetSize(100, 16)
    frame.AuraContainer:SetPoint("LEFT", frame, "RIGHT", 5, 0)

    -- Function to Update Auras
    function frame:AddAura(newAuras)
        -- Ensure AuraContainer is properly positioned
        frame.AuraContainer:ClearAllPoints()
        frame.AuraContainer:SetPoint("LEFT", frame, "RIGHT", 5, 0)  -- Anchor to the right of the unit frame

        for _, aura in ipairs(newAuras) do
            -- Base the y offset on Buffs (top row) or Debuffs (bottom row)
            local auraIndex, yOffset

            if aura.Type == "Debuff" then
                auraIndex = frame.DebuffCount
                yOffset = -10  -- Place Debuffs on lower row
            else
                auraIndex = frame.BuffCount
                yOffset = 20  -- Place Buffs on top row
            end

            -- Create a unique frame for the aura
            local auraFrame = CreateFrame("Frame", nil, frame.AuraContainer)
            auraFrame:SetSize(16, 16)
            auraFrame:SetPoint("TOPLEFT", frame.AuraContainer, "TOPLEFT", auraIndex * 18, yOffset)

            auraFrame.Type = aura.Type

            -- Create the aura icon
            auraFrame.Icon = auraFrame:CreateTexture(nil, "OVERLAY")
            auraFrame.Icon:SetSize(16, 16)
            auraFrame.Icon:SetAllPoints()
            auraFrame.Icon:SetTexture(aura.Icon)

            -- **If it's a Debuff, add a red outline**
            if aura.Type == "Debuff" then
                auraFrame.Border = auraFrame:CreateTexture(nil, "BORDER")
                auraFrame.Border:SetSize(18, 18)  -- Slightly larger than the icon
                auraFrame.Border:SetPoint("CENTER", auraFrame, "CENTER")
                auraFrame.Border:SetColorTexture(1, 0, 0, 1) -- Solid red outline
            end

            -- Create text for turns remaining
            auraFrame.TurnsText = auraFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            auraFrame.TurnsText:SetPoint("TOP", auraFrame, "BOTTOM", 0, -2)
            auraFrame.TurnsText:SetTextColor(1, 1, 0) -- Yellow for visibility
            auraFrame.TurnsText:SetText(aura.RemainingTurns or "∞")

            -- Set tooltip for aura details
            auraFrame:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(aura.Name, 1, 1, 1)
                GameTooltip:AddLine(aura.Description, 1, 1, 1)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Caster: " .. aura.Caster, 1, 1, 1)
                GameTooltip:AddLine("Turns Remaining: " .. (aura.RemainingTurns or "∞"), 1, 1, 0)
                GameTooltip:Show()
            end)
            auraFrame:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            -- Store aura properties
            auraFrame.Guid = aura.Guid
            auraFrame.Caster = aura.Caster
            auraFrame.RemainingTurns = aura.RemainingTurns
            auraFrame.Effects = aura.Effects

            -- Save aura in the frame's Auras table
            table.insert(frame.Auras, auraFrame)

            -- Move to the next slot in Buff or Debuff row
            if aura.Type == "Debuff" then
                frame.DebuffCount = frame.DebuffCount + 1
            else
                frame.BuffCount = frame.BuffCount + 1
            end

            -- Show the aura
            auraFrame:Show()
        end
    end

        -- Casting Bar Frame (Sits to the right of the health bar)
    frame.CastingBar = CreateFrame("StatusBar", nil, frame)
    frame.CastingBar:SetSize(180, 5)  -- Width: 80, Height: 5
    frame.CastingBar:SetPoint("LEFT", frame.HealthBar, "RIGHT", 5, 0)  -- Position to the right of the health bar
    frame.CastingBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    frame.CastingBar:SetStatusBarColor(1, 0.7, 0)  -- Orange color for casting
    frame.CastingBar:SetMinMaxValues(0, 1)
    frame.CastingBar:SetValue(0)
    frame.CastingBar:Hide()  -- Initially hidden

    -- Casting Bar Background
    frame.CastingBarBG = frame:CreateTexture(nil, "BACKGROUND")
    frame.CastingBarBG:SetSize(180, 5)
    frame.CastingBarBG:SetPoint("CENTER", frame.CastingBar, "CENTER")
    frame.CastingBarBG:SetColorTexture(0, 0, 0, 0.5)  -- Dark background
    frame.CastingBarBG:Hide()  -- Initially hidden


    -- Casting Bar Border
    frame.CastingBarBorder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.CastingBarBorder:SetSize(184, 9)  -- Slightly larger than the cast bar
    frame.CastingBarBorder:SetPoint("CENTER", frame.CastingBar, "CENTER", 0, 0)
    frame.CastingBarBorder:Hide()  -- Initially hidden

    frame.CastingBarBorder:SetBackdrop({
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
        edgeSize = 8,
    })

    -- Casting Text (Shows Spell Name & Timer)
    frame.CastingText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.CastingText:SetPoint("CENTER", frame.CastingBar, "CENTER", 0, 8)
    frame.CastingText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE") -- Added outline
    frame.CastingText:SetTextColor(1, 1, 1) -- White text
    frame.CastingText:SetText("")  -- Empty initially

    -- Function to Start a Cast
    function frame:StartCasting(spellName, duration)
        frame.CastingBar:SetMinMaxValues(0, duration)
        frame.CastingBar:SetValue(0)
        frame.CastingText:SetText(spellName)
        frame.CastingBar:Show()
        frame.CastingBarBG:Show()  -- Initially hidden
        frame.CastingBarBorder:Show()
    end

    -- Function to Interrupt Cast
    function frame:InterruptCast()
        frame.CastingBar:Hide()
        frame.CastingBarBG:Hide()  -- Initially hidden
        frame.CastingBarBorder:Hide()
        frame.CastingText:SetText("")
    end

    -- Test Cast Button (For Debugging Casting Bar)
    local foo = false
    if foo then
        frame.TestCastButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        frame.TestCastButton:SetSize(50, 20)
        frame.TestCastButton:SetPoint("LEFT", frame, "RIGHT", 40, 5)
        frame.TestCastButton:SetText("Test Cast")
        frame.TestCastButton:SetScript("OnClick", function()
            local testSpell = "Fireball"
            local testDuration = 3  -- Default to 5 ticks if NumBatches is unavailable
            frame:StartCasting(testSpell, testDuration)
        end)
    end

    -- Edit Button (Visible Only to Leader or Solo)
    frame.EditButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.EditButton:SetSize(20, 20)
    frame.EditButton:SetPoint("CENTER", frame, "LEFT", 0, 0)  -- Positioned to the Right
    frame.EditButton:SetNormalTexture("Interface/Buttons/UI-OptionsButton")  -- Blizzard's Gear Icon
    frame.EditButton:Hide()  -- Hidden by Default

    -- Click Event for Edit Button (Opens the Unit Frame Editor)
    frame.EditButton:SetScript("OnClick", function(self)
        UnitFrameEditor:ShowEditor(frame)
    end)

    -- Add a button above the editor button for applying damage or healing
    frame.ModifyHealthButton = CreateFrame("Frame", nil, frame)
    frame.ModifyHealthButton:SetSize(20, 20)
    frame.ModifyHealthButton:SetPoint("BOTTOM", frame.EditButton, "TOP", 0, -38)
    
    frame.ModifyHealthButton.Texture = frame.ModifyHealthButton:CreateTexture(nil, "ARTWORK")
    frame.ModifyHealthButton.Texture:SetAllPoints()
    frame.ModifyHealthButton.Texture:SetTexture("Interface/Icons/delves-scenario-heart-icon")
    frame.ModifyHealthButton.Texture:SetVertexColor(0.8, 0.6, 0.6)

    frame.ModifyHealthButton:EnableMouse(true)
    frame.ModifyHealthButton:SetScript("OnEnter", function()
        if UnitIsGroupLeader("player") then frame.ModifyHealthButton.Texture:SetVertexColor(1, 0.8, 0.8) end -- Highlight color on hover
    end)
    
    frame.ModifyHealthButton:SetScript("OnLeave", function()
        if UnitIsGroupLeader("player") then frame.ModifyHealthButton.Texture:SetVertexColor(0.8, 0.6, 0.6) end -- Revert to default color
    end)

    frame.ModifyHealthButton:SetScript("OnMouseDown", function()
        if not UnitIsGroupLeader("player") then return end

        StaticPopupDialogs["MODIFY_UNIT_HEALTH"] = {
            text = "Enter damage/healing done:",
            button1 = "Damage",
            button2 = "Heal",
            hasEditBox = true,
            OnAccept = function(self)
                local amount = tonumber(self.editBox:GetText())
                if amount and amount > 0 then
                    frame.CurrentHealth = math.max(frame.CurrentHealth - amount, 0)
                    frame.HealthBar:SetValue(frame.CurrentHealth)
                    frame.HealthText:SetText(frame.CurrentHealth)
                    Broadcast:SyncUnitFrame(frame)
                end
            end,
            OnCancel = function(self)
                local amount = tonumber(self.editBox:GetText())
                if amount and amount > 0 then
                    frame.CurrentHealth = math.min(frame.CurrentHealth + amount, frame.MaxHealth)
                    frame.HealthBar:SetValue(frame.CurrentHealth)
                    frame.HealthText:SetText(frame.CurrentHealth)
                    Broadcast:SyncUnitFrame(frame)
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            enterClicksFirstButton = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("MODIFY_UNIT_HEALTH")
    end)

    -- Function to Check if the Button Should Be Shown
    local function UpdateEditButtonVisibility()
        local isLeader = UnitIsGroupLeader("player") or not IsInGroup()
        if isLeader then
            frame.EditButton:Show()
            frame.ModifyHealthButton:Show()
        else
            frame.EditButton:Hide()
            frame.ModifyHealthButton:Hide()
        end
    end

    -- Visibility Icon (Only for Leader)
    frame.VisibilityButton = CreateFrame("Button", nil, frame)
    frame.VisibilityButton:SetSize(20, 20)
    frame.VisibilityButton:SetPoint("RIGHT", frame, "LEFT", -10, -1)

    -- Set Blizzard UI Visibility Icons
    local visibleIcon = "Interface/COMMON/Indicator-Green"  -- Eye Open
    local invisibleIcon = "Interface/COMMON/Indicator-Red"   -- Eye Closed

    frame.VisibilityButton:SetNormalTexture(visibleIcon)  -- Default Visible Icon
    if UnitIsGroupLeader("player") then frame.VisibilityButton:Show()  -- Hidden by Default
    else frame.VisibilityButton:Hide() end

    -- Function to Toggle Visibility
    frame.isVisible = true  -- Default: Visible

    frame.VisibilityButton:SetScript("OnClick", function(self)
        frame.isVisible = not frame.isVisible
        self:SetNormalTexture(frame.isVisible and visibleIcon or invisibleIcon)

        -- Leader: Reduce Opacity Instead of Hiding
        if UnitIsGroupLeader("player") or not IsInGroup() then
            frame:SetAlpha(frame.isVisible and 1 or 0.5)  -- Set to 50% opacity if hidden

            if frame.NPCNameLabel:GetText() == Targeting.npcTarget then
                -- If the target is the same, clear it and reset the background color
                Targeting:ChangeNpcTarget("NONE")
            
                frame.background:SetColorTexture(0, 0, 0, 0)  -- Reset to original color
            end
        end

        -- Broadcast Visibility Change to Group Members
        if IsInGroup() and UnitIsGroupLeader("player") then
            local frameID = frame:GetName()
            local visibilityState = frame.isVisible and "SHOW" or "HIDE"
            local message = string.format("VIS:%s;%s", frameID, visibilityState)
            local channel = IsInRaid() and "RAID" or "PARTY"
            C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, channel)
        end
    end)


    -- Function to Check if the Visibility Button Should Be Shown
    local function UpdateVisibilityButton()
        local isLeader = UnitIsGroupLeader("player") or not IsInGroup()
        if isLeader then
            frame.VisibilityButton:Show()
        else
            frame.VisibilityButton:Hide()
        end
    end

    UnitFrames.frames[index] = frame
    return frame
end

-- Create 8 Unit Frames
for i = 1, 8 do
    CreateUnitFrame(i)

    -- Create a draggable icon (handle) for dragging the whole UI
    local dragIcon = CreateFrame("Button", "UnitFramesDragIcon", UnitFrames, "UIPanelButtonTemplate")
    dragIcon:SetSize(20, 20)
    dragIcon:SetPoint("TOPLEFT", UnitFrames, "TOPLEFT", 0, 25)  -- Position the icon to the left of the first unit frame

    -- Set a Blizzard interface icon (e.g., the "Interface/Buttons/UI-OptionsButton" gear icon)
    dragIcon:SetNormalTexture("Interface/Buttons/UI-OptionsButton")  -- Use a built-in Blizzard icon
    
    -- Allow dragging of the whole UI via the icon
    dragIcon:SetMovable(true)
    dragIcon:EnableMouse(true)
    dragIcon:RegisterForDrag("LeftButton")
    dragIcon:SetScript("OnDragStart", function(self)
        UnitFrames:StartMoving()  -- Start moving the entire UnitFrames container
    end)
    dragIcon:SetScript("OnDragStop", function(self)
        UnitFrames:StopMovingOrSizing()  -- Stop moving the UnitFrames container
    end)
end

-- Reorders unit frames to ensure there are no gaps.
local function ReorderUnitFrames()
    local yOffset = 0
    for _, frame in ipairs(UnitFrames.frames) do
        if frame.isVisible then
            frame:ClearAllPoints()
            frame:SetPoint("TOP", UnitFrames, "TOP", 0, -yOffset)
            yOffset = yOffset + 55  -- Space between unit frames
        end
    end
end
-- Event Handler for Visibility Updates
local function OnGroupUpdate()
    for _, frame in ipairs(UnitFrames.frames) do
        if frame then
            if UpdateEditButtonVisibility then UpdateEditButtonVisibility(frame) end
            if UpdateVisibilityButton then UpdateVisibilityButton(frame) end
        end
    end

    -- If we are the leader, broadcast a sync to ensure all frames match
    if UnitIsGroupLeader("player") then
        for _, frame in ipairs(UnitFrames.frames) do
            Broadcast:SyncUnitFrame(frame)
        end
    else
        Request:SyncUnitFrame()  -- Request sync after 3 seconds
    end
end

local function HasCondition(frame, condition)
    if frame.Auras then
        for _, aura in ipairs(frame.Auras) do
            if aura.Effects and #aura.Effects > 0 then
                print(#aura.Effects)
                for _, effect in ipairs(aura.Effects) do
                    if effect.Type == condition then return true end
                end
            end
        end
    end

    return false
end

local function CheckForConditions(frame)
    local stun = HasCondition(frame, "Stun")
    local incapacitate = HasCondition(frame, "incapacitate")
    local slow = HasCondition(frame, "Slow")

    return stun, incapacitate, slow
end

-- Updates the give unit frame (direct reference) with the given data.
local function UpdateUnitFrame(frame, data)
    -- Set Raid Marker
    if frame.RaidMarker then
        if data.raidMarker >= 1 and data.raidMarker <= 8 then
            frame.RaidMarker:SetTexture("Interface/TargetingFrame/UI-RaidTargetingIcon_" .. data.raidMarker)
            frame.RaidMarker:Show()
        else
            frame.RaidMarker:Hide()
        end
    end

    -- Set Max and Current Health
    if frame.HealthBar then
        frame.MaxHealth = data.maxHealth or 100
        frame.CurrentHealth = math.max(0, math.min(data.currentHealth or frame.MaxHealth, frame.MaxHealth))  -- Clamp between 0 and Max

        -- Update the shrinking health bar
        frame.HealthBar:SetMinMaxValues(0, frame.MaxHealth)
        frame.HealthBar:SetValue(frame.CurrentHealth)
    end

    -- Set Health Text (Only Current Health)
    if frame.HealthText then
        frame.HealthText:SetText(frame.CurrentHealth)
    end

    -- Apply NPC Name
    if frame.NPCNameLabel then
        if not data.NPCNameLabel or data.NPCNameLabel == "" then
            unnamedNPCCount = unnamedNPCCount + 1
            frame.NPCNameLabel:SetText("Unit Frame [" .. unnamedNPCCount .. "]")
            frame.NPCName = frame.NPCNameLabel:GetText()
        else
            frame.NPCNameLabel:SetText(data.NPCNameLabel)
            frame.NPCName = frame.NPCNameLabel:GetText()
        end
    end

    -- Reorder Frames to Remove Gaps
    ReorderUnitFrames()
end

-- Called when the active batch changes and highlights all npcs taking their turns in yellow.
function UnitFrames:HighlightActiveBatch(activeBatch)
    for _, frame in pairs(UnitFrames.frames) do
        if frame and frame.NPCNameLabel then
            local unitName = strtrim(frame.NPCNameLabel:GetText() or "")

            -- Check if the unit is in the active batch
            local isActive = false
            for _, activeUnit in ipairs(activeBatch or {}) do
                if strtrim(activeUnit) == unitName then
                    isActive = true
                    break
                end
            end

            -- Change name color based on active status
            if isActive then
                frame.NPCNameLabel:SetTextColor(1, 1, 0) -- Yellow for active turn
            else
                frame.NPCNameLabel:SetTextColor(1, 1, 1) -- White for inactive
            end
        end
    end
end

-- Called when the active batch changes. Causes the NPC turn button to show on any npc whose turn it now is.
function UnitFrames:OnUnitFrameTurn(activeBatch)
    for _, frame in pairs(UnitFrames.frames) do
        if frame and frame.NPCNameLabel then
            local unitName = strtrim(frame.NPCNameLabel:GetText() or "")

            -- Check if the unit is in the active batch
            local isActive = false
            for _, activeUnit in ipairs(activeBatch or {}) do
                if strtrim(activeUnit) == unitName then
                    isActive = true
                    break
                end
            end

            -- If active, create or show the button
            if isActive then          
                local stun, incapacitate, slow = CheckForConditions(frame)

                -- Restore the number of Actions. If the target is stunned or incapacitated, set their 
                -- actions remaining to zero instead.
                frame.ActionsRemaining = (stun or incapacitate) and 0 or frame.MaxActions

                if not frame.NpcTurnButton then
                    -- Create the button if it doesn't exist
                    frame.NpcTurnButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
                    frame.NpcTurnButton:SetSize(20, 20)
                    frame.NpcTurnButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)

                    frame.NpcTurnButton:EnableMouse(true)

                    -- Set a placeholder icon (replace with a real texture later)
                    frame.NpcTurnButton:SetNormalTexture("Interface\\ICONS\\inv_faction_orderofembers_round")

                    -- Click event: Left-click opens turn UI, Right-click ends turn
                    frame.NpcTurnButton:SetScript("OnMouseDown", function(self, button)
                        if button == "LeftButton" then
                            UnitFrameTurn:ShowTurnUI(frame)
                        elseif button == "RightButton" then
                            frame.ActionsRemaining = 0
                            UnitFrameTurn.actionsRemaining = 0
                            UnitFrameTurn:UpdateActionsRemaining()
                            UnitFrameTurn:Send_LockPortrait(frame.NPCName)
                        end
                    end)

                    -- Tooltip
                    frame.NpcTurnButton:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

                        -- Set both lines using the small game font
                        GameTooltip:AddLine("Left-click to choose actions", 0.7, 0.7, 0.7, true)
                        GameTooltip:AddLine("Right-click to end turn", 0.7, 0.7, 0.7, true)

                        -- Force small font on all tooltip text
                        for i = 1, GameTooltip:NumLines() do
                            _G["GameTooltipTextLeft" .. i]:SetFontObject(GameFontNormalSmall)
                        end

                        GameTooltip:Show()
                    end)

                    frame.NpcTurnButton:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                    end)
                end

                frame.NpcTurnButton:Show()
            else
                -- Hide the button if the unit is not in the active batch
                if frame.NpcTurnButton then
                    frame.NpcTurnButton:Hide()
                end
            end
        end
    end
end

-- Example: Assigning random data for testing
for i, frame in ipairs(UnitFrames.frames) do
    local defaultData = {
        raidMarker = (i - 1) % 8 + 1,  -- Sequential markers 1 → 8
        health = 100,
        maxHealth = 100,
        armour = 5
    }
    UpdateUnitFrame(frame, defaultData)
end

-- Make the Main Frame Draggable
UnitFrames:SetMovable(true)
UnitFrames:EnableMouse(true)
UnitFrames:RegisterForDrag("LeftButton")
UnitFrames:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
UnitFrames:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

-- Called when the turn batch changes and causes all active spell bars to tick up.
function UnitFrames:AdvanceSpellcastBars()
    for _, frame in pairs(UnitFrames.frames) do
        if frame.CastingBar and frame.CastingBar:IsShown() then
            local currentTick = frame.CastingBar:GetValue() + 1  -- Advance by 1 tick
            local minTicks, maxTicks = frame.CastingBar:GetMinMaxValues()  -- Get the casting duration in ticks

            -- Update the casting bar progress
            frame.CastingBar:SetValue(currentTick)

            -- Check if casting is complete
            if currentTick >= maxTicks then
                print("Casting Complete: " .. frame.CastingText:GetText() .. " for " .. frame.NPCNameLabel:GetText())

                -- Reset cast bar & text
                frame.CastingBar:Hide()
                frame.CastingBarBorder:Hide()
                frame.CastingText:SetText("")
            end
        end
    end
end



-- Called when a unit frame is damaged.
local function Handle_Damage(data)
    local args = { strsplit(";", data) }
    local source, targetUnit, damage, school = args[1], args[2], args[3], args[4]

    UnitFrames:ApplyDamage(source, targetUnit, damage, school)
end

-- Called when a unit frame aura is applied or removed
local function Handle_AddAura(data)
    print("[UnitFrames] - Obsolete method called. Use Handle:AddAuraUnitFrame instead.")
end

-- Called when a player begins their turn, and causes any auras that they have cast to tick down.
function UnitFrames:UpdateAuraTurns(caster, auraGuid)
    local expiredAuras = {}  -- Store expired auras along with their parent frame

    -- ✅ First pass: Update all auras (DO NOT remove them yet)
    local redraw = false
    for _, frame in pairs(UnitFrames.frames) do
        if frame.Auras then
            for _, aura in ipairs(frame.Auras) do
                if aura.Guid == auraGuid and aura.Caster == caster then
                    -- Reduce remaining turns
                    local newTurns = math.max(0, aura.RemainingTurns - 1)

                    -- ✅ Update UI with new turn count
                    aura.RemainingTurns = newTurns                   
                    aura.TurnsText:SetText(newTurns)

                    if newTurns == 0 then
                        -- Print combat log
                        redraw = true
                        aura:Hide()
                    end
                end
            end
        end
    end

    if redraw then UnitFrames:RedrawAllAuras() end
end

-- Redraws all auras. Used to keep the auras in the right place and flush to the side of the unit frame when one is added or removed.
function UnitFrames:RedrawAllAuras()
    for _, frame in pairs(UnitFrames.frames) do
        if frame.AuraContainer then
            -- ✅ Step 1: Clear the Auras list and reset Buff/Debuff counters
            frame.Auras = {}
            frame.BuffCount = 0
            frame.DebuffCount = 0

            -- ✅ Step 2: Ensure AuraContainer is properly positioned
            frame.AuraContainer:ClearAllPoints()
            frame.AuraContainer:SetPoint("LEFT", frame, "RIGHT", 5, 0) -- Anchor to the right of the unit frame

            -- ✅ Step 3: Iterate through existing auras and reposition them using AddAura logic
            for _, aura in ipairs({ frame.AuraContainer:GetChildren() }) do
                if aura:IsShown() then
                    -- Base the y offset on Buffs (top row) or Debuffs (bottom row)
                    local auraIndex, yOffset

                    if aura.Type == "Debuff" then
                        auraIndex = frame.DebuffCount
                        yOffset = -10  -- Place Debuffs on lower row
                        frame.DebuffCount = frame.DebuffCount + 1
                    else
                        auraIndex = frame.BuffCount
                        yOffset = 20  -- Place Buffs on top row
                        frame.BuffCount = frame.BuffCount + 1
                    end

                    -- ✅ Reposition the aura exactly as in AddAura
                    aura:ClearAllPoints()
                    aura:SetPoint("TOPLEFT", frame.AuraContainer, "TOPLEFT", auraIndex * 18, yOffset)

                    -- ✅ Store in Auras list again
                    table.insert(frame.Auras, aura)
                else
                    aura:Hide()  -- Hide completely if it's not visible
                end
            end
        end
    end
end

-- Called when a unit frame is aura is applied or removed
local function Handle_RemoveAura(data)
    print("[UnitFrames] - Obsolete method called. Use Handle:RemoveAuraUnitFrame instead.")
end


-- Called when unit frame data needs to be synced across party members.
function UnitFrames:Handle_Sync(data)
    local args = { strsplit(";", data) }
    local frameID, visibilityState, npcName, npcID, currentHealth, maxHealth, modelX, modelY, modelZ, meleeAC, rangedAC, spellAC =
        args[1], args[2], args[3], tonumber(args[4]), tonumber(args[5]), tonumber(args[6]), tonumber(args[7]), tonumber(args[8]), tonumber(args[9]), tonumber(args[10]), tonumber(args[11]), tonumber(args[12])

    if not frameID then return end

    local frame = _G[frameID]
    if frame then
        -- Sync unit frame visibility
        frame.isVisible = (visibilityState == "SHOW")

        if frame.isVisible ~= isVisible then
            UpdateGroupMembers()  -- Ensure TurnTracker is updated with the new visibility
        end

        if not frame.isVisible and Targeting.npcTarget == frame.NPCNameLabel:GetText() then
            Targeting:ChangeNpcTarget("NONE")
            frame.background:SetColorTexture(0, 0, 0, 0)  -- Reset to original color
        end

        if not UnitIsGroupLeader("player") then
            frame:SetShown(frame.isVisible)
        end

        -- Sync edit button visibility
        if frame.EditButton then
            if UnitIsGroupLeader("player") then
                frame.EditButton:Show()
            else
                frame.EditButton:Hide()
            end
        end

        -- Apply NPC Name
        if frame.NPCName and npcName then
            frame.NPCName = npcName
            frame.NPCNameLabel:SetText(frame.NPCName)
        end

        -- Apply NPC model
        if frame.NPCID and npcID then
            frame.NPCID = npcID
            frame.Portrait:SetDisplayInfo(frame.NPCID)

            if frame.ModelPosition and modelX then
                frame.ModelPosition["x"] = modelX
            end

            if frame.ModelPosition and modelY then
                frame.ModelPosition["y"] = modelY
            end

            if frame.ModelPosition and modelZ then
                frame.ModelPosition["z"] = modelZ
            end

            frame.Portrait:SetPosition(modelX, modelY, modelZ)
        end

        -- Apply Health Values
        if frame.HealthBar and maxHealth and currentHealth then
            frame.MaxHealth = maxHealth
            frame.CurrentHealth = math.min(currentHealth, maxHealth)
            
            frame.HealthBar:SetMinMaxValues(0, maxHealth)
            frame.HealthBar:SetValue(frame.CurrentHealth)
        end
        if frame.HealthText and currentHealth then
            frame.HealthText:SetText(currentHealth)
        end

        -- Apply the AC values
        frame.DefensiveAC["Melee"] = meleeAC
        frame.DefensiveAC["Ranged"] = rangedAC
        frame.DefensiveAC["Spell"] = spellAC
    end
end

-- Called when a unit frame's aura is applied or removed
local function Handle_DamagePlayer(data)
    -- Split the data string into components using ";" as delimiter
    local args = { strsplit(";", data) }
    local source, player, damage, school, type = args[1], args[2], args[3], args[4], args[5]


    -- Split the player name if it includes a realm (for example, "PlayerName-Realm")
    local playerName, playerRealm = strsplit("-", player)
    playerName = playerName or player -- Fallback in case the split doesn't work

    CombatLog:PrintMessage(string.format("%s deals %s %s damage to %s.", source, damage, school, player))

    -- Check if the current player is the one who was damaged
    if UnitName("player") == playerName then
        -- Subtract health.
        local currentHealth = _G.hiddenStats["Health"]
    
        -- Get mitigation.
        local mitigation = 0
        local coefficient = 1
        if type == "DIRECT" then
            if school == "Physical" then
                mitigation = _G.hiddenStats["Armor"]
            else
                mitigation = tonumber(_G.resistanceFrames[school].mit:GetText())
            end
        else
            coefficient = 0.5
            if school == "Physical" then
                mitigation = math.floor(_G.hiddenStats["Armor"] * coefficient)
            else
                mitigation = math.floor(tonumber(_G.resistanceFrames[school].mit:GetText()) * coefficient)
            end       
        end

        -- Calculate final damage.
        local finalDamage = damage - mitigation

        -- Clamp the final damage between 0 and current health
        finalDamage = math.max(0, math.min(finalDamage, currentHealth))

        -- Apply the final damage to health
        _G.hiddenStats["Health"] = _G.hiddenStats["Health"] - finalDamage
        
        -- Print the damage dealt
        -- print(unitFrame .. " dealt " .. finalDamage .. " (" ..damage.. " -" ..mitigation.. ") " .. school .. " damage to " .. player)

        -- Print the current health and mitigation used
        -- print("Health: " ..currentHealth.. " -> " .. _G.hiddenStats["Health"])

        -- Update health and mana (assuming _G.UpdateHealthAndMana() handles UI updates)
        _G.UpdateHealthAndMana()
    end
end

local function Handle_Visibility(data)
    -- Only call this function on the client side.
    if UnitIsGroupLeader("Player") then return end

    -- Split the data string into components using ";" as delimiter
    local args = { strsplit(";", data) }
    local frameID, visibilityState = args[1], args[2]

    local frame = _G[frameID]
    if frame then
        frame.isVisible = (visibilityState == "SHOW")

        if frame.isVisible then 
            frame:Show() 
        else 
            frame:Hide() 
        end

        ReorderUnitFrames()

        if not frame.isVisible and Targeting.npcTarget == frame.NPCNameLabel:GetText() then
            Targeting:ChangeNpcTarget("NONE")
            frame.background:SetColorTexture(0, 0, 0, 0)  -- Reset to original color
        end
    end
end

local function OnAddonMessage(self, event, prefix, message, sender)
    if prefix ~= ADDON_PREFIX then return end  -- Ignore unrelated messages

    -- Syncs the unit frames if a player requests it.
    if message == "REQUEST_SYNC" and UnitIsGroupLeader("player") then
        for _, frame in ipairs(UnitFrames.frames) do
            Broadcast:SyncUnitFrame(frame)
        end
        return
    end

    -- Handle all other inputs.
    local data = message
    if string.sub(message, 1, 4) == "VIS:" then
        data = string.sub(message, 5)
        Handle_Visibility(data)
    end
end


-- Function to handle unit frame clicks, i.e., for targeting a unit frame.
local function OnUnitFrameClick(self, button)
    -- Set npcTarget to the name of the NPC in the clicked unit frame
    local npcTarget = self.NPCNameLabel:GetText()

    -- Check if the target is already selected, and clear it if clicked again
    if Targeting then
        if npcTarget == Targeting.npcTarget then
            -- If the target is the same, clear it and reset the background color
            Targeting:ChangeNpcTarget("NONE")

            -- Reset the background color of all frames
            for _, frame in ipairs(UnitFrames.frames) do
                if frame.background then
                    frame.background:SetColorTexture(0, 0, 0, 0)  -- Reset to original color
                end
                return
            end
        else
            -- If it's a new target, set it and change the background color of the clicked frame
            Targeting:ChangeNpcTarget(npcTarget)
        end
    else
        print("|cffff0000Error: Targetting module not loaded yet.|r")
    end

    -- Reset the background color change from previously selected unit frames
    for _, frame in ipairs(UnitFrames.frames) do
        if frame.background then
            frame.background:SetColorTexture(0, 0, 0, 0)  -- Reset to original color
        end
    end

    -- Change the background color of the clicked unit frame to a slightly lighter shade
    if not self.background then
        self.background = self:CreateTexture(nil, "BACKGROUND")
        self.background:SetAllPoints(self)
        self.background:SetColorTexture(0.2, 0.2, 0.2, 1)  -- Dark color
    end

    -- Set the background color to a slightly lighter shade to indicate it's selected
    self.background:SetColorTexture(0.3, 0.3, 0.3, 1)
end

-- Assuming the unit frames are created dynamically, add the OnClick handler
for _, frame in ipairs(UnitFrames.frames) do
    frame:SetScript("OnMouseDown", OnUnitFrameClick)
end

-- Called when a unit frame deals direct damage (i.e., via an attack) to a player.
function UnitFrames:DamagePlayer(unitFrame, player, type)
    local typeFormatted = type

    if type:upper() == "MELEE" then typeFormatted = "Melee"
    elseif type:upper() == "RANGED" then typeFormatted = "Ranged"
    elseif type:upper() == "SPELL" then typeFormatted = "Spell"
    end

    if typeFormatted == "Melee" or typeFormatted == "Ranged" or typeFormatted == "Spell" then
        -- Find the corresponding unit frame
        for _, frame in pairs(UnitFrames.frames) do
            if frame.NPCNameLabel and frame.NPCNameLabel:GetText() == unitFrame then
                -- Get the spell's dice, bonus and school, then calculate the damage done (before mitigation)
                local dice = frame.OffensiveModifiers[typeFormatted].damageDice
                local bonus = frame.OffensiveModifiers[typeFormatted].attackBonus
                local school = frame.OffensiveModifiers[typeFormatted].school

                local damage = Dice.Simple(string.format("%s+%s", dice, bonus))

                -- After getting the damage done (before mitigation), send a message to all players
                -- notifying them of the damage dealt to the player. For the player, calculate mitigation
                -- and modify health accordingly.
                Broadcast:DamagePlayer(unitFrame, player, damage, school, "DIRECT")

                -- Original damage player message.
                -- local message = string.format("%s;%s;%s;%s", unitFrame, player, damage, school)
                -- local channel = IsInRaid() and "RAID" or "PARTY"
                -- C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "DAMAGE_PLAYER:" .. message, channel)
                -- Original damage player message

                return
            end
        end    
    elseif string.sub(type, 1, 4) == "USER" then
        for _, frame in pairs(UnitFrames.frames) do
            if frame.NPCNameLabel and frame.NPCNameLabel:GetText() == unitFrame then
                -- ✅ Extract the spell index from "USER[XXX]"
                local index = tonumber(string.match(type, "USER%[(%d+)%]"))  

                print(frame.UFSpells[index].Name)

                -- ✅ Ensure index is valid before proceeding
                if index and frame.UFSpells and frame.UFSpells[index] then
                    local spell = frame.UFSpells[index]
                    
                    -- Get the spell's dice, bonus and school, then calculate the damage done (before mitigation)
                    local dice = spell.Dice
                    local bonus = spell.Bonus or 0
                    local school = spell.School

                    local damage = Dice.Simple(string.format("%s+%s", dice, bonus))

                    -- After getting the damage done (before mitigation), send a message to all players
                    -- notifying them of the damage dealt to the player. For the player, calculate mitigation
                    -- and modify health accordingly.
                    Broadcast:DamagePlayer(unitFrame, player, damage, school, "DIRECT")

                    -- Apply aura?
                    if spell.Aura then
                        CTAura:ApplyAura(player, UnitName("player"), spell.Aura)
                    end
                else
                    print("Error: Invalid user spell index:", index)
                end
            end
        end  
    end
end

-- Called from Targeting.lua (which gets the correct target(s) to damage.)
-- Damages the given unit frame. This is called on all players' sides.
function UnitFrames:ApplyDamage(source, targetUnit, damage, school)
    if not targetUnit or targetUnit == "NONE" then
        print("|cffff0000Error: No valid target selected.|r")
        return
    end

    -- Find the corresponding unit frame
    for _, frame in pairs(UnitFrames.frames) do
        if frame.NPCNameLabel and frame.NPCNameLabel:GetText() == targetUnit then
            frame.CurrentHealth = math.max(frame.CurrentHealth - damage, 0)
            frame.HealthBar:SetValue(frame.CurrentHealth)
            frame.HealthText:SetText(frame.CurrentHealth)

            -- Prints a message to the unit frame.
            local message = string.format("%s deals %s %s damage to %s.", source, damage, school, frame.NPCNameLabel:GetText())
            CombatLog:PrintMessage(message)

            -- Optionally handle unit death
            if frame.CurrentHealth <= 0 then
                print(targetUnit .. " has been defeated!")
            end
            return
        end
    end

    print("|cffff0000Error: Unit frame not found for target: " .. targetUnit.. "|r")
end

function UnitFrames:HideAllUnitFrames()
    for _, frame in pairs(UnitFrames.frames) do
        frame:Hide()
    end
end

function UnitFrames:ShowAllUnitFrames()
    for _, frame in pairs(UnitFrames.frames) do
        if frame.isVisible then frame:Show() end
    end
end

-- Register the Event Listener
if not unitFrameListener then
    unitFrameListener = CreateFrame("Frame")
    unitFrameListener:RegisterEvent("GROUP_ROSTER_UPDATE")
    unitFrameListener:RegisterEvent("PLAYER_ENTERING_WORLD")
    unitFrameListener:RegisterEvent("CHAT_MSG_ADDON")

    unitFrameListener:SetScript("OnEvent", function(self, event, ...)
        if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
            OnGroupUpdate()
        elseif event == "CHAT_MSG_ADDON" then
            OnAddonMessage(self, event, ...)
        end
    end)
end


-- Store globally for debugging
_G.CampaignToolkit_UnitFrames = UnitFrames

