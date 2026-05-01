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
3. Four autoloads are registered automatically: `ExtractionLoopManager`, `FactionRegistry`, `QuestManager`, and `PlayerProgression`.
4. Add `PersistentStashManager` as a manual autoload if you need the persistent stash without the hub scene.

---

## Architecture

```
addons/vs_framework/
  ExtractionLoop/     # Hub-and-spoke run loop, field cache stashes
  Factions/           # Faction definitions and player reputation
  AI/                 # AIDirector, ALifeSimulator, RaidEventSystem, extended NPC states
  Anomalies/          # Anomaly fields, artifacts, emissions, radiation
  LootEconomy/        # Tiered loot tables, item condition, trader NPC, weapon modding, body looting
  Survival/           # Hunger/Thirst/Fatigue, bleed, armor, encumbrance
  Procedural/         # Mission resources, grid map generator, objectives
  Quests/             # Quest/contract system with faction reputation integration
  Progression/        # Player XP, levelling, and skill unlocks
  UI/                 # Hub UI, Raid HUD extension, minimap, death screen
  Demo/               # Demo scene controllers
  Integration/        # External reference-source profiles and import policy
```

---

## Reference Integration Workflow

VS Framework should remain the gameplay core, with COGITO providing the first-person immersive-sim foundation. External projects are treated as reviewed references or content donors through `Integration/reference_integration_catalog.tres`.

### Source Priority

| Priority | Source | Use |
|---|---|---|
| 1 | `Void-Sovereigns` | Primary design source for factions, missions, loot themes, anomalies, trader economy, hub/raid flow, and worldbuilding. |
| 2 | `skelerealms` | Secondary content source for atmosphere, encounters, enemy presentation, level dressing, item themes, and progression inspiration. |
| 3 | `Godot4-FPS-Template` | Godot-native FPS implementation reference for weapon feel, camera polish, interaction UX, HUD patterns, and scene organization. |
| 4 | `Godot-Simple-FPS-Weapon-System-Asset` | Godot-native reference for weapon presentation, recoil/sway polish, reload flow, shared-ammo patterns, and viewmodel handling. Use only where it complements COGITO's existing wieldable stack. |
| 5 | `upbge-fps-template` | Concept-only reference for combat pacing, weapon feedback, AI pressure, and level flow. |
| 6 | `Godot-Skill-Tree` | Godot 4 MIT implementation reference for ranked/tiered skill data and skill tree UI. Adapt `SkillData`/`SkillTier`/`SkillInstance` to add multi-rank depth to `SkillDefinition`; use `SkillTree`/`SkillNode` UI scripts as a base for the VS Framework skill tree screen. Do **not** import its `Stats`/`StatModifier` system (conflicts with COGITO attributes) or Job-level unlock gating (conflicts with XP-based unlocks). |
| 7 | `FiniteStateMachine` | Concept-only Godot FSM reference for AI/control-flow patterns. Evaluate state composition and transition ideas without replacing COGITO's existing NPC state machine by default. |
| Blocked | `sunone_aimbot` | Do not integrate. It is unrelated to the framework goals and is explicitly excluded. |

### Practical Rules

1. Map `Void-Sovereigns` features onto existing VS Framework modules before adding new systems.
2. Prefer content, data structures, progression ideas, and scene patterns over direct code reuse.
3. Only consider code from Godot 4-compatible sources when it does not duplicate COGITO or VS Framework functionality.
4. Treat UPBGE sources as design inspiration only because engine differences make direct reuse expensive.
5. Keep blocked sources in the catalog to document exclusions and prevent accidental integration.
6. Treat `Godot-Simple-FPS-Weapon-System-Asset` as a reviewed implementation reference for weapon feel/presentation only; do not import its GPLv3 demo weapon models/textures or replace COGITO's inventory+wieldable pipeline wholesale.
7. `Godot-Skill-Tree` is MIT and Godot 4 native — direct code reuse is permitted for skill data and UI scripts. Keep XP-based unlock logic in `PlayerProgression`; do not adopt its class-level or stat-modifier systems.
8. Treat `FiniteStateMachine` as concept-only until its license, Godot compatibility, and overlap with COGITO's `npc_state_machine.gd` are reviewed. Do not replace the current NPC `States.goto()` / `_state_enter` / `_state_exit` flow without a dedicated migration plan.

### Runtime/Data Access

Load the default catalog when editor tools or game setup screens need to show approved source mappings:

```gdscript
var catalog : SourceIntegrationCatalog = load("res://addons/vs_framework/Integration/reference_integration_catalog.tres")
var faction_sources : Array[SourceIntegrationProfile] = catalog.get_sources_for_module("Factions")
```

Use `SourceIntegrationProfile.can_use_content_data()`, `can_use_as_concept_reference()`, and `can_reuse_code()` before importing or adapting work from a source.

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
5. Create `QuestDefinition` resources and assign them to `QuestManager.quest_definitions`.
6. Create `SkillDefinition` resources and assign them to `PlayerProgression.skills`.
7. Build a raid scene with a NavigationRegion3D, add `DemoRaidZone.gd`, wire all subsystem node exports.
8. Add `ExtractionZone`, `EmissionEvent`, shelter nodes, `AnomalyComponent` areas, and `FieldCacheStash` nodes to taste.
9. Add a `RaidEventSystem` node to the raid scene and wire it to `AIDirector` and any extraction zones.
10. Add `HungerAttribute`, `ThirstAttribute`, `FatigueAttribute`, `BleedState`, `ArmorComponent`, `RadiationAttribute`, and `EncumbranceComponent` as children of the player in your player scene.
11. Add `WeaponModdingComponent` as a child of each wieldable weapon scene. Assign `available_slots` in the editor.
12. In your NPC death handler, instantiate a `LootableCorpse` scene at the NPC's world position and assign a `loot_table`.
13. Deploy and iterate.

---

## Phase 8 — Quest / Contract System

### QuestManager (autoload)

```gdscript
# Accept a quest from a faction board:
QuestManager.accept_quest("retrieve_data_core")

# Fire when the player picks up the required item:
QuestManager.advance_progress("retrieve_data_core", 1)

# Manually complete (e.g. reached extraction zone):
QuestManager.complete_quest("retrieve_data_core")

# After showing the reward UI:
QuestManager.hand_in_quest("retrieve_data_core")

# Listen for changes:
QuestManager.quest_completed.connect(func(id): print("Done: ", id))

# Query the journal:
var active : Array[QuestEntry] = QuestManager.get_active_quests()
var available : Array[QuestEntry] = QuestManager.get_available_quests()
```

### QuestDefinition resource

Create `.tres` files extending `QuestDefinition`. Set `quest_id`, `quest_title`, `giver_faction_id`, `objective_type`, reward fields, and `is_repeatable`. Assign all definitions to `QuestManager.quest_definitions`.

### QuestEntry

Runtime state of each quest. Query via `QuestManager.get_entry(quest_id)`. Use `get_progress_fraction()` and `get_progress_label()` for HUD elements.

---

## Phase 9 — Body Looting

### LootableCorpse

Instantiate from your NPC death handler and add to the current scene:

```gdscript
# Inside NPC die() override or death signal handler:
var corpse : LootableCorpse = corpse_scene.instantiate()
get_tree().current_scene.add_child(corpse)
corpse.global_position = global_position
corpse.loot_table = enemy_loot_table
corpse.guaranteed_items = [{"item_name": "ammo_9mm", "quantity": 15}]
```

Wire the interact signal from COGITO's `InteractableComponent` on the corpse mesh to `LootableCorpse.interact()`. Connect `looted` to your inventory UI.

---

## Phase 10 — Encumbrance / Weight

### EncumbranceComponent

Add as a child of the player node:

```gdscript
# In your player movement code:
var speed_mult : float = encumbrance.get_speed_multiplier()
velocity = direction * base_speed * speed_mult
```

Items need a `weight : float` export property (in kg) on their `InventoryItemPD` resource. If absent, `item_fallback_weight` is used. Connect `over_encumbered` and `encumbrance_cleared` to your HUD for status indicators.

---

## Phase 11 — Weapon Modding

### WeaponModdingComponent

Add as a child of any wieldable scene:

```gdscript
# Attach a suppressor:
weapon_mods.equip_attachment(suppressor_res)

# Read aggregated stat deltas in your fire() function:
var damage : float = base_damage + weapon_mods.get_total_damage_modifier()
var recoil : float = base_recoil + weapon_mods.get_total_recoil_modifier()
```

### WeaponAttachment resource

Create `.tres` files extending `WeaponAttachment`. Set `slot`, `attachment_id`, and the relevant modifier fields. Present available attachments in the trader UI or a dedicated mod workbench scene.

### COGITO Weapon Integration

COGITO's pistol and laser rifle wieldables now look for an optional `CogitoWeaponIntegration` child. Add it alongside `ItemCondition` and `WeaponModdingComponent` on any COGITO `CogitoWieldable` scene to apply VS Framework weapon condition and attachment stats while keeping COGITO's inventory, ammo, reload, and wieldable flow intact.

On each shot, the integration component:
- applies `ItemCondition.take_wear()` and blocks fire if the weapon jams or breaks;
- applies `WeaponModdingComponent.get_total_damage_modifier()` to projectile/hitscan damage;
- exposes helper methods for accuracy, recoil, and magazine modifiers for custom weapons;
- clears jams on reload by default.

This is the concrete integration point for weapon-system ideas from `Godot-Simple-FPS-Weapon-System-Asset`: reuse its weapon-feel patterns through COGITO-compatible components rather than importing its demo assets or replacing the COGITO wieldable pipeline.

---

## Phase 12 — Player Skill Progression

### PlayerProgression (autoload)

```gdscript
# Award XP (also called automatically by QuestManager on completion):
PlayerProgression.add_xp(250)

# Unlock a skill from the skill tree UI:
if PlayerProgression.unlock_skill("endurance_1"):
    # Apply bonuses defined in the SkillDefinition resource to player attributes

# Query state:
var level : int = PlayerProgression.current_level
var fraction : float = PlayerProgression.level_progress_fraction()
var unlockable : Array[SkillDefinition] = PlayerProgression.get_unlockable_skills()
```

### SkillDefinition resource

Create `.tres` files extending `SkillDefinition`. Set `skill_id`, `xp_required`, `prerequisite_skill_ids`, and the attribute bonus fields. After `skill_unlocked` fires, apply `attribute_max_bonus` and `attribute_rate_multiplier` to the corresponding player attribute node.

---

## Phase 13 — Field Cache Stash

### FieldCacheStash

Place `FieldCacheStash` nodes in your raid level and assign a stable `cache_id`:

```gdscript
# Deposit an item (e.g. from a nearby loot container):
field_cache.deposit("v_disk_encrypted", 1)

# Retrieve on a future run:
var retrieved : int = field_cache.retrieve("v_disk_encrypted", 1)
```

Wire COGITO's `InteractableComponent` interact signal to `FieldCacheStash.interact()`. Open a container UI showing `get_contents()`. Contents persist to `user://vs_field_caches.res` and survive player death.

---

## Phase 14 — Dynamic Raid Events

### RaidEventSystem

Add one to your raid scene and feed it the room graph:

```gdscript
# After GridMapGenerator runs:
raid_events.set_room_graph(rooms)

# Events fire automatically on a timer, or manually:
raid_events.fire_event(RaidEventSystem.RaidEvent.PATROL_INCURSION)

# Listen for narrative feedback:
raid_events.patrol_incursion.connect(func(room_id): hud.show_alert("Enemy patrol spotted!"))
raid_events.extraction_sealed.connect(func(zone): hud.show_alert("Extraction point sealed!"))
raid_events.loot_cache_marked.connect(func(pos): minimap.mark_cache(pos))
```

| Event | Description |
|---|---|
| `PATROL_INCURSION` | Spawns a new enemy patrol in a random room via AIDirector |
| `FACTION_SKIRMISH` | Two rooms are flagged as an active inter-faction fight |
| `EXTRACTION_SEALED` | A random ExtractionZone is temporarily sealed |
| `LOOT_CACHE_MARKED` | A hidden loot cache position is broadcast (show on minimap) |
| `ANOMALY_SURGE` | Signals anomaly components in a room to intensify |
| `REINFORCEMENT_CALL` | Triggers a reinforcement wave via AIDirector |
