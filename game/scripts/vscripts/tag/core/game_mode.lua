local Config = require("tag/config/config")
local Debug = require("tag/dev/debug")
local CursedStabilityManager = require(
  "tag/gameplay/cursed/cursed_stability_manager"
)
local FearManager = require("tag/gameplay/cursed/fear_manager")
local ImpactManager = require("tag/gameplay/impact/impact_manager")
local TagManager = require("tag/gameplay/tag/tag_manager")
local StabilityManager = require("tag/gameplay/stability/stability_manager")
local RunnerResourceManager = require(
  "tag/gameplay/resources/runner_resource_manager"
)

if TagGameMode == nil then
  TagGameMode = class({})
end


function TagGameMode:Init()
  LinkLuaModifier(
    "modifier_tag_unstable_entry_slow",
    "tag/gameplay/stability/modifiers/modifier_tag_unstable_entry_slow",
    LUA_MODIFIER_MOTION_NONE
  )

  print("TAG GAME LOADED.")

  Debug.Apply()

  self.tagManager = TagManager()
  self.tagManager:Init()

  self.fearManager = FearManager()
  self.fearManager:Init(self.tagManager)

  self.cursedStabilityManager = CursedStabilityManager()
  self.cursedStabilityManager:Init(self.tagManager)

  self.stabilityManager = StabilityManager()
  self.stabilityManager:Init()

  self.resourceManager = RunnerResourceManager()
  self.resourceManager:Init(
    self.tagManager
  )

  self.impactManager = ImpactManager()
  self.impactManager:Init(
    self.stabilityManager,
    self.cursedStabilityManager,
    self.tagManager
  )

  Debug.RegisterCommands(self)

  GameRules:GetGameModeEntity():SetDamageFilter(
    Dynamic_Wrap(
      TagGameMode,
      "DamageFilter"
    ),
    self
  )

  ListenToGameEvent(
    "npc_spawned",
    Dynamic_Wrap(TagGameMode, "OnNPCSpawned"),
    self
  )

  GameRules:GetGameModeEntity():SetThink(
    "OnThink",
    self,
    "GlobalThink",
    Config.GAME.THINK_INTERVAL
  )
end

function TagGameMode:OnNPCSpawned(event)
  local unit = EntIndexToHScript(event.entindex)

  if unit and unit:IsRealHero() then
    self.tagManager:RegisterHero(unit)
    self.stabilityManager:RegisterHero(unit)
    self.resourceManager:RegisterHero(unit)
  end
end

function TagGameMode:OnThink()
  local state = GameRules:State_Get()

  if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    local currentTime = GameRules:GetGameTime()

    self.tagManager:Update()
    self.fearManager:Update(currentTime)
    self.cursedStabilityManager:Update(currentTime)
    self.resourceManager:Update(currentTime)
    self.stabilityManager:Update(currentTime)
  elseif state >= DOTA_GAMERULES_STATE_POST_GAME then
    return nil
  end

  return Config.GAME.THINK_INTERVAL
end

function TagGameMode:DamageFilter(event)
  local victimIndex =
      event.entindex_victim_const

  if victimIndex == nil
      or victimIndex <= 0
  then
    return true
  end

  local victim =
      EntIndexToHScript(victimIndex)

  if not victim
      or victim:IsNull()
      or not victim:IsRealHero()
  then
    return true
  end

  -- Tag Party does not use conventional HP combat.
  event.damage = 0

  local attackerIndex =
      event.entindex_attacker_const

  if attackerIndex == nil
      or attackerIndex <= 0
  then
    return true
  end

  local attacker =
      EntIndexToHScript(attackerIndex)

  if not attacker
      or attacker:IsNull()
      or not attacker:IsRealHero()
  then
    return true
  end

  local inflictorIndex =
      event.entindex_inflictor_const

  local isNormalAttack =
      inflictorIndex == nil
      or inflictorIndex <= 0

  if isNormalAttack then
    local applied, impactResult =
        self.impactManager:TryNormalImpact(
          attacker,
          victim
        )

    if applied then
      local currentTime =
          GameRules:GetGameTime()

      self.resourceManager:OnNormalImpact(
        attacker,
        currentTime
      )

      self.fearManager:OnNormalImpact(
        attacker,
        impactResult,
        currentTime
      )

      self.cursedStabilityManager:OnNormalImpactLanded(
        attacker,
        currentTime
      )
    end
  end

  return true
end

return TagGameMode
