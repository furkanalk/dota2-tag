local Config = require("tag/config/config")
local PassFeedback =
    require("tag/gameplay/abilities/pass_feedback")


if tag_pass_the_curse == nil then
  tag_pass_the_curse = class({})
end


local function GetTagManager()
  local gameMode =
      GameRules.TagGameMode

  if not gameMode
      or not gameMode.tagManager
  then
    return nil
  end

  return gameMode.tagManager
end

local function GetDirection(
    caster,
    targetPosition
)
  local origin =
      caster:GetAbsOrigin()

  local delta =
      targetPosition - origin

  local length =
      math.sqrt(
        delta.x * delta.x
        + delta.y * delta.y
      )

  if length <= 0 then
    return caster:GetForwardVector()
  end

  return Vector(
    delta.x / length,
    delta.y / length,
    0
  )
end

local function DestroyVisualProjectile(ability)
  local projectileID =
      ability.visualProjectileID

  if projectileID == nil then
    return
  end

  if ProjectileManager:IsValidProjectile(
        projectileID
      ) then
    ProjectileManager:DestroyTrackingProjectile(
      projectileID
    )
  end

  ability.visualProjectileID = nil
end


local function CreateVisualProjectile(
    ability,
    caster,
    direction
)
  local travelTime =
      Config.PASS.RANGE
      / Config.PASS.PROJECTILE_SPEED

  local targetPosition =
      caster:GetAbsOrigin()
      + direction * Config.PASS.RANGE

  targetPosition.z =
      GetGroundHeight(
        targetPosition,
        caster
      )
      + Config.PASS.PROJECTILE_HEIGHT

  local dummy =
      CreateModifierThinker(
        caster,
        ability,
        "modifier_kill",
        {
          duration =
              travelTime + 1.0
        },
        targetPosition,
        caster:GetTeamNumber(),
        false
      )

  if dummy == nil
      or dummy:IsNull()
  then
    return
  end

  dummy:SetAbsOrigin(
    targetPosition
  )

  ability.visualProjectileID =
      ProjectileManager:CreateTrackingProjectile({
        Target = dummy,
        Source = caster,
        Ability = ability,

        EffectName =
            Config.PASS.PROJECTILE_PARTICLE,

        iMoveSpeed =
            Config.PASS.PROJECTILE_SPEED,

        bDodgeable = false,
        bProvidesVision = false,

        iSourceAttachment =
            DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
      })
end

function tag_pass_the_curse:OnSpellStart()
  local caster = self:GetCaster()

  if not caster
      or caster:IsNull()
  then
    return
  end

  PassFeedback.PlayCast(caster)

  local direction =
      GetDirection(
        caster,
        self:GetCursorPosition()
      )

  DestroyVisualProjectile(self)

  CreateVisualProjectile(
    self,
    caster,
    direction
  )

  ProjectileManager:CreateLinearProjectile({
    Ability = self,

    vSpawnOrigin =
        caster:GetAbsOrigin(),

    fDistance =
        Config.PASS.RANGE,

    fStartRadius =
        Config.PASS.PROJECTILE_RADIUS,

    fEndRadius =
        Config.PASS.PROJECTILE_RADIUS,

    Source = caster,

    bHasFrontalCone = false,
    bReplaceExisting = false,
    bDeleteOnHit = false,

    iUnitTargetTeam =
        DOTA_UNIT_TARGET_TEAM_BOTH,

    iUnitTargetType =
        DOTA_UNIT_TARGET_HERO,

    iUnitTargetFlags =
        DOTA_UNIT_TARGET_FLAG_NONE,

    fExpireTime =
        GameRules:GetGameTime()
        + Config.PASS.RANGE
        / Config.PASS.PROJECTILE_SPEED
        + 0.5,

    vVelocity =
        direction
        * Config.PASS.PROJECTILE_SPEED,

    bProvidesVision = false
  })
end

function tag_pass_the_curse:OnProjectileHit(
    target,
    _location
)
  local caster = self:GetCaster()

  if not caster
      or caster:IsNull()
  then
    return true
  end

  if target == nil then
    DestroyVisualProjectile(self)

    PassFeedback.PlayFailure(
      caster,
      "miss"
    )

    return true
  end

  if target:IsNull()
      or target == caster
      or not target:IsRealHero()
  then
    return false
  end

  DestroyVisualProjectile(self)

  local sourcePlayerID =
      caster:GetPlayerOwnerID()

  local targetPlayerID =
      target:GetPlayerOwnerID()

  if sourcePlayerID < 0
      or targetPlayerID < 0
  then
    return false
  end

  local tagManager =
      GetTagManager()

  if tagManager == nil then
    return true
  end

  local _, result =
      tagManager:TryPassTo(
        sourcePlayerID,
        targetPlayerID
      )

  if result == "hit" then
    PassFeedback.PlayHit(
      caster,
      targetPlayerID
    )
  else
    PassFeedback.PlayFailure(
      caster,
      result
    )
  end

  return true
end
