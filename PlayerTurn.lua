local ADDON_PREFIX = "CTSPT"
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
print("[CTSPlayerTurn] Addon prefix registered.")

local PlayerTurn = {}
_G.PlayerTurn = PlayerTurn

-- Turn-based resources remaining
_G.playerHasAction = true
_G.playerHasBonusAction = true
_G.playerHasReacion = true
_G.playerCanDodge = true
_G.playerCanParry = true
_G.playerCanBlock = true

local actionBar = nil  -- Initialize actionBar as nil
local spellSlots = {}
local toggleButton = nil
local offsetXSlider = nil
local offsetYSlider = nil
local currentOffsetX = 0  -- Initial X offset
local currentOffsetY = -50  -- Initial Y offset
local sliderFrame = nil

_G.equippedSpells = _G.equippedSpells or {}

-- Store health and mana bars outside the method for global access
local healthBar, manaBar, healthText, manaText


-- Called when the player's turn begins.
function PlayerTurn:OnPlayerTurn()
    print("### Your turn has begun! ###")
    
    -- Restore the player's turn-based resources
    _G.playerHasAction = true
    _G.playerHasBonusAction = true
    _G.playerHasReacion = true
    _G.playerCanDodge = true
    _G.playerCanParry = true
    _G.playerCanBlock = true

    ShowPlayerTurnUI()

    -- Advances any auras that the player has cast.
    CTAura:AdvanceTurn()
end

-- Shows the player turn UI.
function ShowPlayerTurnUI()
    DisplayActionBar()
    RefreshActionBar()
    PlayerTurn:CreateEndTurnButton()
    PlayerTurn:CreateHealthAndManaBars()
end

function HideActionBar() 
    if actionBar then
        actionBar:Hide()
        healthBar:Hide()
        manaBar:Hide()
        healthText:Hide()
        manaText:Hide()
    end


end

function ShowActionBar() 
    if actionBar then
        actionBar:Show()
        healthBar:Show()
        manaBar:Show()
        healthText:Show()
        manaText:Show()
    else
        DisplayActionBar()
        RefreshActionBar()
        PlayerTurn:CreateEndTurnButton()
        PlayerTurn:CreateHealthAndManaBars()
    end
end

local function CreateSliderFrame()
    -- Create a frame to hold the sliders and make it draggable
    local sliderFrame = CreateFrame("Frame", "SliderFrame", UIParent, "BackdropTemplate")
    sliderFrame:SetSize(220, 100)  -- Adjust size for a better layout
    sliderFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)  -- Center the slider window on the screen
    sliderFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    sliderFrame:SetBackdropColor(0, 0, 0, 0.7)  -- Set background color to black

    -- Enable the slider frame to be draggable
    sliderFrame:SetMovable(true)
    sliderFrame:EnableMouse(true)
    sliderFrame:RegisterForDrag("LeftButton")
    sliderFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    sliderFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    return sliderFrame
end

local function CreateOffsetSlider(sliderName, currentValue, minVal, maxVal, sliderWidth, sliderFrame, onValueChangedCallback, yOffset)
    -- Create a new frame for the slider
    local offsetSlider = CreateFrame("Slider", sliderName, sliderFrame, "OptionsSliderTemplate")
    offsetSlider:SetMinMaxValues(minVal, maxVal)  -- Set min and max values for the offset
    offsetSlider:SetValue(currentValue)  -- Set initial value for the offset
    offsetSlider:SetWidth(sliderWidth)  -- Set the width of the slider
    offsetSlider:SetPoint("TOP", sliderFrame, "TOP", 0, -yOffset)  -- Position it inside the frame

    -- Slider value change handler
    offsetSlider:SetScript("OnValueChanged", onValueChangedCallback)

    -- "+" and "-" labels for the slider
    offsetSlider.low = offsetSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    offsetSlider.low:SetPoint("LEFT", offsetSlider, "LEFT", 0, 0)
    offsetSlider.low:SetText("-")

    offsetSlider.high = offsetSlider:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    offsetSlider.high:SetPoint("RIGHT", offsetSlider, "RIGHT", 0, 0)
    offsetSlider.high:SetText("+")

    return offsetSlider
end

local isSliderMoving = false  -- To prevent stuttering, we'll track whether the slider is being actively moved
function DisplayActionBar()
    -- If the action bar is already created, just show it
    if actionBar then 
        actionBar:Show()
        return
    end

    -- Define the number of rows and columns, as well as slot size
    local SLOT_SIZE, SLOT_PADDING, ROWS, COLUMNS = 54, -16, 2, 5  -- Initial 2 rows of 5 slots
    local newColumns = 8  -- Total columns after adding 6 more slots (5 original + 3 new for second group)
    local totalWidth = newColumns * SLOT_SIZE + (newColumns - 1) * SLOT_PADDING  -- Total width of all columns, considering padding
    local totalHeight = ROWS * SLOT_SIZE + (ROWS - 1) * SLOT_PADDING  -- Total height of all rows, considering padding

    -- Create the action bar frame
    actionBar = CreateFrame("Frame", "MyActionBar", UIParent)  
    actionBar:SetSize(totalWidth, totalHeight)  -- Set the action bar size based on the number of slots
    actionBar:SetPoint("CENTER", UIParent, "CENTER", currentOffsetX, currentOffsetY)  -- Position it based on offsets

    -- Create the background texture manually for the action bar
    local background = actionBar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(actionBar)
    background:SetColorTexture(0, 0, 0, 0.7)  -- Transparent black background (70% opacity)
    background:Hide()

    local startX, startY = 0, 0  -- Starting position for the first slot (no extra offset)

    -- Call the function to create action bar slots
    CreateActionBarSlots(2, 5, 0, 0)  -- 2 rows and 5 columns, starting from (0, 0)
    CreateActionBarSlots(2, 3, 200, 0)  -- 3 rows and 2 columns, starting from (0, -100)

    -- Create the Move Action Bar button to the left of the action bar using the UI-OptionsButton icon
    local moveButton = CreateFrame("Button", "MoveButton", actionBar, "UIPanelButtonTemplate")
    moveButton:SetSize(30, 30)
    moveButton:SetPoint("RIGHT", actionBar, "LEFT", 0, 0)  -- Position it above the action bar
    moveButton:SetNormalTexture("Interface\\Buttons\\UI-OptionsButton")  -- UI-OptionsButton icon texture

    -- Toggle visibility of sliders when the button is clicked
    moveButton:SetScript("OnClick", function()
        if sliderFrame:IsShown() then
            sliderFrame:Hide()
        else
            sliderFrame:Show()
        end
    end)

    -- Create the slider frame
    sliderFrame = CreateSliderFrame()

    -- Create X offset slider (using the new function)
    CreateOffsetSlider("OffsetXSlider", currentOffsetX, -200, 200, 180, sliderFrame, function(self, value)
        currentOffsetX = value
        -- Move the action bar live as the slider is adjusted
        if not isSliderMoving then
            actionBar:SetPoint("CENTER", UIParent, "CENTER", currentOffsetX, currentOffsetY)      
        end
    end, 10)

    -- Create Y offset slider (using the new function)
    CreateOffsetSlider("OffsetYSlider", currentOffsetY, -200, 200, 180, sliderFrame, function(self, value)
        currentOffsetY = value
        -- Move the action bar live as the slider is adjusted
        if not isSliderMoving then
            actionBar:SetPoint("CENTER", UIParent, "CENTER", currentOffsetX, currentOffsetY)
        end
    end, 40)

    -- Initially hide the sliders
    sliderFrame:Hide()
end

-- Function to create action bar slots dynamically and populate existing spellSlots table
local slotId = 1
function CreateActionBarSlots(rows, columns, startX, startY)
    local totalSlots = rows * columns

    local SLOT_SIZE, SLOT_PADDING, ROWS, COLUMNS = 54, -16, 2, 5  -- Initial 2 rows of 5 slots

    -- Loop through the rows and columns to create slots
    for i = 1, totalSlots do
        local slot = CreateFrame("Button", "ActionBarSlot" .. i, actionBar)
        slot:SetSize(SLOT_SIZE, SLOT_SIZE)

        slot.id = slotId

        -- Calculate row and column positions
        local row, col = math.floor((i - 1) / columns), (i - 1) % columns

        -- Position the slot within the action bar frame
        slot:SetPoint("TOPLEFT", actionBar, "TOPLEFT", startX + (col * (SLOT_SIZE + SLOT_PADDING)), startY - (row * (SLOT_SIZE + SLOT_PADDING)))

        -- Background texture
        slot.texture = slot:CreateTexture(nil, "BACKGROUND")
        slot.texture:SetAllPoints(slot)
        slot.texture:SetTexture("Interface\\Buttons\\UI-EmptySlot")

        -- Foreground icon (spell icon)
        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetSize(SLOT_SIZE - 32, SLOT_SIZE - 32)
        slot.icon:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        slot.icon:Hide()

        -- If the spell has requirements, check them and lock the icon if they are not met.
        slot.usable = true
        local spell = _G.equippedSpells[slot.id]  -- Get the spell GUID for this slot
        if spell and spell.Guid then
            slot.usable = CTSpell:CheckRequirements(spell)

            if not usable then
                slot.icon:SetVertexColor(1, 0.5, 0.5)  -- Apply a grey color
                slot.usable = false
            else
                slot.icon:SetVertexColor(1, 1, 1)  -- Apply a grey color      
                slot.usable = true
            end
        end

        -- Add a border for hover effect
        slot.glowBorder = slot:CreateTexture(nil, "OVERLAY")
        slot.glowBorder:SetSize(SLOT_SIZE + 10, SLOT_SIZE + 10)  -- A bit larger than the slot size
        slot.glowBorder:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.glowBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")  -- Replace with a glow texture if you have one
        slot.glowBorder:SetBlendMode("ADD")
        slot.glowBorder:SetAlpha(0)  -- Initially hide the glow
        slot.glowBorder:Hide()  -- Make sure it's hidden initially


        -- Handle right-click to use the spell associated with the slot
        slot:SetScript("OnMouseDown", function(self, button)
            if not slot.usable then return end

            if button == "LeftButton" then
                -- print("Clicked spell slot " ..slot.id)

                slot.glowBorder:SetAlpha(0.7)

                -- Trigger Spell:Use(guid) for the corresponding spell
                local spell = _G.equippedSpells[slot.id]  -- Get the spell GUID for this slot
                if spell and spell.Guid then
                    CTSpell:Use(spell.Guid)  -- Use the spell
                    -- print("Used spell with GUID: " .. spell.Guid)  -- Debugging (optional)
                end
            end
        end)

        slot:SetScript("OnMouseUp", function(self, button)
            if not slot.usable then return end

            if button == "LeftButton" then
                slot.glowBorder:SetAlpha(0.4)
            end
        end)

        -- Show the glow border on mouse hover
        slot:SetScript("OnEnter", function(self)
            local spell = _G.equippedSpells[slot.id]  -- Get the spell GUID for this slot
            if spell and spell.Guid then
                CTSpell:ShowTooltip(spell, slot)
            end

            slot.glowBorder:SetAlpha(0.4)  -- Show the glow with a 70% opacity (adjust as needed)
            slot.glowBorder:Show()  -- Display the glow border
        end)

        -- Hide the glow border when mouse leaves
        slot:SetScript("OnLeave", function(self)
            CTSpell:HideTooltip()

            slot.glowBorder:SetAlpha(0)  -- Hide the glow border
            slot.glowBorder:Hide()
        end)

        -- Store the slot in the existing spellSlots table
        spellSlots[slotId] = slot
        slotId = slotId + 1
    end
end

function ClearSpellSlots()
    for slot, _ in ipairs(spellSlots) do
        spellSlots[slot].icon:Hide()
    end
end

function RefreshActionBar()
    -- print("Refreshing action bar...")

    UpdateHealthAndMana()

    -- Loop through each slot in _G.equippedSpells
    -- print(#_G.equippedSpells)
    ClearSpellSlots()
    for slot, spell in pairs(_G.equippedSpells) do
        -- print("Slot " ..slot.. " | Spell: " ..spell.Name)

        DrawSpellAtSlot(slot)  -- Call the function to draw the spell at the given slot
    end
end

function DrawSpellAtSlot(slot)
    if not spellSlots[slot] then return end

    local texture = _G.equippedSpells[slot].Icon

    spellSlots[slot].icon:SetTexture(texture)
    spellSlots[slot].icon:Show()

    local usable = true
        local spell = _G.equippedSpells[spellSlots[slot].id]  -- Get the spell GUID for this slot
        if spell and spell.Guid then

            -- Check requirements first
            usable = CTSpell:CheckRequirements(spell)

            -- Check to see if the player has either the bonus action or action required to use the spell.
            if spell.ActionCost == "Action" then
                if not _G.playerHasAction then
                    usable = false
                end
            elseif spell.ActionCost == "Bonus Action" then
                if not _G.playerHasBonusAction then
                    usable = false
                end
            end

            if not usable then
                spellSlots[slot].icon:SetVertexColor(1, 0.5, 0.5)  -- Apply red
                spellSlots[slot].usable = false
            else
                spellSlots[slot].icon:SetVertexColor(1, 1, 1)  -- Apply white  
                spellSlots[slot].usable = true
            end
        end
end

function PlayerTurn:CreateEndTurnButton()
    -- Create the green icon as a button
    local endTurnButton = CreateFrame("Button", "EndTurnButton", actionBar)
    endTurnButton:SetSize(54, 54)  -- Set the button size to match the action bar slots
    endTurnButton:SetPoint("RIGHT", actionBar, "RIGHT", 60, 0)  -- Position it at the right side of the action bar

    -- Set the button's icon texture to the green indicator
    endTurnButton:SetNormalTexture("Interface\\COMMON\\Indicator-Green")

    -- Set the initial alpha (fade it out initially)
    endTurnButton:SetAlpha(0.5)  -- Fade the icon to 50% opacity

    -- Set up the button's OnClick handler to call OnEndPlayerTurn
    endTurnButton:SetScript("OnClick", function()
        -- print("Ending the player's turn...")  -- Optional debug message
        OnEndPlayerTurn()  -- Call the function when the button is clicked
    end)
    
    -- Optional: You can also add a tooltip for the button
    endTurnButton:SetScript("OnEnter", function()
        -- On hover, make the button fully visible (opacity = 1)
        endTurnButton:SetAlpha(1)  -- Make the icon fully opaque
        GameTooltip:SetOwner(endTurnButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("End Turn", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    endTurnButton:SetScript("OnLeave", function()
        -- On mouse leave, fade the icon back to 50% opacity
        endTurnButton:SetAlpha(0.5)  -- Fade the icon out slightly
        GameTooltip:Hide()
    end)

    -- Create text over the button that says "End Turn"
    local endTurnText = endTurnButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    endTurnText:SetPoint("CENTER", endTurnButton, "CENTER", 0, 0)  -- Center the text over the button
    endTurnText:SetText("End\nTurn")  -- Set the text
    endTurnText:SetTextColor(1, 1, 1, 1)  -- Set the text color to white (adjust as needed)
end

-- Function to create health and mana bars
function PlayerTurn:CreateHealthAndManaBars()
    -- Create Health Bar
    healthBar = CreateFrame("StatusBar", "HealthBar", UIParent)
    healthBar:SetSize(180, 5)  -- Set size for the health bar
    healthBar:SetPoint("TOPLEFT", actionBar, "TOPLEFT", 12.5, 20)  -- Position it above the action bar on the left
    healthBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")  -- Set texture for the health bar
    healthBar:SetStatusBarColor(0, 1, 0)  -- Green color for health

    -- Create a background for the health bar
    local healthBarBackground = healthBar:CreateTexture(nil, "BACKGROUND")
    healthBarBackground:SetAllPoints(healthBar)
    healthBarBackground:SetColorTexture(0, 0, 0, 0.7)  -- Dark background

    -- Set the current health relative to max health
    local currentHealth = _G.hiddenStats.Health
    local maxHealth = _G.hiddenStats.MaxHealth
    healthBar:SetMinMaxValues(0, maxHealth)
    healthBar:SetValue(currentHealth)

    -- Add text to the health bar
    healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 1)
    healthText:SetText(currentHealth .. " / " .. maxHealth)
    healthText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")


    -- Create Mana Bar
    manaBar = CreateFrame("StatusBar", "ManaBar", UIParent)
    manaBar:SetSize(180, 5)  -- Set size for the mana bar
    manaBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -7)  -- Position it below the health bar
    manaBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")  -- Set texture for the mana bar
    manaBar:SetStatusBarColor(0, 0, 1)  -- Blue color for mana

    -- Create a background for the mana bar
    local manaBarBackground = manaBar:CreateTexture(nil, "BACKGROUND")
    manaBarBackground:SetAllPoints(manaBar)
    manaBarBackground:SetColorTexture(0, 0, 0, 0.7)  -- Dark background

    -- Set the current mana relative to max mana
    local currentMana = _G.hiddenStats.Mana
    local maxMana = _G.hiddenStats.MaxMana
    manaBar:SetMinMaxValues(0, maxMana)
    manaBar:SetValue(currentMana)

    -- Add text to the mana bar
    manaText = manaBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    manaText:SetPoint("CENTER", manaBar, "CENTER", 0, 0)
    manaText:SetText(currentMana .. " / " .. maxMana)
    manaText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
end

-- Function to update health and mana bars
function UpdateHealthAndMana()
    if not healthBar or not manaBar then return end

    -- Update Health Bar
    local currentHealth = _G.hiddenStats.Health
    local maxHealth = _G.hiddenStats.MaxHealth
    healthBar:SetValue(currentHealth)  -- Update the value of the health bar
    healthText:SetText(currentHealth .. " / " .. maxHealth)  -- Update the health text

    -- Update Mana Bar
    local currentMana = _G.hiddenStats.Mana
    local maxMana = _G.hiddenStats.MaxMana
    manaBar:SetValue(currentMana)  -- Update the value of the mana bar
    manaText:SetText(currentMana .. " / " .. maxMana)  -- Update the mana text
end


-- Functions to call when the player's turn ends.
function OnEndPlayerTurn()
    print("### You end your turn ###")
    PlayerTurn:EndTurnAndSendMessage()

    -- Make sure the player cannot do anything else in between turns, other than reactions.
    _G.playerHasAction = false
    _G.playerHasBonusAction = false
    RefreshActionBar()
end

function PlayerTurn:EndTurnAndSendMessage()
    local playerName = UnitName("player")
    local message = string.format("%s has ended their turn", playerName)

    -- Send the message to the appropriate channel (RAID or PARTY)
    local channel = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, channel)

    -- Print the message to the player's chat window
    -- print(message)
end

-- Method to handle the received message
function PlayerTurn:OnTurnEndMessageReceived(message, sender)
    -- Display the message in the chat window
    -- print("Received " .. message .. " from " .. sender)

    -- Split the sender's name (in case it's formatted as "player-name")
    local playerName = string.match(sender, "([^%-]+)")  -- Match everything before the dash ("-")

    -- Ensure playerName is valid
    if playerName then
        _G.LockPortrait(playerName)  -- Lock the portrait based on the player's name
    else
        print("Error: Could not extract player name from sender.")
    end
end

function PlayerTurn:RedrawAllAuras()
    print("Redrawing all auras on player...")

    -- Ensure ActiveAuraIcons exists
    PlayerTurn.ActiveAuraIcons = PlayerTurn.ActiveAuraIcons or {}

    -- Reset Buff/Debuff counters
    PlayerTurn.BuffCount = 0
    PlayerTurn.DebuffCount = 0

    -- Loop through all stored aura icons and reposition them
    for _, auraFrame in ipairs(PlayerTurn.ActiveAuraIcons) do
        if auraFrame:IsShown() then
            -- Determine positioning based on Buff/Debuff type
            local auraIndex, yOffset
            if auraFrame.Type == "Debuff" then
                auraIndex = PlayerTurn.DebuffCount
                yOffset = -10  -- Debuffs below
                PlayerTurn.DebuffCount = PlayerTurn.DebuffCount + 1
            else
                auraIndex = PlayerTurn.BuffCount
                yOffset = 20  -- Buffs above
                PlayerTurn.BuffCount = PlayerTurn.BuffCount + 1
            end

            -- Reposition aura frame
            auraFrame:ClearAllPoints()
            auraFrame:SetPoint("TOPLEFT", healthBar, "TOPLEFT", auraIndex * 18, yOffset)
        else
            -- Hide any auras that shouldn't be shown
            auraFrame:Hide()
        end
    end

    print("✅ Aura redraw complete!")
end


function PlayerTurn:DrawAuraIcon(auraGuid, sender)
    if not healthBar then
        print("❌ Error: Health bar not found for aura placement.")
        return
    end

    -- Fetch aura data from global storage (ensure this exists in your system)
    local auraData = nil
    for _, campaign in pairs(_G.CampaignToolkitCampaignsDB) do
        if campaign.AuraList then  -- Ensure the campaign has an AuraList
            print("Checking campaign: " ..campaign.Name)
            for _, aura in pairs(campaign.AuraList) do
                print("... checking against " ..aura.Guid)

                if aura.Guid == auraGuid then
                    auraData = aura
                    break
                end
            end
        end
        if auraData then break end
    end

    -- Break if broken!
    if not auraData then return end

    local baseSender = strsplit("-", sender) -- Remove realm name
    auraData.Caster = baseSender

    local auraIcon = auraData.Icon or "Interface\\Icons\\INV_Misc_QuestionMark" -- Default icon if missing
    local auraType = auraData.Type or "Buff"  -- Default to Buff if no type is specified

    -- Determine positioning based on type (Buffs go above, Debuffs below)
    local auraIndex, yOffset
    if auraType == "Debuff" then
        auraIndex = PlayerTurn.DebuffCount or 0
        yOffset = -10  -- Debuffs on lower row
        PlayerTurn.DebuffCount = (PlayerTurn.DebuffCount or 0) + 1
    else
        auraIndex = PlayerTurn.BuffCount or 0
        yOffset = 20  -- Buffs on top row
        PlayerTurn.BuffCount = (PlayerTurn.BuffCount or 0) + 1
    end

    -- Create the aura frame
    local auraFrame = CreateFrame("Frame", nil, UIParent)
    auraFrame:SetSize(16, 16)
    auraFrame:SetPoint("TOPLEFT", healthBar, "TOPLEFT", auraIndex * 18, yOffset) -- Stack icons
    auraFrame.Caster = auraData.Caster
    auraFrame.RemainingTurns = auraData.RemainingTurns

    -- Add the aura icon texture
    local icon = auraFrame:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints(auraFrame)
    icon:SetTexture(auraIcon)

    -- If it's a Debuff, add a red border
    if auraType == "Debuff" then
        local border = auraFrame:CreateTexture(nil, "BORDER")
        border:SetSize(18, 18)  -- Slightly larger than icon
        border:SetPoint("CENTER", auraFrame, "CENTER")
        border:SetColorTexture(1, 0, 0, 1) -- Solid red outline
    end

    -- Tooltip functionality (Hover to see aura details)
    auraFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(auraData.Name, 1, 1, 1)
        GameTooltip:AddLine("Caster: " .. auraFrame.Caster, 1, 1, 1)
        GameTooltip:AddLine("Turns Remaining: " .. (auraFrame.RemainingTurns or "∞"), 1, 1, 0)
        GameTooltip:Show()
    end)

    auraFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Store aura icon reference for later removal if needed
    PlayerTurn.ActiveAuraIcons = PlayerTurn.ActiveAuraIcons or {}
    table.insert(PlayerTurn.ActiveAuraIcons, auraFrame)

    auraFrame:Show()
end

function PlayerTurn:AdvanceAurasFromCaster(casterName)
    casterName = strsplit("-", casterName) -- Remove realm name

    if not PlayerTurn.ActiveAuraIcons or #PlayerTurn.ActiveAuraIcons == 0 then
        print("No active auras to tick down.")
        return
    end

    -- Iterate through all active aura icons
    local hasExpired = false
    for i = #PlayerTurn.ActiveAuraIcons, 1, -1 do  -- Iterate backwards to safely remove elements
        local auraFrame = PlayerTurn.ActiveAuraIcons[i]

        if auraFrame.Caster == casterName then  -- Check if this aura was applied by the sender
            -- Reduce the remaining turns
            auraFrame.RemainingTurns = (auraFrame.RemainingTurns) - 1

            print("Tick Advance from:", casterName, "| New Turns Left:", auraFrame.RemainingTurns)

            -- Remove if expired
            if auraFrame.RemainingTurns <= 0 then
                hasExpired = true
                print("Aura expired and removed:", auraFrame.Guid)
                auraFrame:Hide()
                table.remove(PlayerTurn.ActiveAuraIcons, i)
            else
                -- Update the displayed turns
                if auraFrame.TurnsText then
                    auraFrame.TurnsText:SetText(auraFrame.RemainingTurns)
                end
            end
        end
    end

    if hasExpired then PlayerTurn:RedrawAllAuras() end
end


function PlayerTurn:SendAuraTickAdvanceMessage()
    local senderName = UnitName("player") -- Get sender's name

    -- Format the message as "TICK_AURA;<Sender>"
    local message = string.format("TICK_AURA;%s", senderName)

    -- Determine the correct communication channel (RAID or PARTY)
    local channel = IsInRaid() and "RAID" or "PARTY"

    -- Send the message to all group members
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, channel)

    print("Sent Aura Tick Down Message from:", senderName)
end


function PlayerTurn:SendAddAuraMessage(targetPlayer, auraGuid)
    if not targetPlayer or targetPlayer == "" then
        print("❌ Error: No target player specified for adding aura.")
        return
    end

    if not auraGuid or auraGuid == "" then
        print("❌ Error: No aura GUID provided.")
        return
    end

    -- Format the message to send: "ADD_AURA;AuraGUID"
    local message = string.format("ADD_AURA;%s", auraGuid)

    -- Send the addon message using WHISPER channel
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, "WHISPER", targetPlayer)

    print("📨 Sent Add Aura Message via WHISPER to", targetPlayer, "with GUID:", auraGuid)
end

-- Set up the event listener for receiving addon messages
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")  -- Listen for addon messages

frame:SetScript("OnEvent", function(_, event, prefix, message, _, sender)
    -- Ensure it's from the correct addon prefix
    if prefix ~= ADDON_PREFIX then return end

    -- Check if the message is an ADD_AURA command
    local command, auraGuid = strsplit(";", message, 2)
    
    if command == "TICK_AURA" then
        print("Received Aura Advance Request from:", sender)
        PlayerTurn:AdvanceAurasFromCaster(sender)
    elseif command == "ADD_AURA" and auraGuid then
        print("Received Add Aura request from", sender, "with GUID:", auraGuid)
        PlayerTurn:DrawAuraIcon(auraGuid, sender)
    else
        -- Fallback to OnTurnEndMessageReceived for other messages
        PlayerTurn:OnTurnEndMessageReceived(message, sender)
    end
end)


_G.HideActionBar = HideActionBar
_G.RefreshActionBar = RefreshActionBar
_G.UpdateHealthAndMana = UpdateHealthAndMana

