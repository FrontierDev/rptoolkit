-- Create the main frame for the interface window
local inputFrame = CreateFrame("Frame", "TalkingHeadInterface", UIParent, "BackdropTemplate")
inputFrame:SetSize(300, 250)  -- Set the frame size
inputFrame:SetPoint("CENTER", UIParent, "CENTER")  -- Position in the center of the screen
inputFrame:Hide()  -- Hide by default

-- Set the background and border for the frame
inputFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",  -- Blizzard background texture
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",   -- Blizzard border texture
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
inputFrame:SetBackdropColor(0, 0, 0, 1)  -- Black background
inputFrame:SetBackdropBorderColor(1, 1, 1, 1)  -- White border

-- Add a label for the NPC model ID input
local modelIdLabel = inputFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
modelIdLabel:SetPoint("TOP", inputFrame, "TOP", 0, -10)
modelIdLabel:SetText("NPC Model ID:")

-- Add an input box for the NPC model ID
local modelIdBox = CreateFrame("EditBox", nil, inputFrame, "InputBoxTemplate")
modelIdBox:SetSize(200, 30)  -- Set size
modelIdBox:SetPoint("TOP", modelIdLabel, "BOTTOM", 0, -10)
modelIdBox:SetAutoFocus(false)

-- Add a label for the NPC name input
local nameLabel = inputFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
nameLabel:SetPoint("TOP", modelIdBox, "BOTTOM", 0, -20)
nameLabel:SetText("NPC Name:")

-- Add an input box for the NPC name
local nameBox = CreateFrame("EditBox", nil, inputFrame, "InputBoxTemplate")
nameBox:SetSize(200, 30)  -- Set size
nameBox:SetPoint("TOP", nameLabel, "BOTTOM", 0, -10)
nameBox:SetAutoFocus(false)

-- Add a label for the NPC text input
local textLabel = inputFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
textLabel:SetPoint("TOP", nameBox, "BOTTOM", 0, -20)
textLabel:SetText("NPC Text:")

-- Add an input box for the NPC text (single-line)
local textBox = CreateFrame("EditBox", nil, inputFrame, "InputBoxTemplate")
textBox:SetSize(200, 30)  -- Set size for single-line text box
textBox:SetPoint("TOP", textLabel, "BOTTOM", 0, -10)
textBox:SetAutoFocus(false)

-- Add a Send button to trigger the global method
local sendButton = CreateFrame("Button", nil, inputFrame, "UIPanelButtonTemplate")
sendButton:SetSize(100, 30)  -- Button size
sendButton:SetPoint("BOTTOM", inputFrame, "BOTTOM", -50, 10)
sendButton:SetText("Send")

sendButton:SetScript("OnClick", function()
    local modelId = modelIdBox:GetText()
    local npcName = nameBox:GetText()
    local npcText = textBox:GetText()

    -- Function to calculate reading time
    local function calculateDuration(text)
        -- Split text into words
        local wordCount = select("#", string.split(" ", text))
        -- Average reading speed: 225 words per minute
        local wordsPerMinute = 225
        -- Time to read (in seconds)
        local timeInSeconds = (wordCount / wordsPerMinute) * 60
        -- Minimum 5 seconds
        return math.max(timeInSeconds, 5)
    end

    -- Check if fields are populated
    if modelId and npcName and npcText then
        -- Check if the ShowCustomDialogue function is available
        if ShowCustomDialogue then
            -- Calculate duration
            local duration = calculateDuration(npcText)

            local msg = modelId .. ";" .. npcName .. ";" .. npcText .. ";" .. duration

            -- Disable the send button while talking head is showing
            sendButton:SetEnabled(false)
            -- ShowCustomDialogue(modelId, npcName, npcText, duration)

            -- Re-enable after the duration
            C_Timer.After(duration, function()
                sendButton:SetEnabled(true)
            end)

            -- Check if the player is in a group or raid
            if IsInGroup() then

                -- Check if SendAddonMessage function exists
                if C_ChatInfo.SendAddonMessage then

                    -- Check if the player is a raid leader
                    if UnitIsGroupLeader("player") then
                        C_ChatInfo.SendAddonMessage("TALKINGHEAD", msg, "RAID")
                    else
                        C_ChatInfo.SendAddonMessage("TALKINGHEAD", msg, "PARTY")
                    end
                else
                    print("Error: SendAddonMessage is not available.")
                end
            else
                print("Error: You are not in a group or raid.")
            end
        else
            print("Error: ShowCustomDialogue method is not available.")
        end
    else
        print("Error: Please fill all fields!")
    end
end)



-- Add a Close button to hide the window
local closeButton = CreateFrame("Button", nil, inputFrame, "UIPanelButtonTemplate")
closeButton:SetSize(100, 30)  -- Button size
closeButton:SetPoint("BOTTOM", inputFrame, "BOTTOM", 50, 10)
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function()
    inputFrame:Hide()  -- Hide the frame when clicked
end)

-- Make the frame draggable
local isDragging = false
local dragStartX, dragStartY = 0, 0

inputFrame:SetMovable(true)  -- Allow the frame to be movable
inputFrame:EnableMouse(true) -- Make sure the frame can respond to mouse events
inputFrame:SetClampedToScreen(true) -- Keep it within the screen boundaries

inputFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        isDragging = true
        self:StartMoving()  -- Start moving the frame when the left button is clicked
    end
end)

inputFrame:SetScript("OnMouseUp", function(self)
    if isDragging then
        self:StopMovingOrSizing()  -- Stop moving the frame when the mouse button is released
        isDragging = false
    end
end)

-- Slash command to toggle the interface window
SLASH_TALKINGHEADINTERFACE1 = "/th"
SlashCmdList["TALKINGHEADINTERFACE"] = function()
    if inputFrame:IsShown() then
        inputFrame:Hide()  -- Hide the frame if it's already shown
    else
        inputFrame:Show()  -- Show the frame if it's hidden
    end
end
