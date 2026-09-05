local StabilityState = class({})

StabilityState.NORMAL = "NORMAL"
StabilityState.UNSTABLE = "UNSTABLE"

function StabilityState:Init(maxStability, regenProfile)
  self.max = maxStability
  self.current = maxStability
  self.regenProfile = regenProfile
  self.phase = StabilityState.NORMAL

  self.lastImpactTime = nil
  self.nextRegenTime = nil
  self.phaseUntil = nil
end

function StabilityState:GetCurrent()
  return self.current
end

function StabilityState:GetMax()
  return self.max
end

function StabilityState:GetRegenProfile()
  return self.regenProfile
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

function StabilityState:SetNextRegenTime(time)
  self.nextRegenTime = time
end

function StabilityState:GetNextRegenTime()
  return self.nextRegenTime
end

function StabilityState:GetPhaseUntil()
  return self.phaseUntil
end

function StabilityState:SetPhase(phase, phaseUntil)
  self.phase = phase
  self.phaseUntil = phaseUntil
end

return StabilityState
