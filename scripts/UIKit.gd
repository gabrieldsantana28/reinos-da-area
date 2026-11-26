## UIKit.gd
## Funções estáticas de interface compartilhadas pelo Menu, Tutorial e Jogo.
## Mantém a mesma direção de arte medieval/cartográfica do HUD original.

extends RefCounted

# ─────────────────────────────────────────────
#  PALETA (igual à do Main.gd)
# ─────────────────────────────────────────────
const C_BG_DARK      := Color8( 18,  14,  10, 255)
const C_BG_PANEL     := Color8( 28,  22,  14, 245)
const C_BORDER_GOLD  := Color8(148, 112,  38, 255)
const C_TEXT_GOLD    := Color8(212, 180,  90, 255)
const C_TEXT_GOLD2   := Color8(240, 210, 120, 255)
const C_TEXT_WHITE   := Color8(238, 232, 218, 255)
const C_TEXT_MUTED   := Color8(160, 148, 120, 255)
const C_BLUE_MAIN    := Color8( 60, 110, 190, 255)
const C_BLUE_LIGHT   := Color8(120, 175, 255, 255)
const C_BLUE_DIM     := Color8( 35,  65, 120, 200)
const C_RED_MAIN     := Color8(160,  30,  30, 255)
const C_RED_BORDER   := Color8(200,  60,  60, 255)
const C_RED_DIM      := Color8( 90,  18,  18, 200)
const C_GREEN_MAIN   := Color8( 30, 100,  70, 255)
const C_GREEN_LIGHT  := Color8( 80, 180, 120, 255)
const C_GREEN_DIM    := Color8( 18,  58,  40, 200)
const C_BAR_GREEN    := Color8( 68, 168,  68, 255)
const C_BAR_ORANGE   := Color8(220, 140,  40, 255)
const C_SEPARATOR    := Color8(100,  80,  30, 140)
const C_BTN_DARK     := Color8( 40,  30,  16, 235)

const FONT_TITLE := "res://assets/fonts/Cinzel.ttf"
const FONT_SERIF := "res://assets/fonts/Baskerville.ttf"
const FONT_SANS  := "res://assets/fonts/SourceSans.ttf"

static var _font_cache := {}

static func font(path: String) -> Font:
	if _font_cache.has(path):
		return _font_cache[path]
	var f: Font = null
	if ResourceLoader.exists(path):
		f = load(path)
	_font_cache[path] = f
	return f

## Versão "negrito" sintética de uma fonte (as fontes do projeto só têm o peso regular).
static func bold_font(path: String) -> Font:
	var key := path + "#bold"
	if _font_cache.has(key):
		return _font_cache[key]
	var base := font(path)
	if base == null:
		return null
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_embolden = 0.7
	_font_cache[key] = fv
	return fv

# ─────────────────────────────────────────────
#  COMPONENTES
# ─────────────────────────────────────────────
static func label(txt: String, size: int, color: Color, font_path: String = FONT_SANS) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	var f := font(font_path)
	if f: lbl.add_theme_font_override("font", f)
	return lbl

## Texto com BBCode ([b], [color=...]) — usado nos textos longos do tutorial.
static func rich(bbcode: String, size: int, color: Color = C_TEXT_WHITE) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", color)
	var f := font(FONT_SANS)
	if f: r.add_theme_font_override("normal_font", f)
	var fb := bold_font(FONT_SANS)
	if fb: r.add_theme_font_override("bold_font", fb)
	r.text = bbcode
	return r

static func stylebox(bg: Color, border: Color, border_w: int = 2, radius: int = 6, padding: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	if padding > 0:
		sb.set_content_margin_all(padding)
	return sb

static func panel(min_size: Vector2 = Vector2.ZERO, padding: int = 28) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = min_size
	p.add_theme_stylebox_override("panel", stylebox(C_BG_DARK, C_BORDER_GOLD, 3, 10, padding))
	return p

static func hline(width: float = 0.0) -> ColorRect:
	var c := ColorRect.new()
	c.custom_minimum_size = Vector2(width, 2)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL if width <= 0.0 else Control.SIZE_SHRINK_CENTER
	c.color = C_SEPARATOR
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

## Botão de menu: fundo escuro, borda dourada, texto Cinzel. Aceita foco por teclado.
static func menu_button(txt: String, min_size: Vector2 = Vector2(380, 64), accent: Color = C_BORDER_GOLD, font_size: int = 24) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = min_size
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.focus_mode = Control.FOCUS_ALL
	var f := font(FONT_TITLE)
	if f: btn.add_theme_font_override("font", f)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", C_TEXT_GOLD)
	btn.add_theme_color_override("font_hover_color", C_TEXT_GOLD2)
	btn.add_theme_color_override("font_focus_color", C_TEXT_GOLD2)
	btn.add_theme_color_override("font_pressed_color", C_TEXT_WHITE)
	btn.add_theme_color_override("font_disabled_color", C_TEXT_MUTED)

	var sb_normal := stylebox(C_BTN_DARK, accent, 2, 6)
	var sb_hover  := stylebox(C_BTN_DARK.lightened(0.12), C_TEXT_GOLD2, 3, 6)
	var sb_press  := stylebox(C_BTN_DARK.darkened(0.2), C_TEXT_GOLD2, 3, 6)
	var sb_dis    := stylebox(C_BTN_DARK.darkened(0.3), C_SEPARATOR, 2, 6)
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_press)
	btn.add_theme_stylebox_override("disabled", sb_dis)
	btn.add_theme_stylebox_override("focus", sb_hover)

	add_sounds(btn)
	return btn

static func add_sounds(btn: BaseButton) -> void:
	btn.mouse_entered.connect(func():
		if AudioManager and not btn.disabled: AudioManager.play_sfx("ui_hover", 0.05))
	btn.focus_entered.connect(func():
		if AudioManager and not btn.disabled and not btn.is_hovered(): AudioManager.play_sfx("ui_hover", 0.05))
	btn.pressed.connect(func():
		if AudioManager: AudioManager.play_sfx("ui_click"))

## Slider de volume estilizado (0 a 100).
static func slider(value_0_1: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0
	s.max_value = 100
	s.step = 5
	s.value = roundf(value_0_1 * 100.0)
	s.custom_minimum_size = Vector2(320, 32)
	s.focus_mode = Control.FOCUS_ALL
	s.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var track := stylebox(Color8(42, 34, 20), C_BORDER_GOLD, 1, 4)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	var fill := stylebox(C_TEXT_GOLD.darkened(0.25), C_TEXT_GOLD, 1, 4)
	fill.content_margin_top = 4
	fill.content_margin_bottom = 4
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	return s

## Retângulo escuro em tela cheia para escurecer o fundo atrás de janelas modais.
static func dimmer(alpha: float = 0.72) -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(0, 0, 0, alpha)
	d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	return d

## Fileira de estrelas desenhada por código (as fontes do projeto não têm o símbolo ★).
static func stars(filled: int, size: float = 28.0, total: int = 3) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(total * size * 1.15, size)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_meta("filled", filled)
	c.draw.connect(func():
		var f: int = int(c.get_meta("filled", 0))
		for i in total:
			var center := Vector2(size * 0.575 + i * size * 1.15, size * 0.5)
			var pts := PackedVector2Array()
			for k in 10:
				var ang := -PI / 2.0 + k * PI / 5.0
				var r := size * 0.5 if k % 2 == 0 else size * 0.21
				pts.append(center + Vector2(cos(ang), sin(ang)) * r)
			c.draw_colored_polygon(pts, C_TEXT_GOLD2 if i < f else Color(1, 1, 1, 0.10))
			pts.append(pts[0])
			c.draw_polyline(pts, C_BORDER_GOLD if i < f else C_SEPARATOR, 1.5, true))
	return c

static func set_stars(c: Control, filled: int) -> void:
	c.set_meta("filled", filled)
	c.queue_redraw()

# ─────────────────────────────────────────────
#  TRANSIÇÕES DE CENA
# ─────────────────────────────────────────────
## Cria uma cortina preta que some em `duration` segundos (fade-in da cena).
static func fade_in(owner_node: Node, duration: float = 0.45) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	owner_node.add_child(layer)
	var curtain := ColorRect.new()
	curtain.color = Color.BLACK
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(curtain)
	var tw := owner_node.create_tween()
	tw.tween_property(curtain, "color:a", 0.0, duration)
	tw.tween_callback(layer.queue_free)

## Escurece a tela e troca de cena.
static func change_scene(owner_node: Node, path: String, duration: float = 0.35) -> void:
	var tree := owner_node.get_tree()
	tree.paused = false
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	owner_node.add_child(layer)
	var curtain := ColorRect.new()
	curtain.color = Color(0, 0, 0, 0)
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(curtain)
	var tw := layer.create_tween()
	tw.tween_property(curtain, "color:a", 1.0, duration)
	tw.tween_callback(func(): tree.change_scene_to_file(path))
