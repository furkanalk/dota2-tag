local TagCollision = {}

function TagCollision.FindTarget(
    heroes,
    itPlayerID,
    maxDistance
)
  local itHero = heroes[itPlayerID]

  if not itHero
      or itHero:IsNull()
      or not itHero:IsAlive()
  then
    return nil
  end

  local origin = itHero:GetAbsOrigin()

  for playerID, hero in pairs(heroes) do
    if playerID ~= itPlayerID
        and hero
        and not hero:IsNull()
        and hero:IsRealHero()
        and hero:IsAlive()
    then
      local distance =
          (hero:GetAbsOrigin() - origin):Length2D()

      if distance <= maxDistance then
        return playerID
      end
    end
  end

  return nil
end

return TagCollision
