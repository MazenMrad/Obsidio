extends Control

signal play_pressed

@onready var play_button: Button = $PanelContainer/MarginContainer/VBoxContainer/PlayButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	play_button.pressed.connect(_on_play_pressed)
	play_button.grab_focus()

func _on_play_pressed() -> void:
	play_pressed.emit()
	queue_free()
