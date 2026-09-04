local PlayerRegistry = require("tag/players/player_registry")
local ItState = require("tag/gameplay/tag/it_state")


if TagManager == nil then
  TagManager = class({})
end


function TagManager:Init()
  self.players = PlayerRegistry()
  self.players:Init()

  self.itState = ItState()
  self.itState:Init(self.players)

  self.itPlayerID = nil
end

function TagManager:RegisterHero(hero)
  local playerID = self.players:Register(hero)

  if playerID == nil then
    return
  end

  print(
    "HERO SPAWNED: "
    .. hero:GetUnitName()
    .. " | Player "
    .. playerID
  )

  if playerID == self.itPlayerID then
    self.itState:Apply(playerID)
  end
end

function TagManager:Update()
  if self.itPlayerID == nil then
    self:SelectRandomIt()
  end
end

function TagManager:SelectRandomIt()
  local candidates =
      self.players:GetAlivePlayerIDs()

  if #candidates == 0 then
    return
  end

  local playerID =
      candidates[RandomInt(1, #candidates)]

  self:SetIt(playerID)
end

function TagManager:SetIt(playerID)
  if self.itPlayerID == playerID then
    return
  end

  if self.itPlayerID ~= nil then
    self.itState:Remove(self.itPlayerID)
  end

  self.itPlayerID = playerID

  self.itState:Apply(playerID)

  local hero =
      self.players:GetHero(playerID)

  print(
    "IT SELECTED: Player "
    .. playerID
    .. " ("
    .. hero:GetUnitName()
    .. ")"
  )
end

return TagManager
