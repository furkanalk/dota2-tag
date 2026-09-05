local Config = require("tag/config/config")

if modifier_tag_unstable_entry_slow == nil then
  modifier_tag_unstable_entry_slow = class({})
end

local function GetPenaltyScale(modifier)
  local elapsed =
      modifier:GetElapsedTime()

  local duration =
      Config.STABILITY.UNSTABLE_IMPAIRMENT_DURATION

  if duration <= 0 then
    return 0
  end

  return math.max(
    0,
    1 - elapsed / duration
  )
end

function modifier_tag_unstable_entry_slow.IsHidden()
  return false
end

function modifier_tag_unstable_entry_slow.IsDebuff()
  return true
end

function modifier_tag_unstable_entry_slow.IsPurgable()
  return false
end

function modifier_tag_unstable_entry_slow.IgnoreTenacity()
  return true
end

function modifier_tag_unstable_entry_slow.DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE
  }
end

function modifier_tag_unstable_entry_slow.GetModifierTurnRate_Percentage(self)
  return -Config.STABILITY.UNSTABLE_ENTRY_TURN_SLOW
      * GetPenaltyScale(self)
end

function modifier_tag_unstable_entry_slow.GetModifierMoveSpeedBonus_Percentage(
    self
)
  return -Config.STABILITY.UNSTABLE_ENTRY_SLOW
      * GetPenaltyScale(self)
end
