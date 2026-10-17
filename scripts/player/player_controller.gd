class_name PlayerController
extends CharacterBody3D
## 3D Player Controller tailored for an Orthogonal Camera action-roguelike.
## Supports camera-relative WASD movement, mouse cursor aiming on XZ plane,
## invulnerability dash, melee cutlass slash (LMB), and flintlock shot (RMB).

@export_group("Movement")
@export var move_speed: float = 7.5
@export var acceleration: float = 40.0
@export var friction: float = 35.0
@export var rotation_speed: float = 20.0

@export_group("Dash")
@export var dash_speed: float = 20.0
@export var dash_duration: float = 0.18
@export var dash_cooldown: float = 0.65

@export_group("Combat")
@export var melee_weapon: WeaponData
@export var ranged_weapon: WeaponData
@export var bullet_scene: PackedScene

@onready var visuals: Node3D = $Visuals
@onready var body_mesh: MeshInstance3D = $Visuals/BodyMesh
@onready var melee_pivot: Node3D = $Visuals/MeleePivot
@onready var melee_hitbox: HitboxComponent = $Visuals/MeleePivot/MeleeHitbox
@onready var melee_collision: CollisionShape3D = $Visuals/MeleePivot/MeleeHitbox/CollisionShape3D
@onready var slash_visual: MeshInstance3D = $Visuals/MeleePivot/SlashMesh
@onready var muzzle_marker: Marker3D = $Visuals/MuzzleMarker
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent

var _aim_direction: Vector3 = Vector3.FORWARD
var _knockback_velocity: Vector3 = Vector3.ZERO
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.FORWARD
var _melee_cooldown_timer: float = 0.0
var _ranged_cooldown_timer: float = 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _ready() -> void:
	add_to_group("player")
	melee_hitbox.owner_entity = self
	melee_collision.disabled = true
	slash_visual.visible = false

	if melee_weapon != null:
		melee_hitbox.damage = melee_weapon.damage
		melee_hitbox.knockback_force = melee_weapon.knockback_force

	health_component.health_changed.connect(_on_health_changed)
	health_component.armor_changed.connect(_on_armor_changed)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)

	# Emit initial state to HUD
	EventBus.player_spawned.emit(self)
	EventBus.player_health_changed.emit(health_component.current_health, health_component.max_health)
	EventBus.player_armor_changed.emit(health_component.current_armor, health_component.max_armor)


func _physics_process(delta: float) -> void:
	if health_component.is_dead:
		return

	_update_timers(delta)
	_update_mouse_aim(delta)

	var move_dir: Vector3 = _get_camera_relative_input()

	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0 and not _is_dashing:
		_start_dash(move_dir)

	if _is_dashing:
		velocity.x = _dash_direction.x * dash_speed
		velocity.z = _dash_direction.z * dash_speed
	else:
		if move_dir.length_squared() > 0.001:
			velocity.x = move_toward(velocity.x, move_dir.x * move_speed, acceleration * delta)
			velocity.z = move_toward(velocity.z, move_dir.z * move_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
			velocity.z = move_toward(velocity.z, 0.0, friction * delta)

		velocity.x += _knockback_velocity.x
		velocity.z += _knockback_velocity.z

	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, 28.0 * delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	# Combat inputs
	if Input.is_action_pressed("attack_melee") and _melee_cooldown_timer <= 0.0 and not _is_dashing:
		_perform_melee_attack()

	if Input.is_action_pressed("attack_ranged") and _ranged_cooldown_timer <= 0.0 and not _is_dashing:
		_perform_ranged_attack()


func _update_timers(delta: float) -> void:
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta
	if _melee_cooldown_timer > 0.0:
		_melee_cooldown_timer -= delta
	if _ranged_cooldown_timer > 0.0:
		_ranged_cooldown_timer -= delta

	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_end_dash()


func _get_camera_relative_input() -> Vector3:
	var raw_input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if raw_input.length_squared() < 0.001:
		return Vector3.ZERO

	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return Vector3(raw_input.x, 0.0, raw_input.y).normalized()

	var cam_forward: Vector3 = -cam.global_transform.basis.z
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()

	var cam_right: Vector3 = cam.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()

	return (cam_right * raw_input.x + cam_forward * (-raw_input.y)).normalized()


func _update_mouse_aim(delta: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = cam.project_ray_origin(mouse_pos)
	var ray_normal: Vector3 = cam.project_ray_normal(mouse_pos)

	var ground_plane := Plane(Vector3.UP, global_position.y)
	var hit_point: Variant = ground_plane.intersects_ray(ray_origin, ray_normal)

	if hit_point is Vector3:
		var look_vec: Vector3 = (hit_point as Vector3) - global_position
		look_vec.y = 0.0
		if look_vec.length_squared() > 0.01:
			_aim_direction = look_vec.normalized()
			var target_angle: float = atan2(-_aim_direction.x, -_aim_direction.z)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, clampf(rotation_speed * delta, 0.0, 1.0))


func _start_dash(move_dir: Vector3) -> void:
	_is_dashing = true
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_dash_direction = move_dir if move_dir.length_squared() > 0.01 else _aim_direction
	health_component.is_invulnerable = true
	visuals.scale = Vector3(1.15, 0.8, 1.15)
	EventBus.player_dashed.emit(dash_cooldown)


func _end_dash() -> void:
	_is_dashing = false
	health_component.is_invulnerable = false
	visuals.scale = Vector3.ONE


func _perform_melee_attack() -> void:
	var cooldown: float = melee_weapon.cooldown if melee_weapon else 0.35
	var duration: float = melee_weapon.attack_duration if melee_weapon else 0.16
	if melee_weapon:
		melee_hitbox.damage = melee_weapon.damage
		melee_hitbox.knockback_force = melee_weapon.knockback_force

	_melee_cooldown_timer = cooldown
	melee_collision.set_deferred("disabled", false)
	slash_visual.visible = true

	melee_pivot.rotation_degrees.y = -65.0
	var tween: Tween = create_tween()
	tween.tween_property(melee_pivot, "rotation_degrees:y", 65.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		melee_collision.set_deferred("disabled", true)
		slash_visual.visible = false
		melee_pivot.rotation_degrees.y = 0.0
	)


func _perform_ranged_attack() -> void:
	if bullet_scene == null:
		return

	var cooldown: float = ranged_weapon.cooldown if ranged_weapon else 0.45
	var dmg: float = ranged_weapon.damage if ranged_weapon else 22.0
	var kb: float = ranged_weapon.knockback_force if ranged_weapon else 5.0
	var spd: float = ranged_weapon.projectile_speed if ranged_weapon else 24.0
	var life: float = ranged_weapon.projectile_lifetime if ranged_weapon else 1.5

	_ranged_cooldown_timer = cooldown

	var bullet := bullet_scene.instantiate() as Bullet3D
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle_marker.global_position
	bullet.setup(_aim_direction, dmg, kb, spd, life, self)


func _on_health_changed(current_hp: float, max_hp: float) -> void:
	EventBus.player_health_changed.emit(current_hp, max_hp)


func _on_armor_changed(current_armor: float, max_armor: float) -> void:
	EventBus.player_armor_changed.emit(current_armor, max_armor)


func _on_damaged(_amount: float, knockback: Vector3) -> void:
	_knockback_velocity = knockback
	_flash_damage()


func _on_died() -> void:
	EventBus.player_died.emit()
	# Brief pause, then restore for prototype testing
	var timer := get_tree().create_timer(1.2)
	timer.timeout.connect(func() -> void:
		if is_inside_tree():
			get_tree().reload_current_scene()
	)


func _flash_damage() -> void:
	if body_mesh == null:
		return
	var mat := body_mesh.get_active_material(0) as StandardMaterial3D
	if mat == null:
		return
	var orig_color: Color = mat.albedo_color
	mat.albedo_color = Color(1.0, 0.2, 0.2, 1.0)
	var timer := get_tree().create_timer(0.12)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(mat):
			mat.albedo_color = orig_color
	)
