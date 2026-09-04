local PlayerRegistry = class({})

function PlayerRegistry:Init()
  self.heroes = {}
end

function PlayerRegistry:Register(hero)
  local playerID = hero:GetPlayerOwnerID()

  if playerID < 0 then
    return nil
  end

  self.heroes[playerID] = hero

  return playerID
end

function PlayerRegistry:GetHero(playerID)
  return self.heroes[playerID]
end

function PlayerRegistry:GetHeroes()
  return self.heroes
end

function PlayerRegistry:GetAlivePlayerIDs()
  local result = {}

  for playerID, hero in pairs(self.heroes) do
    if hero
        and not hero:IsNull()
        and hero:IsRealHero()
        and hero:IsAlive()
    then
      table.insert(result, playerID)
    end
  end

  return result
end

return PlayerRegistry
