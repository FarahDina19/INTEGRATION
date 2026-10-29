extends Control
## Area Pour: hold to sweep the shaded area under a curve; stop when it equals the integral.

const ROUNDS := 5

var main: Node
var _rng := RandomNumberGenerator.new()
var _state := "intro"
var _round_index := 0
var _round: Dictionary = {}
var _ast: Variant = null
var _t := 0.0
var _x_min := 0.0
var _x_max := 1.0
var _y_max := 1.0
var _area := 0.0
var _holding := false
var _hold_time := 0.0
var _score := 0
var _stars_total := 0
var _graph: Control
var _prompt_holder: CenterContainer
var _area_label: Label
var _round_label: Label
var _score_label: Label
var _pour_button: Button
var _done_button: Button
var _result_label: Label
var _result_card: PanelContainer
var _reveal := false
var _pet: PetView


func _ready() -> void:
	_rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := Kit.hbox(16)
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 18
	add_child(top)
	var left := Kit.card(Color(Kit.PAPER, 0.94), 20, Vector2(16, 10))
	_round_label = Kit.heading("Round 1 / 5", 20)
	left.add_child(_round_label)
	top.add_child(left)
	top.add_child(Kit.spacer())
	var prompt := Kit.card(Color(Kit.PAPER, 0.97), 22, Vector2(26, 8))
	var prompt_col := Kit.vbox(0)
	var caption := Kit.label("Pour exactly this much area", 14, Kit.MUTED, Kit.FONT_MEDIUM)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_col.add_child(caption)
	_prompt_holder = CenterContainer.new()
	_prompt_holder.custom_minimum_size = Vector2(240, 70)
	prompt_col.add_child(_prompt_holder)
	prompt.add_child(prompt_col)
	top.add_child(prompt)
	top.add_child(Kit.spacer())
	var right := Kit.card(Color(Kit.PAPER, 0.94), 20, Vector2(16, 10))
	var right_row := Kit.hbox(10)
	right_row.add_child(Kit.icon("res://assets/art/icons/star.png", 26))
	_score_label = Kit.heading("0", 22)
	_score_label.name = "PourScore"
	right_row.add_child(_score_label)
	var pause := Kit.button("II", "secondary", 48, 44, 18)
	pause.pressed.connect(_pause)
	right_row.add_child(pause)
	right.add_child(right_row)
	top.add_child(right)
	_graph = Control.new()
	_graph.name = "PourGraph"
	_graph.anchor_left = 0.08
	_graph.anchor_right = 0.78
	_graph.anchor_top = 0.24
	_graph.anchor_bottom = 0.86
	_graph.mouse_filter = Control.MOUSE_FILTER_STOP
	_graph.draw.connect(_draw_graph)
	_graph.gui_input.connect(_graph_input)
	add_child(_graph)
	var side := Kit.vbox(12)
	side.anchor_left = 0.8
	side.anchor_right = 0.97
	side.anchor_top = 0.28
	side.anchor_bottom = 0.9
	add_child(side)
	var readout := Kit.card(Color(Kit.PAPER, 0.95), 20, Vector2(18, 12))
	var readout_col := Kit.vbox(2)
	readout_col.add_child(Kit.label("Area so far", 14, Kit.MUTED, Kit.FONT_MEDIUM))
	_area_label = Kit.title("0.00", 40, Kit.TEAL_DARK)
	_area_label.name = "AreaReadout"
	readout_col.add_child(_area_label)
	readout.add_child(readout_col)
	side.add_child(readout)
	_pour_button = Kit.button("Hold to pour", "primary", 0, 70, 17)
	_pour_button.name = "PourButton"
	_pour_button.button_down.connect(func() -> void: _set_holding(true))
	_pour_button.button_up.connect(func() -> void: _set_holding(false))
	side.add_child(_pour_button)
	_done_button = Kit.button("Stop here!", "accent", 0, 56, 19)
	_done_button.name = "StopButton"
	_done_button.pressed.connect(_submit)
	side.add_child(_done_button)
	_result_card = Kit.card(Color(Kit.PAPER, 0.96), 18, Vector2(16, 10))
	_result_card.visible = false
	_result_label = Kit.wrap(Kit.label("", 15, Kit.INK, Kit.FONT_BOLD))
	_result_card.add_child(_result_label)
	side.add_child(_result_card)
	_pet = PetView.new()
	_pet.interactive = false
	_pet.base_height = 150.0
	_pet.custom_minimum_size = Vector2(0, 150)
	_pet.art_key = main.pet.art_key()
	side.add_child(_pet)
	var help := Kit.label("Hold Space, the button, or press on the graph to pour · Enter to stop", 14, Kit.CHALK, Kit.FONT_BOLD)
	help.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	help.offset_top = -34
	help.offset_left = -330
	help.offset_right = 330
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(help)
	_show_intro()


func _show_intro() -> void:
	var column := Kit.vbox(14)
	column.custom_minimum_size = Vector2(520, 0)
	column.add_child(Kit.chip("MINI-GAME", Kit.CORAL_PALE, Kit.CORAL_DARK))
	column.add_child(Kit.heading("Area Pour", 32))
	column.add_child(Kit.wrap(Kit.label("A definite integral is the area under a curve. Hold to pour teal paint under the graph from the lower limit, and stop when the area equals the integral at the top. Work out the value first — then pour with confidence!", 17, Kit.MUTED), 500))
	column.add_child(Kit.wrap(Kit.label("5 rounds · up to 3 stars each · rewards: joy, growth XP and coins", 15, Kit.TEAL_DARK, Kit.FONT_BOLD), 500))
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
		_round_index = 0
		_score = 0
		_stars_total = 0
		_start_round())
	row.add_child(start)
	column.add_child(row)
	main.show_modal(column)
	start.call_deferred("grab_focus")


func _start_round() -> void:
	_round = ProblemBank.pour_round(_rng, _round_index)
	var parsed := MathExpr.parse(str(_round.expr))
	_ast = parsed.ast
	var a := float(_round.a)
	var b := float(_round.b)
	_x_min = a
	_t = a
	_area = 0.0
	_x_max = b + (b - a) * _rng.randf_range(0.45, 0.8)
	_y_max = 0.0
	for i: int in 101:
		var x := lerpf(_x_min, _x_max, i / 100.0)
		_y_max = maxf(_y_max, _f(x))
	_y_max = maxf(_y_max * 1.18, 1.0)
	for child: Node in _prompt_holder.get_children():
		child.queue_free()
	_prompt_holder.add_child(Kit.integral_view(_round.label, 30, Kit.INK))
	_round_label.text = "Round %d / %d" % [_round_index + 1, ROUNDS]
	_score_label.text = str(_score)
	_result_label.text = ""
	_result_card.visible = false
	_reveal = false
	_holding = false
	_pour_button.disabled = false
	_done_button.disabled = false
	_done_button.text = "Stop here!"
	_state = "play"
	_update_readout()
	_graph.queue_redraw()


func _f(x: float) -> float:
	var y := MathExpr.evaluate(_ast, x, 0.0)
	return maxf(0.0, y) if is_finite(y) else 0.0


func _area_to(t: float) -> float:
	var a := _x_min
	if t <= a:
		return 0.0
	var n := 120
	var h := (t - a) / n
	var total := _f(a) + _f(t)
	for i: int in range(1, n):
		total += _f(a + i * h) * (4.0 if i % 2 == 1 else 2.0)
	return total * h / 3.0


func _set_holding(value: bool) -> void:
	if _state != "play":
		_holding = false
		return
	if value and not _holding:
		_hold_time = 0.0
		main.play("player.action", 0.9)
	_holding = value


func _process(delta: float) -> void:
	if _state != "play":
		return
	var holding := _holding or Input.is_key_pressed(KEY_SPACE)
	if holding:
		_hold_time += delta
		var span := float(_round.b) - float(_round.a)
		var speed := span / 3.2 * clampf(0.35 + _hold_time * 0.7, 0.35, 1.4)
		_t = minf(_x_max, _t + speed * delta)
		_area = _area_to(_t)
		_update_readout()
		_graph.queue_redraw()
		if _t >= _x_max:
			_submit()
	else:
		_hold_time = 0.0


func _update_readout() -> void:
	_area_label.text = "%.2f" % _area


func _submit() -> void:
	if _state != "play":
		return
	_state = "reveal"
	_holding = false
	_pour_button.disabled = true
	var target := float(_round.value)
	var error := absf(_area - target) / maxf(absf(target), 0.001)
	var stars := 3 if error <= 0.03 else (2 if error <= 0.08 else (1 if error <= 0.18 else 0))
	var points: int = [0, 40, 70, 100][stars]
	_score += points
	_stars_total += stars
	_score_label.text = str(_score)
	_reveal = true
	_graph.queue_redraw()
	var verdict: String = ["Keep practising!", "Nice pour!", "Great accuracy!", "Perfect pour!"][stars]
	_result_card.visible = true
	_result_label.text = "%s  %s\nTarget %.2f · you poured %.2f (%d%% off)" % [verdict, "★".repeat(stars) + "☆".repeat(3 - stars), target, _area, int(round(error * 100.0))]
	if stars >= 2:
		main.play("score.reward")
		_pet.react("cheer")
	elif stars == 1:
		main.play("player.action")
	else:
		main.play("enemy.impact")
		_pet.react("sad")
	_done_button.text = "Next round  ›" if _round_index < ROUNDS - 1 else "See results"
	_done_button.disabled = false
	if _done_button.pressed.is_connected(_submit):
		_done_button.pressed.disconnect(_submit)
	_done_button.pressed.connect(_advance, CONNECT_ONE_SHOT)
	_done_button.call_deferred("grab_focus")


func _advance() -> void:
	main.play("ui.confirm")
	if not _done_button.pressed.is_connected(_submit):
		_done_button.pressed.connect(_submit)
	_round_index += 1
	if _round_index >= ROUNDS:
		_finish()
	else:
		_start_round()


func _finish() -> void:
	_state = "done"
	var pet: PetState = main.pet
	var best := _score > pet.best_pour
	pet.best_pour = maxi(pet.best_pour, _score)
	var coins := _stars_total * 2
	var xp := 4 + _stars_total * 2
	var joy := 10.0 + minf(30.0, _stars_total * 2.0)
	var summary: String = main.grant(coins, xp, joy)
	main.play("game.victory")
	main.save_now()
	var column := Kit.vbox(12)
	column.custom_minimum_size = Vector2(460, 0)
	column.add_child(Kit.heading("Paint dried — well done!", 30))
	column.add_child(Kit.label("%d / %d stars  ·  score %d%s" % [_stars_total, ROUNDS * 3, _score, "  ·  new best!" if best and _score > 0 else ""], 18, Kit.INK, Kit.FONT_BOLD))
	column.add_child(Kit.wrap(Kit.label(summary, 16, Kit.TEAL_DARK, Kit.FONT_BOLD), 440))
	column.add_child(Kit.wrap(Kit.label("Remember: ∫ from a to b of f(x) dx = F(b) − F(a) is exactly the shaded area.", 16, Kit.MUTED), 440))
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
		_round_index = 0
		_score = 0
		_stars_total = 0
		_start_round())
	row.add_child(home)
	row.add_child(again)
	column.add_child(row)
	main.show_modal(column)
	again.call_deferred("grab_focus")


func _to_screen(x: float, y: float) -> Vector2:
	var s := _graph.size
	var left := 56.0
	var bottom := s.y - 40.0
	var width := s.x - left - 16.0
	var height := bottom - 12.0
	return Vector2(left + (x - _x_min + (_x_max - _x_min) * 0.04) / ((_x_max - _x_min) * 1.04) * width, bottom - y / _y_max * height)


func _draw_graph() -> void:
	if _round.is_empty():
		return
	var chalk := Kit.CHALK
	var origin := _to_screen(_x_min, 0.0)
	var end_x := _to_screen(_x_max, 0.0)
	var top := _to_screen(_x_min, _y_max)
	var axis_left := Vector2(origin.x - 22.0, origin.y)
	_graph.draw_line(axis_left, Vector2(end_x.x + 10.0, origin.y), chalk, 3.0, true)
	_graph.draw_line(Vector2(origin.x, origin.y + 10.0), Vector2(origin.x, top.y), chalk, 3.0, true)
	var font := Kit.font(Kit.FONT_BOLD)
	_graph.draw_string(font, Vector2(end_x.x - 4.0, origin.y + 30.0), "x", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, chalk)
	_graph.draw_string(font, Vector2(origin.x - 50.0, top.y + 16.0), "y", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, chalk)
	var lower_text := str((_round.label as Dictionary).get("lower", ""))
	_graph.draw_string(font, Vector2(origin.x - 8.0, origin.y + 30.0), lower_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, chalk)
	if _t > _x_min:
		var poly := PackedVector2Array()
		poly.append(_to_screen(_x_min, 0.0))
		var steps := 80
		for i: int in steps + 1:
			var x := lerpf(_x_min, _t, i / float(steps))
			poly.append(_to_screen(x, _f(x)))
		poly.append(_to_screen(_t, 0.0))
		_graph.draw_colored_polygon(poly, Color(Kit.TEAL, 0.62))
		_graph.draw_line(_to_screen(_t, 0.0), _to_screen(_t, _f(_t)), Color("7ff0e0"), 3.0, true)
	var curve := PackedVector2Array()
	for i: int in 161:
		var x := lerpf(_x_min, _x_max, i / 160.0)
		curve.append(_to_screen(x, _f(x)))
	_graph.draw_polyline(curve, Color("ffd66b"), 4.0, true)
	if _reveal:
		var b := float(_round.b)
		var p0 := _to_screen(b, 0.0)
		var p1 := _to_screen(b, _y_max * 0.95)
		var dash := 12.0
		var y := p0.y
		while y > p1.y:
			_graph.draw_line(Vector2(p0.x, y), Vector2(p0.x, maxf(p1.y, y - dash * 0.6)), Kit.CORAL, 3.0, true)
			y -= dash
		var upper_text := str((_round.label as Dictionary).get("upper", ""))
		_graph.draw_string(font, Vector2(p0.x - 10.0, origin.y + 30.0), upper_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Kit.CORAL)
		_graph.draw_string(font, Vector2(p1.x + 8.0, p1.y + 18.0), "target edge", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Kit.CORAL)


func _graph_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_set_holding((event as InputEventMouseButton).pressed)
	elif event is InputEventScreenTouch:
		_set_holding((event as InputEventScreenTouch).pressed)


func _pause() -> void:
	if _state != "play" and _state != "reveal":
		return
	var previous := _state
	_state = "paused"
	_holding = false
	main.play("game.pause")
	var column := Kit.vbox(12)
	column.custom_minimum_size = Vector2(360, 0)
	column.add_child(Kit.heading("Paused", 30))
	var resume := Kit.button("Resume", "primary", 0)
	resume.pressed.connect(func() -> void:
		main.close_modal()
		_state = previous)
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
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := (event as InputEventKey).keycode
	if key == KEY_ESCAPE or key == KEY_P:
		if _state == "paused":
			return
		_pause()
		get_viewport().set_input_as_handled()
	elif (key == KEY_ENTER or key == KEY_KP_ENTER) and _state == "play":
		_submit()
		get_viewport().set_input_as_handled()
