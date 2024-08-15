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
local availablePlayerRoleAndIcon = {
    DAMAGER = '|TInterface\\AddOns\\KeyCount_dev\\Icons\\roles:14:14:0:0:64:64:0:18:0:18|t',
    HEALER = '|TInterface\\AddOns\\KeyCount_dev\\Icons\\roles:14:14:0:0:64:64:19:37:0:18|t',
    TANK = '|TInterface\\AddOns\\KeyCount_dev\\Icons\\roles:14:14:0:0:64:64:38:56:0:18|t'
}

---@param rootDescription ModifyMenuCallbackRootDescription
---@param contextData ModifyMenuCallbackContextData
local function isValidMenu(rootDescription, contextData)
    if not contextData then
        local tagType = validMenuTags[rootDescription.tag]
        return not tagType
    end
    local which = contextData.which
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
            Log(string.format('getPlayerNameForMenu found in LFGList: %s %s %s', tostring(name), tostring(realm),
                tostring(level)))
            return getLFGListInfo(owner)
        end
        return
    end
    local unit = contextData.unit
    if unit and UnitExists(unit) then
        name = GetUnitName(unit, true)
        level = UnitLevel(unit)
        Log(string.format('getPlayerNameForMenu found in unit: %s %s %s', tostring(name), tostring(realm),
            tostring(level)))
        return name, realm, level, unit
    end
    local accountInfo = contextData.accountInfo
    if accountInfo then
        local gameAccountInfo = accountInfo.gameAccountInfo
        name = gameAccountInfo.characterName
        realm = gameAccountInfo.realmName
        level = gameAccountInfo.characterLevel
        Log(string.format('getPlayerNameForMenu found in accountInfo: %s %s %s', tostring(name), tostring(realm),
            tostring(level)))
        return name, realm, level, unit
    end
end

local function getSuccessRateColor(rate)
    local idx
    if rate == 0 then
        idx = 1
    elseif rate == 100 then
        idx = 5
    else
        idx = math.floor(rate / 20) + 1
        if idx <= 0 then idx = 1 end
    end
    return KeyCount.defaults.colors.rating[idx].chat
end

local function getStringForRole(data, role)
    local score = KeyCount.utilstats.calculatePlayerScore(data.intime, data.outtime, data.abandoned, data.median,
        data.best)
    local scoreString = string.format("%.0f", score)
    local color = getSuccessRateColor(score)
    return string.format('%s%s%s', color, scoreString, KeyCount.defaults.colors.reset)
end

local function getPlayerDropdownString(data)
    local playerRoleString = ''
    for role, icon in pairs(availablePlayerRoleAndIcon) do
        local _data = data[role] or nil
        if _data then
            playerRoleString = playerRoleString .. icon .. getStringForRole(_data, role)
        end
    end
    return playerRoleString
end

---@param rootDescription ModifyMenuCallbackRootDescription
---@param data table
---@param name string Player name
---@param buttonPerRole boolean?
local function createButton(rootDescription, data, name, buttonPerRole)
    if not buttonPerRole then
        buttonPerRole = false
    end
    if buttonPerRole then
        for role, icon in pairs(availablePlayerRoleAndIcon) do
            local _data = data[role] or nil
            if _data then
                local roleString = icon .. 'Score: ' .. getStringForRole(_data, role)
                rootDescription:CreateButton(roleString, function()
                    GUI:Init()
                    KeyCount.gui:Show(KeyCount.gui.views.searchplayer.type, KeyCount.filterkeys.player.key, name)
                end)
            end
        end
    else
        local dropdownString = getPlayerDropdownString(data)
        rootDescription:CreateButton(string.format("Score: %s", dropdownString), function()
            GUI:Init()
            KeyCount.gui:Show(KeyCount.gui.views.searchplayer.type, KeyCount.filterkeys.player.key, name)
        end)
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
    name = 'Stoel'
    local players = KeyCount:GetStoredPlayers()
    if not players then
        return
    end
    local _data, playerName = KeyCount.filterfunctions.searchPlayerGetData(name, players)
    if not _data then
        return
    end
    local dataSeason = _data[KeyCount.defaults.season]
    rootDescription:CreateDivider()
    rootDescription:CreateTitle(addonName)
    createButton(rootDescription, dataSeason, name, true)
end

if ModifyMenu then
    Log('Called ModifyMenu')
    for name, enabled in pairs(validTypes) do
        if enabled then
            local tag = string.format('MENU_UNIT_%s', name)
            ModifyMenu(tag, OnMenuShow)
        end
    end
    for _, tag in ipairs(validMenuTags) do
        ModifyMenu(tag, GenerateClosure(OnMenuShow))
    end
end
