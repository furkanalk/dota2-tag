local CursedStabilityState = class({})

CursedStabilityState.NORMAL = "NORMAL"
CursedStabilityState.STAGGER = "STAGGER"
CursedStabilityState.RESOLVE = "RESOLVE"

function CursedStabilityState:Init(maxStability, currentTime)
  self.maxStability = maxStability
  self.currentStability = maxStability
  self.phase = CursedStabilityState.NORMAL
  self.phaseUntil = nil
  self.lastCombatTime = currentTime
  self.nextRegenTime = nil
end

function CursedStabilityState:GetCurrent()
  return self.currentStability
end

function CursedStabilityState:GetMax()
  return self.maxStability
end

function CursedStabilityState:SetCurrent(value)
  self.currentStability = math.max(0, math.min(value, self.maxStability))
end

function CursedStabilityState:GetPhase()
  return self.phase
end

function CursedStabilityState:GetPhaseUntil()
  return self.phaseUntil
end

function CursedStabilityState:SetPhase(phase, phaseUntil)
  self.phase = phase
  self.phaseUntil = phaseUntil
end

function CursedStabilityState:GetLastCombatTime()
  return self.lastCombatTime
end

function CursedStabilityState:SetLastCombatTime(currentTime)
  self.lastCombatTime = currentTime
end

function CursedStabilityState:GetNextRegenTime()
  return self.nextRegenTime
end

function CursedStabilityState:SetNextRegenTime(value)
  self.nextRegenTime = value
end

function CursedStabilityState:Add(amount)
  if amount <= 0 then
    return 0
  end

  local previous = self.currentStability
  self:SetCurrent(self.currentStability + amount)
  return self.currentStability - previous
end

return CursedStabilityState
