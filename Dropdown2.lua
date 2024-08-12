local function isValidMenu()
    -- tmp
end

local isLoaded = false
local addonName = "KeyCount"
local validMenuTags = {
    "MENU_UNIT_SELF",
    "MENU_UNIT_PLAYER",
    "MENU_UNIT_BN_FRIEND",
    "MENU_UNIT_FRIEND",
    "MENU_UNIT_TARGET",
    "MENU_UNIT_COMMUNITIES_GUILD_MEMBER",
    "MENU_UNIT_PARTY",
    "MENU_UNIT_RAID",
    "MENU_LFG_FRAME_MEMBER_APPLY",
    "MENU_LFG_FRAME_SEARCH_ENTRY"
}

Menu.ModifyMenu("MENU_UNIT_SELF", function(ownerRegion, rootDescription, contextData)
    print('init modifymenu')
    rootDescription:CreateDivider()
    rootDescription:CreateTitle(addonName)
    local name         = contextData.name or nil
    local server       = contextData.server or nil
    local searchString = ''
    local player       = ''
    -- for k,v in pairs(contextData) do
    --     print(tostring(k), tostring(v))
    -- end
    if name then searchString = name end
    if server then searchString = string.format('%s-%s', searchString, server) end
    rootDescription:CreateButton("KeyCount stats", function()
        if 2 > 1 then
            print('checking '.. searchString)
            KeyCount.filterfunctions.print.searchplayer(searchString, true)
            GUI:Init()
            KeyCount.gui:Show(KeyCount.gui.views.searchplayer.type, KeyCount.filterkeys.player.key, searchString)
        end
    end)
end)

Menu.ModifyMenu("MENU_UNIT_BN_FRIEND", function(ownerRegion, rootDescription, contextData)
    print('init modifymenu')
    rootDescription:CreateDivider()
    rootDescription:CreateTitle(addonName)
    local name         = contextData.name or nil
    local server       = contextData.server or nil
    local searchString = ''
    local player       = ''
    for k,v in pairs(contextData) do
        print(tostring(k), tostring(v))
    end
    if name then searchString = name end
    if server then searchString = string.format('%s-%s', searchString, server) end
    rootDescription:CreateButton("KeyCount stats", function()
        if 2 > 1 then
            print('checking '.. searchString)
            KeyCount.filterfunctions.print.searchplayer(searchString, true)
            GUI:Init()
            KeyCount.gui:Show(KeyCount.gui.views.searchplayer.type, KeyCount.filterkeys.player.key, searchString)
        end
    end)
end)