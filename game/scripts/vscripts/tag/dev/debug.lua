local Config = require("tag/config/config")
local ResourceCommands = require("tag/dev/commands/resource_commands")
local TagCommands = require("tag/dev/commands/tag_commands")

local Debug = {}

function Debug.Apply()
  if not Config.GAME.DEBUG_MODE then
    return
  end

  print("DEBUG MODE ENABLED.")

  GameRules:SetHeroSelectionTime(0)
  GameRules:SetStrategyTime(0)
  GameRules:SetShowcaseTime(0)
  GameRules:SetPreGameTime(0)

  GameRules:GetGameModeEntity():SetFixedRespawnTime(1)

  SendToServerConsole("sv_cheats 1")
end

function Debug.RegisterCommands(gameMode)
  if not Config.GAME.DEBUG_MODE then
    return
  end

  ResourceCommands.Register(gameMode)
  TagCommands.Register(gameMode)
end

return Debug
