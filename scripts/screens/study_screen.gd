extends Control
## Study Desk: typed-answer integration challenges with hints, worked steps and rewards.

var main: Node
var initial_topic := ""
var _rng := RandomNumberGenerator.new()
var _topic_id := "reverse"
var _problem: Dictionary = {}
var _hints_used := 0
var _solution_shown := false
var _solved := false
var _wrong_tries := 0
var _topic_buttons: Dictionary = {}
var _topic_counts: Dictionary = {}
var _topic_title: Label
var _topic_blurb: Label
var _reward_chip: PanelContainer
var _lead: Label
var _integral_holder: CenterContainer
var _input: LineEdit
var _check_button: Button
var _hint_button: Button
var _solution_button: Button
var _next_button: Button
var _feedback_panel: PanelContainer
var _feedback_title: Label
var _feedback_body: Label
var _hint_list: VBoxContainer
var _steps_box: VBoxContainer
var _buddy: PetView
var _buddy_line: Label
var _streak_label: Label


func _ready() -> void:
	_rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not initial_topic.is_empty():
		_topic_id = initial_topic
	else:
		_topic_id = _suggest_topic()
	_build()
	_new_problem()


func _suggest_topic() -> String:
	var pet: PetState = main.pet
	for topic: Dictionary in ProblemBank.TOPICS:
		if int(pet.solved.get(topic.id, 0)) < 3:
			return str(topic.id)
	return str(ProblemBank.TOPICS.pick_random().id)


func _build() -> void:
	var margin := MarginContainer.new()
	Kit.full_rect(margin)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28 if side in ["left", "right"] else 22)
	add_child(margin)
	var card := Kit.card(Kit.PAPER, 30, Vector2(26, 22))
	margin.add_child(card)
	var root := Kit.hbox(22)
	card.add_child(root)
	root.add_child(_build_sidebar())
	var divider := ColorRect.new()
	divider.color = Kit.LINE
	divider.custom_minimum_size = Vector2(2, 0)
	root.add_child(divider)
	root.add_child(_build_workspace())


func _build_sidebar() -> Control:
	var side := Kit.vbox(6)
	side.custom_minimum_size = Vector2(250, 0)
	var back := Kit.button("‹  Back home", "ghost", 0, 40, 16)
	back.name = "BackHome"
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.pressed.connect(_leave)
	side.add_child(back)
	side.add_child(Kit.heading("Study Desk", 26))
	for topic: Dictionary in ProblemBank.TOPICS:
		var button := Button.new()
		button.name = "Topic_" + str(topic.id)
		button.custom_minimum_size = Vector2(0, 46)
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var row := Kit.hbox(8)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Kit.full_rect(row)
		row.offset_left = 14
		row.offset_right = -12
		var text_col := Kit.vbox(0)
		text_col.alignment = BoxContainer.ALIGNMENT_CENTER
		text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label := Kit.label(str(topic.short), 16, Kit.INK, Kit.FONT_BOLD)
		text_col.add_child(name_label)
		var count := Kit.label("", 12, Kit.MUTED, Kit.FONT_MEDIUM)
		text_col.add_child(count)
		row.add_child(text_col)
		var pay := Kit.hbox(3)
		pay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pay.add_child(Kit.icon("res://assets/art/icons/coin.png", 18))
		pay.add_child(Kit.label(str(topic.coins), 14, Color("9a6a00"), Kit.FONT_BOLD))
		pay.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(pay)
		button.add_child(row)
		button.pressed.connect(_select_topic.bind(str(topic.id)))
		Kit.add_press_juice(button)
		side.add_child(button)
		_topic_buttons[topic.id] = button
		_topic_counts[topic.id] = count
	side.add_child(Kit.spacer(false))
	var buddy_card := PanelContainer.new()
	buddy_card.add_theme_stylebox_override("panel", Kit.box(Kit.TEAL_PALE, Color.TRANSPARENT, 20, 0))
	var buddy_col := Kit.vbox(4)
	buddy_card.add_child(buddy_col)
	_buddy = PetView.new()
	_buddy.interactive = false
	_buddy.base_height = 92.0
	_buddy.custom_minimum_size = Vector2(0, 94)
	_buddy.art_key = main.pet.art_key()
	_buddy.happy = main.pet.looks_happy()
	buddy_col.add_child(_buddy)
	_buddy_line = Kit.wrap(Kit.label("I believe in you!", 14, Kit.TEAL_DARK, Kit.FONT_BOLD), 210)
	_buddy_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buddy_col.add_child(_buddy_line)
	_streak_label = Kit.label("", 13, Kit.MUTED, Kit.FONT_MEDIUM)
	_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buddy_col.add_child(_streak_label)
	side.add_child(buddy_card)
	return side


func _build_workspace() -> Control:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var work := Kit.vbox(14)
	work.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(work)
	var header := Kit.hbox(12)
	var title_col := Kit.vbox(2)
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_topic_title = Kit.heading("", 26, Kit.TEAL_DARK)
	title_col.add_child(_topic_title)
	_topic_blurb = Kit.wrap(Kit.label("", 14, Kit.MUTED))
	title_col.add_child(_topic_blurb)
	header.add_child(title_col)
	_reward_chip = Kit.chip("", Kit.GOLD_PALE, Color("9a6a00"), 14)
	_reward_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_reward_chip)
	work.add_child(header)
	var problem_panel := PanelContainer.new()
	var problem_style := Kit.box(Kit.CREAM, Kit.LINE, 22, 2)
	problem_style.content_margin_top = 18
	problem_style.content_margin_bottom = 18
	problem_panel.add_theme_stylebox_override("panel", problem_style)
	var problem_col := Kit.vbox(6)
	problem_panel.add_child(problem_col)
	_lead = Kit.wrap(Kit.label("", 19, Kit.INK, Kit.FONT_MEDIUM))
	_lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	problem_col.add_child(_lead)
	_integral_holder = CenterContainer.new()
	_integral_holder.custom_minimum_size = Vector2(0, 96)
	problem_col.add_child(_integral_holder)
	work.add_child(problem_panel)
	var answer_row := Kit.hbox(10)
	_input = LineEdit.new()
	_input.name = "AnswerInput"
	_input.placeholder_text = "Type your answer, e.g. x^3/3 + 2x + C"
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.custom_minimum_size = Vector2(0, 58)
	_input.add_theme_font_override("font", Kit.font(Kit.FONT_MEDIUM))
	_input.add_theme_font_size_override("font_size", 22)
	_input.max_length = 120
	_input.text_submitted.connect(func(_t: String) -> void: _on_check())
	answer_row.add_child(_input)
	_check_button = Kit.button("Check", "primary", 140, 58, 20)
	_check_button.name = "CheckButton"
	_check_button.pressed.connect(_on_check)
	answer_row.add_child(_check_button)
	_next_button = Kit.button("Next challenge  ›", "accent", 200, 58, 19)
	_next_button.name = "NextButton"
	_next_button.visible = false
	_next_button.pressed.connect(_new_problem)
	answer_row.add_child(_next_button)
	work.add_child(answer_row)
	var pad := HFlowContainer.new()
	pad.add_theme_constant_override("h_separation", 6)
	pad.add_theme_constant_override("v_separation", 6)
	for token: Array in [["x²", "x^2"], ["^", "^"], ["( )", "()"], ["/", "/"], ["eˣ", "e^("], ["ln| |", "ln||"], ["sin", "sin("], ["cos", "cos("], ["π", "π"], ["+ C", " + C"]]:
		var key := Kit.button(str(token[0]), "secondary", 54, 40, 16)
		key.focus_mode = Control.FOCUS_NONE
		key.pressed.connect(_insert.bind(str(token[1])))
		pad.add_child(key)
	work.add_child(pad)
	work.add_child(Kit.wrap(Kit.label("Tips: powers with ^ (x^3), brackets for functions (e^(2x), sin(3x), ln|x+1|). 2x means 2·x. Indefinite answers need + C; definite answers are numbers like 16, 7/2 or 4π.", 13, Kit.SOFT)))
	var help_row := Kit.hbox(10)
	_hint_button = Kit.button("Hint", "secondary", 0, 44, 16)
	_hint_button.name = "HintButton"
	_hint_button.pressed.connect(_on_hint)
	help_row.add_child(_hint_button)
	_solution_button = Kit.button("Show worked solution", "ghost", 0, 44, 16)
	_solution_button.name = "SolutionButton"
	_solution_button.pressed.connect(_on_solution)
	help_row.add_child(_solution_button)
	help_row.add_child(Kit.spacer())
	var skip := Kit.button("New problem", "ghost", 0, 44, 16)
	skip.name = "SkipButton"
	skip.pressed.connect(func() -> void:
		main.play("ui.cancel")
		_new_problem())
	help_row.add_child(skip)
	work.add_child(help_row)
	_feedback_panel = PanelContainer.new()
	_feedback_panel.visible = false
	var feedback_col := Kit.vbox(4)
	_feedback_panel.add_child(feedback_col)
	_feedback_title = Kit.label("", 18, Kit.INK, Kit.FONT_BOLD)
	feedback_col.add_child(_feedback_title)
	_feedback_body = Kit.wrap(Kit.label("", 16, Kit.INK))
	feedback_col.add_child(_feedback_body)
	work.add_child(_feedback_panel)
	_hint_list = Kit.vbox(6)
	work.add_child(_hint_list)
	_steps_box = Kit.vbox(6)
	work.add_child(_steps_box)
	return scroll


func _insert(token: String) -> void:
	var caret := _input.caret_column
	var text := _input.text
	var offset := token.length()
	if token == "()" or token == "ln||":
		offset = token.length() - 1
	_input.text = text.substr(0, caret) + token + text.substr(caret)
	_input.caret_column = caret + offset
	_input.grab_focus()


func _select_topic(topic_id: String) -> void:
	main.play("ui.confirm")
	_topic_id = topic_id
	_new_problem()


func _new_problem() -> void:
	_problem = ProblemBank.generate(_topic_id, _rng)
	_hints_used = 0
	_solution_shown = false
	_solved = false
	_wrong_tries = 0
	_input.text = ""
	_input.editable = true
	_check_button.visible = true
	_check_button.disabled = false
	_next_button.visible = false
	_feedback_panel.visible = false
	for child: Node in _hint_list.get_children():
		child.queue_free()
	for child: Node in _steps_box.get_children():
		child.queue_free()
	var info := ProblemBank.topic(_topic_id)
	_topic_title.text = str(info.name)
	_topic_blurb.text = str(info.blurb)
	_lead.text = str(_problem.lead)
	for child: Node in _integral_holder.get_children():
		child.queue_free()
	var spec: Dictionary = _problem.get("integral", {})
	if not spec.is_empty():
		_integral_holder.add_child(Kit.integral_view(spec, 40, Kit.INK))
		_integral_holder.visible = true
	else:
		_integral_holder.visible = false
	_input.placeholder_text = "Type a number, e.g. 16 or 7/2" if _problem.kind == "definite" else "Type your answer, e.g. x^3/3 + 2x + C"
	_refresh_side()
	_update_help_buttons()
	_input.call_deferred("grab_focus")


func _refresh_side() -> void:
	var pet: PetState = main.pet
	for id: String in _topic_buttons:
		var button: Button = _topic_buttons[id]
		var selected := id == _topic_id
		var style := Kit.box(Kit.TEAL_PALE if selected else Kit.CREAM, Kit.TEAL if selected else Kit.LINE, 16, 2)
		button.add_theme_stylebox_override("normal", style)
		var hover := Kit.box(Kit.TEAL_PALE, Kit.TEAL, 16, 2)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
		button.add_theme_stylebox_override("focus", Kit.box(Color.TRANSPARENT, Kit.GOLD, 16, 3))
		var solved := int(pet.solved.get(id, 0))
		(_topic_counts[id] as Label).text = "%d solved" % solved if solved > 0 else "Not started"
	var preview := ProblemBank.reward(_problem, _hints_used, _solution_shown, pet.streak)
	(_reward_chip.get_node("Text") as Label).text = ("Reward: %d coins · %d XP" % [preview.coins, preview.xp]) if not _solution_shown else "Practice mode · %d XP" % preview.xp
	_streak_label.text = ("Streak ×%d  ·  bonus +%d" % [pet.streak, mini(pet.streak, 5)]) if pet.streak > 0 else "Solve in a row for a streak bonus"


func _update_help_buttons() -> void:
	var hints: Array = _problem.get("hints", [])
	_hint_button.disabled = _solved or _solution_shown or _hints_used >= hints.size()
	_hint_button.text = "Hint (%d/%d)" % [_hints_used, hints.size()] if _hints_used < hints.size() else "No more hints"
	_solution_button.disabled = _solved or _solution_shown


func _feedback(kind: String, title_text: String, body: String) -> void:
	var colors := {"correct": [Kit.TEAL_PALE, Kit.TEAL, Kit.TEAL_DARK], "close": [Kit.GOLD_PALE, Kit.GOLD, Color("8a5d00")], "wrong": [Kit.CORAL_PALE, Kit.CORAL, Kit.CORAL_DARK], "info": [Kit.CREAM, Kit.LINE, Kit.INK]}
	var palette: Array = colors.get(kind, colors.info)
	var style := Kit.box(palette[0], palette[1], 18, 2)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	_feedback_panel.add_theme_stylebox_override("panel", style)
	_feedback_title.text = title_text
	_feedback_title.add_theme_color_override("font_color", palette[2])
	_feedback_body.text = body
	_feedback_panel.visible = true
	_feedback_panel.pivot_offset = Vector2(_feedback_panel.size.x * 0.5, 0)
	_feedback_panel.scale = Vector2(0.97, 0.97)
	create_tween().tween_property(_feedback_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_check() -> void:
	if _solved or _problem.is_empty():
		return
	var answer := _input.text.strip_edges()
	if answer.is_empty():
		main.play("ui.cancel")
		_feedback("info", "Type an answer first", "Use the keypad below if you need symbols like ^, eˣ or ln| |.")
		return
	var result := ProblemBank.check(_problem, answer)
	var pet: PetState = main.pet
	match str(result.status):
		"correct":
			_solved = true
			pet.record_attempt(_topic_id, true)
			var reward := ProblemBank.reward(_problem, _hints_used, _solution_shown, pet.streak - 1)
			var summary: String = main.grant(int(reward.coins), int(reward.xp))
			main.play("score.reward")
			_buddy.set_look(pet.art_key(), true)
			_buddy.react("cheer")
			_buddy_line.text = ["Yay! You did it!", "Brilliant integrating!", "That's my study buddy!", "Woohoo — snack money!"].pick_random()
			_feedback("correct", "Correct!  " + summary, str(result.message) + "\nAnswer: " + str(_problem.answer_display))
			_input.editable = false
			_check_button.visible = false
			_next_button.visible = true
			_next_button.call_deferred("grab_focus")
			_show_steps(false)
		"missing_c", "invalid":
			main.play("ui.cancel")
			_feedback("close", "Almost!" if result.status == "missing_c" else "I couldn't read that", str(result.message))
		_:
			_wrong_tries += 1
			pet.record_attempt(_topic_id, false)
			main.play("enemy.impact")
			_buddy.set_look(pet.art_key(), false)
			_buddy.react("sad")
			_buddy_line.text = ["Hmm, let's try again!", "Mistakes help us learn.", "You've got this!"].pick_random()
			var extra := ""
			if _wrong_tries >= 2 and _hints_used < (_problem.get("hints", []) as Array).size():
				extra = "\nStuck? A hint costs a few coins but keeps the streak going."
			_feedback("wrong", "Not quite yet", str(result.message) + extra)
			_shake(_input)
	_refresh_side()
	_update_help_buttons()


func _shake(control: Control) -> void:
	var origin := control.position
	var tween := create_tween()
	for i: int in 4:
		tween.tween_property(control, "position:x", origin.x + (8.0 if i % 2 == 0 else -8.0), 0.04)
	tween.tween_property(control, "position:x", origin.x, 0.04)


func _on_hint() -> void:
	var hints: Array = _problem.get("hints", [])
	if _hints_used >= hints.size():
		return
	main.play("player.action")
	var hint_panel := PanelContainer.new()
	hint_panel.add_theme_stylebox_override("panel", Kit.box(Kit.GOLD_PALE, Color.TRANSPARENT, 14, 0))
	var row := Kit.hbox(10)
	row.add_child(Kit.label("Hint %d" % (_hints_used + 1), 14, Color("8a5d00"), Kit.FONT_BOLD))
	var text := Kit.wrap(Kit.label(str(hints[_hints_used]), 16, Kit.INK))
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	hint_panel.add_child(row)
	_hint_list.add_child(hint_panel)
	_hints_used += 1
	_refresh_side()
	_update_help_buttons()


func _on_solution() -> void:
	main.confirm("Show the worked solution?", "You'll still earn a little growth XP for finishing it, but no coins for this problem. Your streak resets.", "Show steps", func() -> void:
		_solution_shown = true
		main.pet.streak = 0
		main.play("player.action")
		_show_steps(true)
		_refresh_side()
		_update_help_buttons())


func _show_steps(practice: bool) -> void:
	for child: Node in _steps_box.get_children():
		child.queue_free()
	var steps: Array = _problem.get("steps", [])
	if steps.is_empty():
		return
	var panel := PanelContainer.new()
	var style := Kit.box(Color.WHITE, Kit.LINE, 18, 2)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	var col := Kit.vbox(8)
	panel.add_child(col)
	col.add_child(Kit.label("Worked solution", 17, Kit.TEAL_DARK, Kit.FONT_BOLD))
	for i: int in steps.size():
		var row := Kit.hbox(10)
		var number := Kit.chip(str(i + 1), Kit.TEAL_PALE, Kit.TEAL_DARK, 13)
		number.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(number)
		var line := Kit.wrap(Kit.label(str(steps[i]), 17, Kit.INK, Kit.FONT_MEDIUM))
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(line)
		col.add_child(row)
	if practice:
		col.add_child(Kit.wrap(Kit.label("Now type the final answer yourself to finish this one.", 14, Kit.MUTED)))
	_steps_box.add_child(panel)


func _leave() -> void:
	main.play("ui.cancel")
	main.go_home()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_ESCAPE:
		if main.has_modal():
			main.close_modal()
		else:
			_leave()
		get_viewport().set_input_as_handled()
