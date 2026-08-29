local Config = require("tag/config/config")
local PlayerRegistry = require("tag/players/player_registry")
local TagCollision = require("tag/gameplay/tag/tag_collision")
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
  self.lastTagTime = -999
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

  -- If the current IT hero respawned,
  -- re-apply its IT state.
  if playerID == self.itPlayerID then
    self.itState:Apply(playerID)
  end
end

function TagManager:Update()
  if self.itPlayerID == nil then
    self:SelectRandomIt()
    return
  end

  self:CheckForTag()
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

function TagManager:CheckForTag()
  local currentTime =
      GameRules:GetGameTime()

  if currentTime - self.lastTagTime
      < Config.TAG_COOLDOWN then
    return
  end

  local targetPlayerID =
      TagCollision.FindTarget(
        self.players:GetHeroes(),
        self.itPlayerID,
        Config.TAG_DISTANCE
      )

  if targetPlayerID == nil then
    return
  end

  print(
    "TAG! Player "
    .. self.itPlayerID
    .. " -> Player "
    .. targetPlayerID
  )

  self:SetIt(targetPlayerID)
end

function TagManager:SetIt(playerID)
  if self.itPlayerID == playerID then
    return
  end

  -- Remove IT state from previous player.
  if self.itPlayerID ~= nil then
    self.itState:Remove(self.itPlayerID)
  end

  self.itPlayerID = playerID
  self.lastTagTime = GameRules:GetGameTime()

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
