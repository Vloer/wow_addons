function Log(message)
    if DLAPI then
        DLAPI.DebugLog(AddonName, message)
    end
end

local filterConditions = {
    ["player"] = function(entry, value)
        return string.lower(entry["player"]) == string.lower(value)
    end,
    ["name"] = function(entry, value)
        return string.lower(entry["name"]) == string.lower(value)
    end,
    ["completed"] = function(entry, value)
        return entry["completed"] == value
    end,
    ["completedInTime"] = function(entry, value)
        print(entry["completedInTime"], value)
        return entry["completedInTime"] == value
    end,
    ["time"] = function(entry, value)
        local res = entry["time"] or 0
        return res >= value
    end,
    ["deathsgt"] = function(entry, value)
        local res = entry["totalDeaths"] or 0
        return res >= value
    end,
    ["deathslt"] = function(entry, value)
        local res = entry["totalDeaths"] or 0
        return res <= value
    end,
    ["level"] = function(entry, value)
        return entry.keyDetails.level >= value
    end,
    ["affix"] = function(entry, value)
        local affixes = string.lower(table.concat(entry.keyDetails.affixes))
        local found = 0
        for i = 2, #value do
            if string.find(affixes, value[i]) then
                if value[1] == "OR" then
                    found = (#value - 1)
                    break
                elseif value[1] == "AND" then
                    found = found + 1
                end
            end
        end
        return found == (#value - 1)
    end
}

function FilterData(tbl, key, value)
    if #key == 0 and #value == 0 then return tbl end
    local result = {}

    -- Argument cleaning
    local _key = string.lower(key)
    if _key == "player" and #value == 0 then
        value = UnitName("player")
        print(string.format("FILTER <%s> <%s>", key, tostring(value)))
    elseif #_key <= 3 and #value == 0 then
        value = Defaults.dungeonNamesShort[key]
        _key = "name"
        print(string.format("FILTER <%s> <%s>", _key, tostring(value)))
    elseif _key == "completed" then
        value = true
        print(string.format("FILTER <%s> <%s>", key, tostring(value)))
    elseif _key == "intime" then
        _key = "completedInTime"
        value = true
        print(string.format("FILTER <%s> <%s>", _key, tostring(value)))
    elseif _key == "time" or _key == "deathsgt" or _key == "deathslt" or _key == "level" then
        value = tonumber(value) or 0
        print(string.format("FILTER <%s> <%s>", key, tostring(value)))
    elseif _key == "affix" and #value ~= 0 then
        local values = {}
        print(string.format("FILTER <%s> <%s>", key, tostring(value)))
        if string.find(value, ',') then
            values[1] = "AND"
        else
            values[1] = "OR"
        end

        for substring in string.gmatch(value, "[^|,]+") do
            table.insert(values, string.lower(substring))
        end
        value = values
    elseif _key == "player" then
        print(string.format("FILTER <%s> <%s>", key, tostring(value)))
    elseif _key == "season" then
        if #value == 0 then value = Defaults.dungeonDefault.season end
        print(string.format("FILTER <%s> <%s>", key, tostring(value)))
    end

    -- Table filtering
    for _, entry in ipairs(tbl) do
        if _key == "season" and entry[_key] ~= nil then
            if string.lower(entry[_key]) == string.lower(value) then
                table.insert(result, entry)
            end
        elseif entry["season"] == Defaults.dungeonDefault.season then
            for conditionKey, conditionFunc in pairs(filterConditions) do
                if _key == conditionKey then
                    if conditionFunc(entry, value) then
                        table.insert(result, entry)
                    end
                end
            end
        end
    end
    return result
end

function ParseMsg(msg)
    if not msg or #msg == 0 then return "", "" end
    local _, _, key, value = string.find(msg, "%s?(%w+)%s?(.*)")
    return key, value
end

function FormatTimestamp(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds - (minutes * 60)
    return string.format("%02d:%02d", minutes, remainingSeconds)
end

table.equal = function(t1, t2)
    for k, v in pairs(t1) do
        if t2[k] ~= v then
            return false
        end
    end

    for k, v in pairs(t2) do
        if t1[k] ~= v then
            return false
        end
    end

    return true
end

table.copy = function(destination, source)
    destination = destination or {}
    for key, value in pairs(source) do
        if type(value) == "table" and type(destination[key]) == "table" and destination[key] ~= {} then
            destination[key] = {}
            table.copy(destination[key], value)
        else
            destination[key] = value
        end
    end
    return destination
end

function printf(msg, fmt)
    fmt = fmt or Defaults.colors.chatAnnounce
    print(string.format("%s%s|r", fmt, msg))
end

function SumTbl(tbl)
    if type(tbl) ~= "table" then return end
    local res = 0
    for k, v in pairs(tbl) do
        if type(v) == "number" then
            res = res + v
        end
    end
    return res
end
