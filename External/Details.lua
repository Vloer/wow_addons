local d = {}

d.ignoreDungeonAbilities = {
    "Soul Thorns",
    "Sanguine Ichor",
    "Neltharus Weapons",
    "Rose of the Vale",
    "Anti-Magic Bomb",
    "Wand of Negation"
}

function d:setDetailsAttribute()
    if self.details then return end
    local details = _G.Details
    if not details then
        Log("Details addon could not be found!")
        return false
    end
    self.details = details
end

function d:setCombatAttribute(segment)
    self:setDetailsAttribute()
    if self.details then
        segment = segment or -1
        self.combat = self.details:GetCombat(segment)
    end
end

function d:getPerSecond(attribute, player)
    if not self.combat then self:getCombat() end
    local actor = self.combat:GetActor(attribute, player)
    local total = actor.total
    local ps = total / self.combat:GetCombatTime()
    return ps
end

function d:getTotal(attribute, player)
    if not self.combat then self:getCombat() end
    local actor = self.combat:GetActor(attribute, player)
    return actor.total
end

function d:getDamage(player)
    return {
        total = self:getTotal(DETAILS_ATTRIBUTE_DAMAGE, player),
        dps = self:getPerSecond(DETAILS_ATTRIBUTE_DAMAGE, player)
    }
end

function d:getHealing(player)
    return {
        total = self:getTotal(DETAILS_ATTRIBUTE_HEAL, player),
        hps = self:getPerSecond(DETAILS_ATTRIBUTE_HEAL, player)
    }
end

function d:getAll()
    self:setCombatAttribute()
    if not self.combat then return nil end
    local party = {}
    local containerHeal = self.combat:GetContainer(DETAILS_ATTRIBUTE_HEAL)
    local containerDamage = self.combat:GetContainer(DETAILS_ATTRIBUTE_DAMAGE)
    for _, actor in containerHeal:ListActors() do
        if actor:IsPlayer() then
            local total = actor.total
            local hps = total / self.combat:GetCombatTime()
            local name = actor:name()
            party[name] = party[name] or {}
            party[name].healing = { total = total, hps = hps }
        end
    end
    for _, actor in containerDamage:ListActors() do
        if actor:IsPlayer() then
            local total = actor.total
            local dps = total / self.combat:GetCombatTime()
            local name = actor:name()
            party[name] = party[name] or {}
            party[name].damage = { total = total, dps = dps }
        end
    end
    return party
end

function d:resetCombat()
    if self.combat then
        self.combat = nil
        Log("Details combat data has been reset")
    end
end

KeyCount.details = d
