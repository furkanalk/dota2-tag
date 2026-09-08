-- luacheck: globals modifier_tag_cursed_kit MODIFIER_STATE_PASSIVES_DISABLED

if modifier_tag_cursed_kit == nil then
  modifier_tag_cursed_kit = class({})
end

function modifier_tag_cursed_kit.IsHidden()
  return true
end

function modifier_tag_cursed_kit.IsPurgable()
  return false
end

function modifier_tag_cursed_kit.RemoveOnDeath()
  return false
end

function modifier_tag_cursed_kit.CheckState()
  return {
    [MODIFIER_STATE_PASSIVES_DISABLED] = true
  }
end
