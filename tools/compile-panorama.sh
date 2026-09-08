#!/usr/bin/env bash
set -euo pipefail

DOTA_WSL="/mnt/c/Program Files (x86)/Steam/steamapps/common/dota 2 beta"
RC="$DOTA_WSL/game/bin/win64/resourcecompiler.exe"

# Keep these literal. Resolving the addon symlink through WSL changes the
# source path to C:\dev\..., which Source 2 cannot map back to the addon root.
CONTENT_PANORAMA_WIN='C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\content\dota_addons\tag\panorama\*'
GAME_ROOT_WIN='C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota'

if [[ ! -f "$RC" ]]; then
  echo "ERROR: resourcecompiler.exe not found:"
  echo "  $RC"
  exit 1
fi

"$RC" \
  -v \
  -f \
  -nop4 \
  -i "$CONTENT_PANORAMA_WIN" \
  -r \
  -game "$GAME_ROOT_WIN"
