-- Create the custom Talking Head-like frame
local customFrame = CreateFrame("Frame", "CustomTalkingHead", UIParent)
customFrame:SetSize(500, 150)  -- Frame size (can be adjusted)
customFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 200) -- Position the frame
customFrame:Hide()  -- Hide the frame by default

-- Set the frame's strata and level
customFrame:SetFrameStrata("DIALOG")
customFrame:SetFrameLevel(200)

-- Set background (semi-transparent black)
customFrame.bg = customFrame:CreateTexture(nil, "BACKGROUND")
customFrame.bg:SetAllPoints(true)
customFrame.bg:SetColorTexture(0, 0, 0, 0.7)  -- Semi-transparent black background

-- Add the NPC name text
customFrame.npcNameText = customFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
customFrame.npcNameText:SetPoint("TOPLEFT", customFrame, "TOPLEFT", 10, -10)  -- Align to the top left
customFrame.npcNameText:SetTextColor(1, 0.82, 0)  -- Yellow color

-- Add the model frame for the NPC
customFrame.model = CreateFrame("PlayerModel", nil, customFrame)
customFrame.model:SetSize(120, 120)  -- Set model window size
customFrame.model:SetPoint("LEFT", customFrame, "LEFT", 10, 0)  -- Position to the left
customFrame.model:SetPosition(2, 0, -0.5)  -- Zoom in model
customFrame.model:SetDisplayInfo(17227)  -- Use the NPC model ID (for example 17227)

-- Play the talking animation
customFrame.model:SetAnimation(1400)  -- Animation ID for talking

-- Add the text area for the NPC's dialogue
customFrame.text = customFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
customFrame.text:SetPoint("TOPLEFT", customFrame.model, "TOPRIGHT", 10, -20)
customFrame.text:SetTextColor(1, 1, 1)  -- White text color
customFrame.text:SetWidth(360)  -- Set the width of the text area (ensures wrapping)
customFrame.text:SetJustifyH("LEFT")  -- Left-align the text
customFrame.text:SetJustifyV("TOP")  -- Align text vertically at the top
customFrame.text:SetWordWrap(true)  -- Enable word wrapping

-- Add the "Close" button with the Blizzard talking head X icon
customFrame.closeButton = CreateFrame("Button", nil, customFrame)
customFrame.closeButton:SetSize(32, 32)  -- Button size for the X icon
customFrame.closeButton:SetPoint("TOPRIGHT", customFrame, "TOPRIGHT", -10, -10)  -- Position top right
customFrame.closeButton:SetNormalTexture("Interface\\DialogFrame\\UI-Dialog-Box-CloseButton")  -- Blizzard X button texture
customFrame.closeButton:SetPushedTexture("Interface\\DialogFrame\\UI-Dialog-Box-CloseButton-Down")  -- When pressed
customFrame.closeButton:SetHighlightTexture("Interface\\DialogFrame\\UI-Dialog-Box-CloseButton-Highlight")  -- When hovered
customFrame.closeButton:SetScript("OnClick", function()
    -- Hide the custom frame when clicked
    customFrame:Hide()
    ResetCustomDialogue()  -- Reset the frame after closing
end)

-- Function to reset the custom dialogue window after it fades out
local function ResetCustomDialogue()
    -- Clear the NPC name, text, and reset the model to avoid leftover data
    customFrame.npcNameText:SetText("")
    customFrame.text:SetText("")
    customFrame.model:SetDisplayInfo(0)  -- Reset model display to empty (0 resets to default model)
    customFrame.model:SetAnimation(0)  -- Reset animation
    customFrame.bg:SetAlpha(1)  -- Ensure background is fully visible if reused
    
    -- Reset the alpha of all visible elements
    customFrame.npcNameText:SetAlpha(1)
    customFrame.text:SetAlpha(1)
    customFrame.model:SetAlpha(1)
    customFrame.closeButton:SetAlpha(1)
end

-- Function to display the custom Talking Head dialogue with portrait
_G.ShowCustomDialogue = function(modelId, npcName, text, duration)
    -- Ensure the frame is fully reset before showing a new dialogue
    ResetCustomDialogue()

    -- Update the NPC name
    customFrame.npcNameText:SetText(npcName)

    -- Update the NPC model and dialogue text
    customFrame.model:SetDisplayInfo(modelId)  -- Replace with actual NPC ID as needed
    customFrame.text:SetText(text)

    -- Play the talking animation again to ensure it's played when shown
    customFrame.model:SetAnimation(60)  -- Animation ID for talking

    -- Show the frame (ensure it is visible before fading out)
    customFrame:Show()

    -- Make sure close button alpha is always 1 (fully visible)
    customFrame.closeButton:SetAlpha(1)

    -- Send the NPC's dialogue as a "Creature Say" message
    -- To simulate a "Creature Say" in the chat, we will use this method:
    ChatFrame1:AddMessage(npcName .. " says: " .. text, 1.0, 1.0, 0.624)  -- Correct Creature Say color

    -- Start fading out the entire frame (including background, model, text, close button)
    C_Timer.After(duration, function()  -- Use duration passed from TalkingHeadInterface.lua
        -- Gradually fade all elements out using a timer
        local fadeAlpha = 1
        C_Timer.NewTicker(0.1, function()
            fadeAlpha = fadeAlpha - 0.1  -- Decrease alpha by 0.1 every 0.1 seconds
            if fadeAlpha <= 0 then
                -- Fade out all components and hide the frame when done
                customFrame.bg:SetAlpha(0)
                customFrame.npcNameText:SetAlpha(0)
                customFrame.text:SetAlpha(0)
                customFrame.model:SetAlpha(0)  -- Fade out the model texture
                customFrame.closeButton:SetAlpha(0)  -- Fade out the close button

                -- Hide and reset the frame after fading
                customFrame:Hide()
                ResetCustomDialogue()  -- Reset the frame for the next message
            else
                -- Update the alpha of all elements during fade
                customFrame.bg:SetAlpha(fadeAlpha)
                customFrame.npcNameText:SetAlpha(fadeAlpha)
                customFrame.text:SetAlpha(fadeAlpha)
                customFrame.model:SetAlpha(fadeAlpha)
                customFrame.closeButton:SetAlpha(fadeAlpha)
            end
        end, 10)  -- 10 ticks will fade everything out over 1 second
    end)
end

-- Register the prefix for addon messages
C_ChatInfo.RegisterAddonMessagePrefix("TALKINGHEAD")

-- The message handler function
local function OnAddonMessage(self, event, prefix, message, channel, sender)
    if prefix == "TALKINGHEAD" then
        -- Parse the message
        local modelId, npcName, npcText, duration = strsplit(";", message)
        modelId = tonumber(modelId)
        duration = tonumber(duration)

        -- Display the custom dialogue
        if modelId and npcName and npcText and duration then
            ShowCustomDialogue(modelId, npcName, npcText, duration)
        else
            print("Error: Invalid message format.")
        end
    end
end

-- Register the event handler for receiving messages
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent", OnAddonMessage)


