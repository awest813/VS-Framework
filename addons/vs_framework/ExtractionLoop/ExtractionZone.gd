## ExtractionZone — place this in a raid level to give the player an exit.
##
## The zone can be sealed until an objective is met or a timer expires.
## When the player enters and presses the interact key, extraction begins.
extends Area3D
class_name ExtractionZone

signal extraction_triggered
signal zone_opened
signal zone_sealed

## If true the zone starts sealed and must be opened via open_zone().
@export var starts_sealed : bool = false

## Delay in seconds between the player pressing interact and extraction completing.
@export var extraction_delay : float = 3.0

## Items/currency to report back to ExtractionLoopManager.
## Populated at runtime from the player's current raid inventory.
@export var hint_text_sealed : String = "Extraction sealed — complete your objective first."
@export var hint_text_open : String = "Extract"

## Whether the zone is currently open.
var is_open : bool = true

var _player_inside : bool = false
var _player_node : Node = null
var _extraction_timer : Timer = null
var _extracting : bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_extraction_timer = Timer.new()
	_extraction_timer.wait_time = extraction_delay
	_extraction_timer.one_shot = true
	_extraction_timer.timeout.connect(_on_extraction_timer_timeout)
	add_child(_extraction_timer)

	if starts_sealed:
		is_open = false


func _process(_delta : float) -> void:
	if _player_inside and is_open and not _extracting:
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("interact2"):
			_start_extraction()


## Opens the extraction zone.
func open_zone() -> void:
	is_open = true
	zone_opened.emit()
	_send_player_hint(_player_node, "Extraction zone is now open.")


## Seals the extraction zone.
func seal_zone() -> void:
	is_open = false
	zone_sealed.emit()


func _on_body_entered(body : Node3D) -> void:
	if body.is_in_group("Player"):
		_player_inside = true
		_player_node = body
		if not is_open:
			_send_player_hint(body, hint_text_sealed)
		else:
			_send_player_hint(body, hint_text_open)


func _on_body_exited(body : Node3D) -> void:
	if body.is_in_group("Player"):
		_player_inside = false
		_player_node = null
		if _extracting:
			_cancel_extraction()


func _start_extraction() -> void:
	_extracting = true
	ExtractionLoopManager.begin_extraction()
	_extraction_timer.start()
	extraction_triggered.emit()
	CogitoGlobals.debug_log(true, "ExtractionZone", "Extraction started. Timer: " + str(extraction_delay) + "s")


func _cancel_extraction() -> void:
	_extracting = false
	_extraction_timer.stop()
	CogitoGlobals.debug_log(true, "ExtractionZone", "Extraction cancelled — player left zone.")


func _on_extraction_timer_timeout() -> void:
	_extracting = false
	# Gather what the player is carrying and report to the loop manager.
	var extracted_items : Array[Dictionary] = []
	var earned_currency : int = 0
	if _player_node:
		var inventory = _player_node.get("inventory_data")
		var inventory_slots := VSInventorySlotUtils.get_inventory_slots(inventory)
		if inventory_slots:
			for slot in inventory_slots:
				var item_name := VSInventorySlotUtils.get_slot_item_name(slot)
				if item_name.is_empty():
					continue
				extracted_items.append({
					"item_name": item_name,
					"quantity": VSInventorySlotUtils.get_slot_quantity(slot)
				})
	ExtractionLoopManager.complete_extraction(extracted_items, earned_currency)


func _send_player_hint(player : Node, message : String) -> void:
	if not player:
		return
	var interaction_component = player.get("player_interaction_component")
	if interaction_component and interaction_component.has_method("send_hint"):
		interaction_component.send_hint(null, message)
