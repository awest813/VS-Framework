## TraderStock — resource defining what a single trader sells.
extends Resource
class_name TraderStock

## Internal id of the trader.
@export var trader_id : String = ""
@export var trader_name : String = "Trader"
@export_multiline var trader_description : String = ""

## Faction id of the trader. FactionRegistry reputation gates items.
@export var faction_id : String = ""

## Minimum faction stance required to access this trader's full stock:
## 0 = friendly required, 1 = neutral OK, 2 = always open
@export_range(0, 2) var min_stance_required : int = 1

## Array of TraderStockEntry resources.
@export var stock : Array[TraderStockEntry] = []


## Returns stock entries the player is allowed to see given their faction stance.
func get_available_stock(player_stance : int) -> Array[TraderStockEntry]:
	if player_stance > min_stance_required:
		return []
	var available : Array[TraderStockEntry] = []
	for entry in stock:
		if player_stance <= entry.min_stance:
			available.append(entry)
	return available
