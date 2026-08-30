if tag_pass_the_curse == nil then
  tag_pass_the_curse = class({})
end

function tag_pass_the_curse:OnSpellStart()
  local caster = self:GetCaster()

  if not caster or caster:IsNull() then
    return
  end

  local playerID =
      caster:GetPlayerOwnerID()

  if playerID < 0 then
    return
  end

  local gameMode =
      GameRules.TagGameMode

  if not gameMode
      or not gameMode.tagManager
  then
    return
  end

  gameMode.tagManager:TryPass(playerID)
end
