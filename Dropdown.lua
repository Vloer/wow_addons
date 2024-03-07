local DDE = LibStub and LibStub:GetLibrary("LibDropDownExtension-1.0", true)
local dropdownOptions = {
    {
        text = "Click me to print some stuff!",
        func = function(...) print("You clicked me!", ...) end,
    },
    DDE.Option.Separator,
    {
        text = "This is after the separator",
        func = print,
    },
    DDE.Option.Space,
    {
        text = "This has a space above",
        func = print,
    },
    DDE.Option.Separator,
    {
        text = "This is after yet another separator",
        func = print,
    },
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

local function checkEligibleDropdown(dropdown)
    return (type(dropdown.which) == "string" and validTypes[dropdown.which])
end

local function getPlayerName(dropdown)
    local unit = dropdown.unit
    local name, realm = dropdown.name, dropdown.server
    
end

-- the callback function for when the dropdown event occurs
local function OnEvent(dropdown, event, options, level, data)
    print(string.format('triggered %s %s %s %s %s', tostring(dropdown), tostring(event), tostring(options),
        tostring(level), tostring(data)))
    for k, v in pairs(dropdown) do
        Log(string.format('%s: %s', k, v))
    end
    if event == "OnShow" then
        -- check if dropdown is on a valid player
        -- add the dropdown options to the options table
        print('onshow event')
        KeyCount.util.printTableOnSameLine(dropdown, 'dropdown')
        print('print 2')
        for i = 1, #dropdownOptions do
            options[i] = dropdownOptions[i]
        end
        print('print3')
    elseif event == "OnHide" then
        -- when hiding we can remove our dropdown options from the options table
        for i = #options, 1, -1 do
            options[i] = nil
        end
    end
end
-- registers our callback function for the show and hide events for the first dropdown level only
DDE:RegisterEvent("OnShow OnHide", OnEvent, 1, dropdown)
