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

function PlayerReaction:Request_Defensive(attacker, target, threshold, type, school, spell)
    local message = string.format("%s:%s:%s:%s:%s:%s", type, attacker, target, tostring(threshold), school, spell)

    -- Send the message to the selected channel (party or raid)
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, "WHISPER", target)
end

-- Send the result of a defensive roll to the group leader.
function PlayerReaction:Send_DefensiveResult(attacker, defender, result, type, school, spell)
    local groupLeaderName = nil

    if IsInRaid() then
        groupLeaderName = UnitName("raid1")  -- For raid
    elseif IsInGroup() then
        groupLeaderName = UnitName("party1")  -- For party
    end

    if UnitIsGroupLeader("Player") then
        local playerName, playerRealm = strsplit("-", defender)
        playerName = playerName or sender  -- Fallback in case the split doesn't work

        -- Find the index of the playerName in awaitingPlayers
        local playerIndex
        for index, name in ipairs(UnitFrameTurn.AwaitingPlayers) do
            if name == playerName then
                playerIndex = index
                break
            end
        end

        -- If the playerName is found, remove it from the table
        if playerIndex then
            table.remove(UnitFrameTurn.AwaitingPlayers, playerIndex)
        else
            print("Player not found in awaitingPlayers list.")
        end
    end

    local message = string.format("RESULT:%s:%s:%s:%s:%s", spell, attacker, defender, result, school)

    if UnitName("Player") ~= groupLeaderName then
        -- Send the message to the selected channel (party or raid)
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, "WHISPER", groupLeaderName)
    else
        PlayerReaction:HandleAddonMessage(message, UnitName("Player"))
    end
end

function ReactionFrame:Prompt_CounterAttack(attacker)
    -- Set the title and text prompt
    self.Title:SetText("Attacker: " ..attacker)
    self.PromptText:SetText("Roll to Counterattack")

    -- Clear previous buttons
    for _, button in pairs(self.ActionButtons) do
        button:Hide()
    end
    self.ActionButtons = {}

    -- Create Parry, Dodge, and Block Icon Buttons
    local actionIcons = {
        { name = "Attack", icon = "Interface\\ICONS\\inv_sword_01" }
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
            -- Roll to hit
            local hitRoll, baseRoll = Dice.Roll("1d20", string.format("to hit (Counterattack)"), { "meleeHit" }, false, "NO_SCROLL")
            local target = attacker
            local hit = false
            for _, frame in pairs(UnitFrames.frames) do
                if frame.isVisible and frame.NPCName == target then 
                    if hitRoll >= tonumber(frame.DefensiveAC.Melee) then hit = true end
                end
            end
            if not hit then
                CombatLog:PrintMessage(string.format("Your counterattack failed to damage %s.", target))
                Common:CreateFloatingText("Miss", 1, 1, 1)
                self:Hide()
                return
            end

            -- Check for crit
            local critCheck = Common:CheckForCrit("meleeCrit", baseRoll)
            local coefficient = 1
            local spellSender = string.format("%s's counterattack", UnitName("player"))
            if critCheck == "CRIT_SUCCESS" then 
                coefficient = 2 + (_G.hiddenStats.CriticalStrikeDamage/100)
            elseif critCheck == "CRIT_FAIL" then
                -- print("Critical fail!")
            else
                -- Do nothing (wasn't a crit!)
            end

            -- Roll damage
            local damageDice, weaponName = CTSpell:GetDamageDiceFromWeapon("Main Hand") 
            local message = string.format("damage (%s)", weaponName)
            if critCheck == "CRIT_SUCCESS" then message = string.format("damage (%s) (Critical, x%.1f)", weaponName, coefficient) end
            local damageRoll = coefficient * Dice.Roll(damageDice, message, { "meleeBonus" }, false, "DAMAGE")
            Targeting:ApplyDamage(spellSender, target, math.floor(damageRoll + 0.5), "Physical", "DIRECT")

            -- Trigger any auras that have a TargetHit trigger.
            CTAura:OnEnemyHit(target)

            self:Hide()
        end)

        table.insert(self.ActionButtons, iconButton)  -- Store the icon button for later use
    end

    -- Show the frame
    self:Show()
end

function ReactionFrame:Prompt_MeleeDefensive(attacker, threshold, school, spell)
    -- Set the title and text prompt
    self.Title:SetText("Attacker: " ..attacker)
    self.PromptText:SetText("Choose a defensive roll.")

    -- Clear previous buttons
    for _, button in pairs(self.ActionButtons) do
        button:Hide()
    end
    self.ActionButtons = {}

    if not _G.playerCanBlock and not _G.playerCanParry and not _G.playerCanDodge then
        PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "FAIL", "MELEE", school, spell)
        return
    end

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

        local canUseAction = true
        if action.name == "Block" and not _G.playerCanBlock then
            canUseAction = false
            icon:SetDesaturated(true)
        elseif action.name == "Parry" and not _G.playerCanParry then
            canUseAction = false
            icon:SetDesaturated(true)
        elseif action.name == "Dodge" and not _G.playerCanDodge then
            canUseAction = false
            icon:SetDesaturated(true)
        end

        -- Button click action
        iconButton:SetScript("OnClick", function()
            if not canUseAction then return end

            local roll, baseRoll = 0
            if action.name == "Block" then
                roll, baseRoll = Dice.Roll("1d20", "Block", "blockBonus", false, "ALL")
                _G.playerCanBlock = false
            elseif action.name == "Parry" then
                roll, baseRoll = Dice.Roll("1d20", "Parry", "parryBonus", false, "ALL")
                _G.playerCanParry = false
            elseif action.name == "Dodge" then
                roll, baseRoll = Dice.Roll("1d20", "Dodge", "dodgeBonus", false, "ALL")
                _G.playerCanDodge = false
            end

            if tonumber(roll) < tonumber(threshold) then
                CTAura:OnHitTaken(attacker)
                PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "FAIL", "MELEE", school, spell)
                self:Hide()
            else
                PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "SUCCESS", "MELEE", school, spell)           
                if action.name == "Parry" and Common:CheckForCrit("parryCrit", baseRoll) then 
                    ReactionFrame:Prompt_CounterAttack(attacker) 
                elseif action.name == "Dodge" and Common:CheckForCrit("dodgeCrit", baseRoll) then 
                    ReactionFrame:Prompt_CounterAttack(attacker) 
                end
            end
        end)

        table.insert(self.ActionButtons, iconButton)  -- Store the icon button for later use
    end

    -- Show the frame
    self:Show()
end

function ReactionFrame:Prompt_RangedDefensive(attacker, threshold, school, spell)
    -- Set the title and text prompt
    self.Title:SetText("Attacker: " ..attacker)
    self.PromptText:SetText("Choose a defensive roll.")

    if not _G.playerCanBlock and not _G.playerCanDodge then
        PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "FAIL", "RANGED", school, spell)  
        return
    end

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

        local canUseAction = true
        if action.name == "Block" and not _G.playerCanBlock then
            canUseAction = false
            icon:SetDesaturated(true)
        elseif action.name == "Dodge" and not _G.playerCanDodge then
            canUseAction = false
            icon:SetDesaturated(true)
        end

        -- Button click action
        iconButton:SetScript("OnClick", function()
            local roll = 0
            if action.name == "Block" then
                roll = Dice.Roll("1d20", "Block", "blockBonus", false, "ALL")
            elseif action.name == "Parry" then
                roll = Dice.Roll("1d20", "Parry", "parryBonus", false, "ALL")
            elseif action.name == "Dodge" then
                roll = Dice.Roll("1d20", "Dodge", "dodgeBonus", false, "ALL")
                _G.playerCanDodge = false
            end

            if tonumber(roll) < tonumber(threshold) then
                CTAura:OnHitTaken(attacker)
                PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "FAIL", "RANGED", school, spell)
                _G.playerCanBlock = false
            else
                PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "SUCCESS", "RANGED", school, spell)
            end

            self:Hide()
        end)

        table.insert(self.ActionButtons, iconButton)  -- Store the icon button for later use
    end

    -- Show the frame
    self:Show()
end

function ReactionFrame:Prompt_SpellDefensive(attacker, threshold, school, spell)
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
            local roll = Dice.Roll("1d20", "Resist " ..school, action.modifier, false, "ALL")

            if tonumber(roll) < tonumber(threshold) then
                CTAura:OnHitTaken(attacker)
                PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "FAIL", "SPELL", school, spell)
            else
                PlayerReaction:Send_DefensiveResult(attacker, UnitName("Player"), "SUCCESS", "SPELL", school, spell)
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

        if UnitIsGroupLeader("Player") then
            local playerName, playerRealm = strsplit("-", sender)
            playerName = playerName or sender  -- Fallback in case the split doesn't work

            -- Find the index of the playerName in awaitingPlayers
            local playerIndex
            for index, name in ipairs(UnitFrameTurn.AwaitingPlayers) do
                if name == playerName then
                    playerIndex = index
                    break
                end
            end

            -- If the playerName is found, remove it from the table
            if playerIndex then
                table.remove(UnitFrameTurn.AwaitingPlayers, playerIndex)
            else
                print("Player not found in awaitingPlayers list.")
            end
        end

        if result == "FAIL" then
            UnitFrames:DamagePlayer(attackerName, sender, attackType)
        end
    else
        if components[1] ~= "MELEE" and components[1] ~= "RANGED" and components[1] ~= "SPELL" then
            return
        end

        -- Extract the senderName, targetName, and roll from the components
        local attackerName = components[2]
        local targetName = components[3]
        local threshold = components[4]
        local school = components[5]
        local spell = components[6]

        if attackerName and targetName and threshold then
            if components[1] == "MELEE" then
                ReactionFrame:Prompt_MeleeDefensive(attackerName, threshold, school, spell)
            elseif components[1] == "RANGED" then
                ReactionFrame:Prompt_RangedDefensive(attackerName, threshold, school, spell)
            elseif components[1] == "SPELL" then
                ReactionFrame:Prompt_SpellDefensive(attackerName, threshold, school, spell)
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
