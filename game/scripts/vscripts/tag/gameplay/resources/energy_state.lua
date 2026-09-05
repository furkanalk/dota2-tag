local EnergyState = class({})

function EnergyState:Init(maxEnergy, regenPerSecond, currentTime)
  self.max = maxEnergy
  self.current = maxEnergy
  self.regenPerSecond = regenPerSecond
  self.lastUpdateTime = currentTime
end

function EnergyState:GetCurrent()
  return self.current
end

function EnergyState:GetMax()
  return self.max
end

function EnergyState:GetRegenPerSecond()
  return self.regenPerSecond
end

function EnergyState:SetCurrent(value)
  self.current = math.max(
    0,
    math.min(value, self.max)
  )
end

function EnergyState:SetLastUpdateTime(time)
  self.lastUpdateTime = time
end

function EnergyState:GetLastUpdateTime()
  return self.lastUpdateTime
end

function EnergyState:Add(amount)
  local previous = self.current

  self:SetCurrent(
    self.current + amount
  )

  return self.current - previous
end

function EnergyState:Spend(amount)
  if amount < 0 or self.current < amount then
    return false
  end

  self:SetCurrent(
    self.current - amount
  )

  return true
end

return EnergyState
