## MissionDefinitionResource — data resource that fully describes a mission.
##
## Author missions as .tres files; they are loaded by the MissionBoard UI and
## fed to the GridMapGenerator and AIDirector at runtime.
extends Resource
class_name MissionDefinitionResource

enum ObjectiveType { RETRIEVE, ELIMINATE, SURVIVE, DOCUMENT, FIND_EXTRACTION }
enum ThreatLevel { LOW = 1, MEDIUM = 2, HIGH = 3, EXTREME = 4 }

## Unique mission identifier (no spaces).
@export var mission_id : String = ""

## Display name shown in the Mission Board.
@export var mission_name : String = ""

## Brief shown before deployment.
@export_multiline var mission_briefing : String = ""

## Threat level — drives AIDirector budget and anomaly density.
@export var threat_level : ThreatLevel = ThreatLevel.MEDIUM

## Primary objective type.
@export var objective_type : ObjectiveType = ObjectiveType.RETRIEVE

## Name of item to retrieve (for RETRIEVE objectives).
@export var target_item_name : String = ""

## Name or id of NPC to eliminate (for ELIMINATE objectives).
@export var target_npc_id : String = ""

## Duration in seconds (for SURVIVE objectives).
@export var survive_duration : float = 120.0

## Number of interactables to document (for DOCUMENT objectives).
@export var document_count : int = 3

## Loot profile — ExtractionLootTable resource used for all loot containers.
@export var loot_table : ExtractionLootTable

## 0–1 density of anomalies to place (0 = none, 1 = very dense).
@export_range(0.0, 1.0) var anomaly_density : float = 0.3

## AI spawn budget multiplier layered on top of AIDirector defaults.
@export var ai_budget_multiplier : float = 1.0

## Seed for grid generation (0 = random).
@export var level_seed : int = 0

## Approximate number of rooms in the generated level.
@export_range(5, 30) var room_count : int = 12

## Currency reward for successful extraction.
@export var base_currency_reward : int = 500

## XP reward for successful extraction.
@export var base_xp_reward : int = 100
