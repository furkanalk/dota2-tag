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

function StabilityManager:ApplyImpact(
    sourcePlayerID,
    targetPlayerID,
    amount,
    currentTime
)
  local state = self.states[targetPlayerID]

  if state == nil then
    return false, "unregistered"
  end

  if state:GetPhase() == StabilityState.UNSTABLE then
    return false, "unstable"
  end

  local previous = state:GetCurrent()

  state:SetLastImpactTime(currentTime)
  state:SetCurrent(previous - amount)

  local current = state:GetCurrent()

  print(
    "IMPACT: Player "
    .. tostring(sourcePlayerID)
    .. " -> Player "
    .. targetPlayerID
    .. " | "
    .. current
    .. "/"
    .. state:GetMax()
  )

  if previous > 0 and current == 0 then
    state:SetPhase(
      StabilityState.UNSTABLE,
      currentTime
      + Config.STABILITY.UNSTABLE_DURATION
    )

    print(
      "STABILITY BREAK: Player "
      .. targetPlayerID
      .. " -> UNSTABLE"
    )

    return true, "break"
  end

  return true, "hit"
end

return StabilityManager
