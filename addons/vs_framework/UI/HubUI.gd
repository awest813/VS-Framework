## HubUI — master control script for the hub interface.
##
## Attach to a TabContainer or similar root Control node.
## Populate @export references in the editor.
## The UI reads from PersistentStashManager and FactionRegistry.
extends Control
class_name HubUI

## Tab indices (match the order of tabs in your TabContainer).
const TAB_STASH    : int = 0
const TAB_TRADER   : int = 1
const TAB_MISSIONS : int = 2
const TAB_FACTIONS : int = 3

@export var tab_container : TabContainer

## Stash tab — grid or list showing persistent stash contents.
@export var stash_item_list : VBoxContainer

## Missions tab — list of MissionDefinitionResource .tres paths to display.
@export var mission_button_container : VBoxContainer
@export var mission_briefing_label : Label
@export var deploy_button : Button
@export var mission_definitions : Array[MissionDefinitionResource] = []

## Factions tab — list of faction name + reputation.
@export var faction_list_container : VBoxContainer

var _selected_mission : MissionDefinitionResource = null


func _ready() -> void:
	var stash : Node = get_node_or_null("/root/PersistentStashManager")
	if stash:
		stash.stash_updated.connect(_refresh_stash)

	if deploy_button:
		deploy_button.pressed.connect(_on_deploy_pressed)

	_refresh_stash()
	_populate_missions()
	_populate_factions()


# ─── Stash tab ────────────────────────────────────────────────────────────────

func _refresh_stash() -> void:
	if not stash_item_list:
		return
	for child in stash_item_list.get_children():
		child.queue_free()

	var stash : Node = get_node_or_null("/root/PersistentStashManager")
	if not stash:
		return

	var currency_row := Label.new()
	currency_row.text = "Currency: " + str(stash.currency)
	stash_item_list.add_child(currency_row)

	for entry in stash.stash_items:
		var row := Label.new()
		row.text = str(entry.get("item_name", "?")) + "  x" + str(entry.get("quantity", 0))
		stash_item_list.add_child(row)


# ─── Mission Board tab ────────────────────────────────────────────────────────

func _populate_missions() -> void:
	if not mission_button_container:
		return
	for child in mission_button_container.get_children():
		child.queue_free()

	for mission in mission_definitions:
		var btn := Button.new()
		btn.text = mission.mission_name
		btn.pressed.connect(_on_mission_selected.bind(mission))
		mission_button_container.add_child(btn)


func _on_mission_selected(mission : MissionDefinitionResource) -> void:
	_selected_mission = mission
	if mission_briefing_label:
		mission_briefing_label.text = mission.mission_briefing
	ExtractionLoopManager.select_mission(mission.mission_id)


func _on_deploy_pressed() -> void:
	if not _selected_mission:
		return
	var stash : Node = get_node_or_null("/root/PersistentStashManager")
	var slots : Array = stash.stash_items if stash else []
	ExtractionLoopManager.deploy(slots)
	# The caller should listen to ExtractionLoopManager.raid_started and load the mission scene.


# ─── Factions tab ─────────────────────────────────────────────────────────────

func _populate_factions() -> void:
	if not faction_list_container:
		return
	for child in faction_list_container.get_children():
		child.queue_free()

	if not FactionRegistry:
		return

	for faction in FactionRegistry.factions:
		var row := Label.new()
		var rep : int = FactionRegistry.get_reputation(faction.faction_id)
		var stance_str : String = ["Friendly", "Neutral", "Hostile"][FactionRegistry.get_stance(faction.faction_id)]
		row.text = faction.faction_name + "  Rep: " + str(rep) + "  (" + stance_str + ")"
		faction_list_container.add_child(row)
