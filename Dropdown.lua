local DDE = LibStub and LibStub:GetLibrary("LibDropDownExtension-1.0", true)
local localVars = {}
local dropdownOptions = {
    {
        text = "Search for player in KeyCount",
        func = function()
            print(localVars['name'])
            KeyCount.gui.frame:Show()
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

local function isValidDropdown(dropdown)
    local valid = (type(dropdown.which) == "string" and validTypes[dropdown.which])
    if valid then
        print('dropdown valid')
    else
        print('dropdown invalid')
    end
    return valid
end

local function getPlayerName(dropdown)
    print('enter getPlayerName')
    local unit = dropdown.unit
    local tempName, tempRealm = dropdown.name, dropdown.server
    local menuList = dropdown.menuList
    local name, realm, level
    -- unit
    if not name and UnitExists(unit) then
        if UnitIsPlayer(unit) then
            -- name, realm = KeyCount.util.addRealmToName:GetNameRealm(unit)
            level = UnitLevel(unit)
            if tempName then name = tempName end
            if tempRealm then realm = tempRealm end
            print(tostring(name), tostring(level), tostring(tempName), tostring(tempRealm))
        end
        -- if it's not a player it's pointless to check further
        return name, realm, level, unit
    end
    -- if not name and menuList then
    --     for i = 1, #menuList do
    --         local whisperButton = menuList[i]
    --         if whisperButton and (whisperButton.text == WHISPER_LEADER or whisperButton.text == WHISPER) then
    --             for k,v in pairs(whisperButton) do
    --                 print(k,v )
    --             end
    --             break
    --         end
    --     end
    -- end
end


--the callback function for when the dropdown event occurs
local function OnEvent(dropdown, event, options, level, data)
    if event == "OnShow" then
        if not isValidDropdown(dropdown) then return end
        local name, realm, level, unit = getPlayerName(dropdown)
        localVars['name'] = name
        localVars['realm'] = realm
        localVars['level'] = level
        -- check if dropdown is on a valid player
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
-- registers our callback function for the show and hide events for the first dropdown level only
DDE:RegisterEvent("OnShow OnHide", OnEvent, 1, {})
