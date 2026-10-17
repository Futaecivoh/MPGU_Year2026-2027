class_name HitboxComponent
extends Area3D
## 3D Area that deals damage to HurtboxComponents on matching collision masks.

signal hit_landed(hurtbox: Area3D)

@export var damage: float = 20.0
@export var knockback_force: float = 6.0

var owner_entity: Node3D = null


func _ready() -> void:
	if owner_entity == null and owner is Node3D:
		owner_entity = owner as Node3D


func get_knockback_vector(target_position: Vector3) -> Vector3:
	var origin: Vector3 = global_position
	if owner_entity != null and is_instance_valid(owner_entity):
		origin = owner_entity.global_position
	var direction: Vector3 = target_position - origin
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		direction = Vector3.BACK
	return direction.normalized() * knockback_force
