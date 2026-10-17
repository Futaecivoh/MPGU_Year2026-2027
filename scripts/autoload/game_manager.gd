extends Node
## Manages two-tier economy (Run Currency vs Meta Currency) and global session state.

var run_currency: int = 0:
	set(value):
		run_currency = max(0, value)
		EventBus.currency_updated.emit(run_currency, meta_currency)

var meta_currency: int = 0:
	set(value):
		meta_currency = max(0, value)
		EventBus.currency_updated.emit(run_currency, meta_currency)


func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.player_died.connect(_on_player_died)


func add_currencies(run_amount: int, meta_amount: int) -> void:
	run_currency += run_amount
	meta_currency += meta_amount


func reset_run_currency() -> void:
	run_currency = 0


func _on_enemy_killed(_pos: Vector3, run_reward: int, meta_reward: int) -> void:
	add_currencies(run_reward, meta_reward)


func _on_player_died() -> void:
	# On death in a roguelike run, temporary run currency is lost, meta currency stays
	reset_run_currency()
