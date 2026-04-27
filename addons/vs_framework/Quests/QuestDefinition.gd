## QuestDefinition — data resource describing a quest or contract.
##
## Create .tres files extending QuestDefinition. Register them in QuestManager.
## Quest givers (TraderNPC, mission board NPCs) hand these to the player at runtime.
extends Resource
class_name QuestDefinition

enum QuestObjectiveType {
	RETRIEVE_ITEM,      ## Bring back a specific item.
	ELIMINATE_TARGET,   ## Kill all NPCs in a named group.
	SURVIVE_DURATION,   ## Survive for a number of seconds without dying.
	DOCUMENT_INTEL,     ## Interact with a set number of documentable nodes.
	EXTRACT_ALIVE,      ## Reach an extraction zone and extract successfully.
}

## Unique identifier (no spaces). Used as a key throughout the system.
@export var quest_id : String = ""

## Display name shown in the quest journal.
@export var quest_title : String = ""

## Short description shown in the quest log and board UI.
@export_multiline var quest_description : String = ""

## The faction whose representative gives this quest.
## Completing raises, failing lowers, reputation with this faction.
@export var giver_faction_id : String = ""

## Type of objective that marks this quest as complete.
@export var objective_type : QuestObjectiveType = QuestObjectiveType.RETRIEVE_ITEM

## For RETRIEVE_ITEM: exact item name to collect.
@export var target_item_name : String = ""

## For RETRIEVE_ITEM: how many of the item are required.
@export var target_item_quantity : int = 1

## For ELIMINATE_TARGET: NPC scene group name (all members must be dead).
@export var target_npc_group : String = ""

## For SURVIVE_DURATION: seconds to survive inside the raid zone.
@export var survive_duration : float = 120.0

## For DOCUMENT_INTEL: number of interactable nodes required.
@export var document_count : int = 3

## Currency awarded on hand-in.
@export var reward_currency : int = 0

## XP awarded on hand-in (forwarded to PlayerProgression if present).
@export var reward_xp : int = 50

## Reputation gain with giver_faction_id on hand-in.
@export var reward_reputation : int = 100

## Reputation penalty applied to giver_faction_id when the quest fails.
@export var fail_reputation_loss : int = 50

## Whether the quest resets to AVAILABLE after completion (daily contract style).
@export var is_repeatable : bool = false
