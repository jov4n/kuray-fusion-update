# Fusion + Fakemon System Guide

This guide documents fusion sprite resolution, fakemon registration, and
legacy compatibility paths for this build. All paths below are relative to
the game root.

Additional notes; a lot of places I got stuck got vibecoded, this needs to be tested extensively. it should work, however, it may need to be cleaned up a bit because of the vibe-coded nature. (I was lazy and wanted to get this out into the public before I went back and cleaned it up myself) @fill in the discord for any problems or additional information you run into. It should be pretty simple, drag drop replace files. I do suggest backing up a copy of the game if you decide to try this but I have not run into any issues when downloading a new version of kuray (no spritepacks). but I do not take any responsibility if you break somehow, You've been warned. I will be releasing a tool later to upload your fakemon / custom mon and autocreate paths, and load all the sprites in a "sprite" explorer at a later date.

## Overview

- **Fusions use symbolic IDs** such as `1_FAKEMON` and `4_OFFICIAL`.
- **Primary fusion sprite lookup**:
  - `Graphics/Battlers/<HEAD_ID>/<HEAD_ID>.<BODY_ID>.png`
- **Legacy compatibility** includes:
  - `<HEAD_ID>.<BODY_ID>.png` with `4_0` author suffix
  - Name-based `CHARMANDER.1_FAKEMON.png`
  - Numeric-only `4.1_FAKEMON.png`
- **Fakemon entries** live in `Data/fakemon.json`.
- **Fakemon sprites** live in `Graphics/Battlers/FAKEMON/`.

## How IDs Work

The engine uses **symbolic species IDs**, not the human display name:

- Official species: `4_OFFICIAL` (Charmander)
- Fakemon: `1_FAKEMON`, `2_FAKEMON`, etc.

These IDs are used to build fusion filenames, so keep them consistent.

## Fusion Sprite Lookup (Primary)

For a fusion of `HEAD_ID` + `BODY_ID`:

```
Graphics/Battlers/<HEAD_ID>/<HEAD_ID>.<BODY_ID>.png
```

Example (Fakemon head + Charmander body):

```
Graphics/Battlers/1_FAKEMON/1_FAKEMON.4_OFFICIAL.png
```

## Fusion Sprite Fallbacks (Compatibility)

The loader also tries legacy and name-based patterns:

### Official author suffix fallback

```
Graphics/Battlers/1_FAKEMON/1_FAKEMON.4_0.png
Graphics/Battlers/4_0/4_0.1_FAKEMON.png
```

### Name-based fallback

```
Graphics/Battlers/1_FAKEMON/1_FAKEMON.CHARMANDER.png
Graphics/Battlers/CHARMANDER/CHARMANDER.1_FAKEMON.png
```

### Numeric-only fallback

```
Graphics/Battlers/4/4.1_FAKEMON.png
Graphics/Battlers/1_FAKEMON/1_FAKEMON.4.png
```

These exist to support older community sprite packs and custom naming.

## Adding a New Fusion Sprite (Recommended)

1. Decide **head** and **body** IDs.
2. Place a 96x96 or 288x288 PNG in:

```
Graphics/Battlers/<HEAD_ID>/<HEAD_ID>.<BODY_ID>.png
```

Example:

```
Graphics/Battlers/1_FAKEMON/1_FAKEMON.4_OFFICIAL.png
```

## Adding a Fakemon

### 1) Add entry in `Data/fakemon.json`

Required keys (minimum):

```
{
  "name": "FakemonName",
  "internalName": "FAKEMONNAME",
  "type1": ":NORMAL",
  "type2": "",
  "hp": 60,
  "atk": 60,
  "def": 60,
  "spa": 60,
  "spd": 60,
  "spe": 60,
  "abilities": [],
  "genderRate": "Female50Percent",
  "growthRate": "Medium",
  "baseExp": 100,
  "rareness": 45,
  "happiness": 70,
  "compatibility": "Undiscovered",
  "stepsToHatch": 5000,
  "height": 0.1,
  "weight": 1,
  "color": "Red",
  "shape": "Head",
  "habitat": "None",
  "kind": "Fakemon",
  "pokedex": "A new fakemon."
}
```

### 2) Add sprite

Preferred base sprite path:

```
Graphics/Battlers/<AUTHOR>/<ID_NUMBER>/<ID>.png
```

Example:

```
Graphics/Battlers/PE/1/1_PE.png
```

Optional sprite variants (for custom sprite dex):

```
Graphics/Battlers/PE/1/1_PE_1.png
Graphics/Battlers/PE/1/1_PE_2.png
Graphics/Battlers/PE/1/1_PE_1.jpg
```

### Fakemon fusion sprites inside author folder

Preferred custom fusion placement for fakemon heads:

```
Graphics/Battlers/<AUTHOR>/<ID_NUMBER>/<HEAD_ID>.<BODY_TOKEN>.png
```

Examples:

```
Graphics/Battlers/FAKEMON/1/1_FAKEMON.4.png
Graphics/Battlers/FAKEMON/1/1_FAKEMON.CHARMANDER.png
Graphics/Battlers/FAKEMON/1/1_FAKEMON.2_FILL.png
```

Legacy fallback (still supported):

```
Graphics/Battlers/FAKEMON/<INTERNAL_ID>.png
```

Sprites should be **96x96** or **288x288**.

## Debug: Which Fusion Sprite Is Picked?

Enable in `Data/Scripts/001_Settings.rb`:

```
DEBUG_FUSION_SPRITES = true
```

Then the console prints:

```
Fusion sprite resolved: Graphics/Battlers/...
```

## Notes on Legacy Trainer Species IDs

Legacy trainer species entries like `B295H275` are now translated into
official fusion IDs automatically (e.g. `295` body + `275` head).

If a species is still missing, the trainer loader will fall back to a
placeholder instead of crashing.

## PBS Export Notes

PBS exports now:

- allow numeric InternalNames
- avoid crashing on missing data files
- log failures to `PBS/write_all_errors.txt`

To regenerate:

```
Compiler.write_pokemon
Compiler.write_all
```

