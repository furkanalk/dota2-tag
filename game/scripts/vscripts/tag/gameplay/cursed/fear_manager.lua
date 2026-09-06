local Config = require("tag/config/config")
local FearState = require(
  "tag/gameplay/cursed/fear_state"
)

local FearManager = class({})

local function ValidateConfig()
  local fear = Config.CURSED
      and Config.CURSED.FEAR

  assert(
    type(fear) == "table",
    "Config.CURSED.FEAR must exist"
  )

  local requiredNumbers = {
    "MAX",
    "POSSESSION_START",
    "DECAY_DELAY",
    "DECAY_PER_SECOND"
  }

  for _, key in ipairs(requiredNumbers) do
    assert(
      type(fear[key]) == "number",
      "Config.CURSED.FEAR."
      .. key
      .. " must be a number"
    )
  end

  assert(
    fear.MAX > 0,
    "Config.CURSED.FEAR.MAX must be > 0"
  )

  assert(
    fear.POSSESSION_START >= 0
      and fear.POSSESSION_START <= fear.MAX,
    "Config.CURSED.FEAR.POSSESSION_START must be within 0..MAX"
  )

  assert(
    fear.DECAY_DELAY >= 0,
    "Config.CURSED.FEAR.DECAY_DELAY must be >= 0"
  )

  assert(
    fear.DECAY_PER_SECOND >= 0,
    "Config.CURSED.FEAR.DECAY_PER_SECOND must be >= 0"
  )
end

function FearManager:Init(tagManager)
  ValidateConfig()

  self.tagManager = tagManager
  self.ownerPlayerID = nil
  self.state = nil
end

function FearManager:GetOwnerPlayerID()
  return self.ownerPlayerID
end

function FearManager:GetState(playerID)
  if playerID ~= self.ownerPlayerID then
    return nil
  end

  return self.state
end

function FearManager:GetCurrent(playerID)
  local state = self:GetState(playerID)
  return state and state:GetCurrent() or nil
end

function FearManager:GetMax(playerID)
  local state = self:GetState(playerID)
  return state and state:GetMax() or nil
end

function FearManager:IsCurrentIt(playerID)
  return self.tagManager:GetItPlayerID() == playerID
end

function FearManager:SyncPossession(currentTime)
  local currentItPlayerID =
      self.tagManager:GetItPlayerID()

  if currentItPlayerID == self.ownerPlayerID then
    return
  end

  if self.ownerPlayerID ~= nil then
    print(
      "FEAR POSSESSION END: Player "
      .. self.ownerPlayerID
    )
  end

  self.ownerPlayerID = currentItPlayerID
  self.state = nil

  if currentItPlayerID == nil then
    return
  end

  local fearConfig = Config.CURSED.FEAR
  local state = FearState()

  state:Init(
    fearConfig.MAX,
    fearConfig.POSSESSION_START,
    currentTime
  )

  self.state = state

  print(string.format(
    "FEAR POSSESSION START: Player %d | %.1f/%d",
    currentItPlayerID,
    state:GetCurrent(),
    state:GetMax()
  ))
end

function FearManager:UpdateDecay(currentTime)
  local state = self.state

  if state == nil then
    return
  end

  local lastUpdateTime =
      state:GetLastUpdateTime()

  state:SetLastUpdateTime(currentTime)

  if lastUpdateTime == nil
      or state:GetCurrent() <= 0
  then
    return
  end

  local lastHuntEventTime =
      state:GetLastHuntEventTime()
      or lastUpdateTime

  local decayStart =
      lastHuntEventTime
      + Config.CURSED.FEAR.DECAY_DELAY

  if currentTime <= decayStart then
    return
  end

  local effectiveStart =
      math.max(lastUpdateTime, decayStart)

  local deltaTime =
      math.max(0, currentTime - effectiveStart)

  if deltaTime <= 0 then
    return
  end

  state:Remove(
    Config.CURSED.FEAR.DECAY_PER_SECOND
    * deltaTime
  )
end

function FearManager:Update(currentTime)
  self:SyncPossession(currentTime)
  self:UpdateDecay(currentTime)
end

function FearManager:AddFear(
    playerID,
    amount,
    source,
    currentTime
)
  self:SyncPossession(currentTime)

  if playerID ~= self.ownerPlayerID
      or self.state == nil
      or amount <= 0
  then
    return 0
  end

  self:UpdateDecay(currentTime)

  local gained = self.state:Add(amount)

  -- A valid Fear-generating hunt event keeps the hunt warm
  -- even when Fear is already capped.
  self.state:SetLastHuntEventTime(currentTime)
  self.state:SetLastUpdateTime(currentTime)

  if gained > 0 then
    print(string.format(
      "FEAR GAIN: Player %d | +%.1f | %.1f/%d | %s",
      playerID,
      gained,
      self.state:GetCurrent(),
      self.state:GetMax(),
      tostring(source)
    ))
  end

  return gained
end

function FearManager:SpendFear(
    playerID,
    amount,
    source,
    currentTime
)
  self:SyncPossession(currentTime)

  if playerID ~= self.ownerPlayerID
      or self.state == nil
      or amount < 0
  then
    return false
  end

  self:UpdateDecay(currentTime)

  if not self.state:Spend(amount) then
    return false
  end

  print(string.format(
    "FEAR SPEND: Player %d | -%.1f | %.1f/%d | %s",
    playerID,
    amount,
    self.state:GetCurrent(),
    self.state:GetMax(),
    tostring(source)
  ))

  return true
end

function FearManager:OnNormalImpact(
    attacker,
    impactResult,
    currentTime
)
  if attacker == nil
      or attacker:IsNull()
      or not attacker:IsRealHero()
  then
    return 0
  end

  local playerID =
      attacker:GetPlayerOwnerID()

  if playerID < 0
      or not self:IsCurrentIt(playerID)
  then
    return 0
  end

  local gained = self:AddFear(
    playerID,
    Config.CURSED.FEAR.GAIN.NORMAL_IMPACT,
    "NORMAL_IMPACT",
    currentTime
  )

  if impactResult == "break" then
    gained = gained + self:AddFear(
      playerID,
      Config.CURSED.FEAR.GAIN.STABILITY_BREAK,
      "STABILITY_BREAK",
      currentTime
    )
  end

  return gained
end

return FearManager
