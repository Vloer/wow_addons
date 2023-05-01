--globals
AddonName = "KeyCount_dev"
KeyCount = CreateFrame("Frame", "KeyCount")
KeystoneCurrentlyRunning = false


-- Event behaviour
function KeyCount:OnEvent(event, ...)
    Log(event)
    self[event](self, event, ...)
end

function KeyCount:PLAYER_LOGOUT(event)
    -- Update current table in DB if it is not set to the default values
    KeyCount:SaveDungeons()
    if self.current and not AreTablesEqual(self.current, Defaults.dungeonDefault) then
        table.copy(KeyCountDB.current, self.current)
    end
end

function KeyCount:ADDON_LOADED(event, addonName)
    if addonName == AddonName then
        KeyCount:InitSelf()
        KeyCountDB.sessions = (KeyCountDB.sessions or 0) + 1
        print(string.format("Loaded %s for the %dth time.", addonName, KeyCountDB.sessions))
    end
end

function KeyCount:ZONE_CHANGED_NEW_AREA(event)
    local mapID = C_Map.GetBestMapForUnit("player")
    self.mapInfo = C_Map.GetMapInfo(mapID)
    KeyCount:CheckIfInDungeon()
end

function KeyCount:CHALLENGE_MODE_START(event, mapID)
    if KeystoneCurrentlyRunning then return end -- allow player to re-enter
    KeystoneCurrentlyRunning = true
    KeyCount:SetKeyStart()
end

function KeyCount:CHALLENGE_MODE_COMPLETED(event)
    KeyCount:SetKeyEnd()
end

function KeyCount:GROUP_LEFT(event)
    if not KeystoneCurrentlyRunning then return end
    if KeyCount:CheckIfKeyFailed() then
        KeyCount:SetKeyFailed()
    end
end

function KeyCount:GROUP_ROSTER_UPDATE(event)
    if not KeystoneCurrentlyRunning then return end
    if KeyCount:CheckIfKeyFailed() then
        KeyCount:SetKeyFailed()
    end
end

function KeyCount:COMBAT_LOG_EVENT_UNFILTERED()
    if not UnitInParty(destName) then return end
    local timestamp, event, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, destGUID, destName =  CombatLogGetCurrentEventInfo()
    if event == "UNIT_DIED" then
        if AuraUtil.FindAuraByName("Feign Death", destName) then return end
        self.current.deaths[destName] = (self.current.deaths[destName] or 0) + 1
    end
end

-- Key related functions
function KeyCount:CheckIfInDungeon()
    Log("Called CheckIfInDungeon")
    -- For some reason dalaran has maptype dungeon
    if self.mapInfo and self.mapInfo.mapType == Enum.UIMapType.Dungeon and self.mapInfo.name ~= "Dalaran" then
        Log("Entered dungeon: " .. self.mapInfo.name)
        KeyCount:InitDungeon()
    else
        Log("Finished CheckIfInDungeon")
    end
end

function KeyCount:InitDungeon()
    Log("Called InitDungeon")
    if KeystoneCurrentlyRunning then return end
    if KeyCountDB.current ~= {} and not AreTablesEqual(self.current, Defaults.dungeonDefault) then
        Log("Current dungeon copied from db")
        table.copy(self.current, KeyCountDB.current)
    else
        Log("Current dungeon set to default")
        self.current = table.copy({}, Defaults.dungeonDefault)
    end
    Log("Finished InitDungeon")
end

function KeyCount:SetKeyStart()
    Log("Called SetKeyStart")
    KeyCount:AddDungeonEvents()
    local activeKeystoneLevel, activeAffixIDs, wasActiveKeystoneCharged = C_ChallengeMode.GetActiveKeystoneInfo()
    local challengeMapID = C_ChallengeMode.GetActiveChallengeMapID()
    local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(challengeMapID)
    Log(string.format("Started %s on level %d.", name, activeKeystoneLevel))
    printf(string.format("KeyCount: Started recording for %s %d.", name, activeKeystoneLevel))
    self.current.keyDetails.level = activeKeystoneLevel
    self.current.startedTimestamp = time()
    self.current.party = GetPartyMemberInfo()
    self.current.keyDetails.affixes = {}
    self.current.usedOwnKey = wasActiveKeystoneCharged
    self.current.timeLimit = timeLimit
    self.current.name = name
    for _, affixID in ipairs(activeAffixIDs) do
        local affixName = C_ChallengeMode.GetAffixInfo(affixID)
        table.insert(self.current.keyDetails.affixes, affixName)
    end
    Log("Finished SetKeyStart")
end

function KeyCount:CheckIfKeyFailed(party)
    Log("Called CheckIfKeyFailed")
    if party == nil then party = GetPartyMemberInfo() end
    if #party < 5 then
        Log("Key failed!")
        return true
    end
    Log("Key not failed!")
end

function KeyCount:SetKeyFailed()
    Log("Called SetKeyFailed")
    self.current.completedTimestamp = time()
    self.current.completed = false
    self.current.completedInTime = false
    self.current.total_deaths = SumTbl(self.current.deaths) or 0
    KeyCount:FinishDungeon()
    Log("Finished SetKeyFailed")
end

function KeyCount:SetKeyEnd()
    Log("Called SetKeyEnd")
    local mapChallengeModeID, level, finalTime, onTime, keystoneUpgradeLevels, practiceRun,
    oldOverallDungeonScore, newOverallDungeonScore, IsMapRecord, IsAffixRecord,
    PrimaryAffix, isEligibleForScore, members = C_ChallengeMode.GetCompletionInfo()
    KeystoneCurrentlyRunning = false
    local totalTime = math.floor(finalTime / 1000 + 0.5)
    self.current.completed = true
    self.current.completedTimestamp = time()
    self.current.completedInTime = onTime
    self.current.time = totalTime
    self.current.total_deaths = SumTbl(self.current.deaths) or 0
    if self.current.timeLimit == 0 then
        _, _, self.current.timeLimit = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID)
    end
    KeyCount:FinishDungeon()
    Log("Finished SetKeyEnd")
end

function KeyCount:SaveAndReset()
    Log("Called SaveAndReset")
    local cur = table.copy({}, self.current) --Required to pass by value instead of reference
    local def = table.copy({}, Defaults.dungeonDefault) --Required to pass by value instead of reference
    table.insert(self.dungeons, cur)
    table.copy(self.current, def)
    KeyCountDB.current = {}
    Log("Finished SaveAndReset")
end

function KeyCount:FinishDungeon()
    Log("Called FinishDungeon")
    KeyCount:SetTimeToComplete()
    Log(string.format("Key %s %s %s", self.current.name, self.current.keyDetails.level, self.current.timeToComplete))
    KeyCount:SaveAndReset()
    KeyCount:RemoveDungeonEvents()
    Log("Finished FinishDungeon")
end

-- Game related functions
function GetPartyMemberInfo(printOutput)
    printOutput = printOutput or false
    local partyMemberInfo = {}
    local numGroupMembers = GetNumGroupMembers()
    if numGroupMembers == 0 then
        partyMemberInfo[1] = GetPlayerInfo()
    else
        for i = 1, numGroupMembers do
            local name, _, _, _, class, _, _, _, _, _, _, role = GetRaidRosterInfo(i)
            partyMemberInfo[i] = { name = name, class = class, role = role }
        end
    end
    if printOutput then
        Log("Party:")
        for i, item in ipairs(partyMemberInfo) do
            Log("    " .. item.name .. ": " .. item.class .. " " .. item.role)
        end
    end
    return partyMemberInfo
end

function GetPlayerInfo()
    local specIndex = GetSpecialization()
    local _, _, _, _, specRole = GetSpecializationInfo(specIndex)
    local name = UnitName("player")
    local class = UnitClass("player")
    return { name = name, class = class, role = specRole }
end

function ShowPastDungeons(addToDB)
    PreviousRunsDB = PreviousRunsDB or {}
    addToDB = addToDB or false
    local runs = C_MythicPlus.GetRunHistory(true, true) -- This only captures finished dungeons
    local previousDungeons = {}
    for i, run in ipairs(runs) do
        local map = C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID)
        local level = run.level
        local completed = run.completed
        Log(string.format("%d: %s level %s %s", i, map, level, tostring(completed)))
        local dungeon = Defaults.dungeonDefault
        dungeon.name = map
        dungeon.completedInTime = completed
        dungeon.keyDetails.level = level
        dungeon.completed = completed
        table.insert(previousDungeons, dungeon)
    end

    if addToDB then
        table.move(previousDungeons, 1, #previousDungeons, #KeyCountDB + 1, KeyCountDB)
    end
end

-- Register events
function KeyCount:AddDungeonEvents()
    KeyCount:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    KeyCount:RegisterEvent("GROUP_ROSTER_UPDATE")
    KeyCount:RegisterEvent("GROUP_LEFT")
    KeyCount:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function KeyCount:RemoveDungeonEvents()
    KeyCount:UnregisterEvent("CHALLENGE_MODE_COMPLETED")
    KeyCount:UnregisterEvent("GROUP_ROSTER_UPDATE")
    KeyCount:UnregisterEvent("GROUP_LEFT")
end

KeyCount:RegisterEvent("PLAYER_LOGOUT")
KeyCount:RegisterEvent("ADDON_LOADED")
KeyCount:RegisterEvent("ZONE_CHANGED_NEW_AREA")
KeyCount:RegisterEvent("CHALLENGE_MODE_START")
KeyCount:SetScript("OnEvent", KeyCount.OnEvent)

-- Utils
function KeyCount:InitSelf()
    Log("Called InitSelf")
    self.party = self.party or {}
    self.current = self.current or table.copy({}, Defaults.dungeonDefault)
    self.dungeons = self.dungeons or {}
    KeyCountDB = KeyCountDB or {}
    KeyCountDB.current = KeyCountDB.current or {}
    KeyCountDB.dungeons = KeyCountDB.dungeons or {}
    self.current.player = UnitName("player")
    PreviousRunsDB = PreviousRunsDB or {}
    if next(KeyCountDB.current) ~= nil and not AreTablesEqual(self.current, Defaults.dungeonDefault) then
        Log("Setting current dungeon to value from DB")
        table.copy(self.current, KeyCountDB.current)
    end
    Log("Finished InitSelf")
end

function KeyCount:SetTimeToComplete(timeStart, timeEnd)
    self.current.date = date(Defaults.dateFormat)
    if self.current.time == 0 then
        timeStart = timeStart or self.current.startedTimestamp or 0
        timeEnd = timeEnd or self.current.completedTimestamp or 0
        local timeLost = select(2, C_ChallengeMode.GetDeathCount()) or self.current.total_deaths * 5
        self.current.time = timeEnd - timeStart + timeLost
    end
    self.current.timeToComplete = FormatTimestamp(self.current.time)
end

function ListDungeons(dungeons)
    for i, dungeon in ipairs(dungeons) do
        local result = "Failed"
        if dungeon.completedInTime then
            result = "Timed"
        end
        printf(string.format("[%s] %d: %s %s %d (%d deaths)", dungeon.player, i, result, dungeon.name,
            dungeon.keyDetails.level, dungeon.total_deaths))
    end
end

function GetDungeonSuccessRate(dungeons)
    local res = {}
    local resRate = {}
    for _, dungeon in ipairs(dungeons) do
        if not res[dungeon.name] then
            res[dungeon.name] = {}
            res[dungeon.name].success = 0
            res[dungeon.name].failed = 0
        end
        if dungeon.completedInTime then
            res[dungeon.name].success = (res[dungeon.name].success or 0) + 1
        else
            res[dungeon.name].failed = (res[dungeon.name].failed or 0) + 1
        end
    end
    for name, d in pairs(res) do
        local successRate = 0
        if d.failed == 0 then
            successRate = 100
        elseif d.success == 0 then
            successRate = 0
        else
            successRate = d.success / (d.success + d.failed) * 100
        end
        table.insert(resRate, { name = name, successRate = successRate, success = d.success, failed = d.failed })
    end
    table.sort(resRate, function(a, b)
        return a.successRate > b.successRate
    end)
    for _, d in ipairs(resRate) do
        local fmt = Defaults.colors.chatError
        if d.successRate > 66 then
            fmt = Defaults.colors.chatSuccess
        elseif d.successRate > 33 then
            fmt = Defaults.colors.chatWarning
        end
        printf(string.format("%s: %.2f%% [%d/%d]", d.name, d.successRate, d.success, d.success + d.failed), fmt)
    end
end

function GetPLayerList(dungeons)
    dungeons = dungeons or KeyCountDB.dungeons
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

function GetStoredDungeons()
    if not KeyCountDB or next(KeyCountDB) == nil or next(KeyCountDB.dungeons) == nil then
        printf("No dungeons stored.", Defaults.colors.chatWarning)
        return nil
    end
    return KeyCountDB.dungeons
end

function KeyCount:SaveDungeons()
    for _, dungeon in ipairs(self.dungeons) do
        local name = dungeon.name or ""
        local details = dungeon.keyDetails or {}
        local level = details.level or 0
        printf(string.format("Inserting %s %s", name, level))
        table.insert(KeyCountDB.dungeons, dungeon)
    end
    self.dungeons = {}
end