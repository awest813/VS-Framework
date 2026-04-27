## WeaponModdingComponent — manages attachment slots on a wieldable weapon.
##
## Add as a child of any CogitoWieldable (gun) scene. Configure which slots
## are available for this weapon by populating available_slots. Attach or remove
## WeaponAttachment resources at runtime via the mod UI or trader screens.
##
## Wire the stat properties (get_total_damage_modifier, etc.) into your weapon's
## fire logic to apply attachment bonuses.
extends Node
class_name WeaponModdingComponent

signal attachment_added(slot : int, attachment : WeaponAttachment)
signal attachment_removed(slot : int, attachment : WeaponAttachment)
signal stats_changed

## Which slots are physically present on this weapon model.
@export var available_slots : Array[WeaponAttachment.AttachmentSlot] = []

## Runtime equipped attachments: { AttachmentSlot → WeaponAttachment }.
var _equipped : Dictionary = {}


func _ready() -> void:
	pass


# ─── Public API ───────────────────────────────────────────────────────────────

## Equips an attachment into its designated slot.
## Returns false if the slot is not available on this weapon or is already occupied.
func equip_attachment(attachment : WeaponAttachment) -> bool:
	if not attachment:
		return false
	if attachment.slot not in available_slots:
		push_warning("WeaponModdingComponent: slot %s not available on this weapon." % _slot_name(attachment.slot))
		return false
	if _equipped.has(attachment.slot):
		push_warning("WeaponModdingComponent: slot already occupied — remove the current attachment first.")
		return false
	_equipped[attachment.slot] = attachment
	stats_changed.emit()
	attachment_added.emit(attachment.slot, attachment)
	CogitoGlobals.debug_log(true, "WeaponModdingComponent",
		"Equipped " + attachment.attachment_name + " in slot " + _slot_name(attachment.slot))
	return true


## Removes the attachment from a slot. Returns the removed attachment or null.
func remove_attachment(slot : WeaponAttachment.AttachmentSlot) -> WeaponAttachment:
	if not _equipped.has(slot):
		return null
	var removed : WeaponAttachment = _equipped[slot]
	_equipped.erase(slot)
	stats_changed.emit()
	attachment_removed.emit(slot, removed)
	CogitoGlobals.debug_log(true, "WeaponModdingComponent",
		"Removed " + removed.attachment_name + " from slot " + _slot_name(slot))
	return removed


## Returns the currently equipped attachment for a slot, or null if empty.
func get_attachment(slot : WeaponAttachment.AttachmentSlot) -> WeaponAttachment:
	return _equipped.get(slot, null)


## Returns true if the slot has an attachment equipped.
func has_attachment(slot : WeaponAttachment.AttachmentSlot) -> bool:
	return _equipped.has(slot)


## Returns all currently equipped attachments as an Array[WeaponAttachment].
func get_all_attachments() -> Array[WeaponAttachment]:
	var result : Array[WeaponAttachment] = []
	for att : WeaponAttachment in _equipped.values():
		result.append(att)
	return result


# ─── Aggregate stat helpers ────────────────────────────────────────────────────

## Sum of all damage_modifier values across equipped attachments.
func get_total_damage_modifier() -> float:
	return _sum_float("damage_modifier")


## Sum of all accuracy_modifier values across equipped attachments.
func get_total_accuracy_modifier() -> float:
	return _sum_float("accuracy_modifier")


## Sum of all recoil_modifier values across equipped attachments.
func get_total_recoil_modifier() -> float:
	return _sum_float("recoil_modifier")


## Sum of all ads_speed_modifier values across equipped attachments.
func get_total_ads_speed_modifier() -> float:
	return _sum_float("ads_speed_modifier")


## Sum of all magazine_modifier values across equipped attachments.
func get_total_magazine_modifier() -> int:
	var total : int = 0
	for att : WeaponAttachment in _equipped.values():
		total += att.magazine_modifier
	return total


## Sum of all move_speed_modifier values across equipped attachments.
func get_total_move_speed_modifier() -> float:
	return _sum_float("move_speed_modifier")


## Total weight contributed by all equipped attachments.
func get_total_attachment_weight() -> float:
	return _sum_float("weight")


# ─── Internal ─────────────────────────────────────────────────────────────────

func _sum_float(property : String) -> float:
	var total : float = 0.0
	for att : WeaponAttachment in _equipped.values():
		total += att.get(property) as float
	return total


## Returns a human-readable name for an AttachmentSlot enum value.
## Avoids out-of-bounds array indexing by using a dictionary lookup instead.
func _slot_name(slot : WeaponAttachment.AttachmentSlot) -> String:
	var names : Dictionary = {
		WeaponAttachment.AttachmentSlot.SIGHT: "SIGHT",
		WeaponAttachment.AttachmentSlot.MUZZLE: "MUZZLE",
		WeaponAttachment.AttachmentSlot.GRIP: "GRIP",
		WeaponAttachment.AttachmentSlot.MAGAZINE: "MAGAZINE",
		WeaponAttachment.AttachmentSlot.STOCK: "STOCK",
		WeaponAttachment.AttachmentSlot.TACTICAL: "TACTICAL",
	}
	return names.get(slot, "UNKNOWN")
