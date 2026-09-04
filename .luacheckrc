std = "lua51"
codes = true
max_line_length = 100

globals = {
  "Precache",
  "Activate",
  "TagGameMode",
  "TagManager",
  "tag_pass_the_curse",
  "tag_curse_leap",
  "modifier_tag_curse_leap_motion",
  "PATTACH_WORLDORIGIN",
  "EmitSoundOnLocationWithCaster",
}

read_globals = dofile("tools/luacheck/dota_globals.lua")
