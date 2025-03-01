-- Initialise campaign database
_G.CampaignToolkitCampaignsDB = _G.CampaignToolkitCampaignsDB or {}

local CTCampaign = {}
_G.CTCampaign = CTCampaign

-- Function to generate a unique GUID for the campaign
local function GenerateGUID()
    return string.format("G%d-%d", time() % 100000, math.random(1000, 9999))
end

-- Function to Save a Campaign
function CTCampaign:SaveCampaign(guid, data)
    if not guid then
        print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t ❌ Error: Cannot save campaign without a GUID.")
        return
    end

    -- Ensure the global database exists
    _G.CampaignToolkitCampaignsDB[guid] = {
        Name = data.Name or "Unknown Campaign",
        Author = data.Author or "Unknown Author",
        Guid = guid, -- Ensure GUID is stored properly
        Icon = data.Icon or "interface/icons/inv_misc_questionmark",
        LastUpdated = GetServerTime(),
        SpellList = data.SpellList or {},
        AuraList = data.AuraList or {},
        Description = data.Description or "",
        Parent = data.Parent or "Miscellaneous",
        MarkForDeletion = data.MarkForDeletion or false
    }

    print("    |cff00ff00[RPT] Saved campaign|r:", data.Name, ", GUID:", guid)
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
function CTCampaign:LoadCampaign(guid)
    if not _G.CampaignToolkitCampaignsDB or not _G.CampaignToolkitCampaignsDB[guid] then
        print("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:16|t ❌ Error: Campaign with GUID '" .. guid .. "' not found!")
        return nil
    end

    -- Return a copy of the stored campaign data
    local campaignData = CopyTable(_G.CampaignToolkitCampaignsDB[guid])

    -- Load spells from the campaign.
    Spellbook:LoadSpellsFromCampaign(guid)

    return campaignData
end


function CTCampaign:SetData(data)
    if not data or not data.Guid then
        print("|cffff0000Error: Cannot set data without a valid GUID.|r")
        return
    end

    local guid = data.Guid

    -- Ensure campaign exists in memory
    _G.Campaigns[guid] = _G.Campaigns[guid] or {}

    -- Copy new data into memory
    for k, v in pairs(data) do
        _G.Campaigns[guid][k] = v
    end

    -- Ensure the database exists before saving
    _G.CampaignToolkitCampaignsDB[guid] = _G.CampaignToolkitCampaignsDB[guid] or {}

    -- Save to persistent storage
    _G.CampaignToolkitCampaignsDB[guid] = CopyTable(_G.Campaigns[guid])

    -- Ensure SaveCampaign exists before calling
    if CTCampaign.SaveCampaign then
        CTCampaign:SaveCampaign(guid, _G.Campaigns[guid])
    else
        print("|cffff0000Error: SaveCampaign function not found in CTCampaign.|r")
    end

    print("|cff00ff00Campaign data successfully updated for:|r " .. _G.Campaigns[guid].Name)
end



function CTCampaign:GetSavedCampaigns()
    local campaignList = {}

    if not _G.CampaignToolkitCampaignsDB then 
        return
    end

    for guid, campaign in pairs(_G.CampaignToolkitCampaignsDB) do
        if not campaign.MarkForDeletion then
            table.insert(campaignList, guid)
        end
    end

    return campaignList
end

function CTCampaign:CreateNewCampaign(name, author, icon, description)
    local guid = GenerateGUID()

    local newCampaign = {
        Name = name or "New Campaign",
        Author = author or UnitName("player"),
        Guid = guid,
        Icon = icon or "interface/icons/inv_misc_questionmark",
        LastUpdated = GetServerTime(),
        SpellList = {},
        AuraList = {},
        Description = description or "",
        Parent = "Miscellaneous",
        MarkForDeletion = false
    }

    -- Save Campaign to Database
    CTCampaign:SaveCampaign(guid, newCampaign)

    return guid
end


-- Hook campaign saving to game events (similar to profile saving)
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD") -- Ensures save on reload
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- Ensures data is available on login
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGOUT" or event == "PLAYER_LEAVING_WORLD" then
        if not CTCampaign.MarkedForDeletion then
            -- CTCampaign:SaveCampaign()
        end
    end

    if event == "PLAYER_ENTERING_WORLD" then
        local campaignGuids = CTCampaign:GetSavedCampaigns()  -- Corrected to use CTCampaign:GetSavedCampaigns()
        for _, guid in ipairs(campaignGuids) do
            CTCampaign:LoadCampaign(guid)  -- Corrected to use CTCampaign:LoadCampaign(guid)
        end
    end
end)

