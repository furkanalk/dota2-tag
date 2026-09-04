local TagCollision = {}

local function IsValidHero(hero)
  return hero
      and not hero:IsNull()
      and hero:IsRealHero()
      and hero:IsAlive()
end

local function IsValidTarget(
    playerID,
    hero,
    itPlayerID,
    excludedPlayerID
)
  if playerID == itPlayerID then
    return false
  end

  if playerID == excludedPlayerID then
    return false
  end

  return IsValidHero(hero)
end

local function GetConeDistance(
    hero,
    origin,
    forward,
    maxDistance,
    minDot,
    maxHeightDelta
)
  local offset =
      hero:GetAbsOrigin() - origin

  if math.abs(offset.z) > maxHeightDelta then
    return nil
  end

  local distance = offset:Length2D()

  if distance <= 0
      or distance > maxDistance
  then
    return nil
  end

  local dot =
      (
        offset.x * forward.x
        + offset.y * forward.y
      ) / distance

  if dot < minDot then
    return nil
  end

  return distance
end

function TagCollision.FindTargetInCone(
    heroes,
    itPlayerID,
    maxDistance,
    halfAngleDegrees,
    maxHeightDelta,
    excludedPlayerID
)
  local itHero = heroes[itPlayerID]

  if not IsValidHero(itHero) then
    return nil
  end

  local origin = itHero:GetAbsOrigin()
  local forward = itHero:GetForwardVector()

  local minDot =
      math.cos(math.rad(halfAngleDegrees))

  local bestPlayerID = nil
  local bestDistance = nil

  for playerID, hero in pairs(heroes) do
    if IsValidTarget(
          playerID,
          hero,
          itPlayerID,
          excludedPlayerID
        ) then
      local distance =
          GetConeDistance(
            hero,
            origin,
            forward,
            maxDistance,
            minDot,
            maxHeightDelta
          )

      if distance
          and (
            bestDistance == nil
            or distance < bestDistance
          )
      then
        bestPlayerID = playerID
        bestDistance = distance
      end
    end
  end

  return bestPlayerID
end

return TagCollision
