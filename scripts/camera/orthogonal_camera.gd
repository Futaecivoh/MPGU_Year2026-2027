class_name OrthogonalCameraRig
extends Node3D
## Orthogonal 3D Camera Rig that follows a target smoothly and maintains
## an angled isometric/top-down orthographic projection.

@export var target: Node3D
@export var follow_speed: float = 10.0
@export var pitch_degrees: float = -50.0
@export var yaw_degrees: float = 45.0
@export var orthogonal_size: float = 14.0
@export var camera_distance: float = 35.0

@onready var camera_3d: Camera3D = $Camera3D


func _ready() -> void:
	_apply_camera_settings()
	if target != null:
		global_position = target.global_position


func _physics_process(delta: float) -> void:
	if target != null and is_instance_valid(target):
		global_position = global_position.lerp(target.global_position, clampf(follow_speed * delta, 0.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			orthogonal_size = clampf(orthogonal_size - 1.0, 7.0, 28.0)
			if camera_3d:
				camera_3d.size = orthogonal_size
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			orthogonal_size = clampf(orthogonal_size + 1.0, 7.0, 28.0)
			if camera_3d:
				camera_3d.size = orthogonal_size


func _apply_camera_settings() -> void:
	rotation_degrees = Vector3(pitch_degrees, yaw_degrees, 0.0)
	if camera_3d != null:
		camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera_3d.size = orthogonal_size
		camera_3d.position = Vector3(0.0, 0.0, camera_distance)
		camera_3d.near = 0.05
		camera_3d.far = 200.0
		camera_3d.current = true
