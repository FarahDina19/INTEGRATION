extends Control
## Antiderivative Catch: steer your buddy to catch the bubble holding the antiderivative.

const DURATION := 60.0
const MAX_HEARTS := 3
const LANES := 5

var main: Node
var _rng := RandomNumberGenerator.new()
var _state := "intro"
var _time_left := DURATION
var _score := 0
var _caught := 0
var _combo := 0
var _hearts := MAX_HEARTS
var _round: Dictionary = {}
var _bubbles: Array[Dictionary] = []
var _player_x := 0.5
var _pointer_target := -1.0
var _pet: PetView
var _play_area: Control
var _target_label: Label
var _hearts_row: HBoxContainer
var _time_label: Label
var _score_label: Label
var _hint_label: Label
var _speed := 120.0
var _spawn_delay := 0.0
var _flash: ColorRect


func _ready() -> void:
	_rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_STOP
	_play_area = Control.new()
	_play_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(Kit.full_rect(_play_area))
	_pet = PetView.new()
	_pet.interactive = false
	_pet.base_height = 170.0
	_pet.size = Vector2(190, 180)
	_pet.art_key = main.pet.art_key()
	add_child(_pet)
	_flash = ColorRect.new()
	_flash.color = Color(1, 0.4, 0.3, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(Kit.full_rect(_flash))
	_build_hud()
	resized.connect(_layout_pet)
	_layout_pet()
	_show_intro()


func _build_hud() -> void:
	var top := Kit.hbox(16)
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 18
	add_child(top)
	var left := Kit.card(Color(Kit.PAPER, 0.94), 20, Vector2(16, 10))
	var left_row := Kit.hbox(6)
	_hearts_row = Kit.hbox(4)
	left_row.add_child(_hearts_row)
	left.add_child(left_row)
	top.add_child(left)
	top.add_child(Kit.spacer())
	var target_card := Kit.card(Color(Kit.PAPER, 0.97), 22, Vector2(26, 10))
	var target_col := Kit.vbox(0)
	var caption := Kit.label("Catch the antiderivative of", 14, Kit.MUTED, Kit.FONT_MEDIUM)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_col.add_child(caption)
	_target_label = Kit.label("Ready?", 34, Kit.INK, Kit.FONT_MEDIUM)
	_target_label.name = "CatchTarget"
	_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_col.add_child(_target_label)
	_hint_label = Kit.label("(+ C is understood)", 12, Kit.SOFT)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_col.add_child(_hint_label)
	target_card.add_child(target_col)
	top.add_child(target_card)
	top.add_child(Kit.spacer())
	var right := Kit.card(Color(Kit.PAPER, 0.94), 20, Vector2(16, 10))
	var right_row := Kit.hbox(14)
	_time_label = Kit.heading("60", 24)
	right_row.add_child(_time_label)
	var coin_row := Kit.hbox(4)
	coin_row.add_child(Kit.icon("res://assets/art/icons/star.png", 26))
	_score_label = Kit.heading("0", 24)
	_score_label.name = "CatchScore"
	coin_row.add_child(_score_label)
	right_row.add_child(coin_row)
	var pause := Kit.button("II", "secondary", 48, 44, 18)
	pause.name = "PauseButton"
	pause.pressed.connect(_pause)
	right_row.add_child(pause)
	right.add_child(right_row)
	top.add_child(right)
	var help := Kit.label("Move: ← → / A D, or drag / tap where you want to go", 14, Color.WHITE, Kit.FONT_BOLD)
	help.add_theme_color_override("font_outline_color", Color(0.1, 0.2, 0.15, 0.8))
	help.add_theme_constant_override("outline_size", 6)
	help.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	help.offset_top = -30
	help.offset_left = -260
	help.offset_right = 260
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(help)
	_refresh_hud()


func _refresh_hud() -> void:
	for child: Node in _hearts_row.get_children():
		child.queue_free()
	for i: int in MAX_HEARTS:
		var heart := Kit.icon("res://assets/art/icons/heart.png", 30)
		heart.modulate = Color(1, 1, 1, 1.0 if i < _hearts else 0.22)
		_hearts_row.add_child(heart)
	_time_label.text = "%ds" % int(ceil(_time_left))
	_score_label.text = str(_score)


func _layout_pet() -> void:
	_pet.position = Vector2(_player_x * size.x - _pet.size.x * 0.5, size.y - _pet.size.y - 44.0)


func _show_intro() -> void:
	_state = "intro"
	var column := Kit.vbox(14)
	column.custom_minimum_size = Vector2(520, 0)
	column.add_child(Kit.chip("MINI-GAME", Kit.CORAL_PALE, Kit.CORAL_DARK))
	column.add_child(Kit.heading("Antiderivative Catch", 32))
	column.add_child(Kit.wrap(Kit.label("Bubbles drift down from the sky. Steer %s under the bubble showing the antiderivative of the integral at the top. A wrong catch costs a heart; let the right one fall and a new set arrives." % main.pet.pet_name, 17, Kit.MUTED), 500))
	column.add_child(Kit.wrap(Kit.label("60 seconds · 3 hearts · combos score extra · rewards: joy, growth XP and coins", 15, Kit.TEAL_DARK, Kit.FONT_BOLD), 500))
	var row := Kit.hbox(12)
	var back := Kit.button("Back home", "secondary", 160)
	back.pressed.connect(func() -> void:
		main.play("ui.cancel")
		main.go_home())
	row.add_child(back)
	var start := Kit.button("Start!", "primary", 0)
	start.name = "StartButton"
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(func() -> void:
		main.play("ui.confirm")
		main.close_modal()
		_begin())
	row.add_child(start)
	column.add_child(row)
	main.show_modal(column)
	start.call_deferred("grab_focus")


func _begin() -> void:
	_state = "play"
	_time_left = DURATION
	_score = 0
	_caught = 0
	_combo = 0
	_hearts = MAX_HEARTS
	_speed = 120.0
	_next_round()
	_refresh_hud()


func _next_round() -> void:
	for bubble: Dictionary in _bubbles:
		_pop(bubble, false)
	_bubbles.clear()
	_round = ProblemBank.catch_round(_rng)
	_target_label.text = str(_round.target)
	var options: Array = [str(_round.correct)]
	var wrong: Array = (_round.wrong as Array).duplicate()
	wrong.shuffle()
	for i: int in mini(2 if _caught < 4 else 3, wrong.size()):
		options.append(str(wrong[i]))
	var lanes := range(LANES)
	lanes.shuffle()
	for i: int in options.size():
		var lane: int = lanes[i]
		var node := PanelContainer.new()
		var correct := i == 0
		var style := Kit.box(Color(1, 1, 1, 0.92), Kit.TEAL, 36, 3)
		style.content_margin_left = 20
		style.content_margin_right = 20
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		style.shadow_color = Color(0, 0.2, 0.2, 0.18)
		style.shadow_size = 8
		node.add_theme_stylebox_override("panel", style)
		var label := Kit.label(str(options[i]), 22, Kit.INK, Kit.FONT_MEDIUM)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		node.add_child(label)
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_play_area.add_child(node)
		node.reset_size()
		var lane_x := (lane + 0.5) / float(LANES) * size.x
		var y := -80.0 - _rng.randf_range(0.0, 140.0)
		node.position = Vector2(lane_x - node.size.x * 0.5, y)
		node.pivot_offset = node.size * 0.5
		_bubbles.append({"node": node, "correct": correct, "text": str(options[i]), "wobble": _rng.randf_range(0.0, TAU), "base_x": lane_x})


func _process(delta: float) -> void:
	if _state != "play":
		return
	_time_left -= delta
	if _time_left <= 0.0:
		_time_left = 0.0
		_finish()
		return
	var move := Input.get_axis("move_left", "move_right")
	if Input.is_key_pressed(KEY_A):
		move -= 1.0
	if Input.is_key_pressed(KEY_D):
		move += 1.0
	move = clampf(move, -1.0, 1.0)
	if absf(move) > 0.05:
		_pointer_target = -1.0
		_player_x += move * 0.9 * delta
	elif _pointer_target >= 0.0:
		_player_x = move_toward(_player_x, _pointer_target, 1.3 * delta)
	_player_x = clampf(_player_x, 0.07, 0.93)
	_layout_pet()
	if _spawn_delay > 0.0:
		_spawn_delay -= delta
		if _spawn_delay <= 0.0:
			_next_round()
		_refresh_hud()
		return
	var catch_rect := Rect2(_pet.position + Vector2(_pet.size.x * 0.12, _pet.size.y * 0.15), Vector2(_pet.size.x * 0.76, _pet.size.y * 0.5))
	var floor_y := size.y - 30.0
	for bubble: Dictionary in _bubbles.duplicate():
		var node: PanelContainer = bubble.node
		bubble.wobble = float(bubble.wobble) + delta * 2.0
		node.position.y += _speed * delta
		node.position.x = float(bubble.base_x) - node.size.x * 0.5 + sin(float(bubble.wobble)) * 10.0
		var rect := Rect2(node.position, node.size)
		if rect.intersects(catch_rect):
			_catch(bubble)
			return
		if node.position.y > floor_y:
			if bubble.correct:
				_missed()
				return
			_bubbles.erase(bubble)
			_pop(bubble, false)
	_refresh_hud()


func _catch(bubble: Dictionary) -> void:
	if bubble.correct:
		_combo += 1
		_caught += 1
		var gained := 10 + 5 * mini(_combo - 1, 4)
		_score += gained
		main.play("score.reward", 1.0 + 0.04 * mini(_combo, 6))
		_pet.react("cheer")
		_float_text("+%d%s" % [gained, ("  combo ×%d" % _combo) if _combo > 1 else ""], Kit.TEAL_DARK)
		_speed = minf(240.0, _speed + 8.0)
		_bubbles.erase(bubble)
		_pop(bubble, true)
		_spawn_delay = 0.45
	else:
		_combo = 0
		_hearts -= 1
		main.play("enemy.impact")
		_pet.react("sad")
		_pet.set_look(main.pet.art_key(), false)
		get_tree().create_timer(0.9).timeout.connect(func() -> void:
			if is_instance_valid(_pet):
				_pet.set_look(main.pet.art_key(), true))
		_float_text("Not that one! Differentiate it to check.", Kit.CORAL_DARK)
		_flash.color.a = 0.25
		create_tween().tween_property(_flash, "color:a", 0.0, 0.35)
		_bubbles.erase(bubble)
		_pop(bubble, false)
		if _hearts <= 0:
			_refresh_hud()
			_finish()
			return
	_refresh_hud()


func _missed() -> void:
	_combo = 0
	main.play("ui.cancel")
	_float_text("It was %s — next set!" % str(_round.correct), Kit.MUTED)
	_spawn_delay = 0.6
	for bubble: Dictionary in _bubbles:
		_pop(bubble, false)
	_bubbles.clear()


func _pop(bubble: Dictionary, good: bool) -> void:
	var node: Control = bubble.node
	if not is_instance_valid(node):
		return
	var tween := node.create_tween().set_parallel(true)
	tween.tween_property(node, "scale", Vector2.ONE * (1.4 if good else 0.6), 0.2)
	tween.tween_property(node, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(node.queue_free)


func _float_text(text: String, color: Color) -> void:
	var label := Kit.label(text, 20, color, Kit.FONT_BOLD)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	label.reset_size()
	label.position = Vector2(clampf(_pet.position.x + _pet.size.x * 0.5 - label.size.x * 0.5, 10.0, size.x - label.size.x - 10.0), _pet.position.y - 40.0)
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 70.0, 1.1)
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tween.chain().tween_callback(label.queue_free)


func _gui_input(event: InputEvent) -> void:
	if _state != "play":
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_pointer_target = (event as InputEventMouseButton).position.x / maxf(size.x, 1.0)
	elif event is InputEventMouseMotion and ((event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_pointer_target = (event as InputEventMouseMotion).position.x / maxf(size.x, 1.0)
	elif event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		_pointer_target = (event as InputEventScreenTouch).position.x / maxf(size.x, 1.0)
	elif event is InputEventScreenDrag:
		_pointer_target = (event as InputEventScreenDrag).position.x / maxf(size.x, 1.0)


func _finish() -> void:
	if _state == "done":
		return
	_state = "done"
	for bubble: Dictionary in _bubbles:
		_pop(bubble, false)
	_bubbles.clear()
	var pet: PetState = main.pet
	var best := _score > pet.best_catch
	pet.best_catch = maxi(pet.best_catch, _score)
	var coins := _caught * 2
	var xp := 4 + _caught * 2
	var joy := 10.0 + minf(30.0, _caught * 3.0)
	var summary: String = main.grant(coins, xp, joy)
	main.play("game.victory")
	main.save_now()
	var column := Kit.vbox(12)
	column.custom_minimum_size = Vector2(460, 0)
	column.add_child(Kit.heading("Time's up!" if _hearts > 0 else "Out of hearts!", 32))
	column.add_child(Kit.label("Caught %d antiderivatives  ·  score %d%s" % [_caught, _score, "  ·  new best!" if best and _score > 0 else ""], 18, Kit.INK, Kit.FONT_BOLD))
	column.add_child(Kit.wrap(Kit.label(summary, 16, Kit.TEAL_DARK, Kit.FONT_BOLD), 440))
	column.add_child(Kit.wrap(Kit.label("%s had a great time playing with you!" % pet.pet_name, 16, Kit.MUTED), 440))
	var row := Kit.hbox(12)
	var home := Kit.button("Back home", "secondary", 0)
	home.name = "ResultHome"
	home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.pressed.connect(func() -> void:
		main.play("ui.confirm")
		main.go_home())
	var again := Kit.button("Play again", "primary", 0)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(func() -> void:
		main.play("ui.confirm")
		main.close_modal()
		_begin())
	row.add_child(home)
	row.add_child(again)
	column.add_child(row)
	main.show_modal(column)
	again.call_deferred("grab_focus")


func _pause() -> void:
	if _state != "play":
		return
	_state = "paused"
	main.play("game.pause")
	var column := Kit.vbox(12)
	column.custom_minimum_size = Vector2(360, 0)
	column.add_child(Kit.heading("Paused", 30))
	var resume := Kit.button("Resume", "primary", 0)
	resume.pressed.connect(func() -> void:
		main.close_modal()
		_state = "play")
	column.add_child(resume)
	var quit := Kit.button("Quit to home (no rewards)", "secondary", 0)
	quit.pressed.connect(func() -> void:
		main.play("ui.cancel")
		main.go_home())
	column.add_child(quit)
	main.show_modal(column)
	resume.call_deferred("grab_focus")


func on_focus_lost() -> void:
	_pause()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and ((event as InputEventKey).keycode == KEY_ESCAPE or (event as InputEventKey).keycode == KEY_P):
		if _state == "play":
			_pause()
		elif _state == "paused":
			main.close_modal()
			_state = "play"
		get_viewport().set_input_as_handled()
