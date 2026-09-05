local Config = require("tag/config/config")
local StabilityState = require(
  "tag/gameplay/stability/stability_state"
)

local StabilityManager = class({})

local function GetRegenInterval(state, nextSegment)
  local profileName =
      state:GetRegenProfile()
      or Config.STABILITY.DEFAULT_REGEN_PROFILE

  local profile =
      Config.STABILITY.REGEN_PROFILES[profileName]
      or Config.STABILITY.REGEN_PROFILES.NORMAL

  local maxStability = state:GetMax()
  local progress = 1

  if maxStability > 1 then
    progress =
        (nextSegment - 1)
        / (maxStability - 1)
  end

  progress = math.max(
    0,
    math.min(progress, 1)
  )

  return profile.BASE
      + profile.RAMP
      * math.pow(progress, 1.5)
end

local function ScheduleNextRegen(
    state,
    earliestStartTime
)
  if state:GetCurrent() >= state:GetMax() then
    state:SetNextRegenTime(nil)
    return
  end

  local nextSegment =
      state:GetCurrent() + 1

  state:SetNextRegenTime(
    earliestStartTime
    + GetRegenInterval(
      state,
      nextSegment
    )
  )
end

function StabilityManager:Init()
  self.states = {}
  self.heroes = {}
end

function StabilityManager:RegisterHero(hero)
  local playerID = hero:GetPlayerOwnerID()

  if playerID < 0 then
    return nil
  end

  -- Refresh the hero handle after respawns without resetting Stability.
  self.heroes[playerID] = hero

  if self.states[playerID] ~= nil then
    return self.states[playerID]
  end

  local heroName = hero:GetUnitName()

  local maxStability =
      Config.STABILITY.HERO_MAX[heroName]
      or Config.STABILITY.DEFAULT_MAX

  local regenProfile =
      Config.STABILITY.HERO_REGEN_PROFILE[heroName]
      or Config.STABILITY.DEFAULT_REGEN_PROFILE

  local state = StabilityState()
  state:Init(
    maxStability,
    regenProfile
  )

  self.states[playerID] = state

  print(
    "STABILITY REGISTERED: Player "
    .. playerID
    .. " | "
    .. maxStability
    .. "/"
    .. maxStability
    .. " | "
    .. regenProfile
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
  local nextStability = previous - amount

  state:SetLastImpactTime(currentTime)
  state:SetCurrent(nextStability)

  local current = state:GetCurrent()

  if previous > 0 and current == 0 then
    state:SetNextRegenTime(nil)

    state:SetPhase(
      StabilityState.UNSTABLE,
      currentTime
      + Config.STABILITY.UNSTABLE_DURATION
    )

    local hero =
        self.heroes[targetPlayerID]

    if hero
        and not hero:IsNull()
    then
      hero:AddNewModifier(
        hero,
        nil,
        "modifier_tag_unstable_entry_slow",
        {
          duration =
              Config.STABILITY.UNSTABLE_DURATION
        }
      )
    end

    print(
      "STABILITY BREAK: Player "
      .. targetPlayerID
      .. " -> UNSTABLE"
    )

    return true, "break"
  end

  ScheduleNextRegen(
    state,
    currentTime
    + Config.STABILITY.REGEN_DELAY
  )

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
      StabilityManager.ResolveUnstable(
        playerID,
        state,
        phaseUntil
      )
    end

    StabilityManager.UpdateRegen(
      playerID,
      state,
      currentTime
    )
  end
end

function StabilityManager.ResolveUnstable(
    playerID,
    state,
    resolutionTime
)
  state:SetCurrent(
    math.min(
      1,
      state:GetMax()
    )
  )

  state:SetPhase(
    StabilityState.NORMAL,
    nil
  )

  local earliestStartTime =
      resolutionTime

  local lastImpactTime =
      state:GetLastImpactTime()

  if lastImpactTime ~= nil then
    earliestStartTime =
        math.max(
          earliestStartTime,
          lastImpactTime
          + Config.STABILITY.REGEN_DELAY
        )
  end

  ScheduleNextRegen(
    state,
    earliestStartTime
  )

  print(
    "STABILITY RECOVERED: Player "
    .. playerID
    .. " -> NORMAL | "
    .. state:GetCurrent()
    .. "/"
    .. state:GetMax()
  )
end

function StabilityManager.UpdateRegen(
    playerID,
    state,
    currentTime
)
  if state:GetPhase() ~= StabilityState.NORMAL then
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

  while nextRegenTime ~= nil
    and currentTime >= nextRegenTime
    and state:GetCurrent() < state:GetMax()
  do
    local interval =
        GetRegenInterval(
          state,
          state:GetCurrent() + 1
        )

    state:SetCurrent(
      state:GetCurrent() + 1
    )

    print(string.format(
      "STABILITY REGEN: Player %d | %d/%d | t=%.2f | interval=%.2f",
      playerID,
      state:GetCurrent(),
      state:GetMax(),
      GameRules:GetGameTime(),
      interval
    ))

    if state:GetCurrent() >= state:GetMax() then
      state:SetNextRegenTime(nil)
      nextRegenTime = nil
    else
      local nextSegment =
          state:GetCurrent() + 1

      nextRegenTime =
          nextRegenTime
          + GetRegenInterval(
            state,
            nextSegment
          )

      state:SetNextRegenTime(
        nextRegenTime
      )
    end
  end
end

return StabilityManager
