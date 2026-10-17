extends CanvasLayer
## HUD displaying Player HP, Armor, two-tier Currencies, and control hints.

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPBar/HPLabel
@onready var armor_bar: ProgressBar = $MarginContainer/VBoxContainer/ArmorBar
@onready var armor_label: Label = $MarginContainer/VBoxContainer/ArmorBar/ArmorLabel
@onready var run_currency_label: Label = $MarginContainer/VBoxContainer/CurrencyBox/RunCurrencyLabel
@onready var meta_currency_label: Label = $MarginContainer/VBoxContainer/CurrencyBox/MetaCurrencyLabel


func _ready() -> void:
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_armor_changed.connect(_on_player_armor_changed)
	EventBus.currency_updated.connect(_on_currency_updated)

	_on_currency_updated(GameManager.run_currency, GameManager.meta_currency)


func _on_player_health_changed(current_hp: float, max_hp: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
	if hp_label:
		hp_label.text = "Здоровье (HP): %d / %d" % [ceili(current_hp), ceili(max_hp)]


func _on_player_armor_changed(current_armor: float, max_armor: float) -> void:
	if armor_bar:
		armor_bar.max_value = max(1.0, max_armor)
		armor_bar.value = current_armor
	if armor_label:
		armor_label.text = "Броня (Armor): %d / %d" % [ceili(current_armor), ceili(max_armor)]


func _on_currency_updated(run_curr: int, meta_curr: int) -> void:
	if run_currency_label:
		run_currency_label.text = "Ран-валюта (Ром/Песо): %d" % run_curr
	if meta_currency_label:
		meta_currency_label.text = "Мета-валюта (Дублоны): %d" % meta_curr
