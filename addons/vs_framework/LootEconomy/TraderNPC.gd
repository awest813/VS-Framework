## TraderNPC — hub NPC that the player can buy from and sell to.
##
## Attach to a CogitoObject or static interactable and assign a TraderStock resource.
## The trade UI is opened via COGITO's interact signal.
extends Node
class_name TraderNPC

signal trade_opened(trader_stock : TraderStock)
signal trade_closed
signal item_bought(entry : TraderStockEntry)
signal item_sold(item_name : String, currency_received : int)

@export var trader_stock : TraderStock

## Reference to the TraderUI scene (Control node) to open. Optional.
@export var trader_ui_scene : PackedScene

var _ui_instance : Control = null
var _player_node : Node = null


func _ready() -> void:
	call_deferred("_find_player")


## Called by the interaction system (wire to interactable's interact signal).
func open_trade(player_interaction_component : Node) -> void:
	_player_node = player_interaction_component.get_parent()

	if not trader_stock:
		push_warning("TraderNPC: No TraderStock assigned.")
		return

	var stance : int = 1
	if FactionRegistry and not trader_stock.faction_id.is_empty():
		stance = FactionRegistry.get_stance(trader_stock.faction_id)

	if stance > trader_stock.min_stance_required:
		player_interaction_component.send_hint(null, trader_stock.trader_name + " won't deal with you.")
		return

	if trader_ui_scene and not _ui_instance:
		_ui_instance = trader_ui_scene.instantiate() as Control
		get_tree().current_scene.add_child(_ui_instance)

	if _ui_instance and _ui_instance.has_method("open"):
		_ui_instance.open(trader_stock, _player_node)

	trade_opened.emit(trader_stock)


## Processes a buy request from the UI.
func buy_item(entry : TraderStockEntry) -> bool:
	if not _player_node:
		return false

	var stash : Node = get_node_or_null("/root/PersistentStashManager")
	if not stash:
		return false

	if entry.get_runtime_quantity() == 0:
		return false

	if not stash.spend_currency(entry.buy_price):
		_player_node.player_interaction_component.send_hint(null, "Not enough currency.")
		return false

	entry.consume_one()
	item_bought.emit(entry)

	# Add to player inventory via COGITO's inventory system
	if _player_node.inventory_data and entry.inventory_item:
		_player_node.inventory_data.pick_up_item(entry.inventory_item, 1)

	return true


## Processes a sell request from the UI.
func sell_item(item_name : String, sell_price : int) -> void:
	var stash : Node = get_node_or_null("/root/PersistentStashManager")
	if stash:
		stash.commit_extraction([], sell_price)
	item_sold.emit(item_name, sell_price)


func close_trade() -> void:
	if _ui_instance and _ui_instance.has_method("close"):
		_ui_instance.close()
	trade_closed.emit()


func _find_player() -> void:
	_player_node = get_tree().get_first_node_in_group("Player")
