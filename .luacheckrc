std = "lua51"
codes = true
max_line_length = 100

globals = {
  "Precache",
  "Activate",
  "TagGameMode",
  "TagManager",
  "modifier_tag_unstable_entry_slow",
  "MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE",
  "MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE",
  "LUA_MODIFIER_MOTION_NONE",
}

read_globals = dofile("tools/luacheck/dota_globals.lua")
