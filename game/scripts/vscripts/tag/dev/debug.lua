local Config = require("tag/config/config")

local Debug = {}


function Debug.Apply()
  if not Config.DEBUG_MODE then
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

return Debug
