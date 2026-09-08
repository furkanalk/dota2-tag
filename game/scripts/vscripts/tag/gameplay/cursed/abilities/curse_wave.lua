-- luacheck: globals tag_cursed_curse_wave UF_SUCCESS UF_FAIL_CUSTOM
-- luacheck: globals DOTA_UNIT_TARGET_TEAM_BOTH DOTA_UNIT_TARGET_HERO
-- luacheck: globals DOTA_UNIT_TARGET_FLAG_NONE AddFOWViewer

local Config = require("tag/config/config")

if tag_cursed_curse_wave == nil then
  tag_cursed_curse_wave = class({})
end

local function IsValidHero(hero)
  return hero
      and not hero:IsNull()
      and hero:IsRealHero()
      and hero:IsAlive()
end

-- W shares the same authoritative gates as Q: only the active, non-Staggered
-- Curse host with enough Fear may create a scouting wave.
local function IsFearLockedForInput(self)
    local caster = self:GetCaster()

    if caster == nil or CustomNetTables == nil then
        return false
    end

    local playerID = caster:GetPlayerOwnerID()

    if playerID == nil or playerID < 0 then
        return false
    end

    local state = CustomNetTables:GetTableValue(
        "tag_cursed_ui",
        tostring(playerID)
    )

    return state ~= nil
        and tonumber(state.w_fear_locked) == 1
end

-- Keep the native ability hotkey path intact. When Fear is insufficient,
-- W becomes no-target only long enough to validate immediately on key press.
function tag_cursed_curse_wave.GetBehavior(self)
    if IsFearLockedForInput(self) then
        return DOTA_ABILITY_BEHAVIOR_NO_TARGET
    end

    return DOTA_ABILITY_BEHAVIOR_POINT
end

local function ValidateCast(self)
  if not IsServer() then
    return UF_SUCCESS
  end

  local gameMode = GameRules.TagGameMode
  local caster = self:GetCaster()

  if gameMode == nil
      or caster == nil
      or caster:IsNull()
  then
    self.castError = "The Curse is not ready."
    return UF_FAIL_CUSTOM
  end

  local playerID = caster:GetPlayerOwnerID()

  if playerID < 0
      or gameMode.tagManager:GetItPlayerID() ~= playerID
  then
    self.castError = "Only the Cursed may use Curse Wave."
    return UF_FAIL_CUSTOM
  end

  if gameMode.cursedStabilityManager:IsStaggered(
      playerID
  ) then
    self.castError = "The Curse is staggered."
    return UF_FAIL_CUSTOM
  end

  local currentFear =
      gameMode.fearManager:GetCurrent(playerID)

  if currentFear == nil
      or currentFear
          < Config.CURSED.FEAR.COST.CURSE_WAVE
  then
    self.castError = "Not enough Fear."
    return UF_FAIL_CUSTOM
  end

  self.castError = nil
  return UF_SUCCESS
end

-- Point-target abilities are validated through the location-specific hooks.
-- Keep the generic hooks too so direct/debug orders receive the same rules.
function tag_cursed_curse_wave.CastFilterResult(self)
  return ValidateCast(self)
end

function tag_cursed_curse_wave.CastFilterResultLocation(
    self,
    _location
)
  return ValidateCast(self)
end

function tag_cursed_curse_wave.GetCustomCastError(self)
  return self.castError or ""
end

function tag_cursed_curse_wave.GetCustomCastErrorLocation(
    self,
    _location
)
  return self.castError or ""
end

local function GetCastDirection(
    caster,
    cursorPosition
)
  local direction =
      cursorPosition - caster:GetAbsOrigin()

  direction.z = 0

  if direction:Length2D() < 1 then
    return caster:GetForwardVector()
  end

  return direction:Normalized()
end

-- The projectile is information-only: it never calls either Stability manager.
-- Its job is to create temporary path vision and identify intersected Runners.
function tag_cursed_curse_wave.OnSpellStart(self)
  if not IsServer() then
    return
  end

  local gameMode = GameRules.TagGameMode
  local caster = self:GetCaster()

  if gameMode == nil or not IsValidHero(caster) then
    self:EndCooldown()
    return
  end

  local playerID = caster:GetPlayerOwnerID()
  local currentTime = GameRules:GetGameTime()

  local spent =
      gameMode.fearManager:SpendFear(
        playerID,
        Config.CURSED.FEAR.COST.CURSE_WAVE,
        "CURSE_WAVE",
        currentTime
      )

  if not spent then
    self:EndCooldown()
    return
  end

  local config = Config.CURSED.CURSE_WAVE
  local direction =
      GetCastDirection(
        caster,
        self:GetCursorPosition()
      )

  -- Cooldown prevents overlapping casts today, but explicit hit de-duplication
  -- keeps one Runner from rewarding Fear twice if projectile behavior changes.
  self.hitTargets = {}

  ProjectileManager:CreateLinearProjectile({
    Ability = self,
    EffectName = config.PARTICLE,
    vSpawnOrigin = caster:GetAbsOrigin(),

    fDistance = config.RANGE,
    fStartRadius = config.WIDTH * 0.5,
    fEndRadius = config.WIDTH * 0.5,

    Source = caster,
    bHasFrontalCone = false,
    bReplaceExisting = false,

    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
    iUnitTargetType = DOTA_UNIT_TARGET_HERO,
    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,

    fExpireTime =
        currentTime
        + config.RANGE / config.SPEED
        + 0.5,

    bDeleteOnHit = false,
    vVelocity = direction * config.SPEED,

    -- Lingering path vision is authored manually in OnProjectileThink.
    bProvidesVision = false
  })

  print(string.format(
    "CURSE WAVE: Player %d | range %d | width %d | speed %d",
    playerID,
    config.RANGE,
    config.WIDTH,
    config.SPEED
  ))
end

-- Each projectile sample leaves a short-lived vision footprint, producing the
-- intended supernatural scouting corridor rather than vision only at the tip.
function tag_cursed_curse_wave.OnProjectileThink(
    self,
    location
)
  if not IsServer() or location == nil then
    return
  end

  local gameMode = GameRules.TagGameMode
  local caster = self:GetCaster()

  if gameMode == nil or not IsValidHero(caster) then
    return
  end

  local playerID = caster:GetPlayerOwnerID()

  if gameMode.tagManager:GetItPlayerID() ~= playerID then
    return
  end

  local config = Config.CURSED.CURSE_WAVE

  AddFOWViewer(
    caster:GetTeamNumber(),
    location,
    config.PATH_VISION_RADIUS,
    config.PATH_VISION_DURATION,
    false
  )
end

function tag_cursed_curse_wave.OnProjectileHit(
    self,
    target
)
  if not IsServer() or target == nil then
    return false
  end

  local gameMode = GameRules.TagGameMode
  local caster = self:GetCaster()

  if gameMode == nil
      or not IsValidHero(caster)
      or not IsValidHero(target)
  then
    return false
  end

  local casterPlayerID = caster:GetPlayerOwnerID()
  local targetPlayerID = target:GetPlayerOwnerID()

  if casterPlayerID < 0
      or targetPlayerID < 0
      or targetPlayerID == casterPlayerID
      or gameMode.tagManager:GetItPlayerID() ~= casterPlayerID
  then
    return false
  end

  local targetIndex = target:entindex()

  if self.hitTargets[targetIndex] then
    return false
  end

  self.hitTargets[targetIndex] = true

  local config = Config.CURSED.CURSE_WAVE
  local currentTime = GameRules:GetGameTime()

  -- Direct hits reveal the moving Runner for a short period. The reveal
  -- modifier maintains FOW on the target and applies Dota True Sight.
  target:AddNewModifier(
    caster,
    self,
    "modifier_tag_curse_wave_reveal",
    {
      duration = config.REVEAL_DURATION
    }
  )

  local gained =
      gameMode.fearManager:AddFear(
        casterPlayerID,
        Config.CURSED.FEAR.GAIN.CURSE_WAVE_HIT,
        "CURSE_WAVE_HIT",
        currentTime
      )

  -- A successful W hit is meaningful hunt activity, so passive Cursed
  -- Stability recovery should not continue through the contact.
  gameMode.cursedStabilityManager:MarkCombatActivity(
    casterPlayerID,
    currentTime
  )

  print(string.format(
    "CURSE WAVE HIT: Player %d -> Player %d | +%.1f Fear | reveal %.1fs",
    casterPlayerID,
    targetPlayerID,
    gained,
    config.REVEAL_DURATION
  ))

  return false
end
