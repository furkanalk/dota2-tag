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

  local phase = state:GetPhase()

  if phase == StabilityState.UNSTABLE then
    return false, "unstable"
  end

  local previous = state:GetCurrent()

  state:SetLastImpactTime(currentTime)

  -- Regen starts only after both the no-impact delay and one regen interval.
  state:SetNextRegenTime(
    currentTime
    + Config.STABILITY.REGEN_DELAY
    + Config.STABILITY.REGEN_INTERVAL
  )

  local nextStability =
      previous - amount

  -- BRACED can still be pressured, but cannot be broken again.
  if phase == StabilityState.BRACED then
    nextStability = math.max(
      Config.STABILITY.BRACED_MINIMUM,
      nextStability
    )
  end

  state:SetCurrent(nextStability)

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

function StabilityManager:Update(currentTime)
  for playerID, state in pairs(self.states) do
    local phase = state:GetPhase()
    local phaseUntil = state:GetPhaseUntil()

    if phase == StabilityState.UNSTABLE
        and phaseUntil ~= nil
        and currentTime >= phaseUntil
    then
      state:SetCurrent(
        Config.STABILITY.BRACED_RESTORE
      )

      -- Use the scheduled expiry so server hitches do not extend state windows.
      local bracedUntil =
          phaseUntil
          + Config.STABILITY.BRACED_DURATION

      state:SetPhase(
        StabilityState.BRACED,
        bracedUntil
      )

      print(
        "STABILITY RECOVERED: Player "
        .. playerID
        .. " -> BRACED | "
        .. state:GetCurrent()
        .. "/"
        .. state:GetMax()
      )

      phase = StabilityState.BRACED
      phaseUntil = bracedUntil
    end

    if phase == StabilityState.BRACED
        and phaseUntil ~= nil
        and currentTime >= phaseUntil
    then
      state:SetPhase(
        StabilityState.NORMAL,
        nil
      )

      print(
        "STABILITY STATE: Player "
        .. playerID
        .. " -> NORMAL"
      )
    end

    StabilityManager.UpdateRegen(
      playerID,
      state,
      currentTime
    )
  end
end

function StabilityManager.UpdateRegen(
    playerID,
    state,
    currentTime
)
  if state:GetPhase() == StabilityState.UNSTABLE then
    return
  end

  if state:GetCurrent() >= state:GetMax() then
    state:SetNextRegenTime(nil)
    return
  end

  local nextRegenTime =
      state:GetNextRegenTime()

  if nextRegenTime == nil
      or currentTime < nextRegenTime
  then
    return
  end

  local interval =
      Config.STABILITY.REGEN_INTERVAL

  -- Catch up deterministically if a server tick arrives late.
  local regenTicks =
      math.floor(
        (currentTime - nextRegenTime)
        / interval
      ) + 1

  state:SetCurrent(
    state:GetCurrent()
    + regenTicks
  )

  if state:GetCurrent() >= state:GetMax() then
    state:SetNextRegenTime(nil)
  else
    state:SetNextRegenTime(
      nextRegenTime
      + regenTicks * interval
    )
  end

  print(
    "STABILITY REGEN: Player "
    .. playerID
    .. " | "
    .. state:GetCurrent()
    .. "/"
    .. state:GetMax()
  )
end

return StabilityManager
