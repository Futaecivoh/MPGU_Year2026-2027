class_name HealthComponent
extends Node
## Reusable component for managing Health, Armor, and Invulnerability on any entity.

signal health_changed(current_hp: float, max_hp: float)
signal armor_changed(current_armor: float, max_armor: float)
signal damaged(amount: float, knockback_vector: Vector3)
signal died()

@export var max_health: float = 100.0
@export var max_armor: float = 0.0
@export var is_invulnerable: bool = false

var current_health: float = 100.0
var current_armor: float = 0.0
var is_dead: bool = false


func _ready() -> void:
	current_health = max_health
	current_armor = max_armor
	health_changed.emit(current_health, max_health)
	armor_changed.emit(current_armor, max_armor)


func take_damage(amount: float, knockback_vector: Vector3 = Vector3.ZERO) -> void:
	if is_dead or is_invulnerable or amount <= 0.0:
		return

	var remaining_damage: float = amount

	# Armor absorbs incoming damage first
	if current_armor > 0.0:
		var absorbed: float = min(current_armor, remaining_damage)
		current_armor -= absorbed
		remaining_damage -= absorbed
		armor_changed.emit(current_armor, max_armor)

	if remaining_damage > 0.0:
		current_health = max(0.0, current_health - remaining_damage)
		health_changed.emit(current_health, max_health)

	damaged.emit(amount, knockback_vector)

	if current_health <= 0.0 and not is_dead:
		is_dead = true
		died.emit()


func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func restore_full() -> void:
	is_dead = false
	current_health = max_health
	current_armor = max_armor
	health_changed.emit(current_health, max_health)
	armor_changed.emit(current_armor, max_armor)
