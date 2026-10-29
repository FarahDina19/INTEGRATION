class_name PetView
extends Control
## Draws the companion with idle breathing, blinks of motion and reaction animations.

signal poked

const MAX_PARTICLES := 24

var art_key := "stage1"
var happy := true
var base_height := 300.0
var interactive := true
var _sprite: TextureRect
var _shadow: Control
var _time := 0.0
var _reaction := ""
var _reaction_time := 0.0
var _particles: Array[Control] = []
var _hop := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW
	_shadow = Control.new()
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow.draw.connect(_draw_shadow)
	add_child(_shadow)
	_sprite = TextureRect.new()
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite)
	_refresh_texture()
	resized.connect(_layout)
	_layout()


func set_look(new_art_key: String, is_happy: bool) -> void:
	if new_art_key == art_key and is_happy == happy and _sprite != null and _sprite.texture != null:
		return
	art_key = new_art_key
	happy = is_happy
	_refresh_texture()


func _refresh_texture() -> void:
	if _sprite == null:
		return
	_sprite.texture = Kit.texture("res://assets/art/pet/%s_%s.png" % [art_key, "happy" if happy else "sad"])


func _layout() -> void:
	if _sprite == null:
		return
	var h := minf(size.y, base_height)
	var w := h
	_sprite.size = Vector2(w, h)
	_sprite.pivot_offset = Vector2(w * 0.5, h)
	_sprite.position = Vector2((size.x - w) * 0.5, size.y - h)
	_shadow.size = size
	_shadow.queue_redraw()


func _draw_shadow() -> void:
	var w := minf(size.y, base_height) * 0.55 * (1.0 - _hop * 0.004)
	var center := Vector2(size.x * 0.5, size.y - 6.0)
	var points := PackedVector2Array()
	for i: int in 32:
		var a := TAU * i / 32.0
		points.append(center + Vector2(cos(a) * w * 0.5, sin(a) * w * 0.09))
	_shadow.draw_colored_polygon(points, Color(0.2, 0.12, 0.05, 0.18))


func _process(delta: float) -> void:
	if _sprite == null:
		return
	_time += delta
	var breathe := sin(_time * 2.2) * 0.018
	var sx := 1.0 - breathe
	var sy := 1.0 + breathe
	var rotation_value := 0.0
	_hop = 0.0
	if not _reaction.is_empty():
		_reaction_time += delta
		var t := _reaction_time
		match _reaction:
			"eat":
				var chomp := absf(sin(t * 18.0)) * maxf(0.0, 1.0 - t / 0.9)
				sx += chomp * 0.08
				sy -= chomp * 0.08
				if t > 0.9:
					_reaction = ""
			"play":
				_hop = absf(sin(t * 7.0)) * 60.0 * maxf(0.0, 1.0 - t / 1.4)
				rotation_value = sin(t * 7.0) * 0.12 * maxf(0.0, 1.0 - t / 1.4)
				if t > 1.4:
					_reaction = ""
			"poke":
				rotation_value = sin(t * 26.0) * 0.08 * maxf(0.0, 1.0 - t / 0.6)
				sy += absf(sin(t * 13.0)) * 0.05 * maxf(0.0, 1.0 - t / 0.6)
				if t > 0.6:
					_reaction = ""
			"cheer":
				_hop = absf(sin(t * 9.0)) * 34.0 * maxf(0.0, 1.0 - t / 1.0)
				if t > 1.0:
					_reaction = ""
			"sad":
				sx += 0.04 * maxf(0.0, 1.0 - t / 0.8)
				sy -= 0.05 * maxf(0.0, 1.0 - t / 0.8)
				if t > 0.8:
					_reaction = ""
			"grow":
				var pulse := sin(minf(t, 1.6) / 1.6 * PI)
				sx += pulse * 0.25
				sy += pulse * 0.25
				_sprite.modulate = Color(1, 1, 1).lerp(Color(1.18, 1.18, 1.08), pulse)
				if t > 1.6:
					_sprite.modulate = Color.WHITE
					_reaction = ""
	_sprite.scale = Vector2(sx, sy)
	_sprite.rotation = rotation_value
	var h := minf(size.y, base_height)
	_sprite.position = Vector2((size.x - h) * 0.5, size.y - h - _hop)
	_shadow.queue_redraw()


func react(kind: String) -> void:
	_reaction = kind
	_reaction_time = 0.0
	match kind:
		"eat":
			burst(["res://assets/art/icons/heart.png"], 4)
		"play", "cheer":
			burst(["res://assets/art/icons/heart.png", "res://assets/art/icons/star.png"], 6)
		"poke":
			burst(["res://assets/art/icons/heart.png"], 2)
		"grow":
			burst(["res://assets/art/icons/star.png", "res://assets/art/icons/coin.png", "res://assets/art/icons/heart.png"], 9)


func burst(icon_paths: Array, count: int) -> void:
	var h := minf(size.y, base_height)
	for i: int in count:
		if _particles.size() >= MAX_PARTICLES:
			var oldest: Control = _particles.pop_front()
			if is_instance_valid(oldest):
				oldest.queue_free()
		var particle := Kit.icon(str(icon_paths[i % icon_paths.size()]), randf_range(26.0, 42.0))
		particle.size = particle.custom_minimum_size
		particle.pivot_offset = particle.size * 0.5
		particle.position = Vector2(size.x * 0.5 + randf_range(-h * 0.3, h * 0.3), size.y - h * randf_range(0.45, 0.85))
		add_child(particle)
		_particles.append(particle)
		var tween := particle.create_tween().set_parallel(true)
		var rise := minf(150.0, h * 0.5)
		var drift := Vector2(randf_range(-70.0, 70.0), randf_range(-rise, -rise * 0.6))
		tween.tween_property(particle, "position", particle.position + drift, 1.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(particle, "scale", Vector2.ONE * 1.25, 0.25)
		tween.tween_property(particle, "modulate:a", 0.0, 0.5).set_delay(0.6)
		tween.chain().tween_callback(func() -> void:
			_particles.erase(particle)
			if is_instance_valid(particle):
				particle.queue_free())


func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	var pressed := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if pressed:
		accept_event()
		poked.emit()
