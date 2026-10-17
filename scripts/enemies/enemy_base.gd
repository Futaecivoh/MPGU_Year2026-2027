class_name EnemyBase
extends CharacterBody3D
## Base 3D Enemy with Hurtbox, Attack Hitbox, HealthComponent, state machine,
## knockback physics, and currency drop on death.

enum State {
	IDLE,
	CHASE,
	ATTACK,
	DEAD
}

@export var stats: EnemyStats
@export var is_training_dummy: bool = false

@onready var visuals: Node3D = $Visuals
@onready var body_mesh: MeshInstance3D = $Visuals/BodyMesh
@onready var health_label: Label3D = $HealthLabel3D
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var attack_hitbox: HitboxComponent = $Visuals/AttackHitbox
@onready var attack_collision: CollisionShape3D = $Visuals/AttackHitbox/CollisionShape3D

var current_state: State = State.IDLE
var _target_player: Node3D = null
var _knockback_velocity: Vector3 = Vector3.ZERO
var _attack_timer: float = 0.0
var _spawn_position: Vector3 = Vector3.ZERO
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _ready() -> void:
	add_to_group("enemies")
	_spawn_position = global_position
	attack_hitbox.owner_entity = self

	if stats != null:
		health_component.max_health = stats.max_health
		health_component.current_health = stats.max_health
		attack_hitbox.damage = stats.attack_damage

	if is_training_dummy or (stats != null and stats.move_speed <= 0.0):
		attack_collision.set_deferred("disabled", true)

	health_component.health_changed.connect(_on_health_changed)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)

	_update_health_label()


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if _target_player == null or not is_instance_valid(_target_player):
		_target_player = get_tree().get_first_node_in_group("player") as Node3D

	if _attack_timer > 0.0:
		_attack_timer -= delta

	var move_spd: float = stats.move_speed if stats != null else 4.0
	var chase_dist: float = stats.chase_range if stats != null else 12.0
	var atk_dist: float = stats.attack_range if stats != null else 1.7

	if not is_training_dummy and move_spd > 0.0 and _target_player != null:
		var to_player: Vector3 = _target_player.global_position - global_position
		to_player.y = 0.0
		var distance: float = to_player.length()

		if distance <= atk_dist:
			current_state = State.ATTACK
			velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
			_face_direction(to_player.normalized(), delta)
			if _attack_timer <= 0.0:
				_perform_melee_lunge()
		elif distance <= chase_dist:
			current_state = State.CHASE
			var dir: Vector3 = to_player.normalized()
			velocity.x = dir.x * move_spd
			velocity.z = dir.z * move_spd
			_face_direction(dir, delta)
		else:
			current_state = State.IDLE
			velocity.x = move_toward(velocity.x, 0.0, 15.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 15.0 * delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.x += _knockback_velocity.x
	velocity.z += _knockback_velocity.z
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 24.0 * delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()


func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length_squared() > 0.001:
		var target_angle: float = atan2(-dir.x, -dir.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, clampf(12.0 * delta, 0.0, 1.0))


func _perform_melee_lunge() -> void:
	var cd: float = stats.attack_cooldown if stats != null else 1.0
	_attack_timer = cd

	attack_collision.set_deferred("disabled", false)
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "position:z", -0.35, 0.1)
	tween.tween_property(visuals, "position:z", 0.0, 0.15)
	tween.tween_callback(func() -> void:
		if not is_training_dummy:
			attack_collision.set_deferred("disabled", false)
	)


func _on_health_changed(_current: float, _max: float) -> void:
	_update_health_label()


func _on_damaged(amount: float, knockback: Vector3) -> void:
	var resist: float = stats.knockback_resistance if stats != null else 0.2
	_knockback_velocity = knockback * clampf(1.0 - resist, 0.0, 1.0)
	EventBus.enemy_damaged.emit(self, amount, false)
	_flash_hit()


func _on_died() -> void:
	current_state = State.DEAD
	var run_drop: int = stats.run_currency_drop if stats != null else 10
	var meta_drop: int = stats.meta_currency_drop if stats != null else 2
	EventBus.enemy_killed.emit(global_position, run_drop, meta_drop)

	if is_training_dummy:
		# Respawn the training dummy after a brief pause so the player can keep testing
		visible = false
		hurtbox_component.set_deferred("monitorable", false)
		hurtbox_component.set_deferred("monitoring", false)
		var timer := get_tree().create_timer(1.5)
		timer.timeout.connect(func() -> void:
			if is_inside_tree():
				global_position = _spawn_position
				health_component.restore_full()
				current_state = State.IDLE
				visible = true
				hurtbox_component.set_deferred("monitorable", true)
				hurtbox_component.set_deferred("monitoring", true)
				_update_health_label()
		)
	else:
		queue_free()


func _update_health_label() -> void:
	if health_label == null or health_component == null:
		return
	var title: String = stats.enemy_name if stats != null else "Враг"
	health_label.text = "%s\n%d / %d HP" % [title, ceili(health_component.current_health), ceili(health_component.max_health)]


func _flash_hit() -> void:
	if body_mesh == null:
		return
	var mat := body_mesh.get_active_material(0) as StandardMaterial3D
	if mat == null:
		return
	var orig_color: Color = mat.albedo_color
	mat.albedo_color = Color(1.0, 0.95, 0.7, 1.0)
	var timer := get_tree().create_timer(0.1)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(mat):
			mat.albedo_color = orig_color
	)
