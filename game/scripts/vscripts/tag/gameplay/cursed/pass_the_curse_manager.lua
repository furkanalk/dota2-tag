local Config = require("tag/config/config")

local PassTheCurseManager = class({})

local function ValidateConfig()
  local pass =
      Config.CURSED
      and Config.CURSED.PASS_THE_CURSE

  assert(
    type(pass) == "table",
    "Config.CURSED.PASS_THE_CURSE must exist"
  )

  local requiredNumbers = {
    "RANGE",
    "MIN_ARM_TIME",
    "MAX_HOLD_TIME",
    "FIZZLE_RECOVERY"
  }

  for _, key in ipairs(requiredNumbers) do
    assert(
      type(pass[key]) == "number",
      "Config.CURSED.PASS_THE_CURSE."
      .. key
      .. " must be a number"
    )
  end

  assert(pass.RANGE > 0)
  assert(pass.MIN_ARM_TIME >= 0)
  assert(pass.MAX_HOLD_TIME > pass.MIN_ARM_TIME)
  assert(pass.FIZZLE_RECOVERY >= 0)
end

PassTheCurseManager.IDLE = "IDLE"
PassTheCurseManager.ARMING = "ARMING"
PassTheCurseManager.FIZZLE = "FIZZLE"

local function IsValidHero(hero)
  return hero
      and not hero:IsNull()
      and hero:IsRealHero()
      and hero:IsAlive()
end

local function Distance2D(left, right)
  local delta = left - right
  delta.z = 0
  return delta:Length2D()
end

function PassTheCurseManager:Init(
    tagManager,
    stabilityManager,
    cursedStabilityManager
)
  ValidateConfig()

  self.tagManager = tagManager
  self.stabilityManager = stabilityManager
  self.cursedStabilityManager = cursedStabilityManager

  self.phase = PassTheCurseManager.IDLE
  self.ownerPlayerID = nil

  self.startedAt = nil
  self.readyAt = nil
  self.expiresAt = nil
  self.fizzleUntil = nil
  self.lastResult = nil

  -- Future systems such as true evade, committed traversal, or special
  -- geometry may register extra pre-commit validators here.
  self.validators = {}
end

function PassTheCurseManager:RegisterValidator(name, callback)
  if type(name) ~= "string" or type(callback) ~= "function" then
    return false
  end

  self.validators[name] = callback
  return true
end

function PassTheCurseManager:GetPhase()
  return self.phase
end

function PassTheCurseManager:GetOwnerPlayerID()
  return self.ownerPlayerID
end

function PassTheCurseManager:GetReadyAt()
  return self.readyAt
end

function PassTheCurseManager:GetExpiresAt()
  return self.expiresAt
end

function PassTheCurseManager:GetFizzleUntil()
  return self.fizzleUntil
end

function PassTheCurseManager:GetLastResult()
  return self.lastResult
end

function PassTheCurseManager:IsArming(playerID)
  return self.phase == PassTheCurseManager.ARMING
      and self.ownerPlayerID == playerID
end

function PassTheCurseManager:IsReady(
    playerID,
    currentTime
)
  return self:IsArming(playerID)
      and self.readyAt ~= nil
      and currentTime >= self.readyAt
      and self.expiresAt ~= nil
      and currentTime < self.expiresAt
end

function PassTheCurseManager:IsActionLocked(playerID)
  if self.ownerPlayerID ~= playerID then
    return false
  end

  return self.phase == PassTheCurseManager.ARMING
      or self.phase == PassTheCurseManager.FIZZLE
end

function PassTheCurseManager:Clear(result)
  self.phase = PassTheCurseManager.IDLE
  self.ownerPlayerID = nil

  self.startedAt = nil
  self.readyAt = nil
  self.expiresAt = nil
  self.fizzleUntil = nil

  if result ~= nil then
    self.lastResult = result
  end
end

function PassTheCurseManager:Fizzle(
    reason,
    currentTime
)
  local playerID = self.ownerPlayerID

  self.phase = PassTheCurseManager.FIZZLE
  self.startedAt = nil
  self.readyAt = nil
  self.expiresAt = nil

  self.fizzleUntil =
      currentTime
      + Config.CURSED.PASS_THE_CURSE.FIZZLE_RECOVERY

  self.lastResult = reason

  print(string.format(
    "PASS FIZZLE: Player %s | %s | recovery %.2fs",
    tostring(playerID),
    tostring(reason),
    Config.CURSED.PASS_THE_CURSE.FIZZLE_RECOVERY
  ))

  return false, reason
end

function PassTheCurseManager:CanBegin(
    playerID,
    currentTime
)
  self:Update(currentTime)

  if self.tagManager:GetItPlayerID() ~= playerID then
    return false, "not_cursed"
  end

  if not IsValidHero(
      self.tagManager:GetHero(playerID)
    )
  then
    return false, "invalid_caster"
  end

  if self.phase == PassTheCurseManager.ARMING then
    return false, "already_arming"
  end

  if self.phase == PassTheCurseManager.FIZZLE then
    return false, "fizzle_recovery"
  end

  if self.cursedStabilityManager:IsStaggered(playerID) then
    return false, "cursed_stagger"
  end

  return true, "ok"
end

function PassTheCurseManager:Begin(
    playerID,
    currentTime
)
  local allowed, reason =
      self:CanBegin(playerID, currentTime)

  if not allowed then
    return false, reason
  end

  local config = Config.CURSED.PASS_THE_CURSE

  self.phase = PassTheCurseManager.ARMING
  self.ownerPlayerID = playerID

  self.startedAt = currentTime
  self.readyAt = currentTime + config.MIN_ARM_TIME
  self.expiresAt = currentTime + config.MAX_HOLD_TIME
  self.fizzleUntil = nil
  self.lastResult = "arming"

  print(string.format(
    "PASS ARMING: Player %d | ready %.2f | expires %.2f",
    playerID,
    self.readyAt,
    self.expiresAt
  ))

  return true, "arming"
end

function PassTheCurseManager:ValidateTarget(
    sourcePlayerID,
    targetPlayerID
)
  if self.tagManager:GetItPlayerID() ~= sourcePlayerID then
    return false, "not_cursed"
  end

  if targetPlayerID == nil
      or targetPlayerID < 0
      or targetPlayerID == sourcePlayerID
  then
    return false, "invalid_target"
  end

  local caster =
      self.tagManager:GetHero(sourcePlayerID)

  local target =
      self.tagManager:GetHero(targetPlayerID)

  if not IsValidHero(caster)
      or not IsValidHero(target)
  then
    return false, "invalid_target"
  end

  if not self.stabilityManager:IsCurseable(
      targetPlayerID
  ) then
    return false, "target_not_curseable"
  end

  local range = Config.CURSED.PASS_THE_CURSE.RANGE

  if Distance2D(
      caster:GetAbsOrigin(),
      target:GetAbsOrigin()
    ) > range
  then
    return false, "out_of_range"
  end

  -- Coarse world-connectivity guard only. CanFindPath answers whether the two
  -- positions are reachable through GridNav; it is not a direct line-of-sight
  -- trace. Authored geometry / true-evade / committed traversal checks plug in
  -- through RegisterValidator before the feature leaves this branch.
  if GridNav ~= nil
      and not GridNav:CanFindPath(
        caster:GetAbsOrigin(),
        target:GetAbsOrigin()
      )
  then
    return false, "unreachable_geometry"
  end

  for name, validator in pairs(self.validators) do
    local valid, validatorReason =
        validator(
          sourcePlayerID,
          targetPlayerID,
          caster,
          target
        )

    if not valid then
      return false,
          validatorReason
          or ("rejected_" .. name)
    end
  end

  return true, "ok"
end

function PassTheCurseManager:Release(
    playerID,
    targetPlayerID,
    currentTime
)
  self:Update(currentTime)

  if not self:IsArming(playerID) then
    if self.phase == PassTheCurseManager.FIZZLE then
      return false, self.lastResult or "fizzle_recovery"
    end

    return false, "not_arming"
  end

  if currentTime < self.readyAt then
    return self:Fizzle(
      "released_early",
      currentTime
    )
  end

  if currentTime >= self.expiresAt then
    return self:Fizzle(
      "expired",
      currentTime
    )
  end

  local valid, reason =
      self:ValidateTarget(
        playerID,
        targetPlayerID
      )

  if not valid then
    return self:Fizzle(
      reason,
      currentTime
    )
  end

  -- COMMIT boundary:
  -- everything above this line is cancellable. Once ownership changes,
  -- downstream possession systems resolve against the new authoritative IT.
  self:Clear("committed")

  self.tagManager:SetIt(targetPlayerID)

  print(string.format(
    "PASS COMMIT: Player %d -> Player %d",
    playerID,
    targetPlayerID
  ))

  return true, "committed"
end

function PassTheCurseManager:Update(currentTime)
  if self.phase == PassTheCurseManager.IDLE then
    return
  end

  if self.ownerPlayerID == nil then
    self:Clear("invalid_owner")
    return
  end

  if self.tagManager:GetItPlayerID()
      ~= self.ownerPlayerID
  then
    self:Clear("possession_changed")
    return
  end

  if self.phase == PassTheCurseManager.ARMING then
    if self.cursedStabilityManager:IsStaggered(
        self.ownerPlayerID
      )
    then
      self:Fizzle(
        "cursed_stagger",
        currentTime
      )
      return
    end

    if self.expiresAt ~= nil
        and currentTime >= self.expiresAt
    then
      self:Fizzle(
        "expired",
        currentTime
      )
    end

    return
  end

  if self.phase == PassTheCurseManager.FIZZLE
      and self.fizzleUntil ~= nil
      and currentTime >= self.fizzleUntil
  then
    self:Clear("ready")
  end
end

return PassTheCurseManager
