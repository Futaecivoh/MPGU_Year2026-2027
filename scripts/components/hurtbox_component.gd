class_name HurtboxComponent
extends Area3D
## 3D Area that receives damage from HitboxComponents and forwards it to HealthComponent.

signal hurt(damage: float, knockback: Vector3)

@export var health_component: HealthComponent
@export var invincibility_duration: float = 0.15

var _invincibility_timer: float = 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer -= delta


func _on_area_entered(area: Area3D) -> void:
	if _invincibility_timer > 0.0:
		return

	var hitbox := area as HitboxComponent
	if hitbox == null:
		return

	if health_component != null and (health_component.is_dead or health_component.is_invulnerable):
		return

	_invincibility_timer = invincibility_duration
	var knockback: Vector3 = hitbox.get_knockback_vector(global_position)

	if health_component != null:
		health_component.take_damage(hitbox.damage, knockback)

	hurt.emit(hitbox.damage, knockback)
	hitbox.hit_landed.emit(self)
