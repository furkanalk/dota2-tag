local Config = require("tag/config/config")

local ImpactManager = class({})


local function IsValidHero(hero)
  return hero
      and not hero:IsNull()
      and hero:IsRealHero()
      and hero:IsAlive()
end


function ImpactManager:Init(stabilityManager)
  self.stability = stabilityManager
  self.nextNormalImpactTime = {}
end

function ImpactManager:TryNormalImpact(
    attacker,
    target
)
  if not IsValidHero(attacker)
      or not IsValidHero(target)
  then
    return false, "invalid"
  end

  local sourcePlayerID =
      attacker:GetPlayerOwnerID()

  local targetPlayerID =
      target:GetPlayerOwnerID()

  if sourcePlayerID < 0
      or targetPlayerID < 0
      or sourcePlayerID == targetPlayerID
  then
    return false, "invalid"
  end

  local currentTime =
      GameRules:GetGameTime()

  local nextAllowed =
      self.nextNormalImpactTime[
      sourcePlayerID
      ] or -999

  if currentTime < nextAllowed then
    return false, "cadence"
  end

  self.nextNormalImpactTime[
  sourcePlayerID
  ] =
      currentTime
      + Config.IMPACT.NORMAL_CADENCE

  return self.stability:ApplyImpact(
    sourcePlayerID,
    targetPlayerID,
    Config.IMPACT.NORMAL_AMOUNT,
    currentTime
  )
end

return ImpactManager
