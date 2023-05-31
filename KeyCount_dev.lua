KeyCount = CreateFrame("Frame", "KeyCount")
KeyCount.defaults = {}
KeyCount.exportdata = {}
KeyCount.filterfunctions = {}
KeyCount.filterkeys = {}
KeyCount.guipreparedata = {}
KeyCount.util = {}
KeyCount.utilstats = {}
KeyCount.details = {}
KeyCount.formatdata = {}

-- Event behaviour
function KeyCount:OnEvent(event, ...)
    self[event](self, event, ...)
end

function KeyCount:PLAYER_LOGOUT(event)
    -- Update current table in DB if it is not set to the default values
    KeyCount:SaveDungeons()
    KeyCount:SavePlayers()
    if self.keystoneActive then KeyCountDB.keystoneActive = true else KeyCountDB.keystoneActive = false end
    if self.current and not table.equal(self.current, self.defaults.dungeonDefault) then
        table.copy(KeyCountDB.current, self.current)
    end
end

function KeyCount:ADDON_LOADED(event, addonName)
    if addonName == "KeyCount_dev" then
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
        self.current.party[destName].deaths = (self.current.party[destName].deaths or 0) + 1
        printf(string.format("%s died!", destName), self.defaults.colors.chatError)
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

function KeyCount:InitSelf()
    Log("Called InitSelf")
    self.party = self.party or {}
    self.current = self.current or table.copy({}, self.defaults.dungeonDefault)
    self.dungeons = self.dungeons or {}
    KeyCountDB = KeyCountDB or {}
    KeyCountDB.current = KeyCountDB.current or {}
    KeyCountDB.dungeons = KeyCountDB.dungeons or {}
    KeyCountDB.players = KeyCountDB.players or {}
    PreviousRunsDB = PreviousRunsDB or {}
    if KeyCountDB.keystoneActive then self.keystoneActive = true else self.keystoneActive = false end
    if not table.equal(KeyCountDB.current, self.defaults.dungeonDefault) and self.keystoneActive then
        Log("Setting current dungeon to value from DB")
        table.copy(self.current, KeyCountDB.current)
    end
    Log("Finished InitSelf")
end

function KeyCount:CheckIfInDungeon()
    Log("Called CheckIfInDungeon")
    -- For some reason dalaran has maptype dungeon
    if self.mapInfo and self.mapInfo.mapType == Enum.UIMapType.Dungeon and self.mapInfo.name ~= "Dalaran" and self.mapInfo.name ~= "Aberrus, the Shadowed Crucible" then
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
    if KeyCountDB.current ~= {} and not table.equal(self.current, self.defaults.dungeonDefault) then
        Log("Dungeon state restored from db")
        table.copy(self.current, KeyCountDB.current)
    else
        Log("Dungeon state set to default values")
        self.current = table.copy({}, self.defaults.dungeonDefault)
    end
    Log("Finished InitDungeon")
end

function KeyCount:SetKeyStart()
    Log("Called SetKeyStart")
    KeyCount:AddDungeonEvents()
    local activeKeystoneLevel, activeAffixIDs = C_ChallengeMode.GetActiveKeystoneInfo()
    local challengeMapID = C_ChallengeMode.GetActiveChallengeMapID()
    local name, _, timelimit = C_ChallengeMode.GetMapUIInfo(challengeMapID)
    Log(string.format("Started %s on level %d.", name, activeKeystoneLevel))
    printf(string.format("KeyCount: started recording for %s %d.", name, activeKeystoneLevel))
    self.current.keydata.level = activeKeystoneLevel
    self.current.startedTimestamp = time()
    self.current.party = self:GetPartyMemberInfo()
    self.current.keydata.affixes = {}
    self.current.keydata.timelimit = timelimit
    self.current.name = name
    if self.current.player == "" then self.current.player = UnitName("player") end
    for _, affixID in ipairs(activeAffixIDs) do
        local affixName = C_ChallengeMode.GetAffixInfo(affixID)
        table.insert(self.current.keydata.affixes, affixName)
    end
    Log("Finished SetKeyStart")
end

function KeyCount:CheckIfKeyFailed(party)
    Log("Called CheckIfKeyFailed")
    if party == nil then party = self:GetPartyMemberInfo() end
    local partysize = 0
    for i in pairs(party) do partysize = partysize + 1 end
    if partysize < 5 then
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
    self.current.totalDeaths = self.util.sumTbl(self.current.deaths) or 0
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
    self.current.totalDeaths = self.util.sumTbl(self.current.deaths) or 0
    if self.current.keydata.timelimit == 0 then
        _, _, self.current.keydata.timelimit = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID)
    end
    KeyCount.util.safeExec("SetDetailsData", KeyCount.SetDetailsData, KeyCount)
    KeyCount:FinishDungeon()
    Log("Finished SetKeyEnd")
end

function KeyCount:FinishDungeon()
    Log("Called FinishDungeon")
    self.keystoneActive = false
    KeyCountDB.keystoneActive = false
    KeyCount:SetTimeToComplete()
    Log(string.format("Key %s %s %s", self.current.name, self.current.keydata.level, self.current.timeToComplete))
    KeyCount:SaveAndReset()
    KeyCount:RemoveDungeonEvents()
    Log("Finished FinishDungeon")
end

function KeyCount:SetTimeToComplete()
    self.current.date = {
        date = date(self.defaults.dateFormat),
        datestring = date(),
        datetime = date(self.defaults.datetimeFormat)
    }
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
    self.current.timeToComplete = KeyCount.util.formatTimestamp(self.current.time)
    if self.current.completedInTime then
        local s
        local symbol = self.defaults.dungeonPlusChar
        if self.current.time < (self.current.keydata.timelimit * 0.6) then
            s = symbol .. symbol .. symbol
        elseif self.current.time < (self.current.keydata.timelimit * 0.8) then
            s = symbol .. symbol
        else
            s = symbol
        end
        self.current.stars = s
    end
end

function KeyCount:SaveAndReset()
    Log("Called SaveAndReset")
    local cur = table.copy({}, self.current)                 --Required to pass by value instead of reference
    local def = table.copy({}, self.defaults.dungeonDefault) --Required to pass by value instead of reference
    table.insert(self.dungeons, cur)
    table.copy(self.current, def)
    KeyCountDB.current = {}
    Log("Finished SaveAndReset")
end

function KeyCount:SaveDungeons()
    for _, dungeon in ipairs(self.dungeons) do
        local name = dungeon.name or ""
        local details = dungeon.keydata or {}
        local level = details.level or 0
        printf(string.format("Inserting %s %s", name, level))
        table.insert(KeyCountDB.dungeons, dungeon)
    end
    self.dungeons = {}
end

function KeyCount:SavePlayers()
    local players = KeyCountDB.players or {}
    local dungeons = KeyCount:GetStoredDungeons()
    if not dungeons then return end
    for _, dungeon in ipairs(dungeons) do
        local party = dungeon.party or {}
        for player, playerdata in pairs(party) do
            if not players[player] then
                players[player] = KeyCount.defaults.playerDefault
            end
            players[player].player = player
            players[player].timesgrouped = players[player].timesgrouped + 1
            players[player].damage = playerdata.damage or players[player].damage
            players[player].healing = playerdata.healing or players[player].healing
            local key = KeyCount.defaults.playerkey
            key.name = playerdata.name
            key.level = playerdata.keydata.level
            key.affixes = playerdata.keydata.affixes
        end
    end
end

function KeyCount:GetPartyMemberInfo()
    local info = {}
    local numGroupMembers = GetNumGroupMembers()
    if numGroupMembers == 0 then
        info = self:GetPlayerInfo()
    else
        for i = 1, numGroupMembers do
            local name, _, _, _, class, _, _, _, _, _, _, role = GetRaidRosterInfo(i)
            info[name] = { name = name, class = class, role = role }
        end
    end
    return info
end

function KeyCount:GetPlayerInfo()
    local specIndex = GetSpecialization()
    local _, spec, _, _, specRole = GetSpecializationInfo(specIndex)
    local name = UnitName("player")
    local class = UnitClass("player")
    local info = {}
    info[name] = {
        class = class,
        role = specRole,
        spec = spec,
        name = name
    }
    return info
end

function KeyCount:GetStoredDungeons()
    if not KeyCountDB or next(KeyCountDB) == nil or next(KeyCountDB.dungeons) == nil then
        print(string.format("%sKeyCount: %sNo dungeons stored!%s",
        KeyCount.defaults.colors.chatAnnounce, KeyCount.defaults.colors.chatError, KeyCount.defaults.colors.reset))
        return nil
    end
    local stored = {}
    for i, d in ipairs(KeyCountDB.dungeons) do
        --@debug@
        Log(string.format("Checking data status for dungeon %s: %s %s", i, d.name, d.keydata.level))
        --@end-debug@
        local fixed = KeyCount.util.safeExec("FormatData", KeyCount.formatdata.format, d)
        if fixed then
           table.insert(stored, fixed)
        end
     end
    return stored
end

function KeyCount:SetDetailsData()
    local detailsParty = self.details:getAll()
    if detailsParty then
        for player, data in pairs(detailsParty) do
            local d = data.damage or {}
            local h = data.healing or {}
            local partyplayer = self.current.party[player] or {}
            if next(partyplayer) then
                self.current.party[player].damage = {
                    total = d.total or 0,
                    dps = d.dps or 0
                }
                self.current.party[player].healing = {
                    total = h.total or 0,
                    hps = h.hps or 0
                }
            else
                printf(string.format("Warning: something likely went wrong with the recording of Details data! [%s]", player), self.defaults.colors.chatError)
            end
        end
    end
end