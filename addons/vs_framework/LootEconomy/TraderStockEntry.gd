## TraderStockEntry — one line item in a TraderStock resource.
extends Resource
class_name TraderStockEntry

## Item resource to sell to the player.
@export var inventory_item : InventoryItemPD

## Buy price (player pays this to the trader).
@export var buy_price : int = 200

## Sell price (trader pays this when player sells an item of this type).
@export var sell_price : int = 80

## How many the trader has in stock (-1 = unlimited).
@export var stock_quantity : int = -1

## Minimum faction stance required for this specific item:
## 0 = friendly, 1 = neutral, 2 = hostile (never shown).
@export_range(0, 1) var min_stance : int = 1

## Current runtime quantity (initialised from stock_quantity at session start).
var _quantity_runtime : int = -1


func get_runtime_quantity() -> int:
	if _quantity_runtime == -1:
		_quantity_runtime = stock_quantity
	return _quantity_runtime


func consume_one() -> void:
	if _quantity_runtime > 0:
		_quantity_runtime -= 1
