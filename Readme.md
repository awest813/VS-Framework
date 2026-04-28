# VS Framework

[![GodotEngine](https://img.shields.io/badge/Godot_4.4+-blue?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![Version](https://img.shields.io/badge/version_0.1.0-35A1D7?label=VS%20Framework&labelColor=0E4488)](https://github.com/awest813/VS-Framework)
[![License](https://img.shields.io/github/license/awest813/VS-Framework)](LICENSE)

A Godot 4 extraction/zone game framework built on top of [COGITO](https://codeberg.org/Phazorknight/Cogito).
Designed for **Void-Sovereigns / STALKER-style** games: first-person runs from a hub into dangerous zones with loot, AI pressure, anomalies, and permanent gear-loss stakes.

---

## Features

| System | What it provides |
|---|---|
| **Extraction Loop** | Hub → Mission Select → Deploy → In-Raid → Extract → Debrief state machine |
| **Persistent Stash** | Cross-run item and currency storage that survives death |
| **Field Cache Stash** | In-raid hidden stashes that persist across runs |
| **Faction Registry** | Faction definitions, player reputation, and inter-faction hostility |
| **AI Director** | Room-graph-driven enemy spawning with reinforcement waves |
| **A-Life Simulator** | Fast-resolves off-screen faction conflicts when the player returns to hub |
| **Extended NPC States** | Alert → Search → Hunt → Flank states layered on top of COGITO's NPC state machine |
| **Anomaly System** | Damage fields, artifact spawning, radiation attribute, and emission events |
| **Loot Economy** | Tiered loot tables, item condition, trader NPC, weapon modding, body looting |
| **Survival** | Hunger, Thirst, Fatigue, Bleed, Armor, and Encumbrance attributes |
| **Procedural Missions** | Seeded grid-map generation, five objective types, and room activity streaming |
| **Quest / Contract System** | Faction-tied quests with journal, progress tracking, and repeatable contracts |
| **Player Progression** | XP, levelling, and a skill-tree with prerequisite chains |
| **Dynamic Raid Events** | Patrol incursions, faction skirmishes, extraction sealing, anomaly surges |
| **Weapon Modding** | Slot-based attachments with aggregated stat deltas, integrated with COGITO wieldables |
| **UI Suite** | Hub UI, Raid HUD extension, minimap, death screen |

---

## Requirements

- **Godot 4.4+**
- [COGITO](https://codeberg.org/Phazorknight/Cogito) — already bundled under `addons/cogito/`

---

## Installation

1. Clone or download this repository into your Godot project root.
2. Open **Project → Project Settings → Plugins**.
3. Enable **VS Framework**.

Four autoloads are registered automatically:

| Autoload | Path |
|---|---|
| `ExtractionLoopManager` | `addons/vs_framework/ExtractionLoop/ExtractionLoopManager.gd` |
| `FactionRegistry` | `addons/vs_framework/Factions/FactionRegistry.gd` |
| `QuestManager` | `addons/vs_framework/Quests/QuestManager.gd` |
| `PlayerProgression` | `addons/vs_framework/Progression/PlayerProgression.gd` |

> **Note:** `PersistentStashManager` is **not** auto-registered. Add it manually as an autoload if you need persistent stash functionality outside of the hub scene.

---

## Project Structure

```
addons/vs_framework/
  ExtractionLoop/     # Hub-and-spoke run loop, field cache stashes
  Factions/           # Faction definitions and player reputation
  AI/                 # AIDirector, ALifeSimulator, RaidEventSystem, extended NPC states
  Anomalies/          # Anomaly fields, artifacts, emissions, radiation
  LootEconomy/        # Tiered loot tables, item condition, trader NPC, weapon modding, body looting
  Survival/           # Hunger/Thirst/Fatigue, bleed, armor, encumbrance
  Procedural/         # Mission resources, grid-map generator, objectives
  Quests/             # Quest/contract system with faction reputation integration
  Progression/        # Player XP, levelling, and skill unlocks
  UI/                 # Hub UI, Raid HUD extension, minimap, death screen
  Demo/               # Demo scene controllers
  Integration/        # External reference-source profiles and import policy
```

---

## Quick Start

### 1 — Extraction Loop

```gdscript
# Accept a mission from the Mission Board UI:
ExtractionLoopManager.select_mission("my_mission_id")

# Deploy (pass the player's pre-raid stash snapshot):
ExtractionLoopManager.deploy(stash_manager.stash_items)

# Load the raid scene when the signal fires:
ExtractionLoopManager.raid_started.connect(func(session):
    CogitoSceneManager.load_scene("res://scenes/raid_zone.tscn"))

# Trigger extraction from an ExtractionZone (automatic) or manually:
ExtractionLoopManager.begin_extraction()
ExtractionLoopManager.complete_extraction(extracted_items, earned_currency)

# Handle player death:
ExtractionLoopManager.player_died()

# Return to hub from the debrief screen:
ExtractionLoopManager.close_debrief()
```

### 2 — Factions

```gdscript
FactionRegistry.get_reputation("bandits")          # → int
FactionRegistry.change_reputation("military", 50)
FactionRegistry.get_stance("loners")               # → 0 Friendly / 1 Neutral / 2 Hostile
FactionRegistry.are_factions_hostile("bandits", "military")
```

Reputation persists to `user://vs_factions.res`.

### 3 — Quests

```gdscript
QuestManager.accept_quest("retrieve_data_core")
QuestManager.advance_progress("retrieve_data_core", 1)
QuestManager.complete_quest("retrieve_data_core")
QuestManager.hand_in_quest("retrieve_data_core")

var active : Array[QuestEntry] = QuestManager.get_active_quests()
```

### 4 — Player Progression

```gdscript
PlayerProgression.add_xp(250)
PlayerProgression.unlock_skill("endurance_1")

var level : int    = PlayerProgression.current_level
var frac  : float  = PlayerProgression.level_progress_fraction()
```

---

## Setting Up a New Game

1. Create a Godot 4 project with COGITO and VS Framework enabled.
2. Build a hub scene using COGITO's first-person player; attach `Demo/DemoHubScene.gd` to the root.
3. Create `FactionDefinition` resources and assign them to `FactionRegistry.factions`.
4. Create `MissionDefinitionResource` files for each mission and assign them to `HubUI.mission_definitions`.
5. Create `QuestDefinition` resources and assign them to `QuestManager.quest_definitions`.
6. Create `SkillDefinition` resources and assign them to `PlayerProgression.skills`.
7. Build a raid scene with a `NavigationRegion3D`; attach `Demo/DemoRaidZone.gd` and wire all subsystem exports.
8. Add `ExtractionZone`, `EmissionEvent`, shelter nodes, `AnomalyComponent` areas, and `FieldCacheStash` nodes to taste.
9. Add `RaidEventSystem` to the raid scene and wire it to `AIDirector` and any extraction zones.
10. Add survival components as children of the player node: `HungerAttribute`, `ThirstAttribute`, `FatigueAttribute`, `BleedState`, `ArmorComponent`, `RadiationAttribute`, `EncumbranceComponent`.
11. Add `WeaponModdingComponent` (and optionally `CogitoWeaponIntegration`) as children of each wieldable weapon scene.
12. In your NPC death handler, instantiate a `LootableCorpse` at the NPC's world position and assign a `loot_table`.

---

## Detailed Documentation

Full API reference, GDScript examples, and setup guides for every system live in:

📄 [`addons/vs_framework/README.md`](addons/vs_framework/README.md)

---

## License

See [LICENSE](LICENSE).

COGITO is made by [Philip Drobar](https://www.philipdrobar.com) and contributors — see [COGITO credits](https://cogito.readthedocs.io/en/latest/about.html).
