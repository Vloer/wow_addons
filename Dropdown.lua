local DDE = LibStub and LibStub:GetLibrary("LibDropDownExtension-1.0", true)
local dropdownOptions = {
    {
        text = "Click me to print some stuff!",
        func = function(...) print("You clicked me!", ...) end,
    },
    -- DDE.Option.Separator,
    -- {
    --     text = "This is after the separator",
    --     func = print,
    -- },
    -- DDE.Option.Space,
    -- {
    --     text = "This has a space above",
    --     func = print,
    -- },
    -- DDE.Option.Separator,
    -- {
    --     text = "This is after yet another separator",
    --     func = print,
    -- },
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
    -- print(string.format('triggered %s %s %s %s %s', tostring(dropdown), tostring(event), tostring(options),
    --     tostring(level), tostring(data)))
    -- for k, v in pairs(dropdown) do
    --     Log(string.format('%s: %s', k, v))
    -- end
    if event == "OnShow" then
        if not isValidDropdown(dropdown) then return end
        local name, realm, level, unit = getPlayerName(dropdown)
        -- check if dropdown is on a valid player
        -- if not name or (level and level==KeyCount.defaults.maxlevel) then
        if not name then
            return
        end
        -- add the dropdown options to the options table
        print('Options:')
        for k, v in ipairs(options) do print(k, v) end
        if not options[1] then
            print('not options, dropdownoptions: ' .. #dropdownOptions)
            for i = 1, #dropdownOptions do
                local option = dropdownOptions[i]
                print('adding ' .. option.text)
                options[i] = option
            end
            print('a')
            for i,v in pairs(options) do
                KeyCount.util.printTableOnSameLine(v)
                for k, vv in ipairs(v) do
                    print(k..': '..vv) 
                end
            end
        end
    elseif event == "OnHide" then
        -- when hiding we can remove our dropdown options from the options table
        for i = #options, 1, -1 do
            options[i] = nil
        end
    end
end
-- registers our callback function for the show and hide events for the first dropdown level only
DDE:RegisterEvent("OnShow OnHide", OnEvent, 1, {})
