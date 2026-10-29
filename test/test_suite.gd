extends Node
## Integral Buddy automated checks. Prints the verification marker expected by game-verification.json.

var _failures := PackedStringArray()
var _checks := 0
var _saved_user_files: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	for path: String in [SaveStore.SAVE_PATH]:
		_saved_user_files[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	SaveStore.set("_data", SaveStore.call("_default_data"))
	for item: String in ["I18n", "TuningStore", "SaveStore", "AudioDirector"]:
		_check(get_tree().root.get_node_or_null(item) != null, "%s autoload must exist" % item)
	_test_parser()
	_test_problem_bank()
	_test_checker_feedback()
	_test_minigame_content()
	_test_pet_rules()
	_test_save_roundtrip()
	_test_assets()
	_test_font_glyph_coverage()
	await _test_runtime_flow()
	AudioDirector.call("release_streams")
	await get_tree().process_frame
	_restore_user_files()
	if _failures.is_empty():
		print("[game-generic-tests] PASS: %d checks" % _checks)
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("[game-generic-tests] " + failure)
	print("[game-generic-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
	get_tree().quit(1)


func _restore_user_files() -> void:
	for path: String in _saved_user_files:
		var bytes: Variant = _saved_user_files[path]
		if bytes == null:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_buffer(bytes)
				file.close()


func _test_parser() -> void:
	var cases := [
		["2x^3 + 5x + C", 1.0, 7.0], ["ln|x+1|", 1.0, log(2.0)], ["-1/2cos(2x)", 0.0, -0.5],
		["xe^x", 1.0, exp(1.0)], ["sin 2x", 1.0, sin(2.0)], ["x²", 3.0, 9.0], ["3(2x+1)^2", 1.0, 27.0],
		["x ln x - x", 1.0, -1.0], ["e^(x^2)", 1.0, exp(1.0)], ["(1/2)x^2", 2.0, 2.0], ["4π", 0.0, 4.0 * PI],
		["x·eˣ − eˣ", 1.0, 0.0], ["x^3/3", 3.0, 9.0],
	]
	for c: Array in cases:
		var r := MathExpr.parse(str(c[0]))
		_check(bool(r.ok), "parser accepts %s" % c[0])
		if r.ok:
			_check(absf(MathExpr.evaluate(r.ast, float(c[1])) - float(c[2])) < 1e-6, "parser evaluates %s" % c[0])
	_check(not bool(MathExpr.parse("2x +").ok), "parser rejects incomplete input")
	_check(not bool(MathExpr.parse("x$").ok), "parser rejects unknown symbols")


func _test_problem_bank() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	_check(ProblemBank.topic_ids().size() == 6, "six Unit 3 topics exist")
	for topic: String in ProblemBank.topic_ids():
		var all_ok := true
		for i: int in 30:
			var p := ProblemBank.generate(topic, rng)
			var answer: String = (str(p.answer) + " + C") if p.kind == "indefinite" else str(p.value)
			if str(ProblemBank.check(p, answer).status) != "correct" or str(ProblemBank.check(p, str(p.answer_display)).status) != "correct":
				all_ok = false
				break
			if (p.get("hints", []) as Array).is_empty() or (p.get("steps", []) as Array).is_empty():
				all_ok = false
				break
		_check(all_ok, "%s problems verify against their own answers and have hints + steps" % topic)


func _test_checker_feedback() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var p := ProblemBank.generate("rules", rng)
	_check(str(ProblemBank.check(p, str(p.answer)).status) == "missing_c", "missing + C is detected kindly")
	_check(str(ProblemBank.check(p, "x").status) == "wrong", "a wrong antiderivative is rejected")
	_check(str(ProblemBank.check(p, "2x +").status) == "invalid", "unreadable answers get a format tip")
	var d := ProblemBank.generate("definite", rng)
	_check(str(ProblemBank.check(d, "x + C").status) == "wrong", "definite answers must be numbers")
	var full := ProblemBank.reward(p, 0, false, 0)
	var hinted := ProblemBank.reward(p, 2, false, 0)
	var shown := ProblemBank.reward(p, 0, true, 0)
	_check(int(full.coins) > int(hinted.coins) and int(hinted.coins) > 0, "hints reduce but never zero the coin reward")
	_check(int(shown.coins) == 0 and int(shown.xp) > 0, "showing the solution still grants practice XP")


func _test_minigame_content() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var ok := true
	for i: int in 40:
		var r := ProblemBank.catch_round(rng)
		if (r.wrong as Array).size() < 2 or (r.wrong as Array).has(r.correct):
			ok = false
	_check(ok, "catch rounds have distinct distractors")
	var pour_ok := true
	for i: int in 16:
		var r := ProblemBank.pour_round(rng, i)
		var parsed := MathExpr.parse(str(r.expr))
		if not parsed.ok or float(r.b) <= float(r.a):
			pour_ok = false
			continue
		var n := 400
		var h := (float(r.b) - float(r.a)) / n
		var total := MathExpr.evaluate(parsed.ast, float(r.a)) + MathExpr.evaluate(parsed.ast, float(r.b))
		for k: int in range(1, n):
			total += MathExpr.evaluate(parsed.ast, float(r.a) + k * h) * (4.0 if k % 2 == 1 else 2.0)
		if absf(total * h / 3.0 - float(r.value)) > 1e-3:
			pour_ok = false
	_check(pour_ok, "pour round targets equal the numeric area")


func _test_pet_rules() -> void:
	var pet := PetState.create("  Test Buddy With A Very Long Name ")
	_check(pet.pet_name.length() <= 14 and not pet.pet_name.begins_with(" "), "pet names are trimmed and capped")
	_check(PetState.sanitize_name("") == "Inty", "empty names fall back to Inty")
	var start_full := pet.fullness
	pet.tick(PetState.FULLNESS_DECAY_SECONDS * 3.0 + 0.1)
	_check(is_equal_approx(pet.fullness, start_full - 3.0), "fullness decays over time")
	pet.coins = 5
	_check(not pet.buy("muffin"), "cannot buy without enough coins")
	pet.coins = 100
	_check(pet.buy("muffin") and pet.coins == 86 and pet.item_count("muffin") == 1, "buying spends coins and stocks inventory")
	pet.fullness = 10.0
	pet.use_item("muffin")
	_check(is_equal_approx(pet.fullness, 45.0) and pet.item_count("muffin") == 0, "food restores fullness and is consumed")
	_check(pet.use_item("muffin").is_empty(), "cannot use an item you do not own")
	pet.fullness = 20.0
	pet.joy = 90.0
	pet.gain_xp(200)
	_check(pet.stage == 0 and pet.is_ready_but_needs_care(), "growth waits until needs are cared for")
	pet.add_fullness(50.0)
	_check(pet.stage == 1, "growth happens once needs are met")
	pet.joy = 90.0
	pet.fullness = 90.0
	pet.gain_xp(1000)
	_check(pet.stage == 2 and pet.is_final_stage(), "pet reaches the final Scholar stage")
	_check(pet.mood() == "delighted" and pet.looks_happy(), "mood reflects needs")
	pet.fullness = 5.0
	pet.joy = 5.0
	_check(pet.mood() == "sad" and not pet.looks_happy(), "low needs make the buddy sad")
	var away := PetState.create("Away")
	away.fullness = 80.0
	away.last_seen = int(Time.get_unix_time_from_system()) - 48 * 3600
	away.apply_offline(int(Time.get_unix_time_from_system()))
	_check(away.fullness >= 10.0 and away.fullness <= 41.0, "offline decay is capped and never below 10")


func _test_save_roundtrip() -> void:
	var pet := PetState.create("Saver")
	pet.coins = 77
	pet.inventory["kite"] = 2
	pet.solved["sub"] = 4
	pet.best_catch = 120
	SaveStore.set_pet_data(pet.to_dict())
	SaveStore.call("_load")
	var restored := PetState.from_dict(SaveStore.get_pet_data())
	_check(restored.pet_name == "Saver" and restored.coins == 77 and restored.item_count("kite") == 2, "pet persists through save/load")
	_check(int(restored.solved.get("sub", 0)) == 4 and restored.best_catch == 120, "study stats persist")
	var hostile := PetState.from_dict({"coins": -50, "fullness": 900, "stage": 99, "inventory": {"apple": -3}})
	_check(hostile.coins == 0 and hostile.fullness == 100.0 and hostile.stage == 2 and hostile.item_count("apple") == 0, "corrupt save values are clamped")
	SaveStore.clear_pet()
	_check(not SaveStore.has_pet(), "clearing the save removes the buddy")


func _test_assets() -> void:
	var paths: Array[String] = []
	for stage: String in ["stage1", "stage2", "stage3"]:
		for mood: String in ["happy", "sad"]:
			paths.append("res://assets/art/pet/%s_%s.png" % [stage, mood])
	for id: String in PetState.ITEM_ORDER:
		paths.append(str(PetState.ITEMS[id].icon))
	for icon: String in ["coin", "heart", "food", "star"]:
		paths.append("res://assets/art/icons/%s.png" % icon)
	for scene: String in ["home", "garden", "chalkboard"]:
		paths.append("res://assets/art/scenes/%s.jpg" % scene)
	for path: String in paths:
		_check(ResourceLoader.exists(path) and load(path) is Texture2D, "asset loads: %s" % path)


func _test_font_glyph_coverage() -> void:
	var body := Kit.font(Kit.FONT_MEDIUM)
	_check(body != null, "body font loads")
	if body == null:
		return
	for glyph: String in ["∫", "π", "²", "³", "ˣ", "−", "·", "′", "★", "☆", "›", "‹", "×"]:
		_check(body.has_char(glyph.unicode_at(0)), "font covers %s" % glyph)


func _wait(frames: int = 2) -> void:
	for i: int in frames:
		await get_tree().process_frame


func _find(root: Node, node_name: String) -> Node:
	return root.find_child(node_name, true, false)


func _press(root: Node, node_name: String) -> bool:
	var button := _find(root, node_name) as BaseButton
	_check(button != null, "button exists: " + node_name)
	if button == null:
		return false
	button.emit_signal("pressed")
	return true


func _test_runtime_flow() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	main.size = Vector2(1280, 720)
	await _wait(3)
	_check(main.state == "title", "game opens on the title screen")
	_press(main, "AdoptButton")
	await _wait(2)
	var name_input := _find(main, "NameInput") as LineEdit
	_check(name_input != null, "adopt dialog asks for a name")
	if name_input == null:
		return
	name_input.text = "Testy"
	_press(main, "AdoptConfirm")
	await _wait(4)
	_check(main.state == "home" and main.pet != null and main.pet.pet_name == "Testy", "adopting opens the home with the named buddy")
	_check(SaveStore.has_pet(), "adoption is saved immediately")
	for i: int in 3:
		if _find(main, "TutorialNext") != null:
			_press(main, "TutorialNext")
			await _wait(2)
	_check(main.pet.tutorial_done and not main.has_modal(), "tutorial completes and is remembered")
	main.pet.fullness = 40.0
	_press(main, "Slot_apple")
	await _wait(2)
	_check(main.pet.item_count("apple") == 0 and main.pet.fullness > 40.0, "tray feeds the buddy")
	main.pet.fullness = 60.0
	main.pet.coins = 50
	_press(main, "ShopButton")
	await _wait(2)
	_press(main, "Buy_ball")
	await _wait(1)
	_check(main.pet.coins == 42 and main.pet.item_count("ball") == 2, "shop purchases work")
	_press(main, "ShopClose")
	await _wait(2)
	_press(main, "StudyButton")
	await _wait(3)
	_check(main.state == "study", "study desk opens")
	var study: Node = main.get("_screen")
	var input := _find(main, "AnswerInput") as LineEdit
	var coins_before: int = main.pet.coins
	input.text = "x"
	_press(main, "CheckButton")
	await _wait(1)
	_check(main.pet.streak == 0 and main.pet.coins == coins_before, "wrong answers earn nothing and reset the streak")
	_press(main, "HintButton")
	await _wait(1)
	_check(int(study.get("_hints_used")) == 1, "hints reveal one at a time")
	var problem: Dictionary = study.get("_problem")
	input.text = str(problem.answer_display)
	_press(main, "CheckButton")
	await _wait(2)
	_check(main.pet.coins > coins_before and main.pet.total_solved() == 1, "a correct answer pays coins and records progress")
	_check((_find(main, "NextButton") as Button).visible, "next challenge is offered after solving")
	_press(main, "Topic_definite")
	await _wait(2)
	problem = study.get("_problem")
	_check(str(problem.kind) == "definite", "topic switching loads that topic")
	_press(main, "BackHome")
	await _wait(3)
	_check(main.state == "home", "back home from the study desk")
	_press(main, "CatchButton")
	await _wait(3)
	_check(main.state == "catch", "catch mini-game opens")
	_press(main, "StartButton")
	await _wait(3)
	var catch_game: Node = main.get("_screen")
	_check(str(catch_game.get("_state")) == "play" and not (catch_game.get("_bubbles") as Array).is_empty(), "catch spawns answer bubbles")
	var joy_before: float = main.pet.joy
	catch_game.set("_time_left", 0.01)
	await _wait(3)
	_check(str(catch_game.get("_state")) == "done" and main.pet.joy >= joy_before, "catch ends on time and rewards joy")
	_press(main, "ResultHome")
	await _wait(3)
	_press(main, "PourButton")
	await _wait(3)
	_check(main.state == "pour", "pour mini-game opens")
	_press(main, "StartButton")
	await _wait(2)
	var pour: Node = main.get("_screen")
	var round_data: Dictionary = pour.get("_round")
	pour.set("_t", float(round_data.b))
	pour.set("_area", pour.call("_area_to", float(round_data.b)))
	_press(main, "StopButton")
	await _wait(2)
	_check(int(pour.get("_score")) == 100, "pouring the exact area scores a perfect round")
	main.go_home()
	await _wait(3)
	_check(main.state == "home", "returns home cleanly")
	main.queue_free()
	await _wait(2)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
		print("  FAIL: ", message)
