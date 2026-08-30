std = "lua51"
codes = true
max_line_length = 100

globals = {
  "Precache",
  "Activate",
  "TagGameMode",
  "TagManager",
  "tag_pass_the_curse"
}

read_globals = dofile("tools/luacheck/dota_globals.lua")
