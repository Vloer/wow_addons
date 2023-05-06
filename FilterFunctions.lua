Filter = {
    list = function()
        local dungeons = GetStoredDungeons()
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
    end,
    filter = function(key, value)
        local _dungeons = GetStoredDungeons()
        if _dungeons then
            printf("KeyCount: ===PRINTING DUNGEONS===")
            local dungeons = FilterData(_dungeons, key, value)
            ListDungeons(dungeons)
        end
    end,
    rate = function(key, value)
        local _dungeons = GetStoredDungeons()
        if _dungeons then
            local key, value = ParseMsg(msg)
            local dungeons = FilterData(_dungeons, key, value)
            GetDungeonSuccessRate(dungeons)
        end
    end
}
