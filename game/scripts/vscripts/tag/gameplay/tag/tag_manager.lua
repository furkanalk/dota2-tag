local Config = require("tag/config/config")
local PlayerRegistry = require("tag/players/player_registry")
local AbilityLoadout = require("tag/players/ability_loadout")
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

    self.abilityLoadout:SetCursedEnabled(
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

function TagManager:TryPassTo(
    sourcePlayerID,
    targetPlayerID
)
  if sourcePlayerID ~= self.itPlayerID then
    return nil, "rejected"
  end

  if targetPlayerID == sourcePlayerID then
    return nil, "rejected"
  end

  local sourceHero =
      self.players:GetHero(
        sourcePlayerID
      )

  local targetHero =
      self.players:GetHero(
        targetPlayerID
      )

  if not sourceHero
      or sourceHero:IsNull()
      or not sourceHero:IsAlive()
      or not targetHero
      or targetHero:IsNull()
      or not targetHero:IsAlive()
  then
    return nil, "rejected"
  end

  local currentTime =
      GameRules:GetGameTime()

  if currentTime
      < self.tagBackProtectionUntil
      and targetPlayerID
      == self.tagBackProtectedPlayerID
  then
    print(
      "PASS BLOCKED: Player "
      .. targetPlayerID
      .. " has tag-back immunity"
    )

    return nil, "immune"
  end

  local sourcePosition =
      sourceHero:GetAbsOrigin()

  local targetPosition =
      targetHero:GetAbsOrigin()

  local heightDelta =
      math.abs(
        targetPosition.z
        - sourcePosition.z
      )

  if heightDelta
      > Config.PASS.MAX_HEIGHT_DELTA
  then
    print(
      "PASS BLOCKED: height difference"
    )

    return nil, "miss"
  end

  local previousItPlayerID =
      self.itPlayerID

  print(
    "CURSE PASSED: Player "
    .. sourcePlayerID
    .. " -> Player "
    .. targetPlayerID
  )

  self:SetIt(
    targetPlayerID
  )

  self.tagBackProtectedPlayerID =
      previousItPlayerID

  self.tagBackProtectionUntil =
      currentTime
      + Config.PASS.TAG_BACK_IMMUNITY

  return targetPlayerID, "hit"
end

function TagManager:SetIt(playerID)
  if self.itPlayerID == playerID then
    return
  end

  if self.itPlayerID ~= nil then
    self.itState:Remove(self.itPlayerID)

    self.abilityLoadout:SetCursedEnabled(
      self.itPlayerID,
      false
    )
  end

  self.itPlayerID = playerID

  self.itState:Apply(playerID)

  self.abilityLoadout:SetCursedEnabled(
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
