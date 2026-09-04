local Config = require("tag/config/config")

local ItState = class({})


local function DestroyParticle(particle)
  if particle == nil then
    return
  end

  ParticleManager:DestroyParticle(
    particle,
    false
  )

  ParticleManager:ReleaseParticleIndex(
    particle
  )
end


function ItState:Init(playerRegistry)
  self.players = playerRegistry

  self.ringParticle = nil
  self.curseParticle = nil
end

function ItState:Apply(playerID)
  local hero =
      self.players:GetHero(playerID)

  if not hero
      or hero:IsNull()
  then
    return
  end

  local transitionParticle =
      ParticleManager:CreateParticle(
        Config.IT.TRANSITION_PARTICLE,
        PATTACH_ABSORIGIN_FOLLOW,
        hero
      )

  ParticleManager:ReleaseParticleIndex(
    transitionParticle
  )

  hero:SetRenderColor(
    Config.IT.COLOR.r,
    Config.IT.COLOR.g,
    Config.IT.COLOR.b
  )

  self:DestroyParticles()

  self.ringParticle =
      ParticleManager:CreateParticle(
        Config.IT.RING_PARTICLE,
        PATTACH_ABSORIGIN_FOLLOW,
        hero
      )

  ParticleManager:SetParticleControl(
    self.ringParticle,
    1,
    Vector(255, 60, 60)
  )

  self.curseParticle =
      ParticleManager:CreateParticle(
        Config.IT.CURSE_PARTICLE,
        PATTACH_OVERHEAD_FOLLOW,
        hero
      )

  EmitSoundOn(
    Config.IT.CURSE_AMBIENCE_SOUND,
    hero
  )
end

function ItState:Remove(playerID)
  local hero =
      self.players:GetHero(playerID)

  if not hero
      or hero:IsNull()
  then
    return
  end

  StopSoundOn(
    Config.IT.CURSE_AMBIENCE_SOUND,
    hero
  )

  hero:SetRenderColor(
    255,
    255,
    255
  )

  self:DestroyParticles()
end

function ItState:DestroyParticles()
  DestroyParticle(
    self.ringParticle
  )

  DestroyParticle(
    self.curseParticle
  )

  self.ringParticle = nil
  self.curseParticle = nil
end

return ItState
