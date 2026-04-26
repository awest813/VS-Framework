## ExtractionLootDropEntry — LootDropEntry extension with tier and weight.
extends LootDropEntry
class_name ExtractionLootDropEntry

## Rarity tier of this drop (1 = common, 4 = legendary).
@export_range(1, 4) var tier : int = 1

## Weight relative to other drops in the table (higher = more likely).
@export var weight : int = 10

## Rubles / currency value of this item when sold to a trader.
@export var sell_value : int = 100
