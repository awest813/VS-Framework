## FieldCacheSaveData — persisted snapshot of all field cache stash contents.
extends Resource
class_name FieldCacheSaveData

## Map of cache_id → Array of {item_name, quantity} dictionaries.
@export var cache_data : Dictionary = {}
