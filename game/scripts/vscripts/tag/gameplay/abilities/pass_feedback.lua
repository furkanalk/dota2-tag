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
    Config.PASS.CAST_SOUND,
    caster
  )

  EmitSoundOn(
    Config.PASS.HIT_SOUND,
    target
  )
end

function PassFeedback.PlayFailure(
    caster,
    result
)
  local player =
      caster:GetPlayerOwner()

  if player == nil then
    return
  end

  local soundName = nil

  if result == "miss" then
    soundName =
        Config.PASS.MISS_SOUND
  elseif result == "immune" then
    soundName =
        Config.PASS.IMMUNE_SOUND
  end

  if soundName == nil then
    return
  end

  EmitSoundOnClient(
    soundName,
    player
  )
end

return PassFeedback
