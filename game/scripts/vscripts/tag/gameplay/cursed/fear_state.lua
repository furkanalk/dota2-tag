local FearState = class({})

function FearState:Init(
    maxFear,
    startingFear,
    currentTime
)
  self.maxFear = maxFear
  self.currentFear = 0
  self.lastHuntEventTime = currentTime
  self.lastUpdateTime = currentTime

  self:SetCurrent(startingFear)
end

function FearState:GetCurrent()
  return self.currentFear
end

function FearState:GetMax()
  return self.maxFear
end

function FearState:SetCurrent(value)
  self.currentFear = math.max(
    0,
    math.min(value, self.maxFear)
  )
end

function FearState:Add(amount)
  if amount <= 0 then
    return 0
  end

  local previous = self.currentFear

  self:SetCurrent(
    self.currentFear + amount
  )

  return self.currentFear - previous
end

function FearState:Remove(amount)
  if amount <= 0 then
    return 0
  end

  local previous = self.currentFear

  self:SetCurrent(
    self.currentFear - amount
  )

  return previous - self.currentFear
end

function FearState:CanSpend(amount)
  return amount >= 0
      and self.currentFear >= amount
end

function FearState:Spend(amount)
  if not self:CanSpend(amount) then
    return false
  end

  self:SetCurrent(
    self.currentFear - amount
  )

  return true
end

function FearState:GetLastHuntEventTime()
  return self.lastHuntEventTime
end

function FearState:SetLastHuntEventTime(currentTime)
  self.lastHuntEventTime = currentTime
end

function FearState:GetLastUpdateTime()
  return self.lastUpdateTime
end

function FearState:SetLastUpdateTime(currentTime)
  self.lastUpdateTime = currentTime
end

return FearState
