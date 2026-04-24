extends Node2D

@onready var progress_bar: TextureProgressBar = $TextureProgressBar
@onready var hp_label: Label = $HPLabel

var _max_hp: int = 100
var _current_hp: int = 100

func _ready() -> void:
	# Ensure initial visibility is correct
	modulate.a = 0.9
	if progress_bar:
		progress_bar.value = 100.0

func update_hp(current: int, max_hp: int) -> void:
	_current_hp = current
	_max_hp = max_hp
	var ratio: float = clampf(float(current) / float(maxi(1, max_hp)), 0.0, 1.0)
	position = position.round()
	# Update progress bar value (0-100)
	if progress_bar:
		progress_bar.value = ratio * 100.0
	# Update label
	if hp_label:
		hp_label.text = "%d/%d" % [current, max_hp]
		hp_label.position = hp_label.position.round()
	# Subtle fade when at full HP (was too dark at 0.3)
	var target_alpha: float = 0.6 if ratio >= 1.0 else 0.95
	modulate.a = target_alpha
