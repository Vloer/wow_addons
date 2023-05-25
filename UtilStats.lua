local stats = KeyCount.utilstats

function stats.printDungeons(dungeons)
    for i, dungeon in ipairs(dungeons) do
        if dungeon.completedInTime then
            printf(string.format("[%s] %d: Timed %s %d (%d deaths)", dungeon.player, i, dungeon.name,
                dungeon.keyDetails.level, dungeon.totalDeaths), KeyCount.defaults.colors.rating[5].chat)
        elseif dungeon.completed then
            printf(string.format("[%s] %d: Failed to time %s %d (%d deaths)", dungeon.player, i, dungeon.name,
                dungeon.keyDetails.level, dungeon.totalDeaths), KeyCount.defaults.colors.rating[3].chat)
        else
            printf(string.format("[%s] %d: Abandoned %s %d (%d deaths)", dungeon.player, i, dungeon.name,
                dungeon.keyDetails.level, dungeon.totalDeaths), KeyCount.defaults.colors.rating[1].chat)
        end
    end
end

function stats.printDungeonSuccessRate(tbl)
    for _, d in ipairs(tbl) do
        local colorIdx = math.floor(d.successRate / 20) + 1
        local fmt = KeyCount.defaults.colors.rating[colorIdx].chat
        printf(string.format("%s: %.2f%% [%d/%d]", d.name, d.successRate, d.success, d.success + d.failed + d.outOfTime),
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
            string.format("%s: %.2f%% [%d/%d]", d.name, d.successRate, d.success, d.success + d.failed + d.outOfTime),
            outputchannel)
    end
end

function stats.getDungeonSuccessRate(dungeons)
    local res = {}
    local resRate = {}
    for _, dungeon in ipairs(dungeons) do
        if not res[dungeon.name] then
            res[dungeon.name] = { success = 0, failed = 0, outOfTime = 0, best = 0 }
        end
        if dungeon.completedInTime then
            res[dungeon.name].success = (res[dungeon.name].success or 0) + 1
            local level = dungeon.keyDetails.level
            if level > res[dungeon.name].best then
                res[dungeon.name].best = level
            end
        else
            if dungeon.completed then
                res[dungeon.name].outOfTime = (res[dungeon.name].outOfTime or 0) + 1
            else
                res[dungeon.name].failed = (res[dungeon.name].failed or 0) + 1
            end
        end
    end
    for name, d in pairs(res) do
        local successRate = 0
        local total = d.success + d.failed + d.outOfTime
        if (d.failed + d.outOfTime) == 0 then
            successRate = 100
        elseif d.success == 0 then
            successRate = 0
        else
            successRate = d.success / total * 100
        end
        table.insert(resRate,
            {
                name = name,
                successRate = successRate,
                success = d.success,
                outOfTime = d.outOfTime,
                failed = d.failed,
                best = d.best,
                totalAttempts = total
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
        for player, playerdata in pairs(party) do
            if not data[player] then
                data[player] = { amount = 0, success = 0, failed = 0, outOfTime = 0, best = 0, maxdps = 0 }
            end
            data[player].name = data[player].name or player
            data[player].amount = (data[player].amount or 0) + 1
            local dps = KeyCount.utilstats.getPlayerDps(playerdata)
            if dps > data[player].maxdps then
                data[player].maxdps = dps
            end
            data[player].role = data[player].role or playerdata.role
            data[player].class = data[player].class or playerdata.class
            if d.completedInTime then
                data[player].success = (data[player].success or 0) + 1
                if d.keyDetails.level > data[player].best then
                    data[player].best = d.keyDetails.level
                end
            elseif d.completed then
                data[player].outOfTime = (data[player].outOfTime or 0) + 1
            else
                data[player].failed = (data[player].failed or 0) + 1
            end
            KeyCount.util.printTableOnSameLine(data[player])
        end
    end
    for player, d in pairs(data) do
        local successRate = 0
        local total = d.success + d.failed + d.outOfTime
        if (d.failed + d.outOfTime) == 0 then
            successRate = 100
        elseif d.success == 0 then
            successRate = 0
        else
            successRate = d.success / total * 100
        end
        table.insert(rate,
            {
                name = player,
                amount = d.amount,
                successRate = successRate,
                success = d.success,
                outOfTime = d.outOfTime,
                failed = d.failed,
                best = d.best,
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
        dungeon.completedInTime = completed
        dungeon.keyDetails.level = level
        dungeon.completed = completed
        table.insert(previousDungeons, dungeon)
    end
end

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

function stats.getPlayerDps(data)
    local d = data.damage or {}
    local dps = d.dps or 0
    return dps
end