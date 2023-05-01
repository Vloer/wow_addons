function Log(message)
    if DLAPI then
        DLAPI.DebugLog(AddonName, message)
    end
end

function Filter(tbl, key, value)
    if #key == 0 and #value == 0 then return tbl end
    local result = {}
    if key == "name" and #value <= 3 then
        value = Defaults.DungeonNamesShort[value]
    end
    for _, entry in ipairs(tbl) do
        if entry[key] == value then
            table.insert(result, entry)
        end
    end
    return result
end

function ParseMsg(msg)
    if not msg or #msg == 0 then return "", "" end
    local _, _, key, value = string.find(msg, "%s?(%w+)%s?(.*)")
    if #value == 0 then
        value = key
        key = "name"
    end
    return key, value
end

function FormatTimestamp(seconds)
    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds - (minutes * 60)
    return string.format("%02d:%02d", minutes, remainingSeconds)
end

function AreTablesEqual(table1, table2)
    if table1 == nil or table2 == nil then return table1 == table2 end
    return table.concat(table1) == table.concat(table2)
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
    print(string.format("%sKeyCount: %s|r", fmt, msg))
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
