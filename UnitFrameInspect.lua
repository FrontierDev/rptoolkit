-- UnitFrameInspect.lua (Handles Pop-Up Window)
local InspectFrame = CreateFrame("Frame", "UnitFrameInspectWindow", UIParent, "BackdropTemplate")
InspectFrame:SetSize(250, 150)
InspectFrame:SetPoint("CENTER")
InspectFrame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
InspectFrame:Hide()  -- Hide it by default

-- Close Button
InspectFrame.CloseButton = CreateFrame("Button", nil, InspectFrame, "UIPanelCloseButton")
InspectFrame.CloseButton:SetPoint("TOPRIGHT", InspectFrame, "TOPRIGHT", -5, -5)
InspectFrame.CloseButton:SetScript("OnClick", function()
    InspectFrame:Hide()
end)

-- Function to Show the Pop-Up Window
function UnitFrameInspect_Show(unitFrame)
    InspectFrame:Show()
end
