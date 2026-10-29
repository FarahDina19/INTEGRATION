class_name Kit
extends RefCounted
## Integral Buddy UI kit: warm cream paper, integral-teal accents, coral highlights.

const CREAM := Color("fff7eb")
const PAPER := Color("fffdf8")
const INK := Color("1f3b3a")
const MUTED := Color("5f7472")
const SOFT := Color("8a9a97")
const TEAL := Color("2bb3a3")
const TEAL_DARK := Color("17807a")
const TEAL_PALE := Color("d9f2ee")
const CORAL := Color("ff8a73")
const CORAL_DARK := Color("e0644f")
const CORAL_PALE := Color("ffe3dc")
const GOLD := Color("f5b83d")
const GOLD_PALE := Color("fff1cf")
const LINE := Color("e6dac6")
const CHALK := Color("f4f1e6")

const FONT_REGULAR := "res://assets/fonts/body_regular.tres"
const FONT_MEDIUM := "res://assets/fonts/body_medium.tres"
const FONT_BOLD := "res://assets/fonts/body_bold.tres"
const FONT_HEADING := "res://assets/fonts/heading.tres"
const FONT_TITLE := "res://assets/fonts/title.tres"

static var _font_cache: Dictionary = {}
static var _texture_cache: Dictionary = {}


static func font(path: String) -> Font:
	if not _font_cache.has(path):
		_font_cache[path] = load(path) as Font
	return _font_cache[path]


static func texture(path: String) -> Texture2D:
	if not _texture_cache.has(path):
		_texture_cache[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _texture_cache[path]


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = font(FONT_REGULAR)
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", SOFT)
	theme.set_color("caret_color", "LineEdit", TEAL_DARK)
	theme.set_color("selection_color", "LineEdit", Color(TEAL, 0.3))
	var edit := box(Color.WHITE, LINE, 14, 2)
	edit.content_margin_left = 18
	edit.content_margin_right = 18
	edit.content_margin_top = 10
	edit.content_margin_bottom = 10
	theme.set_stylebox("normal", "LineEdit", edit)
	var edit_focus := edit.duplicate() as StyleBoxFlat
	edit_focus.border_color = TEAL
	edit_focus.set_border_width_all(3)
	theme.set_stylebox("focus", "LineEdit", edit_focus)
	var edit_done := edit.duplicate() as StyleBoxFlat
	edit_done.bg_color = TEAL_PALE
	edit_done.border_color = TEAL
	theme.set_stylebox("read_only", "LineEdit", edit_done)
	theme.set_color("font_uneditable_color", "LineEdit", TEAL_DARK)
	theme.set_color("default_color", "RichTextLabel", INK)
	theme.set_font("normal_font", "RichTextLabel", font(FONT_REGULAR))
	theme.set_font("bold_font", "RichTextLabel", font(FONT_BOLD))
	theme.set_font_size("normal_font_size", "RichTextLabel", 17)
	theme.set_font_size("bold_font_size", "RichTextLabel", 17)
	var scroll_bg := box(Color(INK, 0.06), Color.TRANSPARENT, 6, 0)
	theme.set_stylebox("scroll", "VScrollBar", scroll_bg)
	theme.set_stylebox("grabber", "VScrollBar", box(Color(TEAL, 0.55), Color.TRANSPARENT, 6, 0))
	theme.set_stylebox("grabber_highlight", "VScrollBar", box(TEAL, Color.TRANSPARENT, 6, 0))
	theme.set_stylebox("grabber_pressed", "VScrollBar", box(TEAL_DARK, Color.TRANSPARENT, 6, 0))
	return theme


static func box(bg: Color, border: Color = Color.TRANSPARENT, radius: int = 18, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func card_style(bg: Color = PAPER, radius: int = 24, padding: Vector2 = Vector2(24, 20)) -> StyleBoxFlat:
	var style := box(bg, Color(INK, 0.1), radius, 2)
	style.shadow_color = Color(0.12, 0.2, 0.2, 0.22)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = padding.x
	style.content_margin_right = padding.x
	style.content_margin_top = padding.y
	style.content_margin_bottom = padding.y
	return style


static func card(bg: Color = PAPER, radius: int = 24, padding: Vector2 = Vector2(24, 20)) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", card_style(bg, radius, padding))
	return panel


static func label(text: String, size: int = 18, color: Color = INK, font_path: String = FONT_REGULAR) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_override("font", font(font_path))
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result


static func heading(text: String, size: int = 28, color: Color = INK) -> Label:
	return label(text, size, color, FONT_HEADING)


static func title(text: String, size: int = 64, color: Color = INK) -> Label:
	return label(text, size, color, FONT_TITLE)


static func wrap(target: Label, width: float = 0.0) -> Label:
	target.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if width > 0.0:
		target.custom_minimum_size.x = width
	return target


static func icon(path: String, size: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(size, size)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## kind: "primary" (teal), "accent" (coral), "secondary" (paper), "ghost" (text-only), "danger"
static func button(text: String, kind: String = "secondary", min_width: float = 0.0, height: float = 52.0, font_size: int = 19) -> Button:
	var result := Button.new()
	result.text = text
	result.focus_mode = Control.FOCUS_ALL
	result.custom_minimum_size = Vector2(min_width, height)
	result.add_theme_font_override("font", font(FONT_BOLD))
	result.add_theme_font_size_override("font_size", font_size)
	var base: Color
	var edge: Color
	var text_color := Color.WHITE
	match kind:
		"primary":
			base = TEAL
			edge = TEAL_DARK
		"accent":
			base = CORAL
			edge = CORAL_DARK
		"danger":
			base = CORAL_DARK
			edge = Color("b84634")
		"ghost":
			base = Color(1, 1, 1, 0)
			edge = Color(1, 1, 1, 0)
			text_color = TEAL_DARK
		_:
			base = PAPER
			edge = LINE
			text_color = INK
	for state: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		result.add_theme_color_override(state, text_color)
	result.add_theme_color_override("font_disabled_color", Color(text_color, 0.45))
	var normal := _button_box(base, edge, kind)
	var hover := _button_box(base.lightened(0.08) if kind != "ghost" else Color(TEAL, 0.1), edge, kind)
	var pressed := _button_box(base.darkened(0.08) if kind != "ghost" else Color(TEAL, 0.18), edge, kind)
	pressed.content_margin_top += 3
	pressed.shadow_size = 0
	pressed.border_width_bottom = 2
	var disabled := _button_box(Color(base, 0.55) if kind != "ghost" else base, Color(edge, 0.4), kind)
	result.add_theme_stylebox_override("normal", normal)
	result.add_theme_stylebox_override("hover", hover)
	result.add_theme_stylebox_override("pressed", pressed)
	result.add_theme_stylebox_override("disabled", disabled)
	var focus := box(Color.TRANSPARENT, GOLD, 18, 3)
	focus.set_expand_margin_all(4)
	result.add_theme_stylebox_override("focus", focus)
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_press_juice(result)
	return result


static func _button_box(bg: Color, edge: Color, kind: String) -> StyleBoxFlat:
	var style := box(bg, edge, 16, 2)
	if kind != "ghost":
		style.border_width_bottom = 5
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


static func add_press_juice(control: Control) -> void:
	control.resized.connect(func() -> void: control.pivot_offset = control.size * 0.5)
	control.mouse_entered.connect(func() -> void:
		if control is BaseButton and (control as BaseButton).disabled:
			return
		_bounce(control, 1.03, 0.12))
	control.mouse_exited.connect(func() -> void: _bounce(control, 1.0, 0.12))
	if control is BaseButton:
		(control as BaseButton).button_down.connect(func() -> void: _bounce(control, 0.96, 0.06))
		(control as BaseButton).button_up.connect(func() -> void: _bounce(control, 1.0, 0.14))


static func _bounce(control: Control, target: float, duration: float) -> void:
	if not control.is_inside_tree():
		return
	var tween := control.create_tween()
	tween.tween_property(control, "scale", Vector2.ONE * target, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func meter(fill: Color, height: float = 14.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = 100
	bar.custom_minimum_size = Vector2(0, height)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg := box(Color(INK, 0.1), Color.TRANSPARENT, int(height / 2.0), 0)
	bg.content_margin_top = 0
	bg.content_margin_bottom = 0
	var fg := box(fill, Color.TRANSPARENT, int(height / 2.0), 0)
	fg.content_margin_top = 0
	fg.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


static func chip(text: String, bg: Color = TEAL_PALE, fg: Color = TEAL_DARK, size: int = 14) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := box(bg, Color.TRANSPARENT, 12, 0)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	var text_label := label(text, size, fg, FONT_BOLD)
	text_label.name = "Text"
	panel.add_child(text_label)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


static func hbox(separation: int = 12) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", separation)
	return row


static func vbox(separation: int = 12) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", separation)
	return column


static func spacer(horizontal: bool = true) -> Control:
	var gap := Control.new()
	if horizontal:
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap


static func full_rect(control: Control) -> Control:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return control


## Typeset ∫ with optional limits: {"body": "6x² dx", "lower": "0", "upper": "2"}
static func integral_view(spec: Dictionary, size: int = 40, color: Color = INK) -> HBoxContainer:
	var row := hbox(maxi(4, size / 6))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sign_column := VBoxContainer.new()
	sign_column.add_theme_constant_override("separation", -int(size * 0.35))
	sign_column.alignment = BoxContainer.ALIGNMENT_CENTER
	var has_limits := not str(spec.get("lower", "")).is_empty()
	var upper := label(str(spec.get("upper", "")), int(size * 0.5), color, FONT_MEDIUM)
	upper.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var sign := label("∫", int(size * 1.5), color, FONT_REGULAR)
	sign.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var lower := label(str(spec.get("lower", "")), int(size * 0.5), color, FONT_MEDIUM)
	lower.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if has_limits:
		sign_column.add_child(upper)
	sign_column.add_child(sign)
	if has_limits:
		sign_column.add_child(lower)
	row.add_child(sign_column)
	var body := label(str(spec.get("body", "")), size, color, FONT_MEDIUM)
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(body)
	return row
