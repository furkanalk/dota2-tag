-- luacheck: globals tag_cursed_pass_the_curse UF_SUCCESS UF_FAIL_CUSTOM

local Config = require("tag/config/config")

if tag_cursed_pass_the_curse == nil then
  tag_cursed_pass_the_curse = class({})
end

local ERROR_TEXT = {
  not_cursed = "Only the Cursed may use Pass the Curse.",
  invalid_caster = "The Curse is not ready.",
  cursed_stagger = "The Curse is staggered.",
  already_arming = "The Curse is already reaching.",
  fizzle_recovery = "The Curse is recovering."
}

local function GetPassManager()
  local gameMode = GameRules.TagGameMode

  if gameMode == nil then
    return nil
  end

  return gameMode.passTheCurseManager
end

function tag_cursed_pass_the_curse.CastFilterResult(self)
  if not IsServer() then
    return UF_SUCCESS
  end

  local caster = self:GetCaster()
  local manager = GetPassManager()

  if caster == nil
      or caster:IsNull()
      or manager == nil
  then
    self.castError = "The Curse is not ready."
    return UF_FAIL_CUSTOM
  end

  local playerID = caster:GetPlayerOwnerID()

  local allowed, reason =
      manager:CanBegin(
        playerID,
        GameRules:GetGameTime()
      )

  if not allowed then
    self.castError =
        ERROR_TEXT[reason]
        or "Pass the Curse is unavailable."

    return UF_FAIL_CUSTOM
  end

  self.castError = nil
  return UF_SUCCESS
end

function tag_cursed_pass_the_curse.GetCustomCastError(self)
  return self.castError or ""
end

-- The native E press starts the authoritative arming transaction.
-- Final key-release targeting is supplied by the Panorama input adapter;
-- until that adapter lands, debug commands can release to a player ID.
function tag_cursed_pass_the_curse.OnSpellStart(self)
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()
  local manager = GetPassManager()

  if caster == nil
      or caster:IsNull()
      or manager == nil
  then
    return
  end

  local playerID = caster:GetPlayerOwnerID()

  local started =
      manager:Begin(
        playerID,
        GameRules:GetGameTime()
      )

  if not started then
    self:EndCooldown()
  end
end
