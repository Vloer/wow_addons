local DDE = LibStub and LibStub:GetLibrary("LibDropDownExtension-1.0", true)
local localVars = {}
local dropdownOptions = {
    {
        text = 'Show KeyCount stats',
        func = function()
            -- print(localVars['name'])
            -- KeyCount.gui.frame:Show()
            local name = 'Stoel'
            KeyCount.filterfunctions.print.searchplayer(name, true)
        end
    }
}
local validTypes = {
    ARENAENEMY = true,
    BN_FRIEND = true,
    CHAT_ROSTER = true,
    COMMUNITIES_GUILD_MEMBER = true,
    COMMUNITIES_WOW_MEMBER = true,
    ENEMY_PLAYER = true,
    FOCUS = true,
    FRIEND = true,
    GUILD = true,
    GUILD_OFFLINE = true,
    PARTY = true,
    PLAYER = true,
    RAID = true,
    RAID_PLAYER = true,
    SELF = true,
    TARGET = true,
    WORLD_STATE_SCORE = true,
}

local function getNameForBNetFriend(bnetIDAccount)
    if not C_BattleNet then return nil end
    local index = _G.BNGetFriendIndex(bnetIDAccount)
    if not index then return nil end
    for i = 1, C_BattleNet.GetFriendNumGameAccounts(index), 1 do
        local accountInfo = C_BattleNet.GetFriendGameAccountInfo(index, i)
        if accountInfo and accountInfo.clientProgram == BNET_CLIENT_WOW and (not accountInfo.wowProjectID or accountInfo.wowProjectID ~= WOW_PROJECT_CLASSIC) then
            if accountInfo.realmName then
                accountInfo.characterName = accountInfo.characterName .. "-" .. accountInfo.realmName:gsub("%s+", "")
            end
            return accountInfo.characterName
        end
    end
    return nil
end

local function getNameFromPlayerLink(playerLink)
    if not LinkUtil or not ExtractLinkData then return nil end
    local linkString, linkText = LinkUtil.SplitLink(playerLink)
    local linkType, linkData = ExtractLinkData(linkString)
    if linkType == "player" then
        return linkData
    elseif linkType == "BNplayer" then
        local _, bnetIDAccount = strsplit(":", linkData)
        if bnetIDAccount then
            local bnetID = tonumber(bnetIDAccount)
            if bnetID then
                return getNameForBNetFriend(bnetID)
            end
        end
    end
end

local function isValidDropdown(dropdown)
    return (type(dropdown.which) == "string" and validTypes[dropdown.which])
end

local function getPlayerName(dropdown)
    local unit = dropdown.unit
    local tempName, tempRealm = dropdown.name, dropdown.server
    local menuList = dropdown.menuList
    local name, realm, level
    local bnetIDAccount = dropdown.bnetIDAccount
    local quickJoinMember = dropdown.quickJoinMember
    local quickJoinButton = dropdown.quickJoinButton
    -- unit
    if not name and UnitExists(unit) and UnitIsPlayer(unit) then
        name = GetUnitName(unit, true)
        level = UnitLevel(unit)
        print(string.format('unit name %s realm %s level %s', name, tostring(realm), tostring(level)))
    end
    -- bnet
    if not name and bnetIDAccount then
        print('bnet')
        name, realm, level = getNameForBNetFriend(bnetIDAccount)
        print(string.format('bnet name %s realm %s level %s', name, tostring(realm), tostring(level)))
    end
    -- lfg
    if not name and menuList then
        print('menulist')
        for _, whisperButton in ipairs(menuList) do
            if whisperButton and (whisperButton.text == WHISPER_LEADER or whisperButton.text == WHISPER) then
                if whisperButton.arg1 then
                    return whisperButton.arg1
                end
            end
        end
        print(string.format('menulist name %s realm %s level %s', name, tostring(realm), tostring(level)))
    end
    -- quickjoin
    if not name and (quickJoinButton or quickJoinMember) then
        print('quickjoin')
        local memberInfo = quickJoinMember or quickJoinButton.Members[1]
        if memberInfo.playerLink then
            name, realm, level = getNameFromPlayerLink(memberInfo.playerLink)
        end
        print(string.format('quickjoin name %s realm %s level %s', name, tostring(realm), tostring(level)))
    end
    if not name and tempName then
        name = tempName
    end
    if not realm and tempRealm then
        realm = tempRealm
    end
    print(string.format('name %s realm %s level %s', name, tostring(realm), tostring(level)))
    return name, realm, level
end

--the callback function for when the dropdown event occurs
local function OnEvent(dropdown, event, options, level, data)
    if event == "OnShow" then
        if not isValidDropdown(dropdown) then return end
        local name, realm, plevel, unit = getPlayerName(dropdown)
        localVars['name'] = name
        localVars['realm'] = realm
        localVars['level'] = plevel
        -- if not name or (level and level==KeyCount.defaults.maxlevel) then
        if not name then
            return
        end
        if not options[1] then
            for i = 1, #dropdownOptions do
                local option = dropdownOptions[i]
                options[i] = option
            end
        end
        return true
    elseif event == "OnHide" then
        _G.wipe(options)
        return true
    end
end

-- registers callback
DDE:RegisterEvent("OnShow OnHide", OnEvent, 1)
