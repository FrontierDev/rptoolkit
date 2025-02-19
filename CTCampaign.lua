-- Initialise campaign database
_G.CampaignToolkitCampaignsDB = _G.CampaignToolkitCampaignsDB or {}

local CTCampaign = {}
_G.CTCampaign = CTCampaign

-- Function to generate a unique GUID for the campaign
local function GenerateGUID()
    return string.format("G%d-%d", time() % 100000, math.random(1000, 9999))
end

-- Function to save campaign to database in WTF folder
function CTCampaign:SaveCampaign()
    if not self.Guid then
        print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t ❌ Error: Cannot save campaign with no GUID.")
        return
    end

    -- Ensure the global database exists
    _G.CampaignToolkitCampaignsDB[self.Guid] = {
        Name = self.Name,
        Author = self.Author,
        Guid = self.Guid or GenerateGUID(),
        Icon = self.Icon or "interface/icons/inv_misc_questionmark",
        LastUpdated = GetServerTime(),
        SpellList = self.SpellList or {},
        AuraList = self.AuraList or {},
        Description = self.Description
    }

    print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Campaign '" .. self.Guid .. "' saved successfully.")
end

-- Function to count the number of campaigns in _G.Campaigns
local function CountCampaigns()
    local count = 0
    for _, _ in pairs(_G.Campaigns) do
        count = count + 1
    end
    return count
end

-- Function to load a campaign from the database
function CTCampaign:LoadCampaign(campaignGuid)
    if not _G.CampaignToolkitCampaignsDB[campaignGuid] then
        print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t ❌ Error: Campaign with GUID '" .. campaignGuid .. "' not found!")
        return
    end

    local data = _G.CampaignToolkitCampaignsDB[campaignGuid]
    self:SetData(data)

    -- Add the loaded campaign to _G.Campaigns
    _G.Campaigns[campaignGuid] = self

    print("|TInterface\\RaidFrame\\ReadyCheck-Ready:16|t Loaded campaign: " .. self.Name .. " | Number of campaigns: " .. CountCampaigns())  -- Corrected to use CountCampaigns

    -- Load spells from this campaign.
    Spellbook:LoadSpellsFromCampaign(campaignGuid)
    Spellbook:UpdateSpellbookUI()
end

-- Function to set campaign data
function CTCampaign:SetData(data)
    self.Name = data.Name or "Unknown Campaign"
    self.Guid = data.Guid or GenerateGUID()
    self.Author = data.Author or "Unknown Author"
    self.LastUpdated = data.LastUpdated or GetServerTime()
    self.SpellList = data.SpellList or {}
    self.AuraList = data.AuraList or {}
    self.Icon = data.Icon or "interface/icons/inv_misc_questionmark"
    self.Description = data.Description

    CTCampaign:SaveCampaign() -- Automatically save after setting data
end

-- Function to get a list of saved campaigns
function CTCampaign:GetSavedCampaigns()
    local campaignGuids = {}
    for Guid, _ in pairs(_G.CampaignToolkitCampaignsDB) do
        table.insert(campaignGuids, Guid)
    end
    return campaignGuids
end

-- Hook campaign saving to game events (similar to profile saving)
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD") -- Ensures save on reload
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- Ensures data is available on login
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGOUT" or event == "PLAYER_LEAVING_WORLD" then
        if CTCampaign.Guid ~= "NONE" then
            CTCampaign:SaveCampaign()
            print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t 💾 Campaign '" .. CTCampaign.Guid .. "' saved before logout/reload.")
        end
    end

    if event == "PLAYER_ENTERING_WORLD" then
        local campaignGuids = CTCampaign:GetSavedCampaigns()  -- Corrected to use CTCampaign:GetSavedCampaigns()
        for _, guid in ipairs(campaignGuids) do
            CTCampaign:LoadCampaign(guid)  -- Corrected to use CTCampaign:LoadCampaign(guid)
        end
    end
end)

