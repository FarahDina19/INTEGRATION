extends SceneTree
## Verifies the exported Web PCK: identity, game art, fonts and glyphs, dev exclusions, boot and a gameplay step.

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	_check(ProjectSettings.get_setting("application/config/name") == "Integral Buddy", "exported identity")
	var art: Array[String] = ["icons/coin.png", "icons/heart.png", "icons/food.png", "icons/star.png"]
	for stage: String in ["stage1", "stage2", "stage3"]:
		for mood: String in ["happy", "sad"]:
			art.append("pet/%s_%s.png" % [stage, mood])
	for item: String in ["apple", "muffin", "pie", "ball", "yarn", "kite"]:
		art.append("items/%s.png" % item)
	for scene: String in ["home.jpg", "garden.jpg", "chalkboard.jpg"]:
		art.append("scenes/" + scene)
	for path: String in art:
		_check(ResourceLoader.exists("res://assets/art/" + path), "pack resource: " + path)
	_check(ResourceLoader.exists("res://assets/share/favicon.png"), "pack favicon")
	_check(not ResourceLoader.exists("res://test/test_suite.tscn"), "test scene excluded")
	_check(not ResourceLoader.exists("res://tools/capture_native.gd"), "native capture tool excluded")
	_check(not root.has_node("GlobalLeaderboard"), "no dormant network autoload")
	_check(not DirAccess.dir_exists_absolute("res://assets/template/audio"), "no default audio assets")
	var font := load("res://assets/fonts/body_medium.tres") as Font
	_check(font != null, "exported font")
	var path := "res://localization/en.json"
	_check(FileAccess.file_exists(path), "exported English catalog")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(parsed is Dictionary, "English catalog parses")
	var sample := "∫π²³ˣ−·′★☆›‹×"
	if parsed is Dictionary:
		for value: Variant in (parsed as Dictionary).values():
			sample += str(value)
	for index: int in sample.length():
		var codepoint := sample.unicode_at(index)
		if codepoint >= 32:
			_check(font != null and font.has_char(codepoint), "exported glyph: %d" % codepoint)
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "exported main scene")
	if packed != null:
		var main := packed.instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		_check(str(main.get("state")) == "title", "pack boots to title")
		_check(not main.has_method("_maybe_capture"), "capture routing removed from runtime")
		_check(not main.has_method("_open_tuning"), "release tuning entry point excluded")
		_check(not ResourceLoader.exists("res://scripts/ui/tuning_panel.gd"), "release tuning panel excluded")
		var adopt := main.find_child("AdoptButton", true, false) as BaseButton
		var resume := main.find_child("ContinueButton", true, false) as BaseButton
		if adopt != null:
			adopt.emit_signal("pressed")
			await process_frame
			var confirm := main.find_child("AdoptConfirm", true, false) as BaseButton
			_check(confirm != null, "pack adopt dialog")
			if confirm != null:
				confirm.emit_signal("pressed")
		elif resume != null:
			resume.emit_signal("pressed")
		for i: int in 4:
			await process_frame
		_check(str(main.get("state")) == "home" and main.get("pet") != null, "pack starts pet gameplay")
		var audio := root.get_node("AudioDirector")
		audio.call("play_cue", "ui.confirm")
		audio.call("release_streams")
		main.queue_free()
		await process_frame
	if _failures.is_empty():
		print("[exported-pack] PASS: identity, art, fonts, exclusions, boot, pet gameplay")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[exported-pack] " + failure)
		quit(1)


func _check(condition: bool, context: String) -> void:
	if not condition and context not in _failures:
		_failures.append(context)
