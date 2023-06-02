local stats = KeyCount.utilstats

function stats.printDungeons(dungeons)
    for i, dungeon in ipairs(dungeons) do
        if dungeon.keyresult.value == KeyCount.defaults.keyresult.intime.value then
            printf(string.format("[%s] %d: %s %s %d (%d deaths)", dungeon.player, i, KeyCount.defaults.keyresult.intime.name, dungeon.name,
                dungeon.keydata.level, dungeon.totalDeaths), KeyCount.defaults.colors.rating[5].chat)
        elseif dungeon.keyresult.value == KeyCount.defaults.keyresult.outtime.value then
            printf(string.format("[%s] %d: %s %s %d (%d deaths)", dungeon.player, i, KeyCount.defaults.keyresult.outtime.name, dungeon.name,
                dungeon.keydata.level, dungeon.totalDeaths), KeyCount.defaults.colors.rating[3].chat)
        elseif dungeon.keyresult.value == KeyCount.defaults.keyresult.abandoned.value then
            printf(string.format("[%s] %d: %s %s %d (%d deaths)", dungeon.player, i, KeyCount.defaults.keyresult.abandoned.name, dungeon.name,
                dungeon.keydata.level, dungeon.totalDeaths), KeyCount.defaults.colors.rating[1].chat)
        end
    end
end

function stats.printDungeonSuccessRate(tbl)
    for _, d in ipairs(tbl) do
        local colorIdx = math.floor(d.successRate / 20) + 1
        local fmt = KeyCount.defaults.colors.rating[colorIdx].chat
        printf(string.format("%s: %.2f%% [%d/%d]", d.name, d.successRate, d.intime, d.intime + d.outtime + d.abandoned),
            fmt)
    end
end

function stats.chatDungeonSuccessRate(tbl)
    local next = next
    if not tbl or next(tbl) == nil or #tbl == 0 then return end
    local outputchannel = "PARTY"
    local numgroup = GetNumGroupMembers()
    if numgroup == 0 then
        outputchannel = "SAY"
    elseif numgroup > 5 then
        outputchannel = "RAID"
    end
    for _, d in ipairs(tbl) do
        SendChatMessage(
            string.format("%s: %.2f%% [%d/%d]", d.name, d.successRate, d.intime, d.intime + d.outtime + d.abandoned),
            outputchannel)
    end
end

function stats.getDungeonSuccessRate(dungeons)
    local res = {}
    local resRate = {}
    for _, dungeon in ipairs(dungeons) do
        if not res[dungeon.name] then
            res[dungeon.name] = { intime = 0, outtime = 0, abandoned = 0, best = 0, maxdps = 0, allkeys = {} }
        end
        local keylevel = dungeon.keydata.level or 0
        if keylevel > 0 then
            table.insert(res[dungeon.name].allkeys, keylevel)
        end
        if dungeon.keyresult.value == KeyCount.defaults.keyresult.intime.value then
            res[dungeon.name].intime = (res[dungeon.name].intime or 0) + 1
            local level = dungeon.keydata.level
            if level > res[dungeon.name].best then
                res[dungeon.name].best = level
            end
        elseif dungeon.keyresult.value == KeyCount.defaults.keyresult.outtime.value then
            res[dungeon.name].outtime = (res[dungeon.name].outtime or 0) + 1
        else
            res[dungeon.name].abandoned = (res[dungeon.name].abandoned or 0) + 1
        end
        local dps = stats.getPlayerDps(dungeon.party[dungeon.player])
        if dps > res[dungeon.name].maxdps then
            res[dungeon.name].maxdps = dps
        end
        --@debug@
        KeyCount.util.printTableOnSameLine(res[dungeon.name], "GetDungeonSuccessRate")
        --@end-debug@
    end
    for name, d in pairs(res) do
        local successRate = 0
        local total = d.intime + d.outtime + d.abandoned
        local median = KeyCount.util.calculateMedian(d.allkeys)
        if (d.outtime + d.abandoned) == 0 then
            successRate = 100
        elseif d.intime == 0 then
            successRate = 0
        else
            successRate = d.intime / total * 100
        end
        table.insert(resRate,
            {
                name = name,
                successRate = successRate,
                intime = d.intime,
                outtime = d.outtime,
                abandoned = d.abandoned,
                best = d.best,
                median = median,
                totalAttempts = total,
                maxdps = d.maxdps
            })
    end
    table.sort(resRate, function(a, b)
        return a.successRate > b.successRate
    end)
    return resRate
end

function stats.getPlayerList(dungeons)
    local pl = {}
    for _, d in ipairs(dungeons) do
        local player = d.player
        for _, p in ipairs(pl) do
            local found = false
            if p == player then
                found = true
                break
            end
            if not found then
                table.insert(pl, player)
            end
        end
    end
    return pl
end

function stats.getPlayerSuccessRate(dungeons)
    local data = {}
    local rate = {}
    for _, d in ipairs(dungeons) do
        local party = d.party
        local keylevel = d.keydata.level or 0
        for player, playerdata in pairs(party) do
            if not data[player] then
                data[player] = { amount = 0, intime = 0, abandoned = 0, outtime = 0, best = 0, maxdps = 0, allkeys = {} }
            end
            data[player].name = data[player].name or player
            data[player].amount = (data[player].amount or 0) + 1
            if keylevel > 0 then
                table.insert(data[player].allkeys, keylevel)
            end
            local dps = KeyCount.utilstats.getPlayerDps(playerdata)
            if dps > data[player].maxdps then
                data[player].maxdps = dps
            end
            data[player].role = data[player].role or playerdata.role
            data[player].class = data[player].class or playerdata.class
            if d.keyresult.value == KeyCount.defaults.keyresult.intime.value then
                data[player].intime = (data[player].intime or 0) + 1
                if d.keydata.level > data[player].best then
                    data[player].best = d.keydata.level
                end
            elseif d.completed then
                data[player].outtime = (data[player].outtime or 0) + 1
            else
                data[player].abandoned = (data[player].abandoned or 0) + 1
            end
            --@debug@
            KeyCount.util.printTableOnSameLine(data[player], "GetPlayerSuccessRate")
            --@end-debug@
        end
    end
    for player, d in pairs(data) do
        local successRate = 0
        local total = d.intime + d.abandoned + d.outtime
        local median = KeyCount.util.calculateMedian(d.allkeys)
        if (d.abandoned + d.outtime) == 0 then
            successRate = 100
        elseif d.intime == 0 then
            successRate = 0
        else
            successRate = d.intime / total * 100
        end
        table.insert(rate,
            {
                name = player,
                amount = d.amount,
                successRate = successRate,
                intime = d.intime,
                outtime = d.outtime,
                abandoned = d.abandoned,
                best = d.best,
                median = median,
                maxdps = d.maxdps,
                class = d.class,
                role = d.role
            })
    end
    table.sort(rate, function(a, b)
        return a.amount > b.amount
    end)
    return rate
end

function stats.showPastDungeons()
    PreviousRunsDB = PreviousRunsDB or {}
    local runs = C_MythicPlus.GetRunHistory(true, true) -- This only captures finished dungeons
    local previousDungeons = {}
    for i, run in ipairs(runs) do
        local map = C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID)
        local level = run.level
        local completed = run.completed
        Log(string.format("%d: %s level %s %s", i, map, level, tostring(completed)))
        local dungeon = KeyCount.defaults.dungeonDefault
        dungeon.name = map
        dungeon.keydata.level = level
        dungeon.completed = completed
        table.insert(previousDungeons, dungeon)
    end
end

-- Get the top dps of the party
---@param party table Table containing party data
---@return number dps
function stats.getTopDps(party)
    local dmg = {}
    for player, data in pairs(party) do
        local d = data.damage or {}
        local dps = d.dps or 0
        table.insert(dmg, { player = player, dps = dps })
    end
    table.sort(dmg, function(a, b) return a.dps > b.dps end)
    return dmg[1]
end

-- Get a single players dps
---@param data table The party table data for the specific player
---@return number dps Returns 0 if no data found
function stats.getPlayerDps(data)
    local d = data.damage or {}
    local dps = d.dps or 0
    return dps
end

-- Get a single players hps
---@param data table The party table data for the specific player
---@return number hps Returns 0 if no data found
function stats.getPlayerHps(data)
    local h = data.healing or {}
    local hps = h.hps or 0
    return hps
end