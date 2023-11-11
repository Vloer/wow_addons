--#region REQUIRED GLOBALS/LOCALS
local frames = {}
local fire = function(...) for _, f in ipairs(frames) do f:FireEvent(...) end end
local update = function() for _, f in ipairs(frames) do f:FireUpdate() end end

local Fn = function() end
local Id = function(v) return v end
local Const = function(v) return function(...) return v end end
local Consts = function(...)
    local args = { ... }
    return function(...) return unpack(args) end
end
local Val = function(v) return function(a, ...) if a then return v end end end
local Vals = function(...)
    local args = { ... }
    return function(...) if ... then return unpack(args) end end
end
local Meta = { __index = function(_, k) if k.match and k:match("^[A-Z]") and k:match("[^A-Z_]") then return Fn end end }
local Obj = setmetatable({}, Meta)
GetRealmName = function() return "Tarren Mill" end


CreateFrame = function(frameType, name, parent, template, id)
    parent = parent or UIParent
    local scripts, events, points, textures, lastUpdate, f = {}, {}, {}, {}, 0
    local CreateChild = function() return CreateFrame(nil, nil, f) end
    local GetTexture = function(name)
        return function()
            if not textures[name] then textures[name] = CreateChild() end
            return textures[name]
        end
    end

    ---@class Frame
    f = setmetatable({
        SetScript = function(_, k, v) scripts[k] = v end,
        GetScript = function(_, k) return scripts[k] end,
        HasScript = function(_, k) return not not scripts[k] end,
        RegisterEvent = function(_, k) events[k] = true end,
        UnregisterEvent = function(_, k) events[k] = nil end,
        UnregisterAllEvents = function() wipe(events) end,
        SetParent = function(v) parent = v end,
        GetParent = function() return parent end,
        SetPoint = function(_, ...)
            local n, point, rel, relPoint, x, y = select("#", ...), ...
            if n == 1 then rel, relPoint, x, y = parent, point, 0, 0 end
            if n == 3 and type(rel) == "table" then x, y = 0, 0 end
            if n == 3 and type(rel) == "number" then x, y, rel, relPoint = rel, relPoint, parent, point end
            table.insert(points, { point, rel, relPoint, x, y })
        end,
        GetPoint = function(_, k) return unpack(points[k]) end,
        GetNumPoints = function() return #points end,
        ClearAllPoints = function() wipe(points) end,
        NumLines = Const(0),
        CreateTexture = CreateChild,
        CreateFontString = CreateChild,
        GetNormalTexture = GetTexture("Normal"),
        GetPushedTexture = GetTexture("Pushed"),
        GetHighlightTexture = GetTexture("Highlight"),
        FireEvent = function(_, e, ...) if scripts.OnEvent and events[e] then scripts.OnEvent(f, e, ...) end end,
        FireUpdate = function()
            if scripts.OnUpdate then
                scripts.OnUpdate(f, os.clock() - lastUpdate)
                lastUpdate = os.clock()
            end
        end
    }, Meta)
    table.insert(frames, f)
    if name then _G[name] = f end
    return f
end

require("KeyCount_dev")
require("FormatDataStorage")
require("Util")
require("Defaults")
require("tests.test_data.test_dungeons")
require("tests.test_data.test_playerdata")
require("luaunit")
--#endregion

--#region TEST FUNCTIONS
local function printTableOnSameLine(table, name)
    local output = ""
    name = name or ""
    for key, value in pairs(table) do
        if type(value) == "table" then
            output = output .. key .. ": " .. type(value) .. ", "
        else
            output = output .. key .. ": " .. tostring(value) .. ", "
        end
    end
    output = output:sub(1, -3)
    print(string.format("%s: %s", name, output))
end

local function printTableRecursive(table, indent)
    indent = indent or '   '
    if type(table) == "table" then
        for key, value in pairs(table) do
            if type(value) == "table" then
                print(indent .. key .. " (table) =>")
                printTableRecursive(value, indent .. "  ")
            else
                print(indent .. key .. " => " .. tostring(value))
            end
        end
    else
        print(indent .. tostring(table))
    end
end

--- deeply compare two objects
local function deep_equals(o1, o2, ignore_mt)
    -- same object
    if o1 == o2 then return true end

    local o1Type = type(o1)
    local o2Type = type(o2)
    --- different type
    if o1Type ~= o2Type then return false end
    --- same type but not table, already compared above
    if o1Type ~= 'table' then return false end

    -- use metatable method
    if not ignore_mt then
        local mt1 = getmetatable(o1)
        if mt1 and mt1.__eq then
            --compare using built in method
            return o1 == o2
        end
    end

    -- iterate over o1
    for key1, value1 in pairs(o1) do
        local ignored = false
        for _, _ignore in ipairs({ 'version', 'uuid' }) do
            if _ignore == key1 then ignored = true end
        end
        if not ignored then
            local value2 = o2[key1]
            if value2 == nil or deep_equals(value1, value2, ignore_mt) == false then
                print('Not equal on ' .. tostring(key1) .. ': ' .. tostring(value1) .. ', ' .. tostring(value2))
                return false
            end
        end
    end

    --- check keys in o2 but missing from o1
    for key2, _ in pairs(o2) do
        if o1[key2] == nil then return false end
    end
    return true
end

local function cmp(d1, d2, txt)
    local _txt = txt or "SUCCESS"
    local res = deep_equals(d1, d2)
    if not res then
        print('---ACTUAL---')
        printTableRecursive(d1, " ")
        print('---EXPECTED---')
        printTableRecursive(d2, " ")
    else
        print('    => ' .. _txt)
    end
end

--#endregion
local DATA_PLAYER_VERSION1 = {}
local DATA_PLAYER_VERSION2 = {}

--#region TEST KeyCount:InitSelf
print('Starting tests')
local enable = false
--#endregion

--#region TEST KeyCount:InitDatabase
--#endregion

--#region TEST KeyCount:InitPlayerList
--#endregion

--#region TEST KeyCount.formatdata.formatdungeon
--#endregion

--#region TEST KeyCount.formatdata.formatplayers
--#endregion

--#region TEST KeyCount:SetKeyStart()
--#endregion

--#region TEST KeyCount:SetKeyFailed()
--#endregion

-- TEST DUNGEON START

-- TEST DUNGEON EARLY END

-- TEST DUNGEON END

-- --#region TEST REFORMAT DATA FROM VERISON 1 TO 2
-- print('TEST REFORMAT DATA FROM VERISON 1 TO 2')
-- local dungeon_1_2 = KeyCount.formatdata.formatdungeon(DATA_DUNGEON_VERSION1, 2)
-- cmp(dungeon_1_2, DATA_DUNGEON_VERSION2)
-- --#endregion

-- --#region TEST REFORMAT DATA FROM VERISON 2 TO 3
-- print('TEST REFORMAT DATA FROM VERISON 2 TO 3')
-- local dungeon_2_3 = KeyCount.formatdata.formatdungeon(DATA_DUNGEON_VERSION2, 3)
-- cmp(dungeon_2_3, DATA_DUNGEON_VERSION3)
-- --#endregion

-- --#region TEST REFORMAT DATA FROM VERISON 1 TO 3
-- print('TEST REFORMAT DATA FROM VERISON 1 TO 3')
-- local dungeon_1_3 = KeyCount.formatdata.formatdungeon(DATA_DUNGEON_VERSION1, 3)
-- cmp(dungeon_1_3, DATA_DUNGEON_VERSION3)
-- --#endregion

--#region TEST WRONG DATA FORMAT ON ADDON LOAD
if enable then
    print('TEST INIT DATABASE FORMATTING')
    KeyCountDB = {}
    KeyCountDB['dungeons'] = {}
    -- correct format
    table.insert(KeyCountDB['dungeons'], DATA_DUNGEON_VERSION3)
    KeyCount:InitDatabase()
    cmp(KeyCountDB['dungeons'][1], DATA_DUNGEON_VERSION3, 'SUCCESS: 1D NO FORMAT')
    table.insert(KeyCountDB['dungeons'], DATA_DUNGEON_VERSION2)
    KeyCount:InitDatabase()
    cmp(KeyCountDB['dungeons'][2], DATA_DUNGEON_VERSION3, 'SUCCESS: 2D 1x FORMAT')
    table.insert(KeyCountDB['dungeons'], DATA_DUNGEON_VERSION1)
    KeyCount:InitDatabase()
    cmp(KeyCountDB['dungeons'][3], DATA_DUNGEON_VERSION3, 'SUCCESS: 3D 1x FORMAT')
    table.insert(KeyCountDB['dungeons'], DATA_DUNGEON_WRONG)
    KeyCount:InitDatabase()
    local len = #KeyCountDB['dungeons']
    print('This should be 3: ' .. len)
    if len ~= 3 then
        printTableRecursive(KeyCountDB['dungeons'][len], ' ')
    end
    table.insert(KeyCountDB['dungeons'], DATA_DUNGEON_VERSION3)
    KeyCount:InitDatabase()
    cmp(KeyCountDB['dungeons'][4], DATA_DUNGEON_VERSION3, 'SUCCESS: 4D 0x FORMAT')
    KeyCountDB = {}
    KeyCountDB["dungeons"] = {}
    print(#KeyCountDB['dungeons'])
    table.insert(KeyCountDB['dungeons'], DATA_DUNGEON_WRONG)
    table.insert(KeyCountDB['dungeons'], DATA_DUNGEON_WRONG)
    table.insert(KeyCountDB['dungeons'], DATA_DUNGEON_WRONG)
    KeyCount:InitDatabase()
    local len = #KeyCountDB['dungeons']
    print('This should be 3: ' .. len)
end
--#endregion

--#region TEST get all playerdata
print('TEST PLAYERDATA SEASONS=2 ROLES=2')
local playerdata = TWO_SEASONS_TWO_ROLES
local dungeonsAll = {}
local seasondata = {}
local roledata = {}
local combinedData = {}
print('Settings: seasons=all, roles=all')
local season = 'Dragonflight-2'
local role = 'all'
if season == "all" then
    for _, v in pairs(playerdata) do
        table.insert(seasondata, v)
    end
else
    table.insert(seasondata, playerdata[season])
end
-- printTableRecursive(seasondata)
if seasondata and next(seasondata) ~= nil then
    print('Getting role data')
    local i = 0
    for _, seasonEntry in ipairs(seasondata) do
        i = i + 1
        print('Getting season entry ' .. i)
        if role == "all" then
            for currentRole, roleEntry in pairs(seasonEntry) do
                if not roledata[currentRole] then
                    roledata[currentRole] = {}
                end
                table.insert(roledata[currentRole], roleEntry)
            end
        else
            if not roledata[role] then
                roledata[role] = {}
            end
            table.insert(roledata[role], seasonEntry[role])
        end
    end
end
-- printTableRecursive(roledata)
-- By this point we have a table of roles where each role contains a list of stats per season:
-- {DAMAGER: {season1, season2, ...}, HEALER: {season1, season2, ...}}
if roledata and next(roledata) ~= nil then
    print('Combining stats')
    for roleName, roleData in pairs(roledata) do
        local totalEntries = 0
        local intime = 0
        local outtime = 0
        local abandoned = 0
        local maxdps = 0
        local maxhps = 0
        local best = 0
        local median = {}
        local dungeonsForRole = {}
        local dungeon_ids_seen = {} -- Make sure not to store duplicates (shouldn't be possible)
        for _, seasonEntry in ipairs(roleData) do
            totalEntries = totalEntries + seasonEntry["totalEntries"]
            intime = intime + seasonEntry["intime"]
            outtime = outtime + seasonEntry["outtime"]
            abandoned = abandoned + seasonEntry["abandoned"]
            maxdps = KeyCount.util.getMax(maxdps, seasonEntry["maxdps"])
            maxhps = KeyCount.util.getMax(maxhps, seasonEntry["maxhps"])
            best = KeyCount.util.getMax(best, seasonEntry["best"])
            for _, dung in ipairs(seasonEntry["dungeons"]) do
                local uuid = dung["uuid"]
                if not KeyCount.util.listContainsItem(uuid, dungeon_ids_seen) then
                    table.insert(dungeon_ids_seen, uuid)
                    table.insert(dungeonsForRole, dung)
                    table.insert(dungeonsAll, dung)
                    table.insert(median, dung["level"])
                end
            end
        end
        local _median = KeyCount.util.calculateMedian(median)
        combinedData[roleName] = {
            totalEntries = totalEntries,
            intime = intime,
            outtime = outtime,
            abandoned = abandoned,
            maxdps = maxdps,
            maxhps = maxhps,
            best = best,
            median = _median,
            dungeons = dungeonsForRole,
        }
    end
    printTableRecursive(combinedData)
end
--#endregion
