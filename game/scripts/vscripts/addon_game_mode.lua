local TagGameMode = require("tag/core/game_mode")
local Config = require("tag/config/config")


function Precache(context)
	PrecacheResource(
		"particle",
		Config.IT_RING_PARTICLE,
		context
	)
end

function Activate()
	GameRules.TagGameMode = TagGameMode()
	GameRules.TagGameMode:Init()
end
