extends Control
## Home: the cozy room where the buddy lives. Shows needs, care tray and activities.

var main: Node
var _pet_view: PetView
var _name_label: Label
var _stage_chip: PanelContainer
var _xp_bar: ProgressBar
var _xp_label: Label
var _full_bar: ProgressBar
var _joy_bar: ProgressBar
var _full_value: Label
var _joy_value: Label
var _coin_label: Label
var _speech: Label
var _speech_panel: PanelContainer
var _slots: Dictionary = {}
var _poke_cooldown := 0.0
var _speech_override_time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pet: PetState = main.pet
	_build_status_card()
	_build_coin_pill()
	_build_pet()
	_build_activities()
	_build_tray()
	pet.changed.connect(refresh)
	refresh()


func _exit_tree() -> void:
	var pet: PetState = main.pet if main != null else null
	if pet != null and pet.changed.is_connected(refresh):
		pet.changed.disconnect(refresh)


func _anchor(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0


func _build_status_card() -> void:
	var card := Kit.card(Color(Kit.PAPER, 0.95), 24, Vector2(22, 18))
	card.position = Vector2(24, 22)
	card.custom_minimum_size = Vector2(380, 0)
	add_child(card)
	var column := Kit.vbox(10)
	card.add_child(column)
	var top := Kit.hbox(10)
	_name_label = Kit.heading("", 28)
	top.add_child(_name_label)
	top.add_child(Kit.spacer())
	_stage_chip = Kit.chip("", Kit.GOLD_PALE, Color("9a6a00"), 13)
	_stage_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_stage_chip)
	column.add_child(top)
	var xp_row := Kit.hbox(8)
	xp_row.add_child(Kit.icon("res://assets/art/icons/star.png", 24))
	_xp_bar = Kit.meter(Kit.GOLD, 12)
	xp_row.add_child(_xp_bar)
	column.add_child(xp_row)
	_xp_label = Kit.label("", 13, Kit.MUTED, Kit.FONT_MEDIUM)
	column.add_child(_xp_label)
	var full_row := _need_row("res://assets/art/icons/food.png", "Fullness", Kit.CORAL)
	_full_bar = full_row[1]
	_full_value = full_row[2]
	column.add_child(full_row[0])
	var joy_row := _need_row("res://assets/art/icons/heart.png", "Joy", Kit.TEAL)
	_joy_bar = joy_row[1]
	_joy_value = joy_row[2]
	column.add_child(joy_row[0])


func _need_row(icon_path: String, caption: String, color: Color) -> Array:
	var row := Kit.hbox(8)
	row.add_child(Kit.icon(icon_path, 26))
	var name_label := Kit.label(caption, 15, Kit.INK, Kit.FONT_BOLD)
	name_label.custom_minimum_size.x = 76
	row.add_child(name_label)
	var bar := Kit.meter(color, 14)
	row.add_child(bar)
	var value := Kit.label("", 14, Kit.MUTED, Kit.FONT_MEDIUM)
	value.custom_minimum_size.x = 36
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	return [row, bar, value]


func _build_coin_pill() -> void:
	var row := Kit.hbox(10)
	row.anchor_left = 1.0
	row.anchor_right = 1.0
	row.offset_left = -330
	row.offset_right = -24
	row.offset_top = 22
	row.alignment = BoxContainer.ALIGNMENT_END
	add_child(row)
	var pill := Kit.card(Color(Kit.PAPER, 0.95), 22, Vector2(16, 6))
	var inner := Kit.hbox(8)
	inner.add_child(Kit.icon("res://assets/art/icons/coin.png", 32))
	_coin_label = Kit.heading("0", 24)
	_coin_label.name = "CoinLabel"
	inner.add_child(_coin_label)
	pill.add_child(inner)
	row.add_child(pill)
	var menu := Kit.button("Menu", "secondary", 96, 50, 17)
	menu.name = "MenuButton"
	menu.pressed.connect(_open_menu)
	row.add_child(menu)


func _build_pet() -> void:
	_pet_view = PetView.new()
	_pet_view.name = "PetView"
	_pet_view.base_height = 300.0
	_anchor(_pet_view, 0.36, 0.42, 0.64, 0.9)
	add_child(_pet_view)
	_pet_view.poked.connect(_on_poke)
	_speech_panel = Kit.card(Color(Kit.PAPER, 0.97), 20, Vector2(18, 12))
	_anchor(_speech_panel, 0.34, 0.25, 0.66, 0.25)
	_speech_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_speech_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_speech_panel)
	_speech = Kit.wrap(Kit.label("", 17, Kit.INK, Kit.FONT_MEDIUM))
	_speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speech_panel.add_child(_speech)


func _build_activities() -> void:
	var card := Kit.card(Color(Kit.PAPER, 0.95), 26, Vector2(22, 20))
	card.anchor_left = 1.0
	card.anchor_right = 1.0
	card.anchor_top = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -360
	card.offset_right = -24
	card.offset_top = -190
	card.offset_bottom = 190
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(card)
	var column := Kit.vbox(10)
	card.add_child(column)
	column.add_child(Kit.heading("What shall we do?", 24))
	column.add_child(_activity_button("StudyButton", "Study Desk", "Solve integrals · earn coins", "primary", "res://assets/art/icons/star.png", func() -> void: _go("study")))
	column.add_child(_activity_button("CatchButton", "Antiderivative Catch", "Mini-game · +joy", "secondary", "res://assets/art/items/ball.png", func() -> void: _go("catch")))
	column.add_child(_activity_button("PourButton", "Area Pour", "Mini-game · +joy", "secondary", "res://assets/art/items/kite.png", func() -> void: _go("pour")))
	column.add_child(_activity_button("ShopButton", "Shop", "Snacks & toys", "accent", "res://assets/art/icons/coin.png", _open_shop))


func _activity_button(node_name: String, heading_text: String, sub: String, kind: String, icon_path: String, action: Callable) -> Button:
	var button := Kit.button("", kind, 0, 68)
	button.name = node_name
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var row := Kit.hbox(12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Kit.full_rect(row)
	row.offset_left = 14
	row.offset_right = -10
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var plate_style := Kit.box(Color(1, 1, 1, 0.85), Color.TRANSPARENT, 12, 0)
	plate_style.content_margin_left = 4
	plate_style.content_margin_right = 4
	plate_style.content_margin_top = 4
	plate_style.content_margin_bottom = 4
	plate.add_theme_stylebox_override("panel", plate_style)
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plate.add_child(Kit.icon(icon_path, 38))
	row.add_child(plate)
	var text_column := Kit.vbox(0)
	text_column.alignment = BoxContainer.ALIGNMENT_CENTER
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fg := Kit.INK if kind == "secondary" else Color.WHITE
	text_column.add_child(Kit.label(heading_text, 19, fg, Kit.FONT_BOLD))
	text_column.add_child(Kit.label(sub, 13, Color(fg, 0.78), Kit.FONT_MEDIUM))
	row.add_child(text_column)
	button.add_child(row)
	button.pressed.connect(action)
	return button


func _build_tray() -> void:
	var card := Kit.card(Color(Kit.PAPER, 0.95), 24, Vector2(18, 14))
	card.anchor_top = 1.0
	card.anchor_bottom = 1.0
	card.offset_left = 24
	card.offset_top = -150
	card.offset_bottom = -22
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(card)
	var column := Kit.vbox(8)
	card.add_child(column)
	var header := Kit.hbox(8)
	header.add_child(Kit.label("Care tray", 15, Kit.INK, Kit.FONT_BOLD))
	header.add_child(Kit.label("tap to use", 13, Kit.SOFT))
	column.add_child(header)
	var row := Kit.hbox(8)
	column.add_child(row)
	for id: String in PetState.ITEM_ORDER:
		var item: Dictionary = PetState.ITEMS[id]
		var slot := Button.new()
		slot.name = "Slot_" + id
		slot.custom_minimum_size = Vector2(70, 76)
		slot.tooltip_text = "%s — %s" % [item.name, _effect_text(item)]
		slot.focus_mode = Control.FOCUS_ALL
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var normal := Kit.box(Kit.CREAM, Kit.LINE, 16, 2)
		slot.add_theme_stylebox_override("normal", normal)
		var hover := Kit.box(Kit.GOLD_PALE, Kit.GOLD, 16, 2)
		slot.add_theme_stylebox_override("hover", hover)
		slot.add_theme_stylebox_override("pressed", hover)
		var focus := Kit.box(Color.TRANSPARENT, Kit.GOLD, 16, 3)
		slot.add_theme_stylebox_override("focus", focus)
		var icon := Kit.icon(str(item.icon), 50)
		Kit.full_rect(icon)
		icon.offset_left = 8
		icon.offset_right = -8
		icon.offset_top = 6
		icon.offset_bottom = -14
		slot.add_child(icon)
		var count := Kit.label("0", 14, Kit.INK, Kit.FONT_BOLD)
		count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		count.offset_left = -30
		count.offset_top = -24
		count.offset_right = -7
		count.offset_bottom = -3
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		slot.add_child(count)
		slot.pressed.connect(_use_item.bind(id))
		Kit.add_press_juice(slot)
		row.add_child(slot)
		_slots[id] = {"button": slot, "count": count, "icon": icon}


static func _effect_text(item: Dictionary) -> String:
	var parts: Array[String] = []
	if int(item.fullness) > 0:
		parts.append("+%d fullness" % int(item.fullness))
	if int(item.joy) > 0:
		parts.append("+%d joy" % int(item.joy))
	return ", ".join(parts)


func refresh() -> void:
	if main == null or main.pet == null or _name_label == null:
		return
	var pet: PetState = main.pet
	_name_label.text = pet.pet_name
	(_stage_chip.get_node("Text") as Label).text = "%s · %d/%d" % [pet.stage_info().name, pet.stage + 1, PetState.STAGES.size()]
	_xp_bar.value = pet.stage_progress() * 100.0
	if pet.is_final_stage():
		_xp_label.text = "Fully grown! %d XP earned" % pet.xp
	elif pet.is_ready_but_needs_care():
		_xp_label.text = "Ready to grow — raise Fullness & Joy to %d" % int(PetState.GROW_NEED_THRESHOLD)
	else:
		_xp_label.text = "Growth %d / %d XP to %s" % [pet.xp, pet.next_stage_xp(), PetState.STAGES[pet.stage + 1].name]
	_full_bar.value = pet.fullness
	_joy_bar.value = pet.joy
	_full_value.text = str(int(round(pet.fullness)))
	_joy_value.text = str(int(round(pet.joy)))
	_coin_label.text = str(pet.coins)
	_pet_view.base_height = [290.0, 330.0, 360.0][pet.stage]
	_pet_view.set_look(pet.art_key(), pet.looks_happy())
	if _speech_override_time <= 0.0:
		_speech.text = pet.speech()
	for id: String in _slots:
		var slot: Dictionary = _slots[id]
		var count := pet.item_count(id)
		(slot.count as Label).text = "×%d" % count
		(slot.icon as TextureRect).modulate = Color(1, 1, 1, 1.0 if count > 0 else 0.35)


func _process(delta: float) -> void:
	_poke_cooldown = maxf(0.0, _poke_cooldown - delta)
	if _speech_override_time > 0.0:
		_speech_override_time -= delta
		if _speech_override_time <= 0.0:
			refresh()


func say(text: String, seconds: float = 3.5) -> void:
	_speech.text = text
	_speech_override_time = seconds
	_speech_panel.pivot_offset = _speech_panel.size * 0.5
	_speech_panel.scale = Vector2(0.92, 0.92)
	create_tween().tween_property(_speech_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_poke() -> void:
	if _poke_cooldown > 0.0:
		return
	_poke_cooldown = 0.8
	main.play("player.action", randf_range(0.95, 1.1))
	_pet_view.react("poke")
	var pet: PetState = main.pet
	pet.add_joy(1.0)
	say(["Hehe, that tickles!", "Cuddles! ∫ love dx = ∞ + C", "Let's solve something together!", "I like it when you visit."].pick_random(), 2.5)


func _use_item(id: String) -> void:
	var pet: PetState = main.pet
	if pet.item_count(id) <= 0:
		main.play("ui.cancel")
		say("We don't have a %s yet — it's in the Shop!" % str(PetState.ITEMS[id].name).to_lower(), 3.0)
		return
	var full_before := pet.fullness
	var joy_before := pet.joy
	if str(PetState.ITEMS[id].kind) == "food" and pet.fullness >= 98.0:
		main.play("ui.cancel")
		say("I'm too full to eat another bite!", 2.5)
		return
	var item := pet.use_item(id)
	if item.is_empty():
		return
	main.play("score.reward")
	_pet_view.react("eat" if item.kind == "food" else "play")
	var gained := []
	if pet.fullness > full_before:
		gained.append("+%d fullness" % int(round(pet.fullness - full_before)))
	if pet.joy > joy_before:
		gained.append("+%d joy" % int(round(pet.joy - joy_before)))
	var line: String
	if item.kind == "food":
		line = ["Yum! That %s was delicious." % str(item.name).to_lower(), "Nom nom… thank you!", "My favourite!"].pick_random()
	else:
		line = ["Wheee! Let's play again!", "This is the best toy ever!", "Catch me if you can!"].pick_random()
	say(line + ("  (" + ", ".join(gained) + ")" if not gained.is_empty() else ""), 3.0)
	main.save_now()


func _go(where: String) -> void:
	main.play("ui.confirm")
	match where:
		"study":
			main.open_study()
		"catch":
			main.start_minigame("catch")
		"pour":
			main.start_minigame("pour")


# ------------------------------------------------------------------ shop

func _open_shop() -> void:
	main.play("ui.confirm")
	var column := Kit.vbox(14)
	column.custom_minimum_size = Vector2(760, 0)
	var header := Kit.hbox(12)
	header.add_child(Kit.heading("Buddy Shop", 30))
	header.add_child(Kit.spacer())
	var wallet := Kit.hbox(6)
	wallet.add_child(Kit.icon("res://assets/art/icons/coin.png", 28))
	var wallet_label := Kit.heading(str(main.pet.coins), 24)
	wallet.add_child(wallet_label)
	header.add_child(wallet)
	column.add_child(header)
	column.add_child(Kit.label("Snacks restore Fullness, toys restore Joy. Every item also gives a little growth XP.", 15, Kit.MUTED))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	column.add_child(grid)
	var buy_buttons: Dictionary = {}
	var owned_labels: Dictionary = {}
	var update := func() -> void:
		wallet_label.text = str(main.pet.coins)
		for item_id: String in buy_buttons:
			(buy_buttons[item_id] as Button).disabled = not main.pet.can_buy(item_id)
			(owned_labels[item_id] as Label).text = "Owned ×%d" % main.pet.item_count(item_id)
	for id: String in PetState.ITEM_ORDER:
		var item: Dictionary = PetState.ITEMS[id]
		var tile := PanelContainer.new()
		tile.add_theme_stylebox_override("panel", Kit.box(Kit.CREAM, Kit.LINE, 18, 2))
		tile.custom_minimum_size = Vector2(240, 0)
		var tile_col := Kit.vbox(6)
		tile.add_child(tile_col)
		var top := Kit.hbox(10)
		top.add_child(Kit.icon(str(item.icon), 64))
		var info := Kit.vbox(2)
		info.add_child(Kit.label(str(item.name), 16, Kit.INK, Kit.FONT_BOLD))
		info.add_child(Kit.label(_effect_text(item), 13, Kit.CORAL_DARK if item.kind == "food" else Kit.TEAL_DARK, Kit.FONT_MEDIUM))
		var owned := Kit.label("", 12, Kit.SOFT)
		info.add_child(owned)
		owned_labels[id] = owned
		top.add_child(info)
		tile_col.add_child(top)
		var buy := Kit.button("Buy · %d coins" % int(item.price), "primary", 0, 44, 16)
		buy.name = "Buy_" + id
		buy.pressed.connect(func() -> void:
			if main.pet.buy(id):
				main.play("score.reward")
				main.toast("Bought a %s!" % str(item.name).to_lower())
				main.save_now()
			else:
				main.play("ui.cancel")
			update.call())
		buy_buttons[id] = buy
		tile_col.add_child(buy)
		grid.add_child(tile)
	update.call()
	var footer := Kit.hbox(12)
	var earn := Kit.button("Earn more coins at the Study Desk", "ghost", 0, 44, 16)
	earn.pressed.connect(func() -> void:
		main.close_modal()
		_go("study"))
	footer.add_child(earn)
	footer.add_child(Kit.spacer())
	var close := Kit.button("Done", "secondary", 140)
	close.name = "ShopClose"
	close.pressed.connect(func() -> void:
		main.play("ui.cancel")
		main.close_modal()
		refresh())
	footer.add_child(close)
	column.add_child(footer)
	main.show_modal(column)
	close.call_deferred("grab_focus")


# ------------------------------------------------------------------ menu

func _open_menu() -> void:
	main.play("game.pause")
	var pet: PetState = main.pet
	var column := Kit.vbox(12)
	column.custom_minimum_size = Vector2(440, 0)
	column.add_child(Kit.heading("%s's journal" % pet.pet_name, 28))
	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 24)
	stats.add_theme_constant_override("v_separation", 6)
	var rows := [
		["Challenges solved", str(pet.total_solved())],
		["Accuracy", ("%d%%" % int(round(100.0 * pet.total_solved() / pet.attempts))) if pet.attempts > 0 else "—"],
		["Best streak", str(pet.best_streak)],
		["Best Catch score", str(pet.best_catch)],
		["Best Pour score", str(pet.best_pour)],
	]
	for row: Array in rows:
		stats.add_child(Kit.label(str(row[0]), 16, Kit.MUTED))
		stats.add_child(Kit.label(str(row[1]), 16, Kit.INK, Kit.FONT_BOLD))
	column.add_child(stats)
	var topics := Kit.vbox(4)
	topics.add_child(Kit.label("Solved by topic", 15, Kit.INK, Kit.FONT_BOLD))
	for topic: Dictionary in ProblemBank.TOPICS:
		topics.add_child(Kit.label("%s  ·  %d" % [topic.name, int(pet.solved.get(topic.id, 0))], 14, Kit.MUTED))
	column.add_child(topics)
	var resume := Kit.button("Back to %s" % pet.pet_name, "primary", 0)
	resume.pressed.connect(func() -> void:
		main.play("ui.cancel")
		main.close_modal())
	column.add_child(resume)
	var how := Kit.button("How to play", "secondary", 0)
	how.pressed.connect(func() -> void:
		main.close_modal()
		main.call("_show_tutorial", 0, false))
	column.add_child(how)
	var title := Kit.button("Save & return to title", "ghost", 0)
	title.pressed.connect(func() -> void:
		main.play("ui.cancel")
		main.back_to_title())
	column.add_child(title)
	main.show_modal(column)
	resume.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_ESCAPE):
		if main.has_modal():
			main.close_modal()
		else:
			_open_menu()
		get_viewport().set_input_as_handled()
