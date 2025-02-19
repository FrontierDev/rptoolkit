local ADDON_PREFIX = "CTDEF"
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
print("[CT] Addon prefix registered: " ..ADDON_PREFIX)

local PlayerReaction = {}
_G.PlayerReaction = PlayerReaction

local ReactionFrame = CreateFrame("Frame", "ReactionFrame", UIParent, "BackdropTemplate")
ReactionFrame:SetSize(300, 200)
ReactionFrame:SetPoint("CENTER")
ReactionFrame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    -- edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
ReactionFrame:Hide()  -- Hidden initially

-- Title for the Reaction Frame
ReactionFrame.Title = ReactionFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
ReactionFrame.Title:SetPoint("TOP", ReactionFrame, "TOP", 0, -10)

-- Text area for the prompt (dynamic text)
ReactionFrame.PromptText = ReactionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ReactionFrame.PromptText:SetPoint("TOP", ReactionFrame.Title, "BOTTOM", 0, -10)
ReactionFrame.PromptText:SetWidth(280)
ReactionFrame.PromptText:SetHeight(50)
ReactionFrame.PromptText:SetJustifyH("CENTER")
ReactionFrame.PromptText:SetJustifyV("TOP")
ReactionFrame.PromptText:SetText("Action Prompt Text Goes Here")  -- Placeholder text

-- Create action buttons (they will be added by the prompt functions)
ReactionFrame.ActionButtons = {}

function PlayerReaction:Request_Defensive(attacker, target, threshold, type, school)
    local message = string.format("%s:%s:%s:%s:%s", type, attacker, target, tostring(threshold), school)
    print(message)
    
    -- Send the message to the selected channel (party or raid)
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, "WHISPER", target)
    
    print("Requesting defensive roll from " .. target .. " via WHISPER.")
end

function PlayerReaction:Send_DefensiveResult(attacker, defender, result, type, school)
    local groupLeaderName = nil

    if IsInRaid() then
        groupLeaderName = UnitName("raid1")  -- For raid
    elseif IsInGroup() then
        groupLeaderName = UnitName("party1")  -- For party
    end

    print("Group Leader: " .. (groupLeaderName or "None"))

    local message = string.format("RESULT:%s:%s:%s:%s:%s", type, attacker, defender, result, school)
    print(message)
    
    if not UnitName("Player") == groupLeaderName then
        -- Send the message to the selected channel (party or raid)
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, "WHISPER", groupLeaderName)
    
        print("Sending defensive roll result to " .. groupLeaderName .. " via WHISPER.")
    else
        PlayerReaction:HandleAddonMessage(message, UnitName("Player"))
    end
end

function ReactionFrame:Prompt_MeleeDefensive(attacker, threshold, school)
    -- Set the title and text prompt
    self.Title:SetText("Attacker: " ..attacker)
    self.PromptText:SetText("Choose a defensive roll.")

    -- Clear previous buttons
    for _, button in pairs(self.ActionButtons) do
        button:Hide()
    end
    self.ActionButtons = {}

    -- Create Parry, Dodge, and Block Icon Buttons
    local actionIcons = {
        { name = "Parry", icon = "Interface\\ICONS\\ability_parry" },
        { name = "Dodge", icon = "Interface\\ICONS\\spell_magic_lesserinvisibilty" },
        { name = "Block", icon = "Interface\\ICONS\\inv_shield_06" }
    }

    -- Determine the required size of the frame based on the number of action icons
    local iconSize = 32
    local spacing = 34
    local numIcons = #actionIcons
    local frameHeight = 100   -- 120 is for the header and text
    local frameWidth = 120 + numIcons * (iconSize + 10) -- Standard width for icon buttons and titles

    -- Resize the frame to fit the elements
    self:SetSize(frameWidth, frameHeight)

    -- Position icons and create them
    for i, action in ipairs(actionIcons) do
        local iconButton = CreateFrame("Button", nil, self)
        iconButton:SetSize(iconSize, iconSize)
        iconButton:SetPoint("TOP", self, "TOP", (i - 1) * spacing - 33, -60)  -- Position icons below the prompt text

        local icon = iconButton:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(iconButton)
        icon:SetTexture(action.icon)

        -- Button click action
        iconButton:SetScript("OnClick", function()
            print(action.name .. " defense selected")

            local roll = 0
            if action.name == "Block" then
                roll = Dice.Roll("1d20", "Block", "blockBonus", false, "ALL")
            elseif action.name == "Parry" then
                roll = Dice.Roll("1d20", "Parry", "parryBonus", false, "ALL")
            elseif action.name == "Dodge" then
                roll = Dice.Roll("1d20", "Dodge", "dodgeBonus", false, "ALL")
            end

            if tonumber(roll) < tonumber(threshold) then
                print("Failed " ..action.name.. "!")
                PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "FAIL", "MELEE", school)
            else
                print("Succeeded " ..action.name.. "!")
                PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "SUCCESS", "MELEE", school)
            end

            self:Hide()
        end)

        table.insert(self.ActionButtons, iconButton)  -- Store the icon button for later use
    end

    -- Show the frame
    self:Show()
end

function ReactionFrame:Prompt_RangedDefensive(attacker, threshold, school)
    -- Set the title and text prompt
    self.Title:SetText("Attacker: " ..attacker)
    self.PromptText:SetText("Choose a defensive roll.")

    -- Clear previous buttons
    for _, button in pairs(self.ActionButtons) do
        button:Hide()
    end
    self.ActionButtons = {}

    -- Create Parry, Dodge, and Block Icon Buttons
    local actionIcons = {
        { name = "Dodge", icon = "Interface\\ICONS\\spell_magic_lesserinvisibilty" },
        { name = "Block", icon = "Interface\\ICONS\\inv_shield_06" }
    }

    -- Determine the required size of the frame based on the number of action icons
    local iconSize = 32
    local spacing = 34
    local numIcons = #actionIcons
    local frameHeight = 100   -- 120 is for the header and text
    local frameWidth = 120 + numIcons * (iconSize + 10) -- Standard width for icon buttons and titles

    -- Resize the frame to fit the elements
    self:SetSize(frameWidth, frameHeight)

    -- Position icons and create them
    for i, action in ipairs(actionIcons) do
        local iconButton = CreateFrame("Button", nil, self)
        iconButton:SetSize(iconSize, iconSize)
        iconButton:SetPoint("TOP", self, "TOP", (i - 1) * spacing - 16, -60)  -- Position icons below the prompt text

        local icon = iconButton:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(iconButton)
        icon:SetTexture(action.icon)

        -- Button click action
        iconButton:SetScript("OnClick", function()
            print(action.name .. " defense selected")

            local roll = 0
            if action.name == "Block" then
                roll = Dice.Roll("1d20", "Block", "blockBonus", false, "ALL")
            elseif action.name == "Parry" then
                roll = Dice.Roll("1d20", "Parry", "parryBonus", false, "ALL")
            elseif action.name == "Dodge" then
                roll = Dice.Roll("1d20", "Dodge", "dodgeBonus", false, "ALL")
            end

            if tonumber(roll) < tonumber(threshold) then
                print("Failed " ..action.name.. "!")
                PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "FAIL", "RANGED", school)
            else
                print("Succeeded " ..action.name.. "!")
                PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "SUCCESS", "RANGED", school)
            end

            self:Hide()
        end)

        table.insert(self.ActionButtons, iconButton)  -- Store the icon button for later use
    end

    -- Show the frame
    self:Show()
end

function ReactionFrame:Prompt_SpellDefensive(attacker, threshold, school)
    -- Set the title and text prompt
    self.Title:SetText("Attacker: " .. attacker)
    self.PromptText:SetText("Choose a resistance roll.")

    -- Clear previous buttons
    for _, button in pairs(self.ActionButtons) do
        button:Hide()
    end
    self.ActionButtons = {}

    -- Create Parry, Dodge, and Block Icon Buttons
    local actionIcons = {
        { name = "Fire", icon = "Interface\\ICONS\\spell_fire_fireball", modifier = "fireResist" },
        { name = "Frost", icon = "Interface\\ICONS\\spell_frost_freezingbreath", modifier = "frostResist" },
        { name = "Nature", icon = "Interface\\ICONS\\spell_nature_abolishmagic", modifier = "natureResist" },
        { name = "Arcane", icon = "Interface\\ICONS\\spell_nature_starfall", modifier = "arcaneResist" },
        { name = "Fel", icon = "Interface\\ICONS\\spell_fire_felflamering", modifier = "felResist" },
        { name = "Shadow", icon = "Interface\\ICONS\\spell_shadow_blackplague", modifier = "shadowResist" },
        { name = "Holy", icon = "Interface\\ICONS\\spell_holy_holybolt", modifier = "holyResist" }
    }

    -- Filter the reactions by school.
    self.selectedActionIcons = {}
    for i, action in ipairs(actionIcons) do
        if action.name == school then
            print("Adding " .. school .. " to reaction.")
            table.insert(self.selectedActionIcons, action)
        end
    end

    -- Determine the required size of the frame based on the number of action icons
    local iconSize = 32
    local spacing = 34
    local numIcons = #self.selectedActionIcons or 0
    local frameHeight = 100   -- 120 is for the header and text
    local frameWidth = 180 + numIcons * (iconSize + 10) -- Standard width for icon buttons and titles

    -- Resize the frame to fit the elements
    self:SetSize(frameWidth, frameHeight)

    -- Position icons and create them
    for i, action in ipairs(self.selectedActionIcons) do
        local iconButton = CreateFrame("Button", nil, self)
        iconButton:SetSize(iconSize, iconSize)
        iconButton:SetPoint("TOP", self, "TOP", (i - 1) * spacing, -60)  -- Position icons below the prompt text

        local icon = iconButton:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(iconButton)
        icon:SetTexture(action.icon)

        -- Button click action
        iconButton:SetScript("OnClick", function()
            print(action.name .. " defense selected")

            local roll = Dice.Roll("1d20", "Resist " ..school, action.modifier, false, "ALL")

            if tonumber(roll) < tonumber(threshold) then
                print("Failed " .. action.name .. "!")
                PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "FAIL", "SPELL", school)
            else
                print("Succeeded " .. action.name .. "!")
                PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "SUCCESS", "SPELL", school)
            end

            self:Hide()
        end)

        table.insert(self.ActionButtons, iconButton)  -- Store the icon button for later use
    end

    -- Show the frame
    self:Show()
end


-- Function to handle receiving whispered addon messages
function PlayerReaction:HandleAddonMessage(msg, sender)
    -- Split the message by ":"
    local components = {strsplit(":", msg)}

    if components[1] == "RESULT" then
        local attackType = components[2]
        local attackerName = components[3]
        local defenderName = components[4]
        local result = components[5]

        -- Debug
        print("Received a defensive roll result: " ..defenderName.. " - " ..result)
        
        if UnitIsGroupLeader("Player") then
            print("Handling awaiting list...")

            local playerName, playerRealm = strsplit("-", sender)
            playerName = playerName or sender  -- Fallback in case the split doesn't work

            -- Find the index of the playerName in awaitingPlayers
            local playerIndex
            for index, name in ipairs(UnitFrameTurn.AwaitingPlayers) do
                print("In list: " ..name)
                if name == playerName then
                    playerIndex = index
                    break
                end
            end

            -- If the playerName is found, remove it from the table
            if playerIndex then
                table.remove(UnitFrameTurn.AwaitingPlayers, playerIndex)
                print("No longer awaiting player: " .. playerName)
            else
                print("Player not found in awaitingPlayers list.")
            end
        end

        if result == "FAIL" then
            UnitFrames:DamagePlayer(attackerName, sender, attackType)
        end
    else
        if components[1] ~= "MELEE" and components[1] ~= "RANGED" and components[1] ~= "SPELL" then
            print(components[1])
            return
        end

        -- Extract the senderName, targetName, and roll from the components
        local attackerName = components[2]
        local targetName = components[3]
        local threshold = components[4]
        local school = components[5]

        if attackerName and targetName and threshold then
            print(attackerName .. " attacked " .. targetName .. ".  Threshold to defend is " .. threshold)

            print(components[1])

            if components[1] == "MELEE" then
                ReactionFrame:Prompt_MeleeDefensive(attackerName, threshold, school)
            elseif components[1] == "RANGED" then
                ReactionFrame:Prompt_RangedDefensive(attackerName, threshold, school)
            elseif components[1] == "SPELL" then
                ReactionFrame:Prompt_SpellDefensive(attackerName, threshold, school)
            end
        else
            print("Invalid message format received.")
        end
    end
end

-- Register the event to listen for addon messages

-- Set up the event listener for receiving addon messages
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")  -- Listen for addon messages

frame:SetScript("OnEvent", function(_, event, prefix, message, _, sender)
    -- Ensure it's from the correct addon prefix
    if prefix ~= ADDON_PREFIX then return end

    PlayerReaction:HandleAddonMessage(message, sender)
end)
