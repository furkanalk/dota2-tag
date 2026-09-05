local MomentumState = class({})

function MomentumState:Init(maxMomentum, currentTime)
  self.max = maxMomentum
  self.current = 0
  self.decayGraceUntil = nil
  self.decayProgress = 0
  self.lastUpdateTime = currentTime
  self.lastPosition = nil
end

function MomentumState:GetCurrent()
  return self.current
end

function MomentumState:GetMax()
  return self.max
end

function MomentumState:SetCurrent(value)
  self.current = math.max(
    0,
    math.min(value, self.max)
  )
end

function MomentumState:Add(amount)
  local previous = self.current

  self:SetCurrent(
    self.current + amount
  )

  return self.current - previous
end

function MomentumState:Clear()
  self.current = 0
  self.decayGraceUntil = nil
  self.decayProgress = 0
end

function MomentumState:SetDecayGraceUntil(time)
  self.decayGraceUntil = time
end

function MomentumState:GetDecayGraceUntil()
  return self.decayGraceUntil
end

function MomentumState:SetDecayProgress(value)
  self.decayProgress = math.max(0, value)
end

function MomentumState:GetDecayProgress()
  return self.decayProgress
end

function MomentumState:SetLastUpdateTime(time)
  self.lastUpdateTime = time
end

function MomentumState:GetLastUpdateTime()
  return self.lastUpdateTime
end

function MomentumState:SetLastPosition(position)
  self.lastPosition = position
end

function MomentumState:GetLastPosition()
  return self.lastPosition
end

return MomentumState
