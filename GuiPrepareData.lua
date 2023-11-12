local function rgb(tbl)
    return KeyCount.util.convertRgb(tbl)
end

---Get role image
---@param role string Role name
---@return string R Stringified image or empty string
local function getRoleIcon(role)
    if role == "DAMAGER" then
        return "|TInterface\\AddOns\\KeyCount_dev\\Icons\\roles:14:14:0:0:64:64:0:18:0:18|t"
    elseif role == "HEALER" then
        return "|TInterface\\AddOns\\KeyCount_dev\\Icons\\roles:14:14:0:0:64:64:19:37:0:18|t"
    elseif role == "TANK" then
        return "|TInterface\\AddOns\\KeyCount_dev\\Icons\\roles:14:14:0:0:64:64:38:56:0:18|t"
    end
    return ""
end

---Retrieve class and role from the dungeon party data for the player. Returns empty strings if player can't be found in party (bug)
---@param dungeon table Dungeon data
---@return string class Class name
---@return string role Role name
local function getClassAndRoleFromDungeon(dungeon)
    local party = dungeon.party
    local player = party[dungeon.player] or {}
    local class = player.class or ""
    local role = player.role or ""
    return class, role
end

---Retrieve class color and role icon
---@param class string Class name
---@param role string Role name
---@return table T Table containing [1] color rgb table, [2] color hex value string, [3] role icon string
local function getPlayerRoleAndColor(class, role)
    local color = { r = 1, g = 1, b = 1, a = 1 }
    local colorHex = "ffffffff"
    if #class ~= 0 then
        local classMale = KeyCount.util.getKeyForValue(LOCALIZED_CLASS_NAMES_MALE, class)
        local classFemale = KeyCount.util.getKeyForValue(LOCALIZED_CLASS_NAMES_FEMALE, class)
        local tbl = RAID_CLASS_COLORS[classMale or classFemale]
        color = { r = tbl.r, g = tbl.g, b = tbl.b, a = 1 }
        colorHex = tbl.colorStr
    end
    local roleIcon = getRoleIcon(role)
    return { color = color, hex = colorHex, roleIcon = roleIcon }
end

local function getLevelColor(level)
    local idx = 0
    if level > 0 then
        idx = math.floor(level / 5) + 1
    end
    local r, g, b, hex = GetItemQualityColor(idx)
    local color = { r = r, g = g, b = b, a = 1 }
    return { color = color, hex = hex }
end

local function getResultColor(dungeon)
    if dungeon.keyresult.value == KeyCount.defaults.keyresult.intime.value then
        return KeyCount.defaults.colors.rating[5]
    elseif dungeon.keyresult.value == KeyCount.defaults.keyresult.outtime.value then
        return KeyCount.defaults.colors.rating[3]
    elseif dungeon.keyresult.value == KeyCount.defaults.keyresult.abandoned.value then
        return KeyCount.defaults.colors.rating[1]
    end
end

local function getDeathsColor(deaths)
    local idx
    if deaths == 0 then
        idx = 5
    else
        idx = math.floor(6 - deaths / 4)
        if idx <= 0 then idx = 1 end
    end
    return rgb(KeyCount.defaults.colors.rating[idx].rgb)
end

local function getSuccessRateColor(rate)
    local idx
    if rate == 0 then
        idx = 1
    elseif rate == 100 then
        idx = 5
    else
        idx = math.floor(rate / 20) + 1
        if idx <= 0 then idx = 1 end
    end
    return rgb(KeyCount.defaults.colors.rating[idx].rgb)
end

local function getDungeonTime(dungeon, timetextcolor)
    local symbol = KeyCount.defaults.dungeonPlusChar
    local s = dungeon.timeToComplete
    local result = dungeon.keyresult.value
    local time = dungeon.time
    local limit = dungeon.keydata.timelimit or 0
    local amount
    if result >= KeyCount.defaults.keyresult.intime.value then
        if time < (limit * 0.6) then
            amount = 3
        elseif time < (limit * 0.8) then
            amount = 2
        else
            amount = 1
        end
    else
        amount = 0
    end
    s = KeyCount.util.colorText(s, timetextcolor.chat)
    s = KeyCount.util.addSymbol(s, amount, symbol)
    return s
end

local function formatDps(dps)
    local default = ""
    if type(dps) ~= "number" then return default end
    if dps > 0 then
        return KeyCount.util.formatK(dps)
    end
    return default
end

---Retrieves own player dps from dungeon data, formatted for the GUI
---@param dungeon table
---@return string dps
local function getPlayerDpsString(dungeon)
    local player = dungeon.player
    local party = dungeon.party
    local dps = KeyCount.utilstats.getPlayerDps(party[player])
    if dps > 0 then
        local dpsString = formatDps(dps)
        local topdps = KeyCount.utilstats.getTopDps(party)
        if player == topdps.player and topdps.dps > 0 then
            return KeyCount.util.addSymbol(dpsString, 1)
        else
            return dpsString
        end
    end
    return ""
end

local function prepareRowList(dungeon)
    local row = {}
    local player = dungeon.player
    local name = dungeon.name
    local level = dungeon.keydata.level
    local result = dungeon.keyresult.name
    local resultColor = getResultColor(dungeon)
    local deaths = dungeon.totalDeaths or 0
    local time = getDungeonTime(dungeon, resultColor)
    local date = dungeon.date.date
    local dps = getPlayerDpsString(dungeon)
    local affixes = KeyCount.util.concatTable(dungeon.keydata.affixes, ", ")
    local class, role = getClassAndRoleFromDungeon(dungeon)
    local p = getPlayerRoleAndColor(class, role)
    local playerString = p.roleIcon .. player
    --@debug@
    KeyCount.util.printTableOnSameLine(dungeon, "prepareRowList")
    --@end-debug@
    table.insert(row, { value = playerString, color = p.color })
    table.insert(row, { value = name })
    table.insert(row, { value = level, color = getLevelColor(level).color })
    table.insert(row, { value = result, color = rgb(resultColor.rgb) })
    table.insert(row, { value = deaths, color = getDeathsColor(deaths) })
    table.insert(row, { value = time })
    table.insert(row, { value = dps })
    table.insert(row, { value = date })
    table.insert(row, { value = affixes })
    return { cols = row }
end

local function prepareRowRate(dungeon)
    local row = {}
    local name = dungeon.name
    local attempts = dungeon.totalEntries
    local rate = dungeon.successRate
    local rateString = string.format("%.2f%%", rate)
    local intime = dungeon.intime
    local outtime = dungeon.outtime
    local abandoned = dungeon.abandoned
    local best = dungeon.best
    local median = dungeon.median
    local dps = formatDps(dungeon.maxdps)
    --@debug@
    KeyCount.util.printTableOnSameLine(dungeon, "prepareRowRate")
    --@end-debug@
    table.insert(row, { value = name })
    table.insert(row, { value = attempts })
    table.insert(row, { value = rateString, color = getSuccessRateColor(rate) })
    table.insert(row, { value = intime })
    table.insert(row, { value = outtime })
    table.insert(row, { value = abandoned })
    table.insert(row, { value = best, color = getLevelColor(best).color })
    table.insert(row, { value = median, color = getLevelColor(median).color })
    table.insert(row, { value = dps })
    return { cols = row }
end

local function prepareRowGrouped(player)
    --@debug@
    Log("Preparing row for " .. player.name)
    --@end-debug@
    local row = {}
    local name = player.name
    local amount = player.totalEntries
    local rate = player.successRate
    local rateString = string.format("%.2f%%", rate)
    local intime = player.intime
    local outtime = player.outtime
    local abandoned = player.abandoned
    local best = player.best
    local median = player.median
    local dps = formatDps(player.maxdps)
    local p = getPlayerRoleAndColor(player.class, player.role)
    local playerString = p.roleIcon .. name
    --@debug@
    KeyCount.util.printTableOnSameLine(player, "prepareRowGrouped")
    --@end-debug@

    table.insert(row, { value = playerString, color = p.color })
    table.insert(row, { value = amount })
    table.insert(row, { value = rateString, color = getSuccessRateColor(rate) })
    table.insert(row, { value = intime })
    table.insert(row, { value = outtime })
    table.insert(row, { value = abandoned })
    table.insert(row, { value = best, color = getLevelColor(best).color })
    table.insert(row, { value = median, color = getLevelColor(median).color })
    table.insert(row, { value = dps })
    return { cols = row }
end

---Helper function that inserts data into a table if data was retrieved without any errors.
---@param success boolean
---@param dataToInsert table|nil Data to insert can be nil if success is false
---@param targetTable table
---@param i number Iteration number (used for message on failed attempt)
---@return table T Updated table
local function insertDataIfNoErrors(success, dataToInsert, targetTable, i)
    i = i or 0
    if success and dataToInsert then
        table.insert(targetTable, dataToInsert)
    else
        if i > 0 then
            printf(
                string.format("Error occurred when trying to show data for dungeon %i. " ..
                    "You can fix this by manually removing data for that dungeon from your SavedVariables file.", i),
                KeyCount.defaults.colors.chatWarning, true)
        end
    end
    return targetTable
end

local function prepareList(dungeons)
    local data = {}
    local i = 0
    for _, dungeon in ipairs(dungeons) do
        i = i + 1
        local noErrors, row = KeyCount.util.safeExec("PrepareRowList", prepareRowList, dungeon)
        data = insertDataIfNoErrors(noErrors, row, data, i)
    end
    return data
end

KeyCount.guipreparedata.list = prepareList
KeyCount.guipreparedata.filter = prepareList

function KeyCount.guipreparedata.rate(dungeons)
    local data = {}
    local i = 0
    for _, dungeon in ipairs(dungeons) do
        i = i + 1
        local noErrors, row = KeyCount.util.safeExec("PrepareRowRate", prepareRowRate, dungeon)
        data = insertDataIfNoErrors(noErrors, row, data, i)
    end
    return data
end

function KeyCount.guipreparedata.grouped(players)
    local data = {}
    local i = 0
    for player, playerdata in ipairs(players) do
        i = i + 1
        local noErrors, row = KeyCount.util.safeExec("PrepareRowGrouped", prepareRowGrouped, playerdata)
        data = insertDataIfNoErrors(noErrors, row, data, i)
    end
    return data
end
