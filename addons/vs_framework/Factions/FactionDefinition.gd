## FactionDefinition — resource that defines a single faction.
extends Resource
class_name FactionDefinition

## Internal id used in code (no spaces, all lowercase).
@export var faction_id : String = ""

## Human-readable display name.
@export var faction_name : String = ""

## Brief lore description shown in the Factions UI.
@export_multiline var description : String = ""

## Default hostility toward the player (0 = friendly, 1 = neutral, 2 = hostile).
## Overridden at runtime by FactionRegistry reputation.
@export_range(0, 2) var default_player_stance : int = 1

## IDs of factions this faction is hostile to by default.
@export var hostile_to : Array[String] = []

## IDs of factions this faction is allied with by default.
@export var allied_with : Array[String] = []
