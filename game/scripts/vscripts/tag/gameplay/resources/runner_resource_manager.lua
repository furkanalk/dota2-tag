local Config = require("tag/config/config")
local EnergyState = require(
  "tag/gameplay/resources/energy_state"
)
local MomentumState = require(
  "tag/gameplay/resources/momentum_state"
)

local RunnerResourceManager = class({})

RunnerResourceManager.ENERGY = "ENERGY"
RunnerResourceManager.MOMENTUM = "MOMENTUM"

local function IsValidHero(hero)
  return hero
      and not hero:IsNull()
      and hero:IsRealHero()
end

function RunnerResourceManager:Init(tagManager)
  self.tagManager = tagManager
  self.states = {}
  self.types = {}
  self.heroes = {}
  self.wasCursed = {}
  self.nextImpactEnergyTime = {}
end

function RunnerResourceManager:RegisterHero(hero)
  local playerID = hero:GetPlayerOwnerID()

  if playerID < 0 then
    return nil
  end

  self.heroes[playerID] = hero

  if self.states[playerID] ~= nil then
    return self.states[playerID]
  end

  local heroName = hero:GetUnitName()
  local currentTime = GameRules:GetGameTime()
  local energy = Config.RESOURCES.ENERGY.HERO[heroName]

  if energy ~= nil then
    local state = EnergyState()
    state:Init(energy.MAX, energy.REGEN, currentTime)

    self.states[playerID] = state
    self.types[playerID] = RunnerResourceManager.ENERGY
    self.wasCursed[playerID] = self:IsCursed(playerID)

    print(
      "RESOURCE REGISTERED: Player "
      .. playerID
      .. " | ENERGY "
      .. energy.MAX
      .. " | "
      .. energy.REGEN
      .. "/s"
    )

    return state
  end

  local momentum = Config.RESOURCES.MOMENTUM.HERO[heroName]

  if momentum ~= nil then
    local state = MomentumState()
    state:Init(momentum.MAX, currentTime)
    state:SetLastPosition(hero:GetAbsOrigin())

    self.states[playerID] = state
    self.types[playerID] = RunnerResourceManager.MOMENTUM
    self.wasCursed[playerID] = self:IsCursed(playerID)

    print(
      "RESOURCE REGISTERED: Player "
      .. playerID
      .. " | MOMENTUM 0/"
      .. momentum.MAX
    )

    return state
  end

  print(
    "RESOURCE REGISTERED: Player "
    .. playerID
    .. " | NONE ("
    .. heroName
    .. ")"
  )

  return nil
end

function RunnerResourceManager:GetType(playerID)
  return self.types[playerID]
end

function RunnerResourceManager:GetState(playerID)
  return self.states[playerID]
end

function RunnerResourceManager:GetCurrent(playerID)
  local state = self.states[playerID]
  return state and state:GetCurrent() or nil
end

function RunnerResourceManager:GetMax(playerID)
  local state = self.states[playerID]
  return state and state:GetMax() or nil
end

function RunnerResourceManager:IsCursed(playerID)
  return self.tagManager:GetItPlayerID() == playerID
end

function RunnerResourceManager:AddEnergy(
    playerID,
    amount,
    source
)
  if self.types[playerID] ~= RunnerResourceManager.ENERGY
      or self:IsCursed(playerID)
  then
    return 0
  end

  local state = self.states[playerID]
  local gained = state:Add(amount)

  if gained > 0 then
    print(
      string.format(
        "ENERGY GAIN: Player %d | +%.1f | %.1f/%d | %s",
        playerID,
        gained,
        state:GetCurrent(),
        state:GetMax(),
        tostring(source)
      )
    )
  end

  return gained
end

function RunnerResourceManager:SpendEnergy(
    playerID,
    amount,
    source
)
  if self.types[playerID] ~= RunnerResourceManager.ENERGY
      or self:IsCursed(playerID)
  then
    return false
  end

  local state = self.states[playerID]

  if not state:Spend(amount) then
    return false
  end

  print(
    string.format(
      "ENERGY SPEND: Player %d | -%.1f | %.1f/%d | %s",
      playerID,
      amount,
      state:GetCurrent(),
      state:GetMax(),
      tostring(source)
    )
  )

  return true
end

function RunnerResourceManager:AddMomentum(
    playerID,
    amount,
    source,
    currentTime
)
  if self.types[playerID] ~= RunnerResourceManager.MOMENTUM
      or self:IsCursed(playerID)
  then
    return 0
  end

  local state = self.states[playerID]
  local gained = state:Add(amount)

  if gained <= 0 then
    return 0
  end

  state:SetDecayGraceUntil(
    currentTime + Config.RESOURCES.MOMENTUM.DECAY_GRACE
  )
  state:SetDecayProgress(0)
  state:SetLastUpdateTime(currentTime)

  local hero = self.heroes[playerID]
  if IsValidHero(hero) then
    state:SetLastPosition(hero:GetAbsOrigin())
  end

  print(
    "MOMENTUM GAIN: Player "
    .. playerID
    .. " | +"
    .. gained
    .. " | "
    .. state:GetCurrent()
    .. "/"
    .. state:GetMax()
    .. " | "
    .. tostring(source)
  )

  return gained
end

function RunnerResourceManager:GetMomentumCooldownRecovery(playerID)
  if self.types[playerID] ~= RunnerResourceManager.MOMENTUM then
    return 0
  end

  local state = self.states[playerID]

  return Config.RESOURCES.MOMENTUM.FULL_STACK_COOLDOWN_RECOVERY
      * state:GetCurrent()
      / state:GetMax()
end

function RunnerResourceManager:OnNormalImpact(attacker, currentTime)
  if not IsValidHero(attacker) then
    return 0
  end

  local playerID = attacker:GetPlayerOwnerID()

  if playerID < 0
      or self.types[playerID] ~= RunnerResourceManager.ENERGY
      or self:IsCursed(playerID)
  then
    return 0
  end

  local nextAllowed = self.nextImpactEnergyTime[playerID] or -999

  if currentTime < nextAllowed then
    return 0
  end

  local amount = Config.RESOURCES.ENERGY.MELEE_IMPACT_GAIN

  if attacker:IsRangedAttacker() then
    amount = Config.RESOURCES.ENERGY.RANGED_IMPACT_GAIN
  end

  local gained = self:AddEnergy(
    playerID,
    amount,
    "NORMAL_IMPACT"
  )

  if gained > 0 then
    self.nextImpactEnergyTime[playerID] =
        currentTime + Config.RESOURCES.ENERGY.IMPACT_PROC_LOCKOUT
  end

  return gained
end

function RunnerResourceManager:Update(currentTime)
  for playerID, state in pairs(self.states) do
    local resourceType = self.types[playerID]
    local cursed = self:IsCursed(playerID)
    local wasCursed = self.wasCursed[playerID]

    if cursed ~= wasCursed then
      self:HandleRoleChange(
        playerID,
        state,
        resourceType,
        cursed,
        currentTime
      )
    end

    self.wasCursed[playerID] = cursed

    if resourceType == RunnerResourceManager.ENERGY then
      RunnerResourceManager.UpdateEnergy(
        state,
        currentTime,
        cursed
      )
    else
      self:UpdateMomentum(
        playerID,
        state,
        currentTime,
        cursed
      )
    end
  end
end

function RunnerResourceManager:HandleRoleChange(
    playerID,
    state,
    resourceType,
    cursed,
    currentTime
)
  state:SetLastUpdateTime(currentTime)

  if cursed then
    if resourceType == RunnerResourceManager.MOMENTUM then
      state:Clear()

      print(
        "MOMENTUM CLEARED: Player "
        .. playerID
        .. " | CURSED"
      )
    else
      print(
        string.format(
          "ENERGY FROZEN: Player %d | %.1f/%d",
          playerID,
          state:GetCurrent(),
          state:GetMax()
        )
      )
    end

    return
  end

  if resourceType == RunnerResourceManager.MOMENTUM then
    state:SetDecayProgress(0)
    state:SetDecayGraceUntil(nil)

    local hero = self.heroes[playerID]
    if IsValidHero(hero) then
      state:SetLastPosition(hero:GetAbsOrigin())
    end
  end

  print(
    string.format(
      "RESOURCE RESTORED: Player %d | %s | %.1f/%d",
      playerID,
      resourceType,
      state:GetCurrent(),
      state:GetMax()
    )
  )
end

function RunnerResourceManager.UpdateEnergy(
    state,
    currentTime,
    cursed
)
  local lastUpdateTime = state:GetLastUpdateTime()
  state:SetLastUpdateTime(currentTime)

  if cursed
      or lastUpdateTime == nil
      or state:GetCurrent() >= state:GetMax()
  then
    return
  end

  local deltaTime = math.max(0, currentTime - lastUpdateTime)

  state:Add(
    state:GetRegenPerSecond() * deltaTime
  )
end

function RunnerResourceManager:UpdateMomentum(
    playerID,
    state,
    currentTime,
    cursed
)
  local lastUpdateTime = state:GetLastUpdateTime()
  local hero = self.heroes[playerID]
  local position = nil

  if IsValidHero(hero) then
    position = hero:GetAbsOrigin()
  end

  state:SetLastUpdateTime(currentTime)

  local previousPosition = state:GetLastPosition()
  state:SetLastPosition(position)

  if cursed
      or lastUpdateTime == nil
      or position == nil
      or state:GetCurrent() <= 0
  then
    return
  end

  local graceUntil = state:GetDecayGraceUntil()
  local effectiveStart = lastUpdateTime

  if graceUntil ~= nil then
    if currentTime <= graceUntil then
      return
    end

    effectiveStart = math.max(effectiveStart, graceUntil)
  end

  local deltaTime = math.max(0, currentTime - effectiveStart)

  if deltaTime <= 0 then
    return
  end

  local speed = 0

  if previousPosition ~= nil
      and currentTime > lastUpdateTime
  then
    speed =
        (position - previousPosition):Length2D()
        / (currentTime - lastUpdateTime)
  end

  local moving =
      speed >= Config.RESOURCES.MOMENTUM.MOVING_SPEED_THRESHOLD

  local fullDecay =
      Config.RESOURCES.MOMENTUM.IDLE_FULL_DECAY_DURATION

  if moving then
    fullDecay =
        Config.RESOURCES.MOMENTUM.MOVING_FULL_DECAY_DURATION
  end

  local interval = fullDecay / state:GetMax()
  local progress =
      state:GetDecayProgress() + deltaTime / interval
  local lost = math.floor(progress)

  if lost <= 0 then
    state:SetDecayProgress(progress)
    return
  end

  local previous = state:GetCurrent()
  state:SetCurrent(previous - lost)

  local actualLost = previous - state:GetCurrent()
  progress = progress - actualLost

  if state:GetCurrent() <= 0 then
    progress = 0
  end

  state:SetDecayProgress(progress)

  print(
    "MOMENTUM DECAY: Player "
    .. playerID
    .. " | -"
    .. actualLost
    .. " | "
    .. state:GetCurrent()
    .. "/"
    .. state:GetMax()
    .. " | "
    .. (moving and "MOVING" or "IDLE")
  )
end

return RunnerResourceManager
