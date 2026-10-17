class_name EnemyStats
extends Resource
## Custom Resource defining enemy parameters and currency drops.

@export var enemy_name: String = "Pirate Grunt"
@export var max_health: float = 100.0
@export var move_speed: float = 4.2
@export var chase_range: float = 12.0
@export var attack_range: float = 1.8
@export var attack_damage: float = 15.0
@export var attack_cooldown: float = 1.0
@export var knockback_resistance: float = 0.2
@export var run_currency_drop: int = 10
@export var meta_currency_drop: int = 2
