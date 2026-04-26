## ExtractionLootTable — extends COGITO's LootTable with tier filtering.
##
## Tier 1 = common, Tier 4 = rare. The generator rolls only items whose tier is
## ≤ max_tier_allowed. max_tier_allowed can be raised by mission difficulty.
extends LootTable
class_name ExtractionLootTable

enum Tier { COMMON = 1, UNCOMMON = 2, RARE = 3, LEGENDARY = 4 }

## The highest tier of items allowed to drop from this table.
@export var max_tier_allowed : Tier = Tier.UNCOMMON

## Total weight of items that should be generated per roll call.
@export var weight_budget : int = 100


## Returns a filtered subset of drops respecting max_tier_allowed.
func get_filtered_drops() -> Array:
	var filtered : Array = []
	for drop in drops:
		if drop is ExtractionLootDropEntry:
			if drop.tier <= max_tier_allowed:
				filtered.append(drop)
		else:
			filtered.append(drop)
	return filtered
