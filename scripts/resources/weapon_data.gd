class_name WeaponData
extends Resource
## Custom Resource defining melee or ranged weapons.

enum WeaponType {
	MELEE,
	RANGED
}

@export var weapon_name: String = "Cutlass"
@export var weapon_type: WeaponType = WeaponType.MELEE
@export var damage: float = 100.0
@export var cooldown: float = 0.35
@export var knockback_force: float = 8.0
@export var attack_duration: float = 0.18
@export var max_ammo: int = 5
@export var projectile_speed: float = 22.0
@export var projectile_lifetime: float = 1.5
