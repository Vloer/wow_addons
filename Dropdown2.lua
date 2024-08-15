---@class ModifyMenuCallbackContextData
---@field public fromPlayerFrame? boolean
---@field public isMobile? boolean
---@field public isRafRecruit? boolean
---@field public name? string
---@field public server? string
---@field public unit? string
---@field public which? string
---@field public accountInfo? any
---@field public playerLocation? any
---@field public friendsList? number

---@class ModifyMenuCallbackRootDescription
---@field public tag string
---@field public contextData? ModifyMenuCallbackContextData
---@field public CreateDivider fun(self: ModifyMenuCallbackRootDescription)
---@field public CreateTitle fun(self: ModifyMenuCallbackRootDescription, text: string)
---@field public CreateButton fun(self: ModifyMenuCallbackRootDescription, text: string, callback: fun())

local ModifyMenu = Menu and Menu.ModifyMenu
local addonName = "KeyCount"
local validMenuTags = {
    "MENU_LFG_FRAME_MEMBER_APPLY",
    "MENU_LFG_FRAME_SEARCH_ENTRY",
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

---@param rootDescription ModifyMenuCallbackRootDescription
---@param contextData ModifyMenuCallbackContextData
local function isValidMenu(rootDescription, contextData)
    if not contextData then
        local tagType = validMenuTags[rootDescription.tag]
        print(string.format('isValidMenu: %s %s', tagType, tostring(not(tagType))))
        return not tagType
    end
    local which = contextData.which
    print(string.format('isValidMenu which: %s %s', tostring(which), tostring(validTypes[which])))
    return which and validTypes[which]
end

local function getNameForBNetFriend(bnetIDAccount)
    if not C_BattleNet then return nil end
    local index = BNGetFriendIndex(bnetIDAccount)
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

local function getLFGListInfo(owner)
    return
end

---@param owner any
---@param rootDescription ModifyMenuCallbackRootDescription
---@param contextData ModifyMenuCallbackContextData
---@return string? name, string? realm, number? level, string? unit
local function getPlayerNameForMenu(owner, rootDescription, contextData)
    local name, realm, level
    local tag = rootDescription.tag
    if not contextData then
        local tagType = validMenuTags[tag]
        if tagType == 1 then
            Log(string.format('getPlayerNameForMenu found in LFGList: %s %s %s', tostring(name), tostring(realm), tostring(level)))
            return getLFGListInfo(owner)
        end
        return
    end
    local unit = contextData.unit
    if unit and UnitExists(unit) then
        name = GetUnitName(unit, true)
        level = UnitLevel(unit)
        Log(string.format('getPlayerNameForMenu found in unit: %s %s %s', tostring(name), tostring(realm), tostring(level)))
        return name, realm, level, unit
    end
    local accountInfo = contextData.accountInfo
    if accountInfo then
        local gameAccountInfo = accountInfo.gameAccountInfo
        name = gameAccountInfo.characterName
        realm = gameAccountInfo.realmName
        level = gameAccountInfo.characterLevel
        Log(string.format('getPlayerNameForMenu found in accountInfo: %s %s %s', tostring(name), tostring(realm), tostring(level)))
        return name, realm, level, unit
    end
end

---@param owner any
---@param rootDescription ModifyMenuCallbackRootDescription
---@param contextData ModifyMenuCallbackContextData
local function OnMenuShow(owner, rootDescription, contextData)
    if not isValidMenu(rootDescription, contextData) then
        return
    end
    local name, realm, level, unit = getPlayerNameForMenu(owner, rootDescription, contextData)
    if not name then
        return
    end
    local players = KeyCount:GetStoredPlayers()
    if not players then
        return
    end
    local _data, playerName = KeyCount.filterfunctions.searchPlayerGetData(name, players)
    Log(string.format('Found playerName %s', playerName))
    if not _data then
        return
    end
    -- TODO
    -- Data returned in the format playerName: {season: {role: []}} so extract these
    local dataSeason = _data['Dragonflight-3']
    local data = dataSeason['DAMAGER']
    rootDescription:CreateDivider()
    rootDescription:CreateTitle(addonName)
    local playerScore = KeyCount.utilstats.calculatePlayerScore(data.intime, data.outtime, data.abandoned, data.median, data.best)
    local playerScoreString = string.format("%.0f", playerScore)
    rootDescription:CreateButton(string.format("Score: %s [show stats]", playerScoreString), function()
        GUI:Init()
        KeyCount.gui:Show(KeyCount.gui.views.searchplayer.type, KeyCount.filterkeys.player.key, playerName)
    end)
end

if ModifyMenu then
    Log('Called ModifyMenu')
    for name, enabled in pairs(validTypes) do
        if enabled then
            local tag = string.format('MENU_UNIT_%s', name)
            print(tostring(tag), type(tag))
            ModifyMenu(tag, OnMenuShow)
        end
    end
    for _, tag in ipairs(validMenuTags) do
        print(tostring(tag), type(tag))
        ModifyMenu(tag, GenerateClosure(OnMenuShow))
    end
end









































-- Menu.ModifyMenu("MENU_UNIT_SELF", function(ownerRegion, rootDescription, contextData)
--     print('init modifymenu')
--     rootDescription:CreateDivider()
--     rootDescription:CreateTitle(addonName)
--     local name         = contextData.name or nil
--     local server       = contextData.server or nil
--     local searchString = ''
--     local player       = ''
--     -- for k,v in pairs(contextData) do
--     --     print(tostring(k), tostring(v))
--     -- end
--     for k, v in pairs(rootDescription) do
--         print(tostring(k), tostring(v))
--     end
--     if name then searchString = name end
--     if server then searchString = string.format('%s-%s', searchString, server) end
--     rootDescription:CreateButton("KeyCount stats", function()
--         if 2 > 1 then
--             print('checking ' .. searchString)
--             KeyCount.filterfunctions.print.searchplayer(searchString, true)
--             GUI:Init()
--             KeyCount.gui:Show(KeyCount.gui.views.searchplayer.type, KeyCount.filterkeys.player.key, searchString)
--         end
--     end)
-- end)

-- Menu.ModifyMenu("MENU_UNIT_BN_FRIEND", function(ownerRegion, rootDescription, contextData)
--     print('init modifymenu')
--     rootDescription:CreateDivider()
--     rootDescription:CreateTitle(addonName)
--     local name         = contextData.name or nil
--     local server       = contextData.server or nil
--     local searchString = ''
--     local player       = ''
--     for k, v in pairs(contextData) do
--         print(tostring(k), tostring(v))
--     end
--     if name then searchString = name end
--     if server then searchString = string.format('%s-%s', searchString, server) end
--     rootDescription:CreateButton("KeyCount stats", function()
--         if 2 > 1 then
--             print('checking ' .. searchString)
--             KeyCount.filterfunctions.print.searchplayer(searchString, true)
--             GUI:Init()
--             KeyCount.gui:Show(KeyCount.gui.views.searchplayer.type, KeyCount.filterkeys.player.key, searchString)
--         end
--     end)
-- end)
