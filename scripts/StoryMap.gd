## StoryMap.gd
## Tela do MODO HISTÓRIA: os 5 cenários do continente de Geometria, as 20 fases,
## as estrelas conquistadas e o prólogo. Toda a interface é construída por código.

extends Node2D

const UIKit = preload("res://scripts/UIKit.gd")

const GAME_SCENE := "res://scenes/Main.tscn"
const MENU_SCENE := "res://scenes/Menu.tscn"

var _ui              : CanvasLayer
var _content         : Control
var _lbl_detail      : Label
var _overlay_prologue: Control
var _first_focus     : Control

func _ready() -> void:
	DisplayServer.window_set_title("Reinos da Área — Modo História")
	Story.leave()
	_build_backdrop()
	_build_ui()
	if AudioManager: AudioManager.play_music("bg_music")
	UIKit.fade_in(self)
	if not Story.prologue_seen:
		_open_prologue()
	elif _first_focus:
		_first_focus.grab_focus()

# ─────────────────────────────────────────────
#  FUNDO
# ─────────────────────────────────────────────
func _build_backdrop() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/icons/fundo.jpg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.55, 0.50, 0.40)
	layer.add_child(bg)
	var veil := ColorRect.new()
	veil.color = Color(0.03, 0.02, 0.01, 0.80)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(veil)

# ─────────────────────────────────────────────
#  INTERFACE
# ─────────────────────────────────────────────
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)

	_content = Control.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_content)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 36)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 18)
	margin.add_child(col)

	# Cabeçalho
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 22)
	col.add_child(head)
	var crest := TextureRect.new()
	crest.texture = load("res://assets/icons/brasao.png")
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest.custom_minimum_size = Vector2(96, 110)
	head.add_child(crest)
	var titles := VBoxContainer.new()
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_child(titles)
	var t := UIKit.label("MODO HISTÓRIA", 62, UIKit.C_TEXT_GOLD2, UIKit.FONT_TITLE)
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	t.add_theme_constant_override("shadow_offset_x", 3)
	t.add_theme_constant_override("shadow_offset_y", 4)
	titles.add_child(t)
	var sub_txt := "O continente de Geometria   ·   Estrelas: %d de %d" % [Story.total_stars(), Story.TOTAL_PHASES * 3]
	if Story.finished:
		sub_txt += "   ·   Campanha concluída!"
	titles.add_child(UIKit.label(sub_txt, 22, UIKit.C_TEXT_WHITE, UIKit.FONT_SERIF))

	# Cartões dos cenários
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 18)
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(cards)
	for i in Story.SCENARIOS.size():
		cards.add_child(_build_scenario_card(i))

	# Detalhe da fase em foco
	_lbl_detail = UIKit.label("", 21, UIKit.C_TEXT_GOLD, UIKit.FONT_SERIF)
	_lbl_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_detail.custom_minimum_size = Vector2(0, 30)
	col.add_child(_lbl_detail)

	# Rodapé
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	col.add_child(row)
	var b_pro := UIKit.menu_button("PRÓLOGO", Vector2(280, 60), UIKit.C_BORDER_GOLD, 22)
	b_pro.pressed.connect(_open_prologue)
	row.add_child(b_pro)
	var b_back := UIKit.menu_button("VOLTAR AO MENU", Vector2(320, 60), UIKit.C_TEXT_GOLD, 22)
	b_back.pressed.connect(func(): UIKit.change_scene(self, MENU_SCENE))
	row.add_child(b_back)

	_overlay_prologue = _build_prologue_overlay()

func _build_scenario_card(i: int) -> Control:
	var sc: Dictionary = Story.SCENARIOS[i]
	var first: int = sc["first"]
	var unlocked_any := Story.is_unlocked(first)

	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(336, 0)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var border := UIKit.C_BORDER_GOLD if unlocked_any else UIKit.C_SEPARATOR
	p.add_theme_stylebox_override("panel", UIKit.stylebox(Color(0.07, 0.05, 0.03, 0.92), border, 2, 10, 18))

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)

	var num := UIKit.label("CENÁRIO %s" % sc["num"], 20, UIKit.C_TEXT_GOLD, UIKit.FONT_TITLE)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(num)
	var name_lbl := UIKit.label(String(sc["name"]), 25, UIKit.C_TEXT_WHITE if unlocked_any else UIKit.C_TEXT_MUTED, UIKit.FONT_TITLE)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.custom_minimum_size = Vector2(296, 66)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vb.add_child(name_lbl)

	# Faixa com a cor do cenário
	var stripe := ColorRect.new()
	stripe.custom_minimum_size = Vector2(0, 6)
	var tint: Color = sc["tint"]
	stripe.color = Color(tint.r * 0.75, tint.g * 0.75, tint.b * 0.75)
	vb.add_child(stripe)

	var info := UIKit.label(_scenario_info(sc), 16, UIKit.C_TEXT_MUTED)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(296, 44)
	vb.add_child(info)
	vb.add_child(UIKit.hline())

	for n in range(first, int(sc["last"]) + 1):
		vb.add_child(_build_phase_entry(n))
	return p

func _scenario_info(sc: Dictionary) -> String:
	var shapes := {"rect": "retângulos", "notched": "quinas irregulares", "composite": "formas em L",
		"diagonal": "bordas em degrau", "organic": "formas sem padrão"}
	var s := "Fases %d–%d  ·  %s" % [sc["first"], sc["last"], shapes.get(sc["shape"], "")]
	if float(sc["round_time"]) > 0.0:
		s += "  ·  %d s" % int(sc["round_time"])
	return s

func _build_phase_entry(n: int) -> Control:
	var ph: Dictionary = Story.get_phase(n)
	var unlocked := Story.is_unlocked(n)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var label_txt := "FASE %d" % n
	if not unlocked:
		label_txt += "  ·  BLOQUEADA"
	var b := UIKit.menu_button(label_txt, Vector2(296, 54), UIKit.C_TEXT_GOLD if unlocked else UIKit.C_SEPARATOR, 20)
	b.disabled = not unlocked
	b.tooltip_text = ph["title"]
	b.pressed.connect(func():
		Story.start_phase(n)
		UIKit.change_scene(self, GAME_SCENE))
	var show_detail := func(): _show_detail(n)
	b.mouse_entered.connect(show_detail)
	b.focus_entered.connect(show_detail)
	box.add_child(b)

	var c := CenterContainer.new()
	c.add_child(UIKit.stars(Story.stars[n], 20))
	box.add_child(c)

	# Foco inicial: a fase liberada mais avançada
	if unlocked:
		_first_focus = b
	return box

func _show_detail(n: int) -> void:
	var ph: Dictionary = Story.get_phase(n)
	var names: Array[String] = []
	for k in ph["terrains"]:
		names.append(String(Story.TERRAINS[k]["name"]))
	var txt := "Fase %d  ·  %s   —   Terreno: %s" % [n, ph["title"], " / ".join(names)]
	if bool(ph.get("sudden_death", false)):
		txt += "   ·   Morte Súbita"
	if not Story.is_unlocked(n):
		txt += "   ·   Conclua a fase anterior para liberar"
	_lbl_detail.text = txt

# ─────────────────────────────────────────────
#  PRÓLOGO
# ─────────────────────────────────────────────
func _build_prologue_overlay() -> Control:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.visible = false
	_ui.add_child(holder)
	holder.add_child(UIKit.dimmer(0.75))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(center)
	var p := UIKit.panel(Vector2(980, 0), 44)
	center.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 20)
	p.add_child(vb)
	var t := UIKit.label("PRÓLOGO", 44, UIKit.C_TEXT_GOLD, UIKit.FONT_TITLE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var who := UIKit.label("contado pela Cartógrafa", 20, UIKit.C_TEXT_MUTED, UIKit.FONT_SERIF)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(who)
	vb.add_child(UIKit.hline())
	var body := UIKit.label(Story.PROLOGUE, 22, UIKit.C_TEXT_WHITE, UIKit.FONT_SERIF)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(880, 0)
	vb.add_child(body)
	vb.add_child(UIKit.hline())
	var b := UIKit.menu_button("COMEÇAR A JORNADA", Vector2(420, 64), UIKit.C_TEXT_GOLD, 24)
	b.name = "FirstFocus"
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_close_prologue)
	vb.add_child(b)
	return holder

func _open_prologue() -> void:
	_overlay_prologue.visible = true
	_overlay_prologue.find_child("FirstFocus", true, false).grab_focus()

func _close_prologue() -> void:
	_overlay_prologue.visible = false
	if not Story.prologue_seen:
		Story.prologue_seen = true
		Story.save_progress()
	if _first_focus:
		_first_focus.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _overlay_prologue.visible:
			_close_prologue()
		else:
			UIKit.change_scene(self, MENU_SCENE)
		get_viewport().set_input_as_handled()
