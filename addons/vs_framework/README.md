# VS Framework

A Godot 4 extraction/zone game framework built on top of **COGITO**.
Designed for Void-Sovereigns / STALKER-style games: first-person runs from a hub into dangerous zones with loot, AI pressure, anomalies, and permanent death-of-carried-gear stakes.

---

## Requirements

- Godot 4.4+
- [COGITO](https://codeberg.org/Phazorknight/Cogito) (already included in this project under `addons/cogito`)

## Enabling the Plugin

1. Open **Project → Project Settings → Plugins**.
2. Enable **VS Framework**.
3. Two autoloads are registered automatically: `ExtractionLoopManager` and `FactionRegistry`.
4. Add `PersistentStashManager` as a manual autoload if you need the persistent stash without the hub scene.

---

## Architecture

```
addons/vs_framework/
  ExtractionLoop/     # Hub-and-spoke run loop
  Factions/           # Faction definitions and player reputation
  AI/                 # AIDirector, ALifeSimulator, extended NPC states
  Anomalies/          # Anomaly fields, artifacts, emissions, radiation
  LootEconomy/        # Tiered loot tables, item condition, trader NPC
  Survival/           # Hunger/Thirst/Fatigue, bleed, armor
  Procedural/         # Mission resources, grid map generator, objectives
  UI/                 # Hub UI, Raid HUD extension, minimap, death screen
  Demo/               # Demo scene controllers
```

---

## Phase 1 — Extraction Loop

### ExtractionLoopManager (autoload)

State machine: `Hub → MissionSelect → Deploy → InRaid → Extracting → Debrief`

```gdscript
# From your Mission Board UI when player accepts a mission:
ExtractionLoopManager.select_mission("my_mission_id")

# From your Deploy button:
ExtractionLoopManager.deploy(stash_manager.stash_items)

# Listen for raid_started to load the raid scene:
ExtractionLoopManager.raid_started.connect(func(session):
    CogitoSceneManager.load_scene("res://scenes/raid_zone.tscn"))

# From ExtractionZone (handled automatically) or manually:
ExtractionLoopManager.begin_extraction()
ExtractionLoopManager.complete_extraction(extracted_items, earned_currency)

# On player death:
ExtractionLoopManager.player_died()

# From DebriefScene's "Continue" button:
ExtractionLoopManager.close_debrief()
```

### RunSessionResource

Transient resource that lives for one raid session. Holds the pre-raid stash snapshot, current raid inventory, elapsed time, and alive status. Wiped on death; committed on successful extraction.

### PersistentStashManager (manual autoload)

Saves and loads `user://vs_stash.res`. Tracks persistent currency and item counts across runs. Call `commit_extraction()` after a successful run.

### ExtractionZone

Place an `Area3D` with `ExtractionZone.gd` in your raid level. The player presses the interact key to start a countdown, then extraction completes automatically. Can be sealed with `seal_zone()` / `open_zone()`.

### DebriefScene

Attach `DebriefScene.gd` to your debrief screen Control node. Wire `@export` label/button references in the editor. Shows items extracted (or lost), currency earned, and XP.

---

## Phase 2 — AI & Faction Systems

### FactionRegistry (autoload)

```gdscript
# Check player reputation with a faction:
FactionRegistry.get_reputation("bandits")   # returns int

# Change reputation (positive = friendlier):
FactionRegistry.change_reputation("military", 50)

# Get stance: 0=Friendly, 1=Neutral, 2=Hostile
FactionRegistry.get_stance("loners")

# Check inter-faction hostility:
FactionRegistry.are_factions_hostile("bandits", "military")
```

Reputation persists to `user://vs_factions.res`.

### FactionDefinition resource

Create `.tres` files extending `FactionDefinition`. Populate `faction_id`, `faction_name`, `hostile_to`, and `allied_with`. Assign all factions to `FactionRegistry.factions` in the editor.

### AIDirector

Add to a raid scene. Assign `enemy_scene`, then call:

```gdscript
ai_director.set_room_graph(rooms)   # from GridMapGenerator
ai_director.spawn_encounters()

# Trigger reinforcement wave when player shoots or completes objective:
ai_director.trigger_reinforcements("room_3_2")
```

Spawn budget is determined by room type and critical-path depth. Bots past 60% of max depth spawn force-alerted.

### Extended NPC States

Copy the four new states into your NPC's `NPC_State_Machine` node alongside COGITO's existing states:

| Script | Transition |
|---|---|
| `npc_state_alert.gd` | Heard a sound → waits, then goes to Search |
| `npc_state_search.gd` | Sweeps last known position → returns to Patrol or Hunt |
| `npc_state_hunt.gd` | Confirmed target → sprints and attacks |
| `npc_state_flank.gd` | Moves to the side of the target before attacking |

Wire detection (line-of-sight, sound radius) to set `npc.attention_target` and call `States.goto("alert", suspicious_position)`.

### ALifeSimulator

Add to your hub scene. Call `simulate_world(days)` each time the player returns to hub to fast-resolve off-screen faction conflicts.

---

## Phase 3 — Anomalies

### AnomalyComponent

Place on an `Area3D` in the level. Assign an `AnomalyDefinition` resource. The component:
- Drains the configured player attribute while the player is inside the damage radius.
- Warns the player's AnomalyDetector item when inside the detection radius.
- Spawns an artifact pickup on `_ready()` if the chance roll succeeds.

### RadiationAttribute

Add as a child of the player node (alongside Health, Stamina, etc.) in your player scene. It:
- Builds up when the player stands in anomaly fields or during emissions.
- Drains health above the `drain_threshold`.
- Naturally decays at `natural_decay_rate` per second.

Call `expose(amount)` from `AnomalyComponent` or `EmissionEvent`. Call `cleanse(amount)` from anti-radiation consumable `ConsumableEffect`.

### EmissionEvent

Add one per raid level. Set `auto_interval` (seconds) for automatic emissions or call `trigger_warning()` manually. Add shelter `Area3D` nodes with `ShelterNode.gd` and assign their paths to `shelter_nodes`.

### ArtifactItemPD

Create `.tres` files extending `ArtifactItemPD`. Add `ArtifactModifier` entries to `passive_modifiers`. Wire artifact activation by calling `activate(player)` when the item enters the player inventory (override `CogitoInventory.pick_up_item` or use a signal).

---

## Phase 4 — Loot Economy

### ExtractionLootTable

Extends COGITO's `LootTable`. Create `.tres` files and set `max_tier_allowed` to gate which item tiers can drop. Assign to `MissionDefinitionResource.loot_table`.

### ItemCondition

Add as a child of wieldable scene or armor. Wire `take_wear()` from weapon fire / damage events. Use `repair(amount)` from trader repair services or consumable effects. Read `get_condition_label()` for HUD tooltips.

### TraderNPC

Add as a child of a `CogitoObject` or static interactable node. Assign a `TraderStock` resource. Wire the interactable's interact event to `open_trade(player_interaction_component)`.

---

## Phase 5 — Survival

Add these as children of the player node in your player scene:

| Node | Description |
|---|---|
| `HungerAttribute` | Decays during raids; drains stamina when empty |
| `ThirstAttribute` | Decays faster; drains health when empty |
| `FatigueAttribute` | Accumulates; slows movement at high values |
| `BleedState` | Call `apply_bleed()` from damage code; use bandage consumable to `stop_bleed()` |
| `ArmorComponent` | Call `absorb(raw_damage)` in your damage pipeline; returns reduced damage |

`FoodItemPD` extends `ConsumableItemPD` and restores hunger/thirst. Set `is_stimulant = true` for stim items (applies suppression then crash to `FatigueAttribute`).

---

## Phase 6 — Procedural Missions

### MissionDefinitionResource

Create one `.tres` per mission. Set `mission_id`, `threat_level`, `objective_type`, `loot_table`, `anomaly_density`, `room_count`, and rewards. These resources are listed in `HubUI.mission_definitions`.

### GridMapGenerator

```gdscript
var gen := GridMapGenerator.new()
var rooms : Array = gen.generate(mission_definition)
# rooms is Array[RoomData]
# Pass to AIDirector, RoomActivitySystem, MinimapSystem
```

The generator builds a seeded grid with a critical path (spawn → objective → extraction) plus branch dead-ends (loot/airlock rooms).

### Objective Types

| Class | Completion Condition |
|---|---|
| `ObjectiveRetrieve` | Item with matching name is in player inventory |
| `ObjectiveEliminate` | All NPCs in `target_group` are dead |
| `ObjectiveSurvive` | `survive_duration` seconds elapse without dying |
| `ObjectiveDocument` | Player interacts with `required_count` "documentable" nodes |
| `ObjectiveFindExtraction` | Prerequisite objective completes; reveals ExtractionZone |

Connect `objective_completed` to `ExtractionLoopManager.begin_extraction()` for objectives that trigger immediate extraction, or chain objectives using `ObjectiveFindExtraction`.

### RoomActivitySystem

Add to the raid scene. Feed it the room graph. AI nodes and audio players should be added to a group matching their `room_id` string so the system can freeze/unfreeze them as the player moves.

---

## Phase 7 — UI

### HubUI

Attach to a `TabContainer`. Assign `mission_definitions` array and the stash/faction container references. The Hub UI reads from `PersistentStashManager` and `FactionRegistry` automatically.

### RaidHUDExtension

Add to a `CanvasLayer` in the raid scene. Assign `ProgressBar` references for each survival attribute. The script auto-finds the player's attribute child nodes by class name.

### MinimapSystem

Add a `Control` node of your desired size and attach `MinimapSystem.gd`. Call `reveal_room(room_id)` each time the player enters a room (detect this with a room-trigger `Area3D`).

### RaidDeathScreen

Attach to a full-screen `Control` or `CanvasLayer`. It listens to `ExtractionLoopManager.raid_ended_death` automatically and displays items lost.

---

## Demo Scenes

| Script | Purpose |
|---|---|
| `Demo/DemoHubScene.gd` | Hub root controller — wires ExtractionLoopManager + HubUI + ALifeSimulator |
| `Demo/DemoRaidZone.gd` | Raid root controller — runs GridMapGenerator, AIDirector, sets up objectives |

Attach these to the root nodes of your hub and raid scenes. Assign all `@export` references in the editor.

---

## Adding a New Game

1. Create a Godot 4 project with COGITO and VS Framework enabled.
2. Build a hub scene using COGITO's first-person player, add `DemoHubScene.gd` to the root.
3. Create `FactionDefinition` resources and assign them to `FactionRegistry.factions`.
4. Create `MissionDefinitionResource` files for each mission and assign them to `HubUI.mission_definitions`.
5. Build a raid scene with a NavigationRegion3D, add `DemoRaidZone.gd`, wire all subsystem node exports.
6. Add `ExtractionZone`, `EmissionEvent`, shelter nodes, and `AnomalyComponent` areas to taste.
7. Add `HungerAttribute`, `ThirstAttribute`, `FatigueAttribute`, `BleedState`, `ArmorComponent`, and `RadiationAttribute` as children of the player in your player scene.
8. Deploy and iterate.
