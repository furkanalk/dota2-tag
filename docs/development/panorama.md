# Panorama Development

Tag Party's custom HUD and other client-side UI are implemented with Dota 2
Panorama.

## Source and compiled resources

Author Panorama source under:

```text
content/panorama/
  layout/custom_game/
  scripts/custom_game/
  styles/custom_game/
  images/
```

Source 2 compiles those assets into the matching runtime tree under:

```text
game/panorama/
```

Common compiled extensions:

```text
.xml -> .vxml_c
.js  -> .vjs_c
.css -> .vcss_c
```

Compiled resources are generated artifacts and must not be committed.

## Compile Panorama

Use:

```bash
bash tools/compile-panorama.sh
```

The compiler must receive the addon's literal path inside the Dota installation:

```text
C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\
content\dota_addons\tag\...
```

Do not construct the compiler input path with `wslpath` from the repository
symlink. In the current development setup, that resolves the link to:

```text
C:\dev\dota2-mods\tag\content\...
```

`resourcecompiler.exe` then loses the Source 2 addon root and reports errors
such as:

```text
Failed to split full path ...
FS: Tried to FileExists NULL filename!
```

The working compiler context uses:

```text
-game "C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota"
```

## Layout compiler constraint

The current Dota Panorama compiler rejects an `id` attribute on the root
`Panel` of a loaded layout.

Invalid:

```xml
<Panel id="MyRoot">
```

Valid:

```xml
<Panel>
```

Child panels may have IDs normally.

## Runtime workflow

For changes to Panorama layout, scripts, styles, or the custom UI manifest:

1. Edit files under `content/panorama/`.
2. Run `bash tools/compile-panorama.sh`.
3. Restart the custom game when changing the manifest or UI structure.

Do not rely on Lua `script_reload` for Panorama resource changes.

## Fear affordability presentation

Fear affordability is presentation state, not an engine activation state.

When a Cursed ability is unaffordable:

- Keep the ability mechanically activated so the server cast filter can emit
  the authored `Not enough Fear.` error.
- Tint only the native `AbilityImage`.
- Leave the native cooldown radial/countdown untouched and visible.
- Reserve `SetActivated(false)` for true mechanical locks such as CURSED
  STAGGER.

This keeps the native Dota action bar functional while allowing Tag Party to
communicate its own resource semantics.

## UI art direction

Panorama does not require every HUD element to be pre-rendered artwork.
Layout, typography, spacing, panels, state changes, icon treatment, animation,
and most HUD composition should be built with XML/CSS/JS.

Use custom image assets only where they add real visual identity: bespoke
ornaments, textures, icons, illustrations, or branded backgrounds. This keeps
the HUD responsive, maintainable, and easier to iterate.
