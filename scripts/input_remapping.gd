## Input Remapping Screen - Allows players to rebind controls
## Part of the settings system for accessibility
extends Control

signal remapping_closed

const SETTINGS_PATH: String = "user://settings.cfg"

@onready var button_container: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/ButtonContainer
@onready var back_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/BackButton
@onready var reset_button: Button = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/ResetButton

var listening_for_input: bool = false
var button_to_remap: Button = null
var action_to_remap: String = ""

# Define the remappable actions with default key names shown
const REMAPPABLE_ACTIONS: Dictionary = {
	"change_weapon": "Change Weapon",
	"buy_weapon": "Buy Arrows",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_populate_action_buttons()
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	_load_remaps()


func _populate_action_buttons() -> void:
	# Clear existing buttons
	for child in button_container.get_children():
		child.queue_free()
	
	# Create a button for each remappable action
	for action: String in REMAPPABLE_ACTIONS.keys():
		var display_name: String = REMAPPABLE_ACTIONS[action]
		var hbox := HBoxContainer.new()
		
		var label := Label.new()
		label.text = display_name
		label.custom_minimum_size = Vector2(150, 40)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(label)
		
		var remap_btn := Button.new()
		remap_btn.custom_minimum_size = Vector2(150, 40)
		remap_btn.text = _get_action_key_text(action)
		remap_btn.set_meta("action", action)  # Store action name
		remap_btn.pressed.connect(_on_remap_button_pressed.bind(remap_btn, action))
		hbox.add_child(remap_btn)
		
		button_container.add_child(hbox)


func _get_action_key_text(action: String) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	if events.is_empty():
		return "Not Set"
	
	var event: InputEvent = events[0]
	if event is InputEventKey:
		# Check physical_keycode first (what we use), then keycode
		var keycode: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if keycode == KEY_UNKNOWN or keycode == 0:
			return "Not Set"
		return OS.get_keycode_string(keycode)
	elif event is InputEventMouseButton:
		return "Mouse " + str(event.button_index)
	elif event is InputEventJoypadButton:
		return "Button " + str(event.button_index)
	
	return "Unknown"


func _on_remap_button_pressed(btn: Button, action: String) -> void:
	if listening_for_input:
		return
	
	listening_for_input = true
	button_to_remap = btn
	action_to_remap = action
	btn.text = "Press any key..."
	btn.grab_focus()


func _input(event: InputEvent) -> void:
	if not listening_for_input:
		return
	
	# Handle keyboard input
	if event is InputEventKey and event.pressed and not event.echo:
		_remap_action(action_to_remap, event)
		listening_for_input = false
		button_to_remap.text = OS.get_keycode_string(event.keycode)
		button_to_remap = null
		_save_remaps()
		get_viewport().set_input_as_handled()
	
	# Handle mouse button input (optional)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			_remap_action(action_to_remap, event)
			listening_for_input = false
			button_to_remap.text = "Mouse " + str(event.button_index)
			button_to_remap = null
			_save_remaps()
			get_viewport().set_input_as_handled()


func _remap_action(action: String, event: InputEvent) -> void:
	# Clear existing events for this action
	InputMap.action_erase_events(action)
	# Add the new event
	InputMap.action_add_event(action, event)


func _on_back_pressed() -> void:
	_save_remaps()
	hide()
	remapping_closed.emit()


func _on_reset_pressed() -> void:
	# Reset all actions to default
	for action: String in REMAPPABLE_ACTIONS.keys():
		# Remove all events
		InputMap.action_erase_events(action)
	
	# Load default mappings from project settings
	# This requires reloading the InputMap from project.godot
	# For simplicity, we'll set common defaults:
	_set_default_keybindings()
	_populate_action_buttons()
	_save_remaps()


func _set_default_keybindings() -> void:
	# Set default keybinding for weapon change (Q)
	var change_weapon_event: InputEventKey = InputEventKey.new()
	change_weapon_event.keycode = KEY_Q
	InputMap.action_add_event("change_weapon", change_weapon_event)
	
	# Set default keybinding for buy weapon (B)
	var buy_weapon_event: InputEventKey = InputEventKey.new()
	buy_weapon_event.keycode = KEY_B
	InputMap.action_add_event("buy_weapon", buy_weapon_event)


func _save_remaps() -> void:
	var settings := ConfigFile.new()
	
	# Load existing settings if any
	settings.load(SETTINGS_PATH)
	
	# Save each action's key
	for action: String in REMAPPABLE_ACTIONS.keys():
		var events: Array[InputEvent] = InputMap.action_get_events(action)
		if not events.is_empty():
			var event: InputEvent = events[0]
			if event is InputEventKey:
				settings.set_value("controls", action, event.keycode)
			elif event is InputEventMouseButton:
				settings.set_value("controls", action + "_mouse", event.button_index)
	
	settings.save(SETTINGS_PATH)


func _load_remaps() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return
	
	# Load each action's key
	for action: String in REMAPPABLE_ACTIONS.keys():
		var keycode: int = settings.get_value("controls", action, -1)
		if keycode >= 0:
			# Clear existing and add loaded
			InputMap.action_erase_events(action)
			var event: InputEventKey = InputEventKey.new()
			event.keycode = keycode
			InputMap.action_add_event(action, event)
		
		# Also check for mouse bindings
		var mouse_btn: int = settings.get_value("controls", action + "_mouse", -1)
		if mouse_btn >= 0:
			InputMap.action_erase_events(action)
			var event: InputEventMouseButton = InputEventMouseButton.new()
			event.button_index = mouse_btn
			InputMap.action_add_event(action, event)
	
	# Refresh button labels
	_populate_action_buttons()


func show_remapping() -> void:
	show()
	_populate_action_buttons()
	back_button.grab_focus()
