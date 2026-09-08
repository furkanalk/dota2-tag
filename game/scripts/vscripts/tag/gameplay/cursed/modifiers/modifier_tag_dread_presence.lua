-- luacheck: globals modifier_tag_dread_presence

local Config = require("tag/config/config")

if modifier_tag_dread_presence == nil then
  modifier_tag_dread_presence = class({})
end

local function IsValidHero(hero)
  return hero
      and not hero:IsNull()
      and hero:IsRealHero()
      and hero:IsAlive()
end

function modifier_tag_dread_presence.IsHidden()
  return false
end

function modifier_tag_dread_presence.IsPurgable()
  return false
end

function modifier_tag_dread_presence:OnCreated()
  if not IsServer() then
    return
  end

  self.targetDread = {}
  self.pendingFear = 0
  self.fearEarned = 0

  self.lastThinkTime = GameRules:GetGameTime()
  self.lastFearGrantTime = self.lastThinkTime

  self:StartIntervalThink(
    Config.CURSED.DREAD_PRESENCE.THINK_INTERVAL
  )
end

-- Convert meaningful continuous exposure into a per-second rate that reaches
-- the configured +12 Fear cap only after a near-full successful activation.
function modifier_tag_dread_presence.GetFearGainRate()
  local config =
      Config.CURSED.DREAD_PRESENCE

  local activeWindow =
      math.max(
        0.1,
        config.DURATION
        - config.MEANINGFUL_EXPOSURE_DELAY
      )

  return Config.CURSED.FEAR.GAIN.DREAD_EXPOSURE_MAX
      / activeWindow
end

-- Fear is granted in small batches to avoid per-think log/resource churn.
-- A cast can never exceed DREAD_EXPOSURE_MAX, regardless of Runner count.
function modifier_tag_dread_presence:GrantPendingFear(
    gameMode,
    playerID,
    currentTime
)
  if self.pendingFear <= 0 then
    return
  end

  local remaining =
      Config.CURSED.FEAR.GAIN.DREAD_EXPOSURE_MAX
      - self.fearEarned

  if remaining <= 0 then
    self.pendingFear = 0
    return
  end

  local attempted =
      math.min(self.pendingFear, remaining)

  local gained =
      gameMode.fearManager:AddFear(
        playerID,
        attempted,
        "DREAD_EXPOSURE",
        currentTime
      )

  self.fearEarned =
      self.fearEarned + gained

  -- Exposure while already capped does not bank Fear
  -- for a later spend during the same Q activation.
  self.pendingFear =
      self.pendingFear - attempted
end

-- Maintain per-Runner Dread memory. Remaining nearby ramps the slow; leaving
-- the aura quickly decays that buildup instead of resetting it instantly.
function modifier_tag_dread_presence:UpdateTarget(
    gameMode,
    caster,
    targetPlayerID,
    target,
    deltaTime,
    currentTime
)
  local config =
      Config.CURSED.DREAD_PRESENCE

  local dread =
      self.targetDread[targetPlayerID] or 0

  local distance =
      (target:GetAbsOrigin()
      - caster:GetAbsOrigin()):Length2D()

  if distance > config.RADIUS then
    dread =
        math.max(
          0,
          dread
          - config.DREAD_DECAY_PER_SECOND
          * deltaTime
        )

    if dread <= 0 then
      self.targetDread[targetPlayerID] = nil
    else
      self.targetDread[targetPlayerID] = dread
    end

    return false
  end

  dread =
      math.min(
        config.SLOW_RAMP_DURATION,
        dread + deltaTime
      )

  self.targetDread[targetPlayerID] = dread

  -- Dread Presence deals no Stability damage; it only keeps the normal
  -- Runner recovery timer pushed back while the Runner remains exposed.
  gameMode.stabilityManager:SuppressRegen(
    targetPlayerID,
    currentTime
  )

  local slowRatio =
      math.min(
        1,
        dread / config.SLOW_RAMP_DURATION
      )

  target:AddNewModifier(
    caster,
    self:GetAbility(),
    "modifier_tag_dread_slow",
    {
      duration =
          config.THINK_INTERVAL * 2.5,
      slow =
          config.SLOW_CAP * 100 * slowRatio
    }
  )

  return dread >= config.MEANINGFUL_EXPOSURE_DELAY
end

-- One server loop evaluates all registered Runners. Multiple exposed Runners
-- improve area control, but deliberately do not multiply Fear generation.
function modifier_tag_dread_presence:OnIntervalThink()
  if not IsServer() then
    return
  end

  local gameMode =
      GameRules.TagGameMode

  local caster = self:GetParent()

  if gameMode == nil
      or not IsValidHero(caster)
  then
    self:Destroy()
    return
  end

  local playerID =
      caster:GetPlayerOwnerID()

  if playerID < 0
      or gameMode.tagManager:GetItPlayerID() ~= playerID
  then
    self:Destroy()
    return
  end

  local currentTime =
      GameRules:GetGameTime()

  local deltaTime =
      math.max(
        0,
        currentTime - self.lastThinkTime
      )

  self.lastThinkTime = currentTime

  local anyMeaningfulExposure = false

  for targetPlayerID, target in pairs(
      gameMode.tagManager:GetHeroes()
  ) do
    if targetPlayerID ~= playerID
        and IsValidHero(target)
    then
      local meaningful =
          self:UpdateTarget(
            gameMode,
            caster,
            targetPlayerID,
            target,
            deltaTime,
            currentTime
          )

      if meaningful then
        anyMeaningfulExposure = true
      end
    end
  end

  if anyMeaningfulExposure then
    gameMode.cursedStabilityManager:MarkCombatActivity(
      playerID,
      currentTime
    )

    self.pendingFear =
        self.pendingFear
        + modifier_tag_dread_presence.GetFearGainRate()
        * deltaTime
  end

  if currentTime - self.lastFearGrantTime
      >= Config.CURSED.DREAD_PRESENCE.FEAR_GRANT_INTERVAL
  then
    self:GrantPendingFear(
      gameMode,
      playerID,
      currentTime
    )

    self.lastFearGrantTime = currentTime
  end
end

function modifier_tag_dread_presence:OnDestroy()
  if not IsServer() then
    return
  end

  local gameMode =
      GameRules.TagGameMode

  local caster = self:GetParent()

  if gameMode == nil
      or not IsValidHero(caster)
  then
    return
  end

  local playerID =
      caster:GetPlayerOwnerID()

  if playerID < 0 then
    return
  end

  self:GrantPendingFear(
    gameMode,
    playerID,
    GameRules:GetGameTime()
  )
end
