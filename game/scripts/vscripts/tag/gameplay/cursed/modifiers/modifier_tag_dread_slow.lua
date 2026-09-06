-- luacheck: globals modifier_tag_dread_slow
-- luacheck: globals MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE

if modifier_tag_dread_slow == nil then
  modifier_tag_dread_slow = class({})
end

function modifier_tag_dread_slow.IsHidden()
  return false
end

function modifier_tag_dread_slow.IsDebuff()
  return true
end

function modifier_tag_dread_slow.IsPurgable()
  return false
end

function modifier_tag_dread_slow.OnCreated(self, params)
  self.slowPercent = tonumber(params.slow) or 0
end

function modifier_tag_dread_slow.OnRefresh(self, params)
  self.slowPercent = tonumber(params.slow) or 0
end

function modifier_tag_dread_slow.DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
  }
end

function modifier_tag_dread_slow.GetModifierMoveSpeedBonus_Percentage(self)
  return -self.slowPercent
end
