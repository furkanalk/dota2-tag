local Config = require("tag/config/config")

if modifier_tag_curse_leap_motion == nil then
  modifier_tag_curse_leap_motion = class({})
end


function modifier_tag_curse_leap_motion.IsHidden()
  return true
end

function modifier_tag_curse_leap_motion.IsPurgable()
  return false
end

function modifier_tag_curse_leap_motion:OnCreated(params)
  if not IsServer() then
    return
  end

  self.distance =
      tonumber(params.distance) or 0

  self.duration =
      self:GetDuration()

  self.traveled = 0

  if self.distance <= 0
      or self.duration <= 0
  then
    self:Destroy()
    return
  end

  local parent = self:GetParent()
  local forward = parent:GetForwardVector()

  local length =
      math.sqrt(
        forward.x * forward.x
        + forward.y * forward.y
      )

  if length <= 0 then
    self:Destroy()
    return
  end

  self.direction =
      Vector(
        forward.x / length,
        forward.y / length,
        0
      )

  self.speed =
      self.distance / self.duration

  if not self:ApplyHorizontalMotionController() then
    self:Destroy()
  end
end

function modifier_tag_curse_leap_motion:UpdateHorizontalMotion(
    parent,
    deltaTime
)
  if not IsServer() then
    return
  end

  local remaining =
      self.distance - self.traveled

  if remaining <= 0 then
    self:Destroy()
    return
  end

  local step =
      math.min(
        self.speed * deltaTime,
        remaining
      )

  local currentPosition =
      parent:GetAbsOrigin()

  local nextPosition =
      currentPosition
      + self.direction * step

  if not GridNav:IsTraversable(nextPosition)
      or GridNav:IsBlocked(nextPosition)
  then
    self:Destroy()
    return
  end

  local currentGroundHeight =
      GetGroundHeight(
        currentPosition,
        parent
      )

  local nextGroundHeight =
      GetGroundHeight(
        nextPosition,
        parent
      )

  local heightDelta =
      math.abs(
        nextGroundHeight
        - currentGroundHeight
      )

  if heightDelta
      > Config.LEAP.MAX_STEP_HEIGHT
  then
    self:Destroy()
    return
  end

  nextPosition.z =
      nextGroundHeight

  parent:SetAbsOrigin(nextPosition)

  self.traveled =
      self.traveled + step

  if self.traveled >= self.distance then
    self:Destroy()
  end
end

function modifier_tag_curse_leap_motion:OnHorizontalMotionInterrupted()
  if not IsServer() then
    return
  end

  self:Destroy()
end

function modifier_tag_curse_leap_motion:OnDestroy()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  if not parent
      or parent:IsNull()
  then
    return
  end

  parent:RemoveHorizontalMotionController(
    self
  )

  FindClearSpaceForUnit(
    parent,
    parent:GetAbsOrigin(),
    true
  )
end
