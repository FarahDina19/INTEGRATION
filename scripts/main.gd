extends Control
## Integral Buddy — main router. Owns the companion state, screens, modals and saving.

const ProceduralSfx = preload("res://scripts/manus/procedural_sfx.gd")
const OpenSourceLicenses = preload("res://scripts/manus/open_source_licenses.gd")
const HomeScreenScript = preload("res://scripts/screens/home_screen.gd")
const StudyScreenScript = preload("res://scripts/screens/study_screen.gd")
const CatchGameScript = preload("res://scripts/screens/catch_game.gd")
const PourGameScript = preload("res://scripts/screens/pour_game.gd")

const BACKGROUNDS := {
	"home": "res://assets/art/scenes/home.jpg",
	"garden": "res://assets/art/scenes/garden.jpg",
	"chalkboard": "res://assets/art/scenes/chalkboard.jpg",
}
const AUTOSAVE_SECONDS := 4.0

var pet: PetState
var state := "title"
var _background: TextureRect
var _background_tint: ColorRect
var _screen_layer: Control
var _modal_layer: Control
var _toast_layer: VBoxContainer
var _screen: Control
var _title_screen: Control
var _modal_stack: Array[Control] = []
var _dirty := false
var _autosave_clock := 0.0
var _pending_growth: Array[int] = []
var _transitioning := false


func _ready() -> void:
	theme = Kit.make_theme()
	_register_sounds()
	_background = TextureRect.new()
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(Kit.full_rect(_background))
	_background_tint = ColorRect.new()
	_background_tint.color = Color(1, 0.97, 0.92, 0.0)
	_background_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(Kit.full_rect(_background_tint))
	_screen_layer = Control.new()
	_screen_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(Kit.full_rect(_screen_layer))
	_modal_layer = Control.new()
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(Kit.full_rect(_modal_layer))
	_toast_layer = Kit.vbox(8)
	_toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_layer.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_layer.position = Vector2(-240, 18)
	_toast_layer.custom_minimum_size = Vector2(480, 0)
	add_child(_toast_layer)
	if SaveStore.has_pet():
		pet = PetState.from_dict(SaveStore.get_pet_data())
		pet.apply_offline(int(Time.get_unix_time_from_system()))
		_connect_pet()
	_show_title()


func _connect_pet() -> void:
	pet.changed.connect(func() -> void: _dirty = true)
	pet.grew.connect(_on_pet_grew)


func _register_sounds() -> void:
	var cues := {
		"ui.confirm": ProceduralSfx.tone(660.0, 0.07, 0.11, 880.0),
		"ui.cancel": ProceduralSfx.tone(520.0, 0.08, 0.09, 380.0),
		"score.reward": ProceduralSfx.tone(880.0, 0.16, 0.12, 1320.0),
		"enemy.impact": ProceduralSfx.tone(240.0, 0.18, 0.12, 170.0),
		"player.action": ProceduralSfx.tone(520.0, 0.12, 0.11, 780.0),
		"game.victory": ProceduralSfx.tone(523.0, 0.42, 0.13, 1046.0),
		"game.pause": ProceduralSfx.tone(440.0, 0.06, 0.08, 440.0),
	}
	for cue: String in cues:
		AudioDirector.register_stream(cue, cues[cue])


func play(cue: String, pitch: float = 1.0) -> void:
	AudioDirector.play_cue(cue, pitch)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey or event is InputEventScreenTouch:
		if event.is_pressed():
			AudioDirector.unlock_audio()


func _process(delta: float) -> void:
	if pet != null and state != "title" and not get_tree().paused:
		pet.tick(delta)
	_autosave_clock += delta
	if _dirty and _autosave_clock >= AUTOSAVE_SECONDS:
		save_now()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if pet != null:
			save_now()
		if what != NOTIFICATION_WM_CLOSE_REQUEST and _screen != null and _screen.has_method("on_focus_lost"):
			_screen.call("on_focus_lost")


func save_now() -> void:
	_autosave_clock = 0.0
	if pet == null:
		return
	_dirty = false
	SaveStore.set_pet_data(pet.to_dict())


# ------------------------------------------------------------------ screens

func set_background(key: String, tint: float = 0.0) -> void:
	_background.texture = Kit.texture(str(BACKGROUNDS.get(key, BACKGROUNDS.home)))
	_background_tint.color = Color(1, 0.97, 0.92, tint)


func _swap_screen(next_screen: Control, next_state: String) -> void:
	close_all_modals()
	if _screen != null:
		_screen.queue_free()
	if _title_screen != null:
		_title_screen.queue_free()
		_title_screen = null
	_screen = next_screen
	state = next_state
	if _screen != null:
		_screen.modulate.a = 0.0
		_screen_layer.add_child(Kit.full_rect(_screen))
		create_tween().tween_property(_screen, "modulate:a", 1.0, 0.22)


func go_home() -> void:
	get_tree().paused = false
	set_background("home")
	var home: Control = HomeScreenScript.new()
	home.set("main", self)
	_swap_screen(home, "home")
	save_now()
	if not _pending_growth.is_empty():
		var stage_index: int = _pending_growth.pop_front()
		call_deferred("_celebrate_growth", stage_index)
	elif not pet.tutorial_done:
		call_deferred("_show_tutorial", 0)


func open_study(topic_id: String = "") -> void:
	set_background("home", 0.35)
	var study: Control = StudyScreenScript.new()
	study.set("main", self)
	study.set("initial_topic", topic_id)
	_swap_screen(study, "study")


func start_minigame(kind: String) -> void:
	var game: Control
	if kind == "catch":
		set_background("garden")
		game = CatchGameScript.new()
	else:
		set_background("chalkboard")
		game = PourGameScript.new()
	game.set("main", self)
	_swap_screen(game, kind)


## Apply rewards from any activity and return a short summary string.
func grant(coins: int, xp: int, joy: float = 0.0, fullness: float = 0.0) -> String:
	var parts: Array[String] = []
	if coins > 0:
		pet.add_coins(coins)
		parts.append("+%d coins" % coins)
	if joy != 0.0:
		pet.add_joy(joy)
		parts.append("%+d joy" % int(joy))
	if fullness != 0.0:
		pet.add_fullness(fullness)
	if xp > 0:
		pet.gain_xp(xp)
		parts.append("+%d growth XP" % xp)
	_dirty = true
	return "  ·  ".join(parts)


func _on_pet_grew(stage_index: int) -> void:
	save_now()
	if state == "home":
		call_deferred("_celebrate_growth", stage_index)
	else:
		_pending_growth.append(stage_index)


# ------------------------------------------------------------------ title & adoption

func _show_title() -> void:
	set_background("home", 0.15)
	state = "title"
	if _screen != null:
		_screen.queue_free()
		_screen = null
	if _title_screen != null:
		_title_screen.queue_free()
	_title_screen = Control.new()
	_title_screen.name = "TitleScreen"
	_screen_layer.add_child(Kit.full_rect(_title_screen))
	var pet_view := PetView.new()
	pet_view.name = "TitlePet"
	pet_view.interactive = false
	pet_view.base_height = 430.0
	pet_view.anchor_left = 0.56
	pet_view.anchor_right = 0.94
	pet_view.anchor_top = 0.2
	pet_view.anchor_bottom = 0.93
	if pet != null:
		pet_view.art_key = pet.art_key()
	_title_screen.add_child(pet_view)
	var panel := Kit.card(Color(Kit.PAPER, 0.94), 32, Vector2(44, 36))
	panel.anchor_left = 0.06
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_top = -250
	panel.offset_bottom = 250
	panel.custom_minimum_size = Vector2(540, 0)
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_title_screen.add_child(panel)
	var column := Kit.vbox(14)
	panel.add_child(column)
	var eyebrow := Kit.chip("UNIT 3 · INTEGRATION COMPANION", Kit.TEAL_PALE, Kit.TEAL_DARK, 13)
	eyebrow.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(eyebrow)
	column.add_child(Kit.title("Integral Buddy", 64, Kit.INK))
	column.add_child(Kit.wrap(Kit.label("Raise a curious companion by solving integration challenges. Earn snacks and toys, play mini-games, and watch your buddy grow from Sprout to Scholar.", 18, Kit.MUTED), 460))
	column.add_child(Kit.spacer(false))
	var buttons := Kit.vbox(12)
	column.add_child(buttons)
	var first: Button
	if pet != null:
		var continue_button := Kit.button("Continue with %s" % pet.pet_name, "primary", 380, 60, 21)
		continue_button.name = "ContinueButton"
		continue_button.pressed.connect(_on_continue)
		buttons.add_child(continue_button)
		first = continue_button
		var fresh := Kit.button("Adopt a new buddy", "secondary", 380)
		fresh.name = "NewBuddyButton"
		fresh.pressed.connect(func() -> void: _confirm("Start over?", "%s and all progress will be replaced by a brand-new Sprout." % pet.pet_name, "Start over", _show_adopt))
		buttons.add_child(fresh)
	else:
		var adopt := Kit.button("Adopt your buddy", "primary", 380, 60, 21)
		adopt.name = "AdoptButton"
		adopt.pressed.connect(_show_adopt)
		buttons.add_child(adopt)
		first = adopt
	var how := Kit.button("How to play", "ghost", 380, 44, 17)
	how.pressed.connect(func() -> void: _show_tutorial(0, false))
	buttons.add_child(how)
	var footer := Kit.hbox(8)
	footer.add_child(Kit.label("Companion to the DUM10092 Unit 3 learning apps", 13, Kit.SOFT))
	footer.add_child(Kit.spacer())
	var licenses := Kit.button("Licenses", "ghost", 0, 30, 13)
	licenses.name = "OpenSourceLicensesButton"
	licenses.pressed.connect(func() -> void: OpenSourceLicenses.open(self))
	footer.add_child(licenses)
	column.add_child(footer)
	first.call_deferred("grab_focus")
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.35)


func _on_continue() -> void:
	if _transitioning:
		return
	play("ui.confirm")
	go_home()


func _show_adopt() -> void:
	var column := Kit.vbox(16)
	column.custom_minimum_size = Vector2(460, 0)
	column.add_child(Kit.heading("Name your buddy", 30))
	column.add_child(Kit.wrap(Kit.label("This little Sprout will grow as you master integration. What will you call it?", 17, Kit.MUTED), 440))
	var preview := PetView.new()
	preview.interactive = false
	preview.base_height = 190.0
	preview.custom_minimum_size = Vector2(0, 200)
	column.add_child(preview)
	var input := LineEdit.new()
	input.name = "NameInput"
	input.text = "Inty"
	input.max_length = 14
	input.placeholder_text = "Buddy name"
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.add_theme_font_size_override("font_size", 24)
	input.custom_minimum_size = Vector2(0, 56)
	column.add_child(input)
	var row := Kit.hbox(12)
	var cancel := Kit.button("Back", "secondary", 140)
	cancel.pressed.connect(func() -> void:
		play("ui.cancel")
		close_modal())
	var confirm_button := Kit.button("Adopt!", "primary", 0)
	confirm_button.name = "AdoptConfirm"
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var adopt_now := func() -> void:
		if _transitioning:
			return
		play("score.reward")
		_adopt(input.text)
	confirm_button.pressed.connect(adopt_now)
	input.text_submitted.connect(func(_t: String) -> void: adopt_now.call())
	row.add_child(cancel)
	row.add_child(confirm_button)
	column.add_child(row)
	show_modal(column)
	input.call_deferred("grab_focus")
	input.call_deferred("select_all")


func _adopt(name_text: String) -> void:
	_transitioning = true
	pet = PetState.create(name_text)
	_connect_pet()
	save_now()
	close_all_modals()
	go_home()
	_transitioning = false


# ------------------------------------------------------------------ modals

func show_modal(content: Control, padding: Vector2 = Vector2(32, 28)) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_layer.add_child(Kit.full_rect(root))
	var dim := ColorRect.new()
	dim.color = Color(0.1, 0.18, 0.18, 0.45)
	root.add_child(Kit.full_rect(dim))
	var center := CenterContainer.new()
	root.add_child(Kit.full_rect(center))
	var panel := Kit.card(Kit.PAPER, 28, padding)
	panel.add_child(content)
	center.add_child(panel)
	panel.resized.connect(func() -> void: panel.pivot_offset = panel.size * 0.5)
	panel.scale = Vector2(0.94, 0.94)
	panel.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.15)
	_modal_stack.append(root)
	return root


func close_modal() -> void:
	if _modal_stack.is_empty():
		return
	var root: Control = _modal_stack.pop_back()
	if is_instance_valid(root):
		root.queue_free()


func close_all_modals() -> void:
	while not _modal_stack.is_empty():
		close_modal()


func has_modal() -> bool:
	return not _modal_stack.is_empty()


func _confirm(heading_text: String, body: String, accept_text: String, on_accept: Callable) -> void:
	var column := Kit.vbox(16)
	column.custom_minimum_size = Vector2(420, 0)
	column.add_child(Kit.heading(heading_text, 28))
	column.add_child(Kit.wrap(Kit.label(body, 17, Kit.MUTED), 420))
	var row := Kit.hbox(12)
	var keep := Kit.button("Cancel", "secondary", 0)
	keep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	keep.pressed.connect(func() -> void:
		play("ui.cancel")
		close_modal())
	var accept := Kit.button(accept_text, "danger", 0)
	accept.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accept.pressed.connect(func() -> void:
		close_modal()
		on_accept.call())
	row.add_child(keep)
	row.add_child(accept)
	column.add_child(row)
	show_modal(column)
	keep.call_deferred("grab_focus")


func confirm(heading_text: String, body: String, accept_text: String, on_accept: Callable) -> void:
	_confirm(heading_text, body, accept_text, on_accept)


func toast(text: String, color: Color = Kit.TEAL_DARK) -> void:
	var panel := Kit.card(Kit.PAPER, 18, Vector2(20, 10))
	var text_label := Kit.label(text, 17, color, Kit.FONT_BOLD)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(text_label)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_layer.add_child(panel)
	while _toast_layer.get_child_count() > 3:
		var oldest := _toast_layer.get_child(0)
		_toast_layer.remove_child(oldest)
		oldest.queue_free()
	panel.modulate.a = 0.0
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	tween.tween_interval(2.4)
	tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(panel.queue_free)


func _show_tutorial(step: int, mark_done: bool = true) -> void:
	var pages := [
		["Meet your buddy!", "Your companion has two needs: Fullness and Joy. They slowly drop while you play, so check in often. Tap your buddy for a little cuddle."],
		["Study to earn coins", "Open the Study Desk to solve integration challenges — reverse differentiation, the basic rules, substitution, by parts, partial fractions and definite integrals. Hints and worked steps are always there if you get stuck."],
		["Care, play and grow", "Spend coins in the Shop on snacks and toys. Play Antiderivative Catch and Area Pour to cheer your buddy up. With enough growth XP — and full, happy needs — your buddy grows from Sprout to Explorer to Scholar!"],
	]
	var page: Array = pages[step]
	var column := Kit.vbox(14)
	column.custom_minimum_size = Vector2(520, 0)
	var chip := Kit.chip("HOW TO PLAY · %d / %d" % [step + 1, pages.size()])
	chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(chip)
	column.add_child(Kit.heading(str(page[0]), 30))
	column.add_child(Kit.wrap(Kit.label(str(page[1]), 18, Kit.MUTED), 500))
	var row := Kit.hbox(12)
	if step > 0:
		var back := Kit.button("Back", "secondary", 120)
		back.pressed.connect(func() -> void:
			close_modal()
			_show_tutorial(step - 1, mark_done))
		row.add_child(back)
	row.add_child(Kit.spacer())
	var last := step == pages.size() - 1
	var next := Kit.button("Let's go!" if last else "Next", "primary", 160)
	next.name = "TutorialNext"
	next.pressed.connect(func() -> void:
		play("ui.confirm")
		close_modal()
		if last:
			if mark_done and pet != null:
				pet.tutorial_done = true
				save_now()
		else:
			_show_tutorial(step + 1, mark_done))
	row.add_child(next)
	column.add_child(row)
	show_modal(column)
	next.call_deferred("grab_focus")


func _celebrate_growth(stage_index: int) -> void:
	if pet == null:
		return
	play("game.victory")
	var info: Dictionary = PetState.STAGES[stage_index]
	var column := Kit.vbox(12)
	column.custom_minimum_size = Vector2(480, 0)
	var chip := Kit.chip("STAGE %d / %d" % [stage_index + 1, PetState.STAGES.size()], Kit.GOLD_PALE, Color("9a6a00"))
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(chip)
	var heading_label := Kit.heading("%s grew into a%s %s!" % [pet.pet_name, "n" if str(info.name).begins_with("E") else "", info.name], 30)
	heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(Kit.wrap(heading_label, 460))
	var view := PetView.new()
	view.interactive = false
	view.base_height = 240.0
	view.custom_minimum_size = Vector2(0, 280)
	view.clip_contents = true
	view.art_key = str(info.art)
	column.add_child(view)
	view.call_deferred("react", "grow")
	var message := "All your practice is paying off. Keep studying to reach the final stage!" if stage_index < PetState.STAGES.size() - 1 else "Your buddy is a fully grown Scholar — just like you're becoming an integration expert. Keep caring for it and chasing best scores!"
	var body := Kit.wrap(Kit.label(message, 17, Kit.MUTED), 460)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(body)
	var ok := Kit.button("Wonderful!", "primary", 240)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(func() -> void:
		close_modal()
		if _screen != null and _screen.has_method("refresh"):
			_screen.call("refresh"))
	column.add_child(ok)
	show_modal(column)
	ok.call_deferred("grab_focus")


func back_to_title() -> void:
	save_now()
	close_all_modals()
	_show_title()
