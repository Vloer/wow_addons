SLASH_KEYCOUNT1 = "/keycount"
SLASH_KEYCOUNT2 = "/kc"
function SlashCmdList.KEYCOUNT()
    print(" ")
    printf("KeyCount: ===WELCOME===")
    printf("Type /kch or /kchelp for available options!")
    local dungeons = GetStoredDungeons()
    if dungeons then
        printf(string.format("There are %d dungeons stored in your database.", #dungeons))
    end
end

SLASH_KEYCOUNT_LIST1 = "/keycount_list"
SLASH_KEYCOUNT_LIST2 = "/kc_list"
SLASH_KEYCOUNT_LIST3 = "/kcl"
SLASH_KEYCOUNT_LIST4 = "/kclist"
function SlashCmdList.KEYCOUNT_LIST()
    print(" ")
    local dungeons = GetStoredDungeons()
    local dl = {}
    if dungeons then
        printf("KeyCount: ===PRINTING DUNGEONS===")
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
    print(" ")
    local key, value = ParseMsg(msg)
    local _dungeons = GetStoredDungeons()
    if _dungeons then
        printf("KeyCount: ===PRINTING DUNGEONS===")
        local dungeons = FilterData(_dungeons, key, value)
        ListDungeons(dungeons)
    end
end

SLASH_KEYCOUNT_SUCCESSRATE1 = "/kcrate"
SLASH_KEYCOUNT_SUCCESSRATE2 = "/kcr"
function SlashCmdList.KEYCOUNT_SUCCESSRATE(msg)
    print(" ")
    printf("KeyCount: ===PRINTING STATS===")
    local _dungeons = GetStoredDungeons()
    if _dungeons then
        local key, value = ParseMsg(msg)
        local dungeons = FilterData(_dungeons, key, value)
        GetDungeonSuccessRate(dungeons)
    end
end

SLASH_KEYCOUNT_HELP1 = "/kchelp"
SLASH_KEYCOUNT_HELP2 = "/kch"
function SlashCmdList.KEYCOUNT_HELP(msg)
    print(" ")
    printf("KeyCount: ===OPTIONS===")
    printf(" ")
    printf(" [/kcl]  |  [/kclist]")
    printf(" List all dungeons without filtering", Defaults.colors.chatWarning)
    printf(" ")
    printf(" [/kcf]  |  [/kcfilter]")
    printf(" List all dungeons with applied filter. You can filter for any key/value pair present in the dungeon object. Example:",
    Defaults.colors.chatWarning)
    printf(" /kcf player YOURNAME", Defaults.colors.chatWarning)
    printf(" For specific dungeon filtering, only type the dungeon abbreviation like so: ",
    Defaults.colors.chatWarning)
    printf(" /kcf ULD", Defaults.colors.chatWarning)
    printf(" ")
    printf(" [/kcr]  |  [/kcrate]")
    printf(" Show the success rate of all dungeons. Can be paired with filters.", Defaults.colors.chatWarning)
end

SLASH_KEYCOUNT_FILTEROPTS1 = "/kcfilteroptions"
SLASH_KEYCOUNT_FILTEROPTS2 = "/kco"
SLASH_KEYCOUNT_FILTEROPTS3 = "/kcoptions"
function SlashCmdList.KEYCOUNT_FILTEROPTS(msg)
    print(" ")
    printf("KeyCount: ===FILTER OPTIONS===")
    printf(" Format is /kcf or /kcrate <key> <value>")
    print(string.format("%s [<nothing>] %sDungeon name or abbreviation (ex: RLP)|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning))
    print(string.format("%s [season] %sMythic+ season (ex: Dragonflight-1)|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning))
    print(string.format("%s [player] %sPlayer name|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning))
    print(string.format("%s [name] %sDungeon name|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning))
    print(string.format("%s [completed] %sOnly completed runs|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning))
    print(string.format("%s [inTime] %sOnly runs completed in time|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning))
    print(string.format("%s [time] %sOnly runs longer than x seconds|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning))
    print(string.format("%s [deathsGT] %sOnly runs more than x deaths|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning))
    print(string.format("%s [deathsLT] %sOnly runs less than x deaths|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning))
    print(string.format("%s [level] %sOnly runs above specific level|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning))
    print(string.format("%s [date] %sSpecific date (format 1999-12-31)|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning)) 
    print(string.format("%s [affix] %sSpecific affix (comma = AND, | = OR)|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning))
    print(string.format("%s Example: %saffix raging,quaking = raging AND quaking|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning))
    print(string.format("%s Example: %saffix volcanic||necrotic = either volcanic or necrotic or both|r", Defaults.colors.chatAnnounce, Defaults.colors.chatWarning))
end


