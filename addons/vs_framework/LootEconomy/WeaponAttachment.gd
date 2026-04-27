## WeaponAttachment — resource describing one modular weapon attachment.
##
## Create .tres files for each attachment type (scopes, suppressors, grips, etc.).
## Assign them to WeaponModdingComponent slots via the editor or at runtime.
extends Resource
class_name WeaponAttachment

enum AttachmentSlot {
	SIGHT,       ## Optics / scope slot.
	MUZZLE,      ## Suppressor, flash-hider, compensator.
	GRIP,        ## Foregrip / vertical grip.
	MAGAZINE,    ## Extended / drum / reduced-capacity mag.
	STOCK,       ## Stock or folding brace.
	TACTICAL,    ## Laser, flashlight, etc.
}

## Unique identifier used for save/load and conflict checks.
@export var attachment_id : String = ""

## Display name shown in the mod UI.
@export var attachment_name : String = ""

## Tooltip description.
@export_multiline var description : String = ""

## Which weapon slot this attachment occupies.
@export var slot : AttachmentSlot = AttachmentSlot.SIGHT

## Additive modifier to weapon damage (negative = reduces damage).
@export var damage_modifier : float = 0.0

## Additive modifier to accuracy (0–1 scale; positive = tighter spread).
@export var accuracy_modifier : float = 0.0

## Additive modifier to recoil (positive = more recoil, negative = less).
@export var recoil_modifier : float = 0.0

## Additive modifier to ADS (aim-down-sights) speed multiplier.
@export var ads_speed_modifier : float = 0.0

## Additive modifier to magazine capacity (integer part used).
@export var magazine_modifier : int = 0

## Additive modifier to movement speed while weapon is raised (0–1 scale).
@export var move_speed_modifier : float = 0.0

## Ergonomic weight of this attachment (contributes to EncumbranceComponent).
@export var weight : float = 0.1

## ItemCondition node path on the weapon (optional; attachment degrades with use).
@export var requires_item_condition : bool = false
