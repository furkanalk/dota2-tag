local Config = require("tag/config/config")

local PassFeedback = {}


local function GetHero(playerID)
  local hero =
      PlayerResource:GetSelectedHeroEntity(
        playerID
      )

  if not hero
      or hero:IsNull()
  then
    return nil
  end

  return hero
end

function PassFeedback.PlayCast(caster)
  caster:StartGesture(
    ACT_DOTA_ATTACK
  )
end

function PassFeedback.PlayHit(
    caster,
    targetPlayerID
)
  local target =
      GetHero(targetPlayerID)

  if target == nil then
    return
  end

  target:StartGesture(
    ACT_DOTA_FLINCH
  )

  local particle =
      ParticleManager:CreateParticle(
        Config.PASS.HIT_PARTICLE,
        PATTACH_ABSORIGIN_FOLLOW,
        target
      )

  ParticleManager:ReleaseParticleIndex(
    particle
  )

  EmitSoundOn(
    Config.PASS.SUCCESS_VOICE_SOUND,
    caster
  )

  EmitSoundOn(
    Config.PASS.SUCCESS_HIT_SOUND,
    target
  )
end

function PassFeedback.PlayFailure(
    caster,
    result
)
  if result == "miss" then
    EmitSoundOn(
      Config.PASS.MISS_SOUND,
      caster
    )

    return
  end

  if result ~= "immune" then
    return
  end

  local player =
      caster:GetPlayerOwner()

  if player == nil then
    return
  end

  EmitSoundOnClient(
    Config.PASS.IMMUNE_SOUND,
    player
  )
end

return PassFeedback
