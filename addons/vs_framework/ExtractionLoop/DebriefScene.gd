## DebriefScene controller — attach to the root of your debrief screen scene.
##
## Reads the last session from ExtractionLoopManager and populates the UI.
extends Control
class_name DebriefScene

@export var label_outcome : Label
@export var label_time : Label
@export var label_currency : Label
@export var label_xp : Label
@export var item_list_container : VBoxContainer
@export var button_continue : Button

## XP awarded per item extracted.
@export var xp_per_item : int = 10

## Currency earned per item (simple flat rate; override for richer economy).
@export var currency_per_item : int = 5


func _ready() -> void:
	var loop : Node = get_node_or_null("/root/ExtractionLoopManager")
	if not loop:
		push_warning("DebriefScene: ExtractionLoopManager autoload not found.")
		return

	var session : RunSessionResource = loop.active_session

	if button_continue:
		button_continue.pressed.connect(_on_continue_pressed)

	_populate(session)


func _populate(session : RunSessionResource) -> void:
	if not session:
		if label_outcome:
			label_outcome.text = "Run data unavailable."
		return

	# Outcome text
	if label_outcome:
		label_outcome.text = "SUCCESS" if session.is_alive else "KILLED IN ACTION"

	# Time
	if label_time:
		var minutes := int(session.elapsed_time) / 60
		var seconds := int(session.elapsed_time) % 60
		label_time.text = "Raid time: %02d:%02d" % [minutes, seconds]

	# Currency & XP
	var total_xp : int = session.raid_inventory.size() * xp_per_item if session.is_alive else 0
	var total_currency : int = session.raid_inventory.size() * currency_per_item if session.is_alive else 0

	if label_currency:
		label_currency.text = "Currency earned: %d" % total_currency
	if label_xp:
		label_xp.text = "XP earned: %d" % total_xp

	# Item list
	if item_list_container:
		for child in item_list_container.get_children():
			child.queue_free()

		var items_to_show : Array = session.raid_inventory if session.is_alive else session.stash_snapshot
		var prefix : String = "EXTRACTED: " if session.is_alive else "LOST: "
		for entry in items_to_show:
			var row := Label.new()
			row.text = prefix + str(entry.get("item_name", "Unknown")) + " x" + str(entry.get("quantity", 1))
			item_list_container.add_child(row)


func _on_continue_pressed() -> void:
	var loop : Node = get_node_or_null("/root/ExtractionLoopManager")
	if loop:
		loop.close_debrief()
