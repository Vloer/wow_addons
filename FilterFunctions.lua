local orderByPlayer = function(dungeons)
    local dl = {}
    for _, dungeon in pairs(dungeons) do
        local player = dungeon.player
        if not dl[player] then dl[player] = {} end
        table.insert(dl[player], dungeon)
    end
    return dl
end

local fList = function()
    local _dungeons = GetStoredDungeons()
    if _dungeons then
        local dl = orderByPlayer(_dungeons)
        -- local dl = _dungeons
        for _, dungeons in pairs(dl) do
            ListDungeons(dungeons)
        end
    end
end

local fFilter = function(key, value)
    local _dungeons = GetStoredDungeons()
    if _dungeons then
        if #key == 0 and #value == 0 then
            local dl = orderByPlayer(_dungeons)
            for _, dungeons in pairs(dl) do
                ListDungeons(dungeons)
            end
        else
            local filteredDungeons = FilterData(_dungeons, key, value)
            ListDungeons(filteredDungeons)
        end

    end
end

local fRate = function(key, value)
    local _dungeons = GetStoredDungeons()
    if _dungeons then
        local filteredDungeons = FilterData(_dungeons, key, value)
        GetDungeonSuccessRate(filteredDungeons)
    end
end

FilterFunc = {
    listAll = fList,
    filter = fFilter,
    rate = fRate
}
