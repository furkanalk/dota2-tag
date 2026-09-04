local Config = require("tag/config/config")
local StabilityState = require(
  "tag/gameplay/stability/stability_state"
)

local StabilityManager = class({})

function StabilityManager:Init()
  self.states = {}
end

function StabilityManager:RegisterHero(hero)
  local playerID = hero:GetPlayerOwnerID()

  if playerID < 0 then
    return nil
  end

  if self.states[playerID] ~= nil then
    return self.states[playerID]
  end

  local maxStability =
      Config.STABILITY.HERO_MAX[
      hero:GetUnitName()
      ]
      or Config.STABILITY.DEFAULT_MAX

  local state = StabilityState()
  state:Init(maxStability)

  self.states[playerID] = state

  print(
    "STABILITY REGISTERED: Player "
    .. playerID
    .. " | "
    .. maxStability
    .. "/"
    .. maxStability
  )

  return state
end

function StabilityManager:GetState(playerID)
  return self.states[playerID]
end

function StabilityManager:GetCurrent(playerID)
  local state = self.states[playerID]

  if state == nil then
    return nil
  end

  return state:GetCurrent()
end

function StabilityManager:GetMax(playerID)
  local state = self.states[playerID]

  if state == nil then
    return nil
  end

  return state:GetMax()
end

function StabilityManager:GetPhase(playerID)
  local state = self.states[playerID]

  if state == nil then
    return nil
  end

  return state:GetPhase()
end

return StabilityManager
