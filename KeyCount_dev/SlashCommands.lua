SLASH_KEYCOUNT_LIST1 = "/keycount_list"
SLASH_KEYCOUNT_LIST2 = "/kc_list"
SLASH_KEYCOUNT_LIST3 = "/kcl"
SLASH_KEYCOUNT_LIST4 = "/kclist"
function SlashCmdList.KEYCOUNT_LIST()
    local dungeons = StoredDungeons()
    local dl = {}
    if dungeons then
        for _, dungeon in pairs(dungeons) do
            local player = dungeon.player
            if not dl[player] then dl[player] = {} end
            table.insert(dl[player], dungeon)
        end
        for _, dungeons in pairs(dl) do
            ListDungeons(dungeons)
        end
    end
end

SLASH_KEYCOUNT_FILTER1 = "/kcfilter"
SLASH_KEYCOUNT_FILTER2 = "/kcf"
function SlashCmdList.KEYCOUNT_FILTER(msg)
    local key, value = ParseMsg(msg)
    local _dungeons = StoredDungeons()
    if _dungeons then
        local dungeons = Filter(_dungeons, key, value)
        ListDungeons(dungeons)
    end
end

SLASH_KEYCOUNT_SUCCESSRATE1 = "/kcrate"
function SlashCmdList.KEYCOUNT_SUCCESSRATE(msg)
    local _dungeons = StoredDungeons()
    if _dungeons then
        local key, value = ParseMsg(msg)
        local dungeons = Filter(_dungeons, key, value)
        GetDungeonSuccessRate(dungeons)
    end
end

SLASH_KEYCOUNT_CLEAR_ALL1 = "/kcclearall"
function SlashCmdList.KEYCOUNT_CLEAR_ALL()
    wipe(KeyCountDB)
    Log("Cleared KeyCount database.")
end
