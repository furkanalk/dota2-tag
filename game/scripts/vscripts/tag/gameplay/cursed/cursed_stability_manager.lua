local Config = require("tag/config/config")
local CursedStabilityState = require(
  "tag/gameplay/cursed/cursed_stability_state"
)

local CursedStabilityManager = class({})

local function ValidateConfig()
  local stability = Config.CURSED and Config.CURSED.STABILITY

  assert(type(stability) == "table", "Config.CURSED.STABILITY must exist")

  local requiredNumbers = {
    "MAX",
    "PASSIVE_REGEN_DELAY",
    "PASSIVE_REGEN_INTERVAL",
    "BLOOD_BATH_HEAL",
    "FRACTURED_THRESHOLD",
    "STAGGER_DURATION",
    "RESOLVE_DURATION"
  }

  for _, key in ipairs(requiredNumbers) do
    assert(
      type(stability[key]) == "number",
      "Config.CURSED.STABILITY." .. key .. " must be a number"
    )
  end

  assert(stability.MAX > 0)
  assert(stability.PASSIVE_REGEN_DELAY >= 0)
  assert(stability.PASSIVE_REGEN_INTERVAL > 0)
  assert(stability.BLOOD_BATH_HEAL >= 0)
  assert(stability.FRACTURED_THRESHOLD >= 0)
  assert(stability.FRACTURED_THRESHOLD <= stability.MAX)
  assert(stability.STAGGER_DURATION >= 0)
  assert(stability.RESOLVE_DURATION >= 0)
end

function CursedStabilityManager:Init(tagManager)
  ValidateConfig()
  self.tagManager = tagManager
  self.ownerPlayerID = nil
  self.state = nil
end

function CursedStabilityManager:GetOwnerPlayerID()
  return self.ownerPlayerID
end

function CursedStabilityManager:GetState(playerID)
  if playerID ~= self.ownerPlayerID then
    return nil
  end

  return self.state
end

function CursedStabilityManager:GetCurrent(playerID)
  local state = self:GetState(playerID)
  return state and state:GetCurrent() or nil
end

function CursedStabilityManager:GetMax(playerID)
  local state = self:GetState(playerID)
  return state and state:GetMax() or nil
end

function CursedStabilityManager:GetPhase(playerID)
  local state = self:GetState(playerID)
  return state and state:GetPhase() or nil
end

function CursedStabilityManager:IsCurrentIt(playerID)
  return self.tagManager:GetItPlayerID() == playerID
end

function CursedStabilityManager:IsStaggered(playerID)
  return self:GetPhase(playerID) == CursedStabilityState.STAGGER
end

function CursedStabilityManager:IsFractured(playerID)
  local state = self:GetState(playerID)

  if state == nil then
    return false
  end

  return state:GetPhase() ~= CursedStabilityState.STAGGER
      and state:GetCurrent() > 0
      and state:GetCurrent() <= Config.CURSED.STABILITY.FRACTURED_THRESHOLD
end

function CursedStabilityManager:SyncPossession(currentTime)
  local currentItPlayerID = self.tagManager:GetItPlayerID()

  if currentItPlayerID == self.ownerPlayerID then
    return
  end

  if self.ownerPlayerID ~= nil then
    print("CURSED STABILITY POSSESSION END: Player " .. self.ownerPlayerID)
  end

  self.ownerPlayerID = currentItPlayerID
  self.state = nil

  if currentItPlayerID == nil then
    return
  end

  local state = CursedStabilityState()
  state:Init(Config.CURSED.STABILITY.MAX, currentTime)

  self.state = state

  print(string.format(
    "CURSED STABILITY POSSESSION START: Player %d | %d/%d",
    currentItPlayerID,
    state:GetCurrent(),
    state:GetMax()
  ))
end

function CursedStabilityManager:MarkCombatActivity(
    playerID,
    currentTime
)
  self:SyncPossession(currentTime)

  if playerID ~= self.ownerPlayerID or self.state == nil then
    return false
  end

  self.state:SetLastCombatTime(currentTime)
  self.state:SetNextRegenTime(
    currentTime + Config.CURSED.STABILITY.PASSIVE_REGEN_DELAY
  )

  return true
end

function CursedStabilityManager:UpdateLifecycle(currentTime)
  local state = self.state

  if state == nil then
    return
  end

  local phase = state:GetPhase()
  local phaseUntil = state:GetPhaseUntil()

  if phase == CursedStabilityState.STAGGER
      and phaseUntil ~= nil
      and currentTime >= phaseUntil
  then
    state:SetCurrent(state:GetMax())

    local resolveUntil =
        phaseUntil + Config.CURSED.STABILITY.RESOLVE_DURATION

    state:SetPhase(CursedStabilityState.RESOLVE, resolveUntil)
    state:SetLastCombatTime(phaseUntil)
    state:SetNextRegenTime(nil)

    print(string.format(
      "CURSED STAGGER END: Player %d | %d/%d | RESOLVE",
      self.ownerPlayerID,
      state:GetCurrent(),
      state:GetMax()
    ))

    phase = state:GetPhase()
    phaseUntil = state:GetPhaseUntil()
  end

  if phase == CursedStabilityState.RESOLVE
      and phaseUntil ~= nil
      and currentTime >= phaseUntil
  then
    state:SetPhase(CursedStabilityState.NORMAL, nil)

    print(
      "CURSED RESOLVE END: Player "
      .. self.ownerPlayerID
      .. " -> NORMAL"
    )
  end
end

function CursedStabilityManager:UpdateRegen(currentTime)
  local state = self.state

  if state == nil
      or state:GetPhase() == CursedStabilityState.STAGGER
      or state:GetCurrent() >= state:GetMax()
  then
    return
  end

  local nextRegenTime = state:GetNextRegenTime()

  if nextRegenTime == nil then
    local lastCombatTime = state:GetLastCombatTime() or currentTime

    nextRegenTime =
        lastCombatTime + Config.CURSED.STABILITY.PASSIVE_REGEN_DELAY

    state:SetNextRegenTime(nextRegenTime)
  end

  if currentTime < nextRegenTime then
    return
  end

  while state:GetCurrent() < state:GetMax()
    and currentTime >= nextRegenTime
  do
    state:Add(1)

    print(string.format(
      "CURSED STABILITY REGEN: Player %d | %d/%d",
      self.ownerPlayerID,
      state:GetCurrent(),
      state:GetMax()
    ))

    nextRegenTime =
        nextRegenTime + Config.CURSED.STABILITY.PASSIVE_REGEN_INTERVAL

    state:SetNextRegenTime(nextRegenTime)
  end

  if state:GetCurrent() >= state:GetMax() then
    state:SetNextRegenTime(nil)
  end
end

function CursedStabilityManager:Update(currentTime)
  self:SyncPossession(currentTime)
  self:UpdateLifecycle(currentTime)
  self:UpdateRegen(currentTime)
end

function CursedStabilityManager:ApplyImpact(
    sourcePlayerID,
    targetPlayerID,
    amount,
    currentTime
)
  self:SyncPossession(currentTime)
  self:UpdateLifecycle(currentTime)

  if targetPlayerID ~= self.ownerPlayerID or self.state == nil then
    return false, "not_cursed"
  end

  if amount <= 0 then
    return false, "invalid_amount"
  end

  local state = self.state
  local phase = state:GetPhase()

  if phase == CursedStabilityState.STAGGER then
    return false, "cursed_stagger"
  end

  self:MarkCombatActivity(
    targetPlayerID,
    currentTime
  )

  local previous = state:GetCurrent()
  local nextStability = previous - amount

  if phase == CursedStabilityState.RESOLVE
      and nextStability <= 0
  then
    state:SetCurrent(1)

    print(string.format(
      "CURSED RESOLVE ABSORB: Player %d -> Player %d | %d/%d",
      sourcePlayerID,
      targetPlayerID,
      state:GetCurrent(),
      state:GetMax()
    ))

    return true, "cursed_resolve_absorb"
  end

  state:SetCurrent(nextStability)
  local current = state:GetCurrent()

  if current <= 0 then
    state:SetCurrent(0)
    state:SetPhase(
      CursedStabilityState.STAGGER,
      currentTime + Config.CURSED.STABILITY.STAGGER_DURATION
    )
    state:SetNextRegenTime(nil)

    print(
      "CURSED STAGGER: Player "
      .. targetPlayerID
      .. " | caused by Player "
      .. tostring(sourcePlayerID)
    )

    return true, "cursed_stagger"
  end

  if previous > Config.CURSED.STABILITY.FRACTURED_THRESHOLD
      and current <= Config.CURSED.STABILITY.FRACTURED_THRESHOLD
  then
    print(string.format(
      "CURSED FRACTURED: Player %d | %d/%d",
      targetPlayerID,
      current,
      state:GetMax()
    ))
  else
    print(string.format(
      "CURSED IMPACT: Player %d -> Player %d | %d/%d",
      sourcePlayerID,
      targetPlayerID,
      current,
      state:GetMax()
    ))
  end

  return true, "cursed_hit"
end

function CursedStabilityManager:Heal(
    playerID,
    amount,
    source,
    currentTime
)
  self:SyncPossession(currentTime)
  self:UpdateLifecycle(currentTime)

  if playerID ~= self.ownerPlayerID
      or self.state == nil
      or amount <= 0
      or self.state:GetPhase() == CursedStabilityState.STAGGER
  then
    return 0
  end

  local healed = self.state:Add(amount)

  self:MarkCombatActivity(
    playerID,
    currentTime
  )

  if healed > 0 then
    print(string.format(
      "CURSED STABILITY HEAL: Player %d | +%d | %d/%d | %s",
      playerID,
      healed,
      self.state:GetCurrent(),
      self.state:GetMax(),
      tostring(source)
    ))
  end

  return healed
end

function CursedStabilityManager:OnNormalImpactLanded(
    attacker,
    currentTime
)
  if attacker == nil
      or attacker:IsNull()
      or not attacker:IsRealHero()
  then
    return 0
  end

  local playerID = attacker:GetPlayerOwnerID()

  if playerID < 0 or not self:IsCurrentIt(playerID) then
    return 0
  end

  return self:Heal(
    playerID,
    Config.CURSED.STABILITY.BLOOD_BATH_HEAL,
    "BLOOD_BATH",
    currentTime
  )
end

return CursedStabilityManager
