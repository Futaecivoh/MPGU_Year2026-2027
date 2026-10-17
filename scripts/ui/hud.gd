extends CanvasLayer
## HUD displaying Player HP, Armor, two-tier Currencies, and control hints.

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/HPBar/HPLabel
@onready var armor_bar: ProgressBar = $MarginContainer/VBoxContainer/ArmorBar
@onready var armor_label: Label = $MarginContainer/VBoxContainer/ArmorBar/ArmorLabel
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/AmmoLabel
@onready var run_currency_label: Label = $MarginContainer/VBoxContainer/CurrencyBox/RunCurrencyLabel
@onready var meta_currency_label: Label = $MarginContainer/VBoxContainer/CurrencyBox/MetaCurrencyLabel


func _ready() -> void:
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_armor_changed.connect(_on_player_armor_changed)
	EventBus.player_ammo_changed.connect(_on_player_ammo_changed)
	EventBus.player_out_of_ammo.connect(_on_player_out_of_ammo)
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


func _on_player_ammo_changed(current_ammo: int, max_ammo: int) -> void:
	if ammo_label == null:
		return
	var pips: String = ""
	for i in range(max_ammo):
		pips += "● " if i < current_ammo else "○ "
	if current_ammo > 0:
		ammo_label.text = "Пули (Пистоль): %s(%d / %d)" % [pips, current_ammo, max_ammo]
		ammo_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 1.0))
	else:
		ammo_label.text = "Пули (Пистоль): ПУСТО (0 / %d)" % max_ammo
		ammo_label.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35, 1.0))


func _on_player_out_of_ammo() -> void:
	if ammo_label == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(ammo_label, "modulate", Color(1.0, 0.2, 0.2, 1.0), 0.08)
	tween.tween_property(ammo_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)


func _on_currency_updated(run_curr: int, meta_curr: int) -> void:
	if run_currency_label:
		run_currency_label.text = "Ран-валюта (Ром/Песо): %d" % run_curr
	if meta_currency_label:
		meta_currency_label.text = "Мета-валюта (Дублоны): %d" % meta_curr
