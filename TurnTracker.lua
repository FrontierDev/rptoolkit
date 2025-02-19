local ADDON_PREFIX = "CTSTurnTracker"
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
print("[CTSTurnTracker] Addon prefix registered.")

local TurnTracker = {}
_G.TurnTracker = TurnTracker

function TurnTracker:Debug_TurnTracker()
    print("Executed call to TurnTracker.lua")
end

-- Variables --
local turnCounter = 0
local isCombatInitiativePhase = true
local currentPlayer = UnitName("player")
local activePlayerName = currentPlayer
local isVisible = false
local groupMembers = {}
local initiativeGuid = nil
local currentBatch = 1  -- Start with the first batch
local numBatches = 1  -- Default 1 batch, will be updated based on group size
local batches = {}  -- Table to store the batches_G.groupMembers = groupMembers
local activePortraits = {}
local activeBatch = {}
local batchMode = true

TurnTracker.NumBatches = numBatches
TurnTracker.GroupMembers = groupMembers

local TurnTracker = CreateFrame("Frame", "CTSTurnTracker", UIParent)
TurnTracker:SetSize(128, 128)
TurnTracker:SetPoint("TOP", UIParent, "TOP", 0, -20)
TurnTracker:EnableMouse(true)
TurnTracker:RegisterForDrag("LeftButton")
TurnTracker:SetMovable(true)
TurnTracker:SetScript("OnDragStart", TurnTracker.StartMoving)
TurnTracker:SetScript("OnDragStop", TurnTracker.StopMovingOrSizing)
TurnTracker:Hide()

TurnTracker.icon = TurnTracker:CreateTexture(nil, "ARTWORK")
TurnTracker.icon:SetTexture("Interface\\PVPFrame\\Icons\\prestige-icon-4")
TurnTracker.icon:SetAllPoints()

-- Combined Turn Label (Turn + Counter)
TurnTracker.turnLabel = TurnTracker:CreateFontString(nil, "OVERLAY")
TurnTracker.turnLabel:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
TurnTracker.turnLabel:SetPoint("BOTTOM", TurnTracker.icon, "TOP", 0, 10)
TurnTracker.turnLabel:SetText("Turn")

-- Function to create and display a single portrait or model for a player/NPC
local function CreatePortrait(parentFrame, unit, playerName)
    -- Create a frame to hold the portrait
    local portraitFrame = CreateFrame("Frame", nil, parentFrame)
    portraitFrame:SetSize(48, 48)
    
    portraitFrame.Locked = false

    -- Circular Border (for portrait styling)
    local circularBorder = portraitFrame:CreateTexture(nil, "BORDER")
    circularBorder:SetSize(72, 72)
    circularBorder:SetPoint("CENTER")
    circularBorder:SetTexture("Interface\\COMMON\\Indicator-Gray")  -- Placeholder texture
    circularBorder:SetVertexColor(1, 1, 1, 1)  -- Full opacity
    circularBorder:Show()

    -- Portrait texture (inside the border)
    local portrait = portraitFrame:CreateTexture(nil, "ARTWORK")
    portraitFrame.portrait = portrait
    portrait:SetSize(48, 48)  -- Slightly smaller to fit inside the border
    portrait:SetPoint("CENTER", circularBorder, "CENTER")  -- Align with the border
    portrait:Hide()  -- Default hidden until displayed

    -- Model for NPCs (replaces portrait for NPCs)
    local model = CreateFrame("PlayerModel", nil, portraitFrame)
    portraitFrame.model = model
    model:SetSize(48, 48)
    model:SetPoint("CENTER", circularBorder, "CENTER", 0, 0)
    model:SetPosition(2, 0, -0.5)
    model:Hide()

    -- Determine if it's a player or NPC and display accordingly
    if unit then
        -- It's a player, use portrait texture
        SetPortraitTexture(portrait, unit)
        portrait:Show()
        model:Hide()  -- Hide the model for players
    else
        -- It's an NPC, use model
        if _G.CampaignToolkit_UnitFrames and _G.CampaignToolkit_UnitFrames.frames then
            for _, frame in ipairs(_G.CampaignToolkit_UnitFrames.frames) do
                if frame.NPCName and frame.NPCName:GetText() == playerName then
                    local npcID = frame.Portrait:GetDisplayInfo()  -- Get NPC Model ID
                    model:ClearModel()
                    model:SetDisplayInfo(npcID)
                    model:Show()
                    portrait:Hide()  -- Hide portrait for NPCs
                    break
                end
            end
        end
    end

    -- Show the portrait frame once it's fully configured
    portraitFrame:Show()

    -- Return the frame that holds the portrait (useful for positioning)
    return portraitFrame
end


local function GetGroupChannel()
    return IsInRaid() and "RAID" or "PARTY"
end

local function TableIndexOf(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end
    return nil
end

local function GetGroupMembers()
    return groupMembers
end

local function UpdateGroupMembers()
    groupMembers = {}

    -- Add Party & Raid Members First
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)
            if name and type(name) == "string" then
                table.insert(groupMembers, name)
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local name = UnitName("party" .. i)
            if name and type(name) == "string" then
                table.insert(groupMembers, name)
            end
        end
        local playerName = UnitName("player")
        if playerName and type(playerName) == "string" then
            table.insert(groupMembers, playerName)
        end
    else
        local playerName = UnitName("player")
        if playerName and type(playerName) == "string" then
            table.insert(groupMembers, playerName)
        end
    end

    -- Add UnitFrames (NPCs) to Turn Order
    if _G.CampaignToolkit_UnitFrames and _G.CampaignToolkit_UnitFrames.frames then
        for _, frame in ipairs(_G.CampaignToolkit_UnitFrames.frames) do
            if frame.isVisible and frame.NPCName then
                local npcName = frame.NPCName:GetText()
                if npcName and npcName ~= "" then
                    table.insert(groupMembers, npcName) -- Add NPCs at the end of the turn order
                end
            end
        end
    end

    -- print("[CTSTurnTracker] Updated group members:", table.concat(groupMembers, ", "))
end


local function FindUnitIDByName(targetName)
    if UnitName("player") == targetName then
        return "player"
    end
    if IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = "party" .. i
            if UnitName(unit) == targetName then
                return unit
            end
        end
    end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            if UnitName(unit) == targetName then
                return unit
            end
        end
    end
    return nil
end

-- Function to update the turn tracker
local function UpdateTurnTracker()
    -- If it's turn 0, show 'combat begins' and hide portraits
    if turnCounter == 0 then
        TurnTracker.turnLabel:SetText("Combat Begins")
        return  -- Don't proceed further for Turn 0
    else
        TurnTracker.turnLabel:SetText("Turn " .. turnCounter)
    end

    -- Highlight unit frames for active batch
    UnitFrames:HighlightActiveBatch(activeBatch)

    if UnitIsGroupLeader("Player") then
        UnitFrames:UpdateNpcTurnButtons(activeBatch)
    end

    -- Tick down any buffs that are active
    if activeBatch then
        for _, unitName in ipairs(activeBatch) do
            -- Trim any whitespace to prevent formatting issues
            unitName = strtrim(unitName or "")
            -- Find all unit frames where this unit may have cast an aura
            for _, frame in pairs(_G.UnitFrames.frames) do
                if frame.Auras then
                    for _, aura in ipairs(frame.Auras) do
                        if aura.Caster == unitName then
                            _G.UnitFrames:UpdateAuraTurns(unitName, aura.Guid)
                        end
                    end
                end
            end
        end
    end

    -- Tick up the cast bars that are Active
    UnitFrames:AdvanceSpellcastBars()

    -- Return if not in batch mode (we will be in batch mode...)
    if batchMode then return end

    -- Proceed with normal turn updates for other turns
    if not activePlayerName or activePlayerName == "Unknown Player" then return end

    local unit = FindUnitIDByName(activePlayerName)
    local isNPC = false
    local npcID = nil

    if not unit or not UnitExists(unit) then
        -- Check if the active player is actually an NPC in UnitFrames
        if _G.CampaignToolkit_UnitFrames and _G.CampaignToolkit_UnitFrames.frames then
            for _, frame in ipairs(_G.CampaignToolkit_UnitFrames.frames) do
                if frame.isVisible and frame.NPCName and frame.NPCName:GetText() == activePlayerName then
                    -- Found NPC, use its assigned model instead
                    if frame.Portrait and frame.Portrait:GetModelFileID() then
                        npcID = frame.Portrait:GetDisplayInfo() -- Get NPC Model ID
                        isNPC = true
                    end
                    break
                end
            end
        end
    end

    if isNPC and npcID then
        -- Hide the static portrait
        TurnTracker.portrait:Hide()

        -- Use the 3D model instead
        TurnTracker.model:ClearModel()
        TurnTracker.model:SetDisplayInfo(npcID)
        TurnTracker.model:SetRotation(math.rad(0)) -- Adjust rotation if needed
        TurnTracker.model:Show()
        TurnTracker.playerNameText:Show()
        TurnTracker.circularBorder:Show()

    else
        -- It's a player, use the default portrait system
        TurnTracker.model:Hide()
        SetPortraitTexture(TurnTracker.portrait, unit)
        TurnTracker.portrait:Show()
        TurnTracker.circularBorder:Show()
        TurnTracker.playerNameText:Show()
    end

    -- Debugging: If texture fails, set a default placeholder
    if not TurnTracker.portrait:GetTexture() then
        TurnTracker.portrait:SetTexture("Interface\\CharacterFrame\\TempPortrait")
        print("[CTSTurnTracker] WARNING: Using fallback portrait texture.")
    end

    TurnTracker.playerNameText:SetText(activePlayerName)
    TurnTracker.circularBorder:Show()
end

-- Function to display portraits for all players in the active batch
local function DisplayPortraitsForActiveBatch()
    if not batchMode then
        -- If we are not in batch mode, use the default method to display a single portrait
        return
    end

    -- Ensure currentBatch is within the valid range
    if currentBatch < 1 or currentBatch > numBatches then
        print("Error: Invalid currentBatch value")
        return
    end

    -- Get the active batch based on the currentBatch
    local activeBatch = batches[currentBatch] or activeBatch

    if not activeBatch then
        print("Error: activeBatch is nil for currentBatch " .. currentBatch)
        return
    end

    -- Print the current active batch for debugging
    -- print("[CTSTurnTracker] Active Batch: " .. currentBatch)
    -- print("[CTSTurnTracker] Members in Active Batch: " .. table.concat(activeBatch, ", "))

    -- Calculate the total width required for all portraits (including spacing)
    local totalWidth = 0
    local portraitSpacing = 60  -- Space between portraits
    for _, playerName in ipairs(activeBatch) do
        totalWidth = totalWidth + portraitSpacing 
    end

    -- Create a parent frame to hold all the portraits for the active batch
    local parentFrame = CreateFrame("Frame", "BatchPortraits", TurnTracker)
    parentFrame:SetSize(totalWidth, 100)  -- Adjust size based on total width of portraits
    
    -- Position the parent frame under the TurnTracker, centered horizontally
    parentFrame:SetPoint("TOP", TurnTracker, "BOTTOM", 0, -10)  -- Position under TurnTracker
    parentFrame:SetPoint("CENTER", TurnTracker, "CENTER", 0, -50)  -- Center horizontally

    -- Loop through all members in the active batch and create portraits
    local offsetX = 0
    for _, playerName in ipairs(activeBatch) do
        local unit = FindUnitIDByName(playerName)  -- Get the unit ID for the player
        local portraitFrame = CreatePortrait(parentFrame, unit, playerName)  -- Create the portrait

        -- Position the portraits horizontally, adjusting for each new portrait
        portraitFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offsetX, 0)
        offsetX = offsetX + portraitSpacing  -- Adjust spacing between portraits

        -- Store the portrait frame in activePortraits
        portraitFrame.playerName = playerName
        table.insert(activePortraits, portraitFrame)

        -- Was the current player added to the batch? If so, it's their turn!
        if playerName == UnitName("player") then PlayerTurn.OnPlayerTurn() end
    end
    -- Show the parent frame for the portraits
    parentFrame:Show()
end

function LockPortrait(playerName)
    -- Loop through the active portraits in TurnTracker to find the sender's portrait

    local anyActive = false
    for _, portrait in pairs(activePortraits) do
        -- Check if the portrait corresponds to the sender (player whose turn ended)
        print("Checking " .. portrait.playerName.. " vs. " ..playerName)

        if portrait.playerName == playerName then
            print("Attempting to lock portrait for " .. playerName)

            -- Check if portrait.model and portrait.portrait exist before modifying them
            if portrait.model then
                print("Locking 3D model for " .. playerName)
                portrait.model:SetAlpha(0.5)  -- Reduce opacity to 50% to grey it out
            else
                print("No model found for " .. playerName)
            end

            if portrait.portrait then
                print("Locking 2D portrait for " .. playerName)
                portrait.portrait:SetAlpha(0.5)  -- Grey out the portrait texture
                portrait.portrait:SetVertexColor(0.5, 0.5, 0.5)  -- Apply a grey color
            else
                print("No 2D portrait found for " .. playerName)
            end

            portrait.Locked = true
            -- Optionally, display a message in the UI indicating the player has ended their turn
        end

        if not portrait.Locked then 
            anyActive = true 
        end
    end
    
    if not anyActive and UnitIsGroupLeader("player") then TurnTracker:NextTurn() end
end


-- Function to clear all portraits
local function ClearPortraits()
    -- Loop through all active portraits and destroy them
    for _, portraitFrame in ipairs(activePortraits) do
        portraitFrame:Hide()  -- Hide the portrait
        portraitFrame:ClearAllPoints()  -- Clear the position
        portraitFrame:SetParent(nil)  -- Remove the portrait from its parent
    end
    -- Clear the active portraits table to free up memory
    print("Portraits before: " ..#activePortraits)
    activePortraits = {}
    print("Portraits after: " ..#activePortraits)
end


local function SetTrackerVisibility(visible)
    isVisible = visible
    if visible then
        TurnTracker:Show()
    else
        TurnTracker:Hide()
    end
end

-- Function to send turn updates to all players in the group
local function SendTurnUpdate()
    if IsInGroup() and UnitIsGroupLeader("player") then
        local visibilityState = isVisible and "1" or "0"
        
        -- Ensure batches[currentBatch] exists
        if not batches[currentBatch] then
            print("[CTSTurnTracker] Error: Active batch is nil!")
            return
        end
        
        -- Create a list of player names to display portraits for in the active batch
        local playerNames = table.concat(batches[currentBatch], ",")  -- Create a comma-separated list of player names
        
        -- Send the message with the current turn and the list of player names in the active batch
        local message = turnCounter .. ":" .. playerNames .. ":" .. visibilityState
        local channel = GetGroupChannel()
        
        -- Send to the group (RAID, PARTY, etc.)
        print("SENDING TURN MESSAGE.")
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, string.format("NEXT:%s", message), channel)
    end
end

local function RequestTurnSync()
    if IsInGroup() then
        local channel = GetGroupChannel()
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "REQUEST_SYNC", channel)
    end
end

local function HandleAddonMessage(prefix, message, _, sender)
    if prefix ~= ADDON_PREFIX then return end  -- Ignore unrelated messages

    if message == "REQUEST_SYNC" and UnitIsGroupLeader("player") then
        SendTurnUpdate()
    elseif message == "REQUEST_SYNC" and not UnitIsGroupLeader("player") then return
    else
        print(message)
        if UnitIsGroupLeader("player") then return end

        -- Parse the message (newTurn, playerNames, visibilityState)
        local command, newTurn, playerNamesReceived, visibilityState = strsplit(":", message)

        if command == "NEXT" then
            print("RECEIVED NEXT TURN MESSAGE")
        else
            print("RECEIVED UNKNOWN MESSAGE")
            return
        end

        -- Debug print to check the received player names
        if playerNamesReceived then
            print("[CTSTurnTracker] Received player names for batch: " .. playerNamesReceived)
        end

        -- Update the turn and visibility
        turnCounter = tonumber(newTurn)
        local visible = visibilityState == "1"
        SetTrackerVisibility(visible)

        -- Split the player names into a table and insert them into activeBatch
        local playerNames = {strsplit(",", playerNamesReceived)}  -- Split by commas

        -- Ensure activeBatch is reset before adding new players
        activeBatch = {}

        -- Insert each player into the activeBatch
        for _, playerName in ipairs(playerNames) do
            table.insert(activeBatch, playerName)  -- Add player to activeBatch
        end

        -- Debug: Print the active batch for debugging
        print("[CTSTurnTracker] Active Batch: " .. table.concat(activeBatch, ", "))

        -- Ensure UpdateTurnTracker is called on all clients
        UpdateTurnTracker()

        if turnCounter > 0 then
            ClearPortraits()
            DisplayPortraitsForActiveBatch()
        end
    end
end


-- Function to monitor and wait for all initiative rolls to be completed
local resultTicker = nil
local function MonitorAllRolls(rollGuid, ticker)
    -- Flag to track if all rolls have been received
    local allResultsReceived = true

    -- Check if all players have rolled (excluding NPCs)
    for _, playerName in ipairs(groupMembers) do
        if UnitIsPlayer(playerName) then
            -- If a player hasn't rolled yet, set allResultsReceived to false
            if not Dice.rollResults[rollGuid][playerName] then
                allResultsReceived = false
                break
            end
        end
    end

    -- If all rolls have been received, print a debug message and cancel the ticker
    if allResultsReceived then
        print("[CTSTurnTracker] All initiative rolls have been received.")
        resultTicker:Cancel()  -- Stop the ticker once all rolls are in
    else
        print("[CTSTurnTracker] Waiting for all initiative rolls...")
    end

    return allResultsReceived
end

-- Function to sort groupMembers by initiative and separate players and NPCs
local function SortGroupMembersByInitiative()
    local players = {}
    local npcs = {}

    -- Step 1: Separate players and NPCs
    for _, playerName in ipairs(groupMembers) do
        if UnitIsPlayer(playerName) then
            -- Add player to the players table
            table.insert(players, {name = playerName, initiative = Dice.rollResults[initiativeGuid][playerName]})
        else
            -- Add NPC to the NPCs table
            table.insert(npcs, playerName)
        end
    end

    -- Step 2: Sort players by initiative (highest first)
    table.sort(players, function(a, b)
        return a.initiative > b.initiative
    end)

    -- Step 3: Rebuild groupMembers: sorted players first, then NPCs
    groupMembers = {}
    for _, player in ipairs(players) do
        table.insert(groupMembers, player.name)
    end
    for _, npc in ipairs(npcs) do
        table.insert(groupMembers, npc)
    end

    -- Step 4: Print the final sorted turn order
    -- print("[CTSTurnTracker] Final Turn Order:")
    -- for i, member in ipairs(groupMembers) do
    --    print(string.format("  %d. %s", i, member))
    -- end
end

-- Function to batch group members (populate the batches table)
local function BatchGroupMembers()
    -- Ensure groupMembers is populated
    UpdateGroupMembers()
    SortGroupMembersByInitiative()

    local totalMembers = #groupMembers  -- Total number of group members
    local batchSize = 5  -- We are using 5 members per batch for now
    numBatches = math.ceil(totalMembers / batchSize)

    batches = {}  -- Reset the batches table
    local currentBatchIndex = 1

    for i = 1, totalMembers do
        -- Add each member to the current batch
        if not batches[currentBatchIndex] then
            batches[currentBatchIndex] = {}
        end
        table.insert(batches[currentBatchIndex], groupMembers[i])

        -- If the batch size is reached, move to the next batch
        if #batches[currentBatchIndex] == batchSize then
            currentBatchIndex = currentBatchIndex + 1
        end
    end

    -- Print batches for debugging
    -- for i, batch in ipairs(batches) do
    --    print("[CTSTurnTracker] Batch " .. i .. ": " .. table.concat(batch, ", "))
    -- end
end


SLASH_CTS1, SLASH_CTS2, SLASH_CTS3 = "/cts", "/ctstart", "/ctnext"

-- Function to start the turn tracker with initiative roll
local function StartTurnTracker()
    turnCounter = 0

    -- Roll initiative for all players and NPCs
    initiativeGuid = Dice.RequestRoll(nil, "initiative", "Initiative")  -- Start the roll request
    UpdateGroupMembers()  -- Update the list of group members (players and NPCs)

    -- Set the active player as the first member in the sorted list
    activePlayerName = groupMembers[1] or currentPlayer
    SetTrackerVisibility(true)
    UpdateTurnTracker()

    -- Create a ticker to monitor the rolls every second
    resultTicker = C_Timer.NewTicker(1, function()
        if MonitorAllRolls(initiativeGuid, resultTicker) then
            Dice.PrintRollResults(initiativeGuid)
            SortGroupMembersByInitiative()
            BatchGroupMembers()         
            SendTurnUpdate()
        end
    end)
end

-- Function to handle next turn and switch to the next batch
local function NextTurn()
    print("DEBUG -- NEXT TURN/BATCH CALLED")
    if isCombatInitiativePhase then
        turnCounter = 1
        currentBatch = 1
        isCombatInitiativePhase = false
    elseif currentBatch == numBatches then
        turnCounter = turnCounter + 1
        currentBatch = 1
    elseif currentBatch < numBatches then
        currentBatch = currentBatch + 1
    end

    -- Ensure batches are populated correctly
    if not batches or #batches == 0 then
        print("Error: Batches not populated correctly.")
        return
    end

    -- Ensure currentBatch is within valid range
    if currentBatch < 1 or currentBatch > numBatches then
        print("Error: Invalid currentBatch value")
        return
    end

    -- Now we can safely access the active batch
    activeBatch = batches[currentBatch]

    if not activeBatch then
        print("Error: activeBatch is nil for currentBatch " .. currentBatch)
        return
    end

    -- Position portraits and create them for the active batch (done in DisplayPortraitsForActiveBatch)
    -- Create a parent frame to hold all the portraits for the active batch
    -- This code is no longer necessary in NextTurn, as it's handled by DisplayPortraitsForActiveBatch
    -- DisplayPortraitsForActiveBatch() is already being called separately in the game logic
    ClearPortraits()
    UpdateTurnTracker()
    DisplayPortraitsForActiveBatch()
    SendTurnUpdate()
end
TurnTracker.NextTurn = NextTurn



-- Function to end the turn tracker and reset all relevant states
local function EndTurnTracker()
    -- Hide the tracker
    SetTrackerVisibility(false)
    _G.HideActionBar()

    -- Reset the turn counter to 1 (combat phase begins from here)
    turnCounter = 1

    -- Reset activePlayerName to nil to ensure it's cleared
    activePlayerName = "Unknown Player"

    -- Reset the initiative phase flag to false (indicating combat has started)
    isCombatInitiativePhase = true

    -- Optionally, clear group members or reset them based on your needs
    groupMembers = {}

    -- Ensure any other needed resets are done here
    -- Reset initiative GUID if necessary
    initiativeGuid = nil

    -- Reset the turn tracker UI (e.g., portraits, name text)
    UpdateTurnTracker()

    -- Send a turn update to sync across the group
    SendTurnUpdate()
end


-- Slash Command Handling
SlashCmdList["CTS"] = function(msg)
    if not UnitIsGroupLeader("player") then
        print("[CTSTurnTracker] Only the party leader can control the turn tracker.")
        return
    end

    if msg == "start" then
        StartTurnTracker()  -- Start the turn tracker
    elseif msg == "next" then
        NextTurn()  -- Progress to the next turn
    elseif msg == "end" then
        EndTurnTracker()  -- End the turn tracker
    elseif msg == "hide" then
        _G.HideActionBar()
    elseif msg == "show" then
        _G.ShowActionBar()
    else
        print("Usage: /cts start | /cts next | /cts end")
    end
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        HandleAddonMessage(...)
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdateGroupMembers()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Delay the sync request to ensure addon messages are available
        C_Timer.After(2, function()
            RequestTurnSync()
        end)
    end
end)

_G.UpdateGroupMembers = UpdateGroupMembers
_G.UpdateTurnTracker = UpdateTurnTracker
_G.LockPortrait = LockPortrait
_G.GetGroupMembers = GetGroupMembers
_G.FindUnitIDByName = FindUnitIDByName
