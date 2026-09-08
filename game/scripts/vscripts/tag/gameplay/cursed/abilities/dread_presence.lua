-- luacheck: globals tag_cursed_dread_presence UF_SUCCESS UF_FAIL_CUSTOM

local Config = require("tag/config/config")

if tag_cursed_dread_presence == nil then
  tag_cursed_dread_presence = class({})
end

-- Server-authoritative cast gate: only the current, non-Staggered IT with
-- enough Fear may start Dread Presence.
function tag_cursed_dread_presence.CastFilterResult(self)
  if not IsServer() then
    return UF_SUCCESS
  end

  local gameMode =
      GameRules.TagGameMode

  local caster =
      self:GetCaster()

  if gameMode == nil
      or caster == nil
      or caster:IsNull()
  then
    self.castError =
        "The Curse is not ready."

    return UF_FAIL_CUSTOM
  end

  local playerID =
      caster:GetPlayerOwnerID()

  if playerID < 0
      or gameMode.tagManager:GetItPlayerID() ~= playerID
  then
    self.castError =
        "Only the Cursed may use Dread Presence."

    return UF_FAIL_CUSTOM
  end

  if gameMode.cursedStabilityManager:IsStaggered(
      playerID
  ) then
    self.castError =
        "The Curse is staggered."

    return UF_FAIL_CUSTOM
  end

  local currentFear =
      gameMode.fearManager:GetCurrent(playerID)

  if currentFear == nil
      or currentFear
          < Config.CURSED.FEAR.COST.DREAD_PRESENCE
  then
    self.castError =
        "Not enough Fear."

    return UF_FAIL_CUSTOM
  end

  self.castError = nil
  return UF_SUCCESS
end

function tag_cursed_dread_presence.GetCustomCastError(self)
  return self.castError or ""
end

-- Fear is the real resource for Cursed abilities; Dota mana remains unused.
function tag_cursed_dread_presence.OnSpellStart(self)
  if not IsServer() then
    return
  end

  local gameMode =
      GameRules.TagGameMode

  local caster =
      self:GetCaster()

  if gameMode == nil
      or caster == nil
      or caster:IsNull()
  then
    self:EndCooldown()
    return
  end

  local playerID =
      caster:GetPlayerOwnerID()

  local currentTime =
      GameRules:GetGameTime()

  local spent =
      gameMode.fearManager:SpendFear(
        playerID,
        Config.CURSED.FEAR.COST.DREAD_PRESENCE,
        "DREAD_PRESENCE",
        currentTime
      )

  if not spent then
    self:EndCooldown()
    return
  end

  caster:RemoveModifierByName(
    "modifier_tag_dread_presence"
  )

  caster:AddNewModifier(
    caster,
    self,
    "modifier_tag_dread_presence",
    {
      duration =
          Config.CURSED.DREAD_PRESENCE.DURATION
    }
  )

  print(string.format(
    "DREAD PRESENCE: Player %d | %.1fs | radius %d",
    playerID,
    Config.CURSED.DREAD_PRESENCE.DURATION,
    Config.CURSED.DREAD_PRESENCE.RADIUS
  ))
end
