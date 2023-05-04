--globals
AddonName = "KeyCount_dev"
KeyCount = CreateFrame("Frame", "KeyCount")


-- Event behaviour
function KeyCount:OnEvent(event, ...)
    self[event](self, event, ...)
end

function KeyCount:PLAYER_LOGOUT(event)
    -- Update current table in DB if it is not set to the default values
    KeyCount:SaveDungeons()
    if self.keystoneActive then KeyCountDB.keystoneActive = true else KeyCountDB.keystoneActive = false end
    if self.current and not table.equal(self.current, Defaults.dungeonDefault) then
        table.copy(KeyCountDB.current, self.current)
    end
end

function KeyCount:ADDON_LOADED(event, addonName)
    if addonName == AddonName then
        KeyCountDB.sessions = (KeyCountDB.sessions or 0) + 1
        print(string.format("Loaded %s for the %dth time.", addonName, KeyCountDB.sessions))
        KeyCount:InitSelf()
    end
end

function KeyCount:ZONE_CHANGED_NEW_AREA(event)
    local mapID = C_Map.GetBestMapForUnit("player")
    self.mapInfo = C_Map.GetMapInfo(mapID)
    KeyCount:CheckIfInDungeon()
end

function KeyCount:CHALLENGE_MODE_START(event, mapID)
    if self.keystoneActive then return end -- allow player to re-enter
    self.keystoneActive = true
    KeyCount:SetKeyStart()
end

function KeyCount:CHALLENGE_MODE_COMPLETED(event)
    KeyCount:SetKeyEnd()
end

function KeyCount:GROUP_LEFT(event)
    if not self.keystoneActive then return end
    if KeyCount:CheckIfKeyFailed() then
        KeyCount:SetKeyFailed()
    end
end

function KeyCount:GROUP_ROSTER_UPDATE(event)
    if not self.keystoneActive then return end
    if KeyCount:CheckIfKeyFailed() then
        KeyCount:SetKeyFailed()
    end
end

function KeyCount:COMBAT_LOG_EVENT_UNFILTERED()
    local timestamp, event, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, destGUID, destName =
        CombatLogGetCurrentEventInfo()
    if event == "UNIT_DIED" and UnitInParty(destName) then
        if AuraUtil.FindAuraByName("Feign Death", destName) then return end
        self.current.deaths[destName] = (self.current.deaths[destName] or 0) + 1
        printf(string.format("%s died!", destName), Defaults.colors.chatError)
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
    local keystoneStillRunning = C_ChallengeMode.IsChallengeModeActive()
    if self.keystoneActive then
        if not keystoneStillRunning then
            -- Likely reset instance without ending key
            KeyCount:FinishDungeon()
            return
        else
            Log("Keystone still active!")
            return
        end
    end
    if KeyCountDB.current ~= {} and not table.equal(self.current, Defaults.dungeonDefault) then
        printf("Dungeon state restored")
        table.copy(self.current, KeyCountDB.current)
    else
        Log("Dungeon state set to default values")
        self.current = table.copy({}, Defaults.dungeonDefault)
    end
    Log("Finished InitDungeon")
end

function KeyCount:SetKeyStart()
    Log("Called SetKeyStart")
    KeyCount:AddDungeonEvents()
    local activeKeystoneLevel, activeAffixIDs = C_ChallengeMode.GetActiveKeystoneInfo()
    local challengeMapID = C_ChallengeMode.GetActiveChallengeMapID()
    local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(challengeMapID)
    Log(string.format("Started %s on level %d.", name, activeKeystoneLevel))
    printf(string.format("Started recording for %s %d.", name, activeKeystoneLevel))
    self.current.keyDetails.level = activeKeystoneLevel
    self.current.startedTimestamp = time()
    self.current.party = GetPartyMemberInfo()
    self.current.keyDetails.affixes = {}
    self.current.timeLimit = timeLimit
    self.current.name = name
    if self.current.player == "" then self.current.player = UnitName("player") end
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
    self.current.totalDeaths = SumTbl(self.current.deaths) or 0
    KeyCount:FinishDungeon()
    Log("Finished SetKeyFailed")
end

function KeyCount:SetKeyEnd()
    Log("Called SetKeyEnd")
    local mapChallengeModeID, level, finalTime, onTime, keystoneUpgradeLevels, practiceRun,
    oldOverallDungeonScore, newOverallDungeonScore, IsMapRecord, IsAffixRecord,
    PrimaryAffix, isEligibleForScore, members = C_ChallengeMode.GetCompletionInfo()
    self.keystoneActive = false
    local totalTime = math.floor(finalTime / 1000 + 0.5)
    self.current.completed = true
    self.current.completedTimestamp = time()
    self.current.completedInTime = onTime
    self.current.time = totalTime
    self.current.totalDeaths = SumTbl(self.current.deaths) or 0
    if self.current.timeLimit == 0 then
        _, _, self.current.timeLimit = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID)
    end
    KeyCount:FinishDungeon()
    Log("Finished SetKeyEnd")
end

function KeyCount:SaveAndReset()
    Log("Called SaveAndReset")
    local cur = table.copy({}, self.current)            --Required to pass by value instead of reference
    local def = table.copy({}, Defaults.dungeonDefault) --Required to pass by value instead of reference
    table.insert(self.dungeons, cur)
    table.copy(self.current, def)
    KeyCountDB.current = {}
    Log("Finished SaveAndReset")
end

function KeyCount:FinishDungeon()
    Log("Called FinishDungeon")
    self.keystoneActive = false
    KeyCountDB.keystoneActive = false
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
    KeyCount:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
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
    PreviousRunsDB = PreviousRunsDB or {}
    if KeyCountDB.keystoneActive then self.keystoneActive = true else self.keystoneActive = false end
    if not table.equal(KeyCountDB.current, Defaults.dungeonDefault) and self.keystoneActive then
        Log("Setting current dungeon to value from DB")
        table.copy(self.current, KeyCountDB.current)
    end
    Log("Finished InitSelf")
end

function KeyCount:SetTimeToComplete()
    self.current.date = date(Defaults.dateFormat)
    if self.current.time == 0 then
        local timeStart = self.current.startedTimestamp
        local timeEnd = self.current.completedTimestamp
        if timeEnd == 0 then
            timeEnd = time()
        end
        local timeLost = select(2, C_ChallengeMode.GetDeathCount())
        if self.current.totalDeaths > 0 and timeLost == 0 then
            timeLost = self.current.totalDeaths * 5
        end
        self.current.time = timeEnd - timeStart + timeLost
    end
    self.current.timeToComplete = FormatTimestamp(self.current.time)
end

function ListDungeons(dungeons)
    for i, dungeon in ipairs(dungeons) do
        if dungeon.completedInTime then
            printf(string.format("[%s] %d: Timed %s %d (%d deaths)", dungeon.player, i, dungeon.name,
                dungeon.keyDetails.level, dungeon.totalDeaths), Defaults.colors.rating[5])
        elseif dungeon.completed then
            printf(string.format("[%s] %d: Failed to time %s %d (%d deaths)", dungeon.player, i, dungeon.name,
                dungeon.keyDetails.level, dungeon.totalDeaths), Defaults.colors.rating[3])
        else
            printf(string.format("[%s] %d: Abandoned %s %d (%d deaths)", dungeon.player, i, dungeon.name,
                dungeon.keyDetails.level, dungeon.totalDeaths), Defaults.colors.rating[1])
        end
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
        local colorIdx = math.floor(d.successRate / 20) + 1
        local fmt = Defaults.colors.rating[colorIdx]
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
        printf("No dungeons stored.", Defaults.colors.chatError)
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
