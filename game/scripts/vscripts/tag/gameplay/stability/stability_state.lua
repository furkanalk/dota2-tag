local StabilityState = class({})

StabilityState.NORMAL = "NORMAL"
StabilityState.UNSTABLE = "UNSTABLE"
StabilityState.BRACED = "BRACED"

function StabilityState:Init(maxStability)
  self.max = maxStability
  self.current = maxStability
  self.phase = StabilityState.NORMAL

  self.lastImpactTime = nil
  self.phaseUntil = nil
end

function StabilityState:GetCurrent()
  return self.current
end

function StabilityState:GetMax()
  return self.max
end

function StabilityState:GetPhase()
  return self.phase
end

function StabilityState:SetCurrent(value)
  self.current = math.max(
    0,
    math.min(value, self.max)
  )
end

function StabilityState:SetLastImpactTime(time)
  self.lastImpactTime = time
end

function StabilityState:GetLastImpactTime()
  return self.lastImpactTime
end

function StabilityState:GetPhaseUntil()
  return self.phaseUntil
end

function StabilityState:SetPhase(phase, phaseUntil)
  self.phase = phase
  self.phaseUntil = phaseUntil
end

return StabilityState
