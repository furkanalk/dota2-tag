if tag_pass_the_curse == nil then
  tag_pass_the_curse = class({})
end


local function PlayCastFeedback(caster)
  caster:StartGesture(
    ACT_DOTA_ATTACK
  )
end

local function PlayHitFeedback(targetPlayerID)
  local target =
      PlayerResource:GetSelectedHeroEntity(
        targetPlayerID
      )

  if not target
      or target:IsNull()
  then
    return
  end

  target:StartGesture(
    ACT_DOTA_FLINCH
  )
end

local function PlayFailureFeedback(caster)
  local player =
      caster:GetPlayerOwner()

  if player == nil then
    return
  end

  EmitSoundOnClient(
    "General.CastFail_InvalidTarget_Hero",
    player
  )
end


function tag_pass_the_curse:OnSpellStart()
  local caster = self:GetCaster()

  if not caster
      or caster:IsNull()
  then
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

  PlayCastFeedback(caster)

  local targetPlayerID, result =
      gameMode.tagManager:TryPass(
        playerID
      )

  if result == "hit" then
    PlayHitFeedback(targetPlayerID)
    return
  end

  if result == "miss"
      or result == "immune"
  then
    PlayFailureFeedback(caster)
  end
end
