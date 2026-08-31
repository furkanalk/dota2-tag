local TagGameMode = require("tag/core/game_mode")
local Config = require("tag/config/config")

function Precache(context)
	PrecacheResource(
		"particle",
		Config.IT.RING_PARTICLE,
		context
	)

	PrecacheResource(
		"particle",
		Config.IT.CURSE_PARTICLE,
		context
	)

	PrecacheResource(
		"particle",
		Config.PASS.HIT_PARTICLE,
		context
	)

	PrecacheResource(
		"soundfile",
		Config.IT.SOUND_FILE,
		context
	)

	PrecacheResource(
		"particle",
		Config.IT.TRANSITION_PARTICLE,
		context
	)

	PrecacheResource(
		"particle",
		Config.PASS.PROJECTILE_PARTICLE,
		context
	)
end

function Activate()
	-- luacheck: ignore 122
	GameRules.TagGameMode = TagGameMode()
	GameRules.TagGameMode:Init()
end
