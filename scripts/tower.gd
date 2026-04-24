extends StaticBody2D

## Tower upgrade levels: tower -> tower2 -> tower3 -> tower4 -> tower5 -> tower6
## Each tower has a next_tower_name that points to the next level's node in the scene

const DISSOLVE_SHADER: Shader = preload("res://scenes/shaders/dissolve.gdshader")
const DESTRUCTION_EFFECT_SCENE: PackedScene = preload("res://scenes/effects/destruction_effect.tscn")
const HEALTH_BAR_SCENE: PackedScene = preload("res://scenes/ui/health_bar.tscn")

signal tower_destroyed

@export var max_hp: int = 200
@export var damage_per_second: int = 15
@export var upgrade_cost: int = 50
@export var next_tower_name: String = "tower2" ## Name of the next tower node in the scene
@export var enable_destruction_particles: bool = false
@export_range(0.0, 1.0, 0.001) var wear_base_sensitivity: float = 0.0
@export_range(0.0, 1.0, 0.001) var wear_damage_boost: float = 1.0
@export_range(0.1, 3.0, 0.01) var wear_response_curve: float = 0.6
@export_range(0.0, 1.0, 0.001) var wear_min_after_damage: float = 0.18
@export var debug_wear_updates: bool = true
@export var debug_wear_setup: bool = true
@export var debug_wear_triggers: bool = true

var enemy_touching: bool = false
var current_hp: int = 0
var enemy_nearby: bool = false
var damage_timer: float = 0.0
var number_enemies: int = 0
var player_mount: Marker2D
var tower_visual: CanvasItem
var tower_wear_material: ShaderMaterial
var is_destroying: bool = false
var _default_body_collision_layer: int = 0
var _default_body_collision_mask: int = 0
var _default_area_collision_layer: int = 0
var _default_area_collision_mask: int = 0

@onready var death_gui: Control = $"../CanvasLayer/death"
@onready var lost_audio: AudioStreamPlayer2D = $"../CanvasLayer/death/lost"
@onready var upgrade_btn: TextureButton = $"../CanvasLayer/Control/sidebar/actions/upgrade_tower"
@onready var damage_area: Area2D = get_node_or_null("tower")
@onready var tower_upgrade_sound: AudioStreamPlayer = $"../Audio/tower_upgrade"

var hit_tween: Tween
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _health_bar: Node2D = null


func _ready() -> void:
	# Cache player_mount reference
	player_mount = get_node_or_null("PlayerMount")
	tower_visual = _resolve_tower_visual()
	_default_body_collision_layer = collision_layer
	_default_body_collision_mask = collision_mask
	if damage_area:
		_default_area_collision_layer = damage_area.collision_layer
		_default_area_collision_mask = damage_area.collision_mask
	print("[tower boot] node=", name, " path=", get_path(), " visible=", visible)

	if death_gui:
		death_gui.hide()
	if current_hp <= 0:
		current_hp = max_hp
	_setup_wear_shader()
	_update_wear_from_health()
	_setup_health_bar()
	if upgrade_btn:
		upgrade_btn.visible = true
		_update_upgrade_button()

	# Only move player if this tower is visible (active tower)
	if visible:
		_move_player_to_mount()
	_bind_player_lifecycle()
	_set_active_state(visible)


func _process(_delta: float) -> void:
	if not is_destroying and get_parent() and get_parent().get_node_or_null("Player") == null:
		_destroy_due_to_player_death()

	_update_upgrade_button()


func _update_upgrade_button() -> void:
	# Only update the button if this tower is visible (active)
	if not visible:
		return
	if upgrade_btn == null:
		return
	upgrade_btn.disabled = not can_upgrade()
	if upgrade_btn.disabled:
		upgrade_btn.modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		upgrade_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)


func can_upgrade() -> bool:
	if next_tower_name.is_empty():
		return false
	var parent_node: Node = get_parent()
	if parent_node == null:
		return false
	var next_tower: Node = parent_node.get_node_or_null(next_tower_name)
	if next_tower == null:
		return false
	return global_var.coins >= upgrade_cost


func take_damage(damage: int) -> void:
	if not visible:
		return
	if debug_wear_triggers:
		print("[tower wear] take_damage called | base=", damage, " nearby_count=", number_enemies, " hp_before=", current_hp)
	current_hp -= damage + number_enemies
	_update_wear_from_health()
	_update_health_bar()
	trigger_hit_effect()
	_shake_camera(10.0, 0.22)
	if current_hp <= 0:
		destroy_tower()


func trigger_hit_effect() -> void:
	if tower_visual == null and tower_wear_material == null:
		return
	if hit_tween:
		hit_tween.kill()

	if tower_wear_material:
		_set_hit_strength(1.0)
		hit_tween = create_tween()
		hit_tween.tween_method(_set_hit_strength, 1.0, 0.0, 0.16)
		return

	hit_tween = create_tween()
	hit_tween.tween_property(tower_visual, "modulate", Color.RED, 0.08)
	hit_tween.tween_property(tower_visual, "modulate", Color.WHITE, 0.08)


func destroy_tower() -> void:
	if is_destroying:
		return
	is_destroying = true

	# Play destruction shader effect
	_spawn_destruction_effect()

	tower_destroyed.emit()

	if enable_destruction_particles:
		create_destruction_particles()

	if lost_audio:
		lost_audio.play()

	var player: Node = get_parent().get_node_or_null("Player")
	if player:
		player.queue_free()

	if death_gui:
		death_gui.show()

	enemy_nearby = false
	set_process(false)
	set_physics_process(false)
	process_mode = Node.PROCESS_MODE_DISABLED
	collision_layer = 0
	collision_mask = 0
	if upgrade_btn:
		upgrade_btn.disabled = true
	queue_free()


func _spawn_destruction_effect() -> void:
	# Get tower texture from the visual node
	var tower_texture: Texture2D = null
	if tower_visual is Sprite2D:
		tower_texture = tower_visual.texture
	elif tower_visual is AnimatedSprite2D:
		# For animated sprites, use the current frame texture
		tower_texture = tower_visual.sprite_frames.get_frame_texture(tower_visual.animation, tower_visual.frame)
	
	if DESTRUCTION_EFFECT_SCENE and tower_texture:
		var effect := DESTRUCTION_EFFECT_SCENE.instantiate()
		effect.texture = tower_texture
		effect.global_position = global_position
		effect.start_scale = tower_visual.scale if tower_visual else Vector2.ONE
		effect.duration = 0.8
		effect.use_particles = enable_destruction_particles
		get_tree().root.add_child(effect)


func create_destruction_particles() -> void:
	for i in range(20):
		var particle := Sprite2D.new()
		var rock_texture: Texture2D = preload("res://assets/map/rocks .png")
		particle.texture = rock_texture
		particle.scale = Vector2(0.2, 0.2)
		particle.global_position = global_position + Vector2(
			rng.randf_range(-30.0, 30.0),
			rng.randf_range(-30.0, 30.0)
		)

		get_tree().root.add_child(particle)

		var tween := create_tween()
		tween.parallel().tween_property(
			particle, "position",
			particle.position + Vector2(rng.randf_range(-100.0, 100.0), rng.randf_range(-50.0, -150.0)),
			2.0
		)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 2.0)
		tween.parallel().tween_property(particle, "rotation", rng.randf_range(-10.0, 10.0), 2.0)
		tween.tween_callback(particle.queue_free)


func _on_upgrade_tower_pressed() -> void:
	if not can_upgrade():
		return

	var parent_node: Node = get_parent()
	if parent_node == null:
		return

	# Get the next tower node from the scene
	var next_tower: Node = parent_node.get_node_or_null(next_tower_name)
	if next_tower == null:
		push_error("[tower] Next tower node '%s' not found" % next_tower_name)
		return

	global_var.coins -= upgrade_cost

	# Calculate health ratio to transfer to new tower
	var health_ratio: float = float(current_hp) / float(maxi(1, max_hp))

	# Hide current tower (will be queue_freed)
	_set_active_state(false)
	visible = false

	# Show and enable the next tower
	next_tower.visible = true
	if next_tower.has_method("_set_active_state"):
		next_tower._set_active_state(true)
	else:
		next_tower.set_process(true)
		next_tower.collision_layer = 1
		next_tower.collision_mask = 15

	# Transfer state to next tower
	if next_tower.has_method("set_hp_ratio"):
		next_tower.set_hp_ratio(health_ratio)
	else:
		# Direct property access if method doesn't exist
		if "current_hp" in next_tower and "max_hp" in next_tower:
			next_tower.current_hp = maxi(1, int(round(float(next_tower.max_hp) * health_ratio)))

	# Transfer enemy state
	if "enemy_touching" in next_tower:
		next_tower.enemy_touching = enemy_touching
	if "enemy_nearby" in next_tower:
		next_tower.enemy_nearby = enemy_nearby
	if "damage_timer" in next_tower:
		next_tower.damage_timer = damage_timer
	if "number_enemies" in next_tower:
		next_tower.number_enemies = number_enemies

	# Play build sound
	var build_sound: AudioStreamPlayer2D = parent_node.get_node_or_null("wall/build_sound")
	if build_sound:
		build_sound.play()

	# Play tower upgrade sound
	if tower_upgrade_sound != null:
		tower_upgrade_sound.play()

	# Move player to the new tower's mount point
	if next_tower.has_method("_move_player_to_mount"):
		next_tower._move_player_to_mount()

	# Free the old tower
	queue_free()


## Called by previous tower to set health ratio
func set_hp_ratio(ratio: float) -> void:
	current_hp = maxi(1, int(round(float(max_hp) * ratio)))
	_update_wear_from_health()


func _move_player_to_mount() -> void:
	if player_mount == null:
		# Try to get it again in case it wasn't cached
		player_mount = get_node_or_null("PlayerMount")
		if player_mount == null:
			return
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	var player: Node2D = parent_node.get_node_or_null("Player") as Node2D
	if player:
		player.global_position = player_mount.global_position


func _on_area_2d_area_entered(area: Area2D) -> void:
	if not visible:
		return
	if debug_wear_triggers:
		print("[tower wear] area_entered: ", area.name)
	if _is_enemy_area(area):
		number_enemies += 1
		enemy_nearby = true


func _on_area_2d_area_exited(area: Area2D) -> void:
	if not visible:
		return
	if debug_wear_triggers:
		print("[tower wear] area_exited: ", area.name)
	if _is_enemy_area(area):
		number_enemies = maxi(0, number_enemies - 1)
		if number_enemies == 0:
			enemy_nearby = false


func update_progress(value: float) -> void:
	if tower_wear_material:
		tower_wear_material.set_shader_parameter("progress", value)
	elif material:
		material.set_shader_parameter("progress", value)


func _setup_wear_shader() -> void:
	if tower_visual == null:
		push_warning("[tower] No tower visual node found for wear shader setup.")
		return

	var sprite_material: ShaderMaterial = tower_visual.material as ShaderMaterial
	if sprite_material == null:
		push_warning("[tower] Tower visual is missing ShaderMaterial. Assign dissolve material in the scene.")
		return
	if sprite_material.shader == null:
		push_warning("[tower] Tower visual ShaderMaterial has no shader assigned.")
		return

	tower_wear_material = sprite_material.duplicate() as ShaderMaterial
	tower_wear_material.resource_local_to_scene = true
	tower_wear_material.set_shader_parameter("hit_strength", 0.0)
	tower_visual.material = tower_wear_material

	if debug_wear_setup:
		var shader_path: String = tower_wear_material.shader.resource_path if tower_wear_material.shader else "<null>"
		var noise_tex: Variant = tower_wear_material.get_shader_parameter("noise_texture")
		var sensitivity: Variant = tower_wear_material.get_shader_parameter("sensitivity")
		print("[tower wear setup] visual=", tower_visual.get_path())
		print("[tower wear setup] shader_path=", shader_path)
		print("[tower wear setup] has_noise_texture=", noise_tex != null)
		print("[tower wear setup] initial_sensitivity=", sensitivity)


func _update_wear_from_health() -> void:
	if tower_wear_material == null:
		if debug_wear_updates:
			print("[tower wear] skipped update: tower_wear_material is null")
		return
	var health_ratio: float = clampf(float(current_hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	var wear_amount: float = 1.0 - health_ratio
	var curved_wear: float = pow(wear_amount, wear_response_curve)
	var sensitivity: float = clampf(wear_base_sensitivity + (curved_wear * wear_damage_boost), 0.0, 1.0)
	if wear_amount > 0.0:
		sensitivity = maxf(sensitivity, wear_min_after_damage)
	tower_wear_material.set_shader_parameter("sensitivity", sensitivity)
	if debug_wear_updates:
		var applied: Variant = tower_wear_material.get_shader_parameter("sensitivity")
		print("[tower wear] hp=", current_hp, "/", max_hp, " wear=", wear_amount, " sensitivity_set=", sensitivity, " sensitivity_read=", applied)


func set_wear_shader_parameter(param_name: StringName, value: Variant) -> void:
	if tower_wear_material == null:
		return
	tower_wear_material.set_shader_parameter(param_name, value)


func _set_hit_strength(value: float) -> void:
	if tower_wear_material == null:
		return
	tower_wear_material.set_shader_parameter("hit_strength", clampf(value, 0.0, 1.0))


func _bind_player_lifecycle() -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	var player: Node = parent_node.get_node_or_null("Player")
	if player == null:
		return
	var on_player_exited: Callable = Callable(self, "_on_player_tree_exited")
	if not player.tree_exited.is_connected(on_player_exited):
		player.tree_exited.connect(on_player_exited)


func _set_active_state(active: bool) -> void:
	set_process(active)
	set_physics_process(active)
	if active:
		collision_layer = _default_body_collision_layer
		collision_mask = _default_body_collision_mask
	else:
		collision_layer = 0
		collision_mask = 0

	if damage_area:
		damage_area.monitoring = active
		damage_area.monitorable = active
		if active:
			damage_area.collision_layer = _default_area_collision_layer
			damage_area.collision_mask = _default_area_collision_mask
		else:
			damage_area.collision_layer = 0
			damage_area.collision_mask = 0


func _resolve_tower_visual() -> CanvasItem:
	var named_tower: CanvasItem = get_node_or_null("Tower") as CanvasItem
	if named_tower:
		return named_tower
	var animated: AnimatedSprite2D = find_child("AnimatedSprite2D", true, false) as AnimatedSprite2D
	if animated:
		return animated
	var sprite: Sprite2D = find_child("Sprite2D", true, false) as Sprite2D
	if sprite:
		return sprite
	return null


func _is_enemy_area(area: Area2D) -> bool:
	if area == null:
		return false
	# Check if the parent body is in the "enemies" group
	var parent_body: Node2D = area.get_parent()
	if parent_body and parent_body.is_in_group("enemies"):
		return true
	# Fallback: name-based check for legacy compatibility
	var area_name: String = area.name.to_lower()
	return area_name.begins_with("enemy")


func _on_player_tree_exited() -> void:
	_destroy_due_to_player_death()


func _destroy_due_to_player_death() -> void:
	if is_destroying:
		return
	if death_gui:
		death_gui.show()
	is_destroying = true
	enemy_nearby = false
	set_process(false)
	set_physics_process(false)
	process_mode = Node.PROCESS_MODE_DISABLED
	collision_layer = 0
	collision_mask = 0
	if upgrade_btn:
		upgrade_btn.disabled = true
	queue_free()


func _shake_camera(amount: float, duration: float) -> void:
	var parent_node: Node = get_parent()
	if parent_node == null:
		return
	var camera: Camera2D = parent_node.get_node_or_null("Camera2D") as Camera2D
	if camera and camera.has_method("shake"):
		camera.shake(amount, duration)


func _setup_health_bar() -> void:
	if not visible:
		return
	_health_bar = HEALTH_BAR_SCENE.instantiate()
	add_child(_health_bar)
	# Position above the tower visual
	if tower_visual:
		var visual_rect: Rect2 = Rect2()
		if tower_visual is Sprite2D:
			visual_rect = (tower_visual as Sprite2D).get_rect()
		_health_bar.position = Vector2(0, -visual_rect.size.y * (tower_visual as Sprite2D).scale.y - 8).round()
	else:
		_health_bar.position = Vector2(0, -72).round()
	_health_bar.update_hp(current_hp, max_hp)


func _update_health_bar() -> void:
	if _health_bar:
		_health_bar.update_hp(current_hp, max_hp)
