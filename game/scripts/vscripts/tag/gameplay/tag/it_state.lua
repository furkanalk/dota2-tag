local Config = require("tag/config/config")

local ItState = class({})

function ItState:Init(playerRegistry)
  self.players = playerRegistry
  self.particle = nil
end

function ItState:Apply(playerID)
  local hero = self.players:GetHero(playerID)

  if not hero or hero:IsNull() then
    return
  end

  local baseSpeed =
      self.players:GetBaseMoveSpeed(playerID)

  hero:SetBaseMoveSpeed(
    baseSpeed + Config.IT_SPEED_BONUS
  )

  hero:SetRenderColor(
    Config.IT_COLOR.r,
    Config.IT_COLOR.g,
    Config.IT_COLOR.b
  )

  self:DestroyParticle()

  self.particle =
      ParticleManager:CreateParticle(
        Config.IT_RING_PARTICLE,
        PATTACH_ABSORIGIN_FOLLOW,
        hero
      )

  ParticleManager:SetParticleControl(
    self.particle,
    1,
    Vector(255, 60, 60)
  )
end

function ItState:Remove(playerID)
  local hero = self.players:GetHero(playerID)

  if not hero or hero:IsNull() then
    return
  end

  hero:SetBaseMoveSpeed(
    self.players:GetBaseMoveSpeed(playerID)
  )

  hero:SetRenderColor(255, 255, 255)

  self:DestroyParticle()
end

function ItState:DestroyParticle()
  if self.particle == nil then
    return
  end

  ParticleManager:DestroyParticle(
    self.particle,
    false
  )

  ParticleManager:ReleaseParticleIndex(
    self.particle
  )

  self.particle = nil
end

return ItState
