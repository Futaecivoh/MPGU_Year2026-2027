extends Node
## Global EventBus for decoupled communication between Gameplay/Combat (Dev 1)
## and World/Economy/UI systems (Dev 2).

# Player signals
signal player_spawned(player: Node3D)
signal player_health_changed(current_hp: float, max_hp: float)
signal player_armor_changed(current_armor: float, max_armor: float)
signal player_died()
signal player_dashed(cooldown: float)

# Combat & Enemy signals
signal enemy_damaged(enemy: Node3D, amount: float, is_critical: bool)
signal enemy_killed(enemy_position: Vector3, run_currency_reward: int, meta_currency_reward: int)

# Economy & Progression signals
signal currency_updated(run_currency: int, meta_currency: int)
signal map_node_selected(node_id: String, node_type: String)
