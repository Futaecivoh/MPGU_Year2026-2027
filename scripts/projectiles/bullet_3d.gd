class_name Bullet3D
extends Node3D
## 3D Projectile for Flintlock / Musket ranged attacks.

var direction: Vector3 = Vector3.FORWARD
var speed: float = 24.0
var lifetime: float = 1.5

@onready var hitbox: HitboxComponent = $HitboxComponent


func _ready() -> void:
	hitbox.hit_landed.connect(_on_hit_landed)
	hitbox.body_entered.connect(_on_body_entered)


func setup(shoot_dir: Vector3, dmg: float, knockback: float, proj_speed: float, proj_lifetime: float, shooter: Node3D) -> void:
	direction = shoot_dir.normalized()
	direction.y = 0.0
	speed = proj_speed
	lifetime = proj_lifetime
	if hitbox != null:
		hitbox.damage = dmg
		hitbox.knockback_force = knockback
		hitbox.owner_entity = shooter
	if direction.length_squared() > 0.001:
		look_at(global_position + direction, Vector3.UP)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_hit_landed(_hurtbox: Area3D) -> void:
	queue_free()


func _on_body_entered(_body: Node3D) -> void:
	# Hit a static wall/obstacle
	queue_free()
