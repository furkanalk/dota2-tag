local Config = require("tag/config/config")
local PlayerRegistry = require("tag/players/player_registry")
local AbilityLoadout = require("tag/players/ability_loadout")
local TagCollision = require("tag/gameplay/tag/tag_collision")
local ItState = require("tag/gameplay/tag/it_state")


if TagManager == nil then
  TagManager = class({})
end


function TagManager:Init()
  self.players = PlayerRegistry()
  self.players:Init()

  self.abilityLoadout = AbilityLoadout()
  self.abilityLoadout:Init(self.players)

  self.itState = ItState()
  self.itState:Init(self.players)

  self.itPlayerID = nil

  self.tagBackProtectedPlayerID = nil
  self.tagBackProtectionUntil = -999
end

function TagManager:RegisterHero(hero)
  local playerID = self.players:Register(hero)

  if playerID == nil then
    return
  end

  self.abilityLoadout:Install(playerID)

  print(
    "HERO SPAWNED: "
    .. hero:GetUnitName()
    .. " | Player "
    .. playerID
  )

  if playerID == self.itPlayerID then
    self.itState:Apply(playerID)

    self.abilityLoadout:SetPassEnabled(
      playerID,
      true
    )
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

function TagManager:TryPass(sourcePlayerID)
  if sourcePlayerID ~= self.itPlayerID then
    return false
  end

  local currentTime =
      GameRules:GetGameTime()

  local excludedPlayerID = nil

  if currentTime
      < self.tagBackProtectionUntil
  then
    excludedPlayerID =
        self.tagBackProtectedPlayerID
  end

  local targetPlayerID =
      TagCollision.FindTargetInCone(
        self.players:GetHeroes(),
        sourcePlayerID,
        Config.PASS_RANGE,
        Config.PASS_CONE_HALF_ANGLE,
        excludedPlayerID
      )

  if targetPlayerID == nil then
    print(
      "PASS MISSED: Player "
      .. sourcePlayerID
    )

    return false
  end

  local previousItPlayerID =
      self.itPlayerID

  print(
    "CURSE PASSED: Player "
    .. sourcePlayerID
    .. " -> Player "
    .. targetPlayerID
  )

  self:SetIt(targetPlayerID)

  self.tagBackProtectedPlayerID =
      previousItPlayerID

  self.tagBackProtectionUntil =
      currentTime
      + Config.TAG_BACK_IMMUNITY

  return true
end

function TagManager:SetIt(playerID)
  if self.itPlayerID == playerID then
    return
  end

  if self.itPlayerID ~= nil then
    self.itState:Remove(self.itPlayerID)

    self.abilityLoadout:SetPassEnabled(
      self.itPlayerID,
      false
    )
  end

  self.itPlayerID = playerID

  self.itState:Apply(playerID)

  self.abilityLoadout:SetPassEnabled(
    playerID,
    true
  )

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
