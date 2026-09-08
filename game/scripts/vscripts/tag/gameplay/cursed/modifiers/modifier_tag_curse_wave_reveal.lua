-- luacheck: globals modifier_tag_curse_wave_reveal AddFOWViewer

local Config = require("tag/config/config")

if modifier_tag_curse_wave_reveal == nil then
  modifier_tag_curse_wave_reveal = class({})
end

function modifier_tag_curse_wave_reveal.IsHidden()
  return false
end

function modifier_tag_curse_wave_reveal.IsDebuff()
  return true
end

function modifier_tag_curse_wave_reveal.IsPurgable()
  return false
end

function modifier_tag_curse_wave_reveal:RefreshVision()
  local parent = self:GetParent()

  if parent == nil
      or parent:IsNull()
      or self.viewerTeam == nil
  then
    return
  end

  AddFOWViewer(
    self.viewerTeam,
    parent:GetAbsOrigin(),
    Config.CURSED.CURSE_WAVE.DIRECT_REVEAL_RADIUS,
    Config.CURSED.CURSE_WAVE.REVEAL_VISION_TICK,
    false
  )
end

function modifier_tag_curse_wave_reveal.OnCreated(self)
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()
  local parent = self:GetParent()

  if caster == nil
      or caster:IsNull()
      or parent == nil
      or parent:IsNull()
  then
    self:Destroy()
    return
  end

  self.viewerTeam = caster:GetTeamNumber()

  -- True Sight handles invisibility while repeated FOW samples keep a moving
  -- target actually visible to the Curse host's team for the reveal window.
  parent:AddNewModifier(
    caster,
    self:GetAbility(),
    "modifier_truesight",
    {
      duration =
          Config.CURSED.CURSE_WAVE.REVEAL_DURATION
    }
  )

  self:RefreshVision()
  self:StartIntervalThink(
    Config.CURSED.CURSE_WAVE.REVEAL_THINK_INTERVAL
  )
end

function modifier_tag_curse_wave_reveal.OnIntervalThink(self)
  self:RefreshVision()
end
