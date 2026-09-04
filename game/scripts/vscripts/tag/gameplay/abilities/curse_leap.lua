local Config = require("tag/config/config")

LinkLuaModifier(
  "modifier_tag_curse_leap_motion",
  "tag/gameplay/abilities/modifiers/modifier_tag_curse_leap_motion",
  LUA_MODIFIER_MOTION_HORIZONTAL
)

if tag_curse_leap == nil then
  tag_curse_leap = class({})
end


function tag_curse_leap:OnSpellStart()
  local caster = self:GetCaster()

  if not caster
      or caster:IsNull()
  then
    return
  end

  caster:StartGesture(
    ACT_DOTA_ATTACK
  )

  caster:AddNewModifier(
    caster,
    self,
    "modifier_tag_curse_leap_motion",
    {
      duration =
          Config.LEAP.DURATION,

      distance =
          Config.LEAP.DISTANCE
    }
  )
end
