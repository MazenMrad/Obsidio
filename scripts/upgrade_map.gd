extends Control

@onready var panel: PanelContainer = $Panel
@onready var weapon_container: Node2D = $Panel/Margin/VBox/Canvas/WeaponContainer
@onready var canvas_bg: Control = $Panel/Margin/VBox/Canvas
@onready var line_canvas: Control = $Panel/Margin/VBox/Canvas/LineCanvas
@onready var coin_label: Label = $Panel/Margin/VBox/Header/CoinLabel
@onready var close_btn: Button = $Panel/Margin/VBox/Header/CloseBtn
@onready var background: ColorRect = $Background

var weapon_nodes: Dictionary = {}
var _map_tween: Tween = null
var _is_animating: bool = false
var _link_visual_nodes: Array[CanvasItem] = []

var upgrade_tree: Dictionary = {
	"rock": {"cost": 0, "prerequisites": [], "connections": ["bow"]},
	"bow": {"cost": 0, "prerequisites": ["rock"], "connections": ["spear", "axe", "knife"]},
	"knife": {"cost": 15, "prerequisites": ["bow"], "connections": []},
	"axe": {"cost": 10, "prerequisites": ["bow"], "connections": []},
	"spear": {"cost": 20, "prerequisites": ["bow"], "connections": []}
}

var dragging: TextureRect = null
var drag_offset: Vector2 = Vector2.ZERO
var hold_time: float = 0.0
var hold_target: String = ""
var hold_tween: Tween = null
var is_panning: bool = false
var pan_last_mouse_position: Vector2 = Vector2.ZERO
var graph_zoom: float = 1.0
var graph_offset: Vector2 = Vector2.ZERO

const HOLD_DURATION: float = 0.5
const PANEL_MIN_SIZE: Vector2 = Vector2(520.0, 360.0)
const PANEL_MAX_SIZE: Vector2 = Vector2(760.0, 560.0)
const CANVAS_MIN_SIZE: Vector2 = Vector2(420.0, 220.0)
const MIN_GRAPH_ZOOM: float = 0.7
const MAX_GRAPH_ZOOM: float = 1.75
const GRAPH_ZOOM_STEP: float = 0.1
const LINK_DOT_SPACING: float = 14.0
const LINK_DOT_SIZE: float = 6.0
const WEAPON_LAYOUT: Dictionary = {
	"rock": Vector2(0.16, 0.70),
	"bow": Vector2(0.35, 0.70),
	"spear": Vector2(0.76, 0.22),
	"axe": Vector2(0.76, 0.54),
	"knife": Vector2(0.76, 0.82)
}


func _ready() -> void:
	line_canvas.z_index = 0
	weapon_container.z_index = 1
	setup_weapons()
	setup_close_button()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	_update_coins()
	_update_lines()


func setup_weapons() -> void:
	var node_map: Dictionary = {
		"rock_weapon": "rock",
		"bow_weapon": "bow",
		"spear_weapon": "spear",
		"axe_weapon": "axe",
		"knife_weapon": "knife"
	}

	for node_name in node_map.keys():
		var weapon_name: String = node_map[node_name]
		var node: Node = weapon_container.get_node_or_null(node_name)
		if node is TextureRect:
			var weapon := node as TextureRect
			weapon_nodes[weapon_name] = weapon
			weapon.gui_input.connect(_on_weapon_input.bind(weapon, weapon_name))
			weapon.mouse_filter = Control.MOUSE_FILTER_STOP

	_arrange_weapons()
	_refresh_all()


func setup_close_button() -> void:
	close_btn.pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	_close_with_animation()


func _open_with_animation() -> void:
	if _is_animating and _map_tween:
		_map_tween.kill()
	
	_is_animating = true
	
	# Set initial state for animation
	background.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.85, 0.85)
	visible = true
	
	# Populate map data
	_update_coins()
	_refresh_all()
	_arrange_weapons()
	_update_lines()
	
	# Animate in
	_map_tween = create_tween()
	_map_tween.set_parallel(true)
	_map_tween.set_ease(Tween.EASE_OUT)
	_map_tween.set_trans(Tween.TRANS_BACK)
	_map_tween.tween_property(background, "modulate:a", 1.0, 0.25)
	_map_tween.tween_property(panel, "modulate:a", 1.0, 0.25)
	_map_tween.tween_property(panel, "scale", Vector2.ONE, 0.3)
	_map_tween.set_parallel(false)
	_map_tween.tween_callback(func(): _is_animating = false)


func _close_with_animation() -> void:
	if _is_animating and _map_tween:
		_map_tween.kill()
	
	_is_animating = true
	
	# Animate out
	_map_tween = create_tween()
	_map_tween.set_parallel(true)
	_map_tween.set_ease(Tween.EASE_IN)
	_map_tween.set_trans(Tween.TRANS_QUAD)
	_map_tween.tween_property(background, "modulate:a", 0.0, 0.15)
	_map_tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	_map_tween.tween_property(panel, "scale", Vector2(0.85, 0.85), 0.15)
	_map_tween.set_parallel(false)
	_map_tween.tween_callback(func():
		visible = false
		_is_animating = false
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible and not _is_animating:
			_open_with_animation()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			is_panning = event.pressed
			pan_last_mouse_position = get_global_mouse_position()
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_graph(1.0 + GRAPH_ZOOM_STEP)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_graph(1.0 - GRAPH_ZOOM_STEP)
			accept_event()
			return

	if event is InputEventMouseMotion and is_panning:
		var mouse_position: Vector2 = get_global_mouse_position()
		graph_offset += mouse_position - pan_last_mouse_position
		pan_last_mouse_position = mouse_position
		_arrange_weapons()
		_update_lines()
		accept_event()


func _process(delta: float) -> void:
	if hold_target != "" and hold_time > 0.0:
		hold_time += delta
		if hold_time >= HOLD_DURATION:
			attempt_purchase(hold_target)
			hold_target = ""
			hold_time = 0.0
			_stop_hold()


func _get_node_center(node: TextureRect) -> Vector2:
	return node.global_position + node.size * 0.5 - line_canvas.global_position


func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_size := Vector2(
		clampf(viewport_size.x * 0.68, PANEL_MIN_SIZE.x, PANEL_MAX_SIZE.x),
		clampf(viewport_size.y * 0.62, PANEL_MIN_SIZE.y, PANEL_MAX_SIZE.y)
	)
	panel.offset_left = -panel_size.x * 0.5
	panel.offset_top = -panel_size.y * 0.5
	panel.offset_right = panel_size.x * 0.5
	panel.offset_bottom = panel_size.y * 0.5
	canvas_bg.custom_minimum_size = Vector2(
		maxf(CANVAS_MIN_SIZE.x, panel_size.x - 72.0),
		maxf(CANVAS_MIN_SIZE.y, panel_size.y - 132.0)
	)
	_arrange_weapons()
	_update_lines()


func _arrange_weapons() -> void:
	if weapon_nodes.is_empty() or not is_instance_valid(canvas_bg):
		return

	var canvas_size: Vector2 = canvas_bg.size
	if canvas_size.x <= 0.0 or canvas_size.y <= 0.0:
		canvas_size = canvas_bg.custom_minimum_size
	if canvas_size.x <= 0.0 or canvas_size.y <= 0.0:
		return
	line_canvas.custom_minimum_size = canvas_size
	line_canvas.size = canvas_size

	var icon_size: float = clampf(minf(canvas_size.x, canvas_size.y) * 0.16 * graph_zoom, 44.0, 112.0)
	_clamp_graph_offset(canvas_size, icon_size)

	for weapon_name in weapon_nodes.keys():
		var weapon: TextureRect = weapon_nodes[weapon_name]
		var anchor_point: Vector2 = WEAPON_LAYOUT.get(weapon_name, Vector2(0.5, 0.5))
		var target_position := Vector2(
			canvas_size.x * anchor_point.x - icon_size * 0.5,
			canvas_size.y * anchor_point.y - icon_size * 0.5
		) + graph_offset
		weapon.custom_minimum_size = Vector2.ONE * icon_size
		weapon.size = Vector2.ONE * icon_size
		weapon.position = Vector2(roundf(target_position.x), roundf(target_position.y))


func _clamp_graph_offset(canvas_size: Vector2, icon_size: float) -> void:
	if canvas_size.x <= 0.0 or canvas_size.y <= 0.0:
		return

	var min_base := Vector2(INF, INF)
	var max_base := Vector2(-INF, -INF)

	for anchor_point in WEAPON_LAYOUT.values():
		var base_top_left := Vector2(
			canvas_size.x * anchor_point.x - icon_size * 0.5,
			canvas_size.y * anchor_point.y - icon_size * 0.5
		)
		min_base.x = minf(min_base.x, base_top_left.x)
		min_base.y = minf(min_base.y, base_top_left.y)
		max_base.x = maxf(max_base.x, base_top_left.x + icon_size)
		max_base.y = maxf(max_base.y, base_top_left.y + icon_size)

	var padding := Vector2(28.0, 28.0)
	var min_offset := Vector2(padding.x - min_base.x, padding.y - min_base.y)
	var max_offset := Vector2((canvas_size.x - padding.x) - max_base.x, (canvas_size.y - padding.y) - max_base.y)

	if min_offset.x > max_offset.x:
		graph_offset.x = (min_offset.x + max_offset.x) * 0.5
	else:
		graph_offset.x = clampf(graph_offset.x, min_offset.x, max_offset.x)

	if min_offset.y > max_offset.y:
		graph_offset.y = (min_offset.y + max_offset.y) * 0.5
	else:
		graph_offset.y = clampf(graph_offset.y, min_offset.y, max_offset.y)


func _zoom_graph(zoom_factor: float) -> void:
	var previous_zoom: float = graph_zoom
	var next_zoom: float = clampf(previous_zoom * zoom_factor, MIN_GRAPH_ZOOM, MAX_GRAPH_ZOOM)
	if is_equal_approx(previous_zoom, next_zoom):
		return

	var mouse_local: Vector2 = get_global_mouse_position() - canvas_bg.global_position
	graph_zoom = next_zoom
	graph_offset = mouse_local - ((mouse_local - graph_offset) * (next_zoom / previous_zoom))
	_arrange_weapons()
	_update_lines()


func _on_weapon_input(event: InputEvent, weapon: TextureRect, weapon_name: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_interaction(weapon, weapon_name)
		else:
			_end_interaction()
		return

	if event is InputEventMouseMotion and dragging == weapon:
		var container_rect: Vector2 = canvas_bg.global_position
		var canvas_size: Vector2 = canvas_bg.size if canvas_bg.size != Vector2.ZERO else canvas_bg.custom_minimum_size
		var max_x: float = container_rect.x + canvas_size.x
		var max_y: float = container_rect.y + canvas_size.y
		var new_pos: Vector2 = get_global_mouse_position() - drag_offset
		new_pos.x = clampf(new_pos.x, container_rect.x, max_x - weapon.size.x)
		new_pos.y = clampf(new_pos.y, container_rect.y, max_y - weapon.size.y)
		weapon.global_position = Vector2(roundf(new_pos.x), roundf(new_pos.y))
		_update_lines()


func _start_interaction(weapon: TextureRect, weapon_name: String) -> void:
	if is_unlocked(weapon_name):
		dragging = weapon
		drag_offset = get_global_mouse_position() - weapon.global_position
		hold_time = 0.0
		return

	hold_target = weapon_name
	hold_time = 0.01
	_start_hold_animation(weapon)


func _end_interaction() -> void:
	dragging = null
	if hold_target != "":
		hold_target = ""
		hold_time = 0.0
		_stop_hold()


func _start_hold_animation(weapon: TextureRect) -> void:
	if hold_tween:
		hold_tween.kill()
	hold_tween = create_tween().set_loops()
	hold_tween.tween_property(weapon, "scale", Vector2(1.15, 1.15), 0.25)
	hold_tween.tween_property(weapon, "scale", Vector2(1.0, 1.0), 0.25)


func _stop_hold() -> void:
	if hold_tween:
		hold_tween.kill()
		hold_tween = null
	for node in weapon_nodes.values():
		(node as TextureRect).scale = Vector2.ONE


func is_unlocked(weapon_name: String) -> bool:
	return weapon_name in global_var.unlocked_weapons


func can_purchase(weapon_name: String) -> bool:
	if is_unlocked(weapon_name):
		return false

	var data: Dictionary = upgrade_tree[weapon_name]
	if global_var.coins < int(data["cost"]):
		return false
	for prereq in data["prerequisites"]:
		if prereq not in global_var.unlocked_weapons:
			return false
	return true


func attempt_purchase(weapon_name: String) -> void:
	if not can_purchase(weapon_name):
		_shake(weapon_nodes[weapon_name] as TextureRect)
		return

	global_var.coins -= int(upgrade_tree[weapon_name]["cost"])
	global_var.unlocked_weapons.append(weapon_name)
	global_var.state = _weapon_enum_from_name(weapon_name)
	if has_node("purchase_sound"):
		$purchase_sound.play()

	var weapon: TextureRect = weapon_nodes[weapon_name]
	var tween := create_tween()
	tween.tween_property(weapon, "modulate", Color.GREEN, 0.15)
	tween.tween_property(weapon, "modulate", Color.WHITE, 0.3)

	_stop_hold()
	_refresh_all()
	_update_coins()
	_update_lines()


func _weapon_enum_from_name(weapon_name: String) -> global_var.Weapon:
	match weapon_name:
		"rock":
			return global_var.Weapon.ROCK
		"bow":
			return global_var.Weapon.BOW
		"knife":
			return global_var.Weapon.KNIFE
		"axe":
			return global_var.Weapon.AXE
		"spear":
			return global_var.Weapon.SPEAR
		_:
			return global_var.Weapon.BOW


func _shake(weapon: TextureRect) -> void:
	var tween := create_tween()
	var original: float = weapon.global_position.x
	tween.tween_property(weapon, "global_position:x", original - 8.0, 0.05)
	tween.tween_property(weapon, "global_position:x", original + 8.0, 0.05)
	tween.tween_property(weapon, "global_position:x", original - 6.0, 0.05)
	tween.tween_property(weapon, "global_position:x", original + 6.0, 0.05)
	tween.tween_property(weapon, "global_position:x", original, 0.05)
	hold_time = 0.0


func _refresh_all() -> void:
	for weapon_name in weapon_nodes.keys():
		_refresh_weapon(weapon_name)


func _refresh_weapon(weapon_name: String) -> void:
	var weapon: TextureRect = weapon_nodes[weapon_name]
	var grey: CanvasItem = weapon.get_node_or_null("grey_layer")
	var highlight: CanvasItem = weapon.get_node_or_null("highlight")
	var price_lbl: Label = weapon.get_node_or_null("price")

	if is_unlocked(weapon_name):
		if grey:
			grey.visible = false
		if highlight:
			highlight.visible = false
		if price_lbl:
			price_lbl.text = "Owned"
		weapon.modulate = Color.WHITE
		return

	var cost: int = int(upgrade_tree[weapon_name]["cost"])
	if price_lbl:
		price_lbl.text = "Free" if cost == 0 else str(cost)

	var affordable: bool = global_var.coins >= cost
	var has_prereqs: bool = true
	for prereq in upgrade_tree[weapon_name]["prerequisites"]:
		if prereq not in global_var.unlocked_weapons:
			has_prereqs = false
			break

	if grey:
		grey.visible = not (has_prereqs and affordable)
	if highlight:
		highlight.visible = has_prereqs and affordable


func _update_coins() -> void:
	if is_instance_valid(coin_label):
		coin_label.text = "Coins: %d" % global_var.coins


func _update_lines() -> void:
	_rebuild_link_visuals()


func _rebuild_link_visuals() -> void:
	for visual in _link_visual_nodes:
		if is_instance_valid(visual):
			visual.queue_free()
	_link_visual_nodes.clear()

	var color_active = Color(0.3, 0.8, 0.3, 0.95)
	var color_locked = Color(0.35, 0.35, 0.35, 0.75)
	var color_available = Color(0.75, 0.72, 0.25, 0.9)

	for weapon_name in upgrade_tree.keys():
		if not weapon_nodes.has(weapon_name):
			continue
		var from_node: TextureRect = weapon_nodes[weapon_name]
		var from_pos: Vector2 = _get_node_center(from_node)

		for connected_name in upgrade_tree[weapon_name]["connections"]:
			if not weapon_nodes.has(connected_name):
				continue
			var to_node: TextureRect = weapon_nodes[connected_name]
			var to_pos: Vector2 = _get_node_center(to_node)
			var color: Color = color_locked
			if is_unlocked(weapon_name):
				color = color_active if is_unlocked(connected_name) else color_available

			var mid_x: float = lerpf(from_pos.x, to_pos.x, 0.56)
			var joint_a := Vector2(mid_x, from_pos.y)
			var joint_b := Vector2(mid_x, to_pos.y)
			_add_link_segment_visual(from_pos, joint_a, color)
			_add_link_segment_visual(joint_a, joint_b, color)
			_add_link_segment_visual(joint_b, to_pos, color)


func _add_link_segment_visual(from: Vector2, to: Vector2, color: Color) -> void:
	var backbone := Line2D.new()
	backbone.points = PackedVector2Array([from, to])
	backbone.width = 2.0
	backbone.default_color = color.darkened(0.35)
	backbone.antialiased = true
	line_canvas.add_child(backbone)
	_link_visual_nodes.append(backbone)

	var distance: float = from.distance_to(to)
	if distance <= 0.0:
		return
	var direction: Vector2 = (to - from).normalized()
	var dot_count: int = int(distance / LINK_DOT_SPACING)
	for i in range(dot_count + 1):
		var point: Vector2 = from + direction * minf(distance, float(i) * LINK_DOT_SPACING)
		var dot := ColorRect.new()
		dot.color = color
		dot.position = Vector2(roundf(point.x - LINK_DOT_SIZE * 0.5), roundf(point.y - LINK_DOT_SIZE * 0.5))
		dot.size = Vector2.ONE * LINK_DOT_SIZE
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line_canvas.add_child(dot)
		_link_visual_nodes.append(dot)
