local Config = require("tag/config/config")
local Debug = require("tag/dev/debug")
local TagManager = require("tag/gameplay/tag/tag_manager")


if TagGameMode == nil then
  TagGameMode = class({})
end


function TagGameMode:Init()
  print("TAG GAME LOADED.")

  Debug.Apply()

  self.tagManager = TagManager()
  self.tagManager:Init()

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
  end
end

function TagGameMode:OnThink()
  local state = GameRules:State_Get()

  if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    self.tagManager:Update()
  elseif state >= DOTA_GAMERULES_STATE_POST_GAME then
    return nil
  end

  return Config.GAME.THINK_INTERVAL
end

return TagGameMode
