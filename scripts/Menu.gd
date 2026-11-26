## Menu.gd
## Tela inicial do jogo: Jogar, Tutorial, Opções, Créditos e Sair.
## Toda a interface é construída por código, no mesmo estilo do Main.gd.

extends Node2D

# Scripts carregados explicitamente (nao dependem do cache de classes do editor)
const UIKit = preload("res://scripts/UIKit.gd")
const TerritoryGenerator = preload("res://scripts/TerritoryGenerator.gd")
const TerritoryRenderer = preload("res://scripts/TerritoryRenderer.gd")

const GAME_SCENE     := "res://scenes/Main.tscn"
const TUTORIAL_SCENE := "res://scenes/Tutorial.tscn"

const SCREEN_W := 1920
const SCREEN_H := 1080
const BG_CELL  := 60

## Edite aqui os nomes da equipe que aparecem em "Créditos".
const CREDITS_TEAM := [
	["Equipe do projeto", "Gabriel Luis de Santana e Bruno Farias Travessini"],
	["Nome da equipe", "Dominadores"],
]

var _bg_renderer : TerritoryRenderer
var _bg_gen      : TerritoryGenerator
var _bg_timer    : float = 0.0

var _ui            : CanvasLayer
var _main_column   : VBoxContainer
var _btn_play      : Button
var _btn_tutorial  : Button
var _btn_options   : Button
var _btn_credits   : Button
var _btn_quit      : Button
var _lbl_record    : Label

var _overlay_options  : Control
var _overlay_credits  : Control
var _overlay_firstrun : Control
var _overlay_mode     : Control   # escolha entre Modo História e Campanha Clássica

var _lbl_music_val : Label
var _lbl_sfx_val   : Label
var _slider_music  : HSlider
var _slider_sfx    : HSlider
var _chk_full      : CheckButton
var _diff_buttons  : Array[Button] = []
var _lbl_diff_desc : Label

func _ready() -> void:
	DisplayServer.window_set_title("Reinos da Área")
	Story.leave()
	_build_backdrop()
	_build_ui()
	_refresh_record()
	if AudioManager: AudioManager.play_music("bg_music")
	UIKit.fade_in(self)
	_btn_play.grab_focus()

func _process(delta: float) -> void:
	# A cada poucos segundos, o mapa do fundo gera novos territórios.
	_bg_timer += delta
	if _bg_timer >= 6.0:
		_bg_timer = 0.0
		_regenerate_backdrop()

# ─────────────────────────────────────────────
#  FUNDO ANIMADO (reaproveita o renderizador do jogo)
# ─────────────────────────────────────────────
func _build_backdrop() -> void:
	_bg_gen = TerritoryGenerator.new()
	_bg_gen.grid_cols = SCREEN_W / BG_CELL
	_bg_gen.grid_rows = SCREEN_H / BG_CELL
	_bg_gen.min_cells = 20
	_bg_gen.max_cells = 140

	_bg_renderer = TerritoryRenderer.new()
	_bg_renderer.cell_size = BG_CELL
	_bg_renderer.grid_cols = SCREEN_W / BG_CELL
	_bg_renderer.grid_rows = SCREEN_H / BG_CELL
	_bg_renderer.textura_fundo = load("res://assets/icons/fundo.jpg")
	add_child(_bg_renderer)
	_regenerate_backdrop()

	# Véu escuro com degradê para o texto ficar legível.
	var veil_layer := CanvasLayer.new()
	veil_layer.layer = 1
	add_child(veil_layer)
	var veil := TextureRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	var grad := Gradient.new()
	grad.set_color(0, Color(0.03, 0.02, 0.01, 0.92))
	grad.set_color(1, Color(0.03, 0.02, 0.01, 0.35))
	grad.add_point(0.45, Color(0.03, 0.02, 0.01, 0.80))
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill_from = Vector2(0, 0.5)
	gtex.fill_to = Vector2(1, 0.5)
	gtex.width = 256
	gtex.height = 8
	veil.texture = gtex
	veil_layer.add_child(veil)

func _regenerate_backdrop() -> void:
	# Os dois reinos ficam na metade direita (a esquerda é ocupada pelo título).
	var p := _bg_gen.generate(randi_range(40, 75), 17, 8, 1)
	var e := _bg_gen.generate(randi_range(40, 75), 24, 8, 1)
	_bg_renderer.set_territories(p, e)

# ─────────────────────────────────────────────
#  INTERFACE
# ─────────────────────────────────────────────
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 10
	add_child(_ui)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 160)
	margin.add_theme_constant_override("margin_top", 70)
	margin.add_theme_constant_override("margin_bottom", 60)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)

	_main_column = VBoxContainer.new()
	_main_column.alignment = BoxContainer.ALIGNMENT_CENTER
	_main_column.add_theme_constant_override("separation", 14)
	_main_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	margin.add_child(_main_column)

	var crest := TextureRect.new()
	crest.texture = load("res://assets/icons/brasao.png")
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest.custom_minimum_size = Vector2(0, 190)
	_main_column.add_child(crest)

	var title := UIKit.label("REINOS DA ÁREA", 88, UIKit.C_TEXT_GOLD2, UIKit.FONT_TITLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	_main_column.add_child(title)

	var subtitle := UIKit.label("Conquiste o mapa estimando áreas com o olhar", 24, UIKit.C_TEXT_WHITE, UIKit.FONT_SERIF)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_column.add_child(subtitle)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 24)
	_main_column.add_child(sp)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 14)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_main_column.add_child(buttons)

	_btn_play     = UIKit.menu_button("JOGAR", Vector2(400, 72), UIKit.C_TEXT_GOLD, 30)
	_btn_tutorial = UIKit.menu_button("TUTORIAL")
	_btn_options  = UIKit.menu_button("OPÇÕES")
	_btn_credits  = UIKit.menu_button("CRÉDITOS")
	_btn_quit     = UIKit.menu_button("SAIR")
	for b in [_btn_play, _btn_tutorial, _btn_options, _btn_credits, _btn_quit]:
		b.size_flags_horizontal = Control.SIZE_FILL
		buttons.add_child(b)

	_btn_play.pressed.connect(_on_play)
	_btn_tutorial.pressed.connect(func(): UIKit.change_scene(self, TUTORIAL_SCENE))
	_btn_options.pressed.connect(func(): _open_overlay(_overlay_options))
	_btn_credits.pressed.connect(func(): _open_overlay(_overlay_credits))
	_btn_quit.pressed.connect(_on_quit)

	var sp2 := Control.new()
	sp2.custom_minimum_size = Vector2(0, 16)
	_main_column.add_child(sp2)

	_lbl_record = UIKit.label("", 20, UIKit.C_TEXT_MUTED)
	_lbl_record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main_column.add_child(_lbl_record)

	# Rodapé: versão e dica de controles
	var footer := UIKit.label("v%s   ·   Setas / Enter para navegar   ·   F11 alterna tela cheia" % _version(), 16, UIKit.C_TEXT_MUTED)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	footer.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	footer.grow_vertical = Control.GROW_DIRECTION_BEGIN
	footer.offset_right = -30
	footer.offset_bottom = -20
	root.add_child(footer)

	_overlay_options  = _build_options_overlay()
	_overlay_credits  = _build_credits_overlay()
	_overlay_firstrun = _build_firstrun_overlay()
	_overlay_mode     = _build_mode_overlay()

func _version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.2.0"))

func _refresh_record() -> void:
	if Settings.best_score <= 0 and Settings.best_dominance <= 0.0:
		_lbl_record.text = "Dificuldade: %s   ·   Nenhum recorde ainda" % Settings.get_difficulty_name()
	else:
		_lbl_record.text = "Dificuldade: %s   ·   Recorde: %d pts   ·   Melhor domínio: %.0f%%" % [
			Settings.get_difficulty_name(), Settings.best_score, Settings.best_dominance]

# ─────────────────────────────────────────────
#  AÇÕES
# ─────────────────────────────────────────────
func _on_play() -> void:
	if not Settings.tutorial_seen:
		_open_overlay(_overlay_firstrun)
		return
	_open_overlay(_overlay_mode)

func _on_quit() -> void:
	get_tree().quit()

func _open_overlay(ov: Control) -> void:
	for o in [_overlay_options, _overlay_credits, _overlay_firstrun, _overlay_mode]:
		o.visible = (o == ov)
	_main_column.modulate.a = 0.25
	var first := ov.find_child("FirstFocus", true, false)
	if first is Control:
		(first as Control).grab_focus()

func _close_overlays() -> void:
	for o in [_overlay_options, _overlay_credits, _overlay_firstrun, _overlay_mode]:
		o.visible = false
	_main_column.modulate.a = 1.0
	_refresh_record()
	_btn_play.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var any_open: bool = _overlay_options.visible or _overlay_credits.visible or _overlay_firstrun.visible or _overlay_mode.visible
		if any_open:
			_close_overlays()
			get_viewport().set_input_as_handled()

# ─────────────────────────────────────────────
#  JANELA: OPÇÕES
# ─────────────────────────────────────────────
func _make_modal(title_txt: String, size: Vector2) -> Array:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.visible = false
	_ui.add_child(holder)
	holder.add_child(UIKit.dimmer(0.55))

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(center)

	var p := UIKit.panel(size, 40)
	center.add_child(p)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 22)
	p.add_child(vb)

	var t := UIKit.label(title_txt, 40, UIKit.C_TEXT_GOLD, UIKit.FONT_TITLE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	vb.add_child(UIKit.hline())
	return [holder, vb]

func _build_options_overlay() -> Control:
	var parts := _make_modal("OPÇÕES", Vector2(760, 0))
	var holder: Control = parts[0]
	var vb: VBoxContainer = parts[1]

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 22)
	vb.add_child(grid)

	# Música
	grid.add_child(UIKit.label("Música", 24, UIKit.C_TEXT_WHITE))
	_slider_music = UIKit.slider(Settings.music_volume)
	_slider_music.name = "FirstFocus"
	grid.add_child(_slider_music)
	_lbl_music_val = UIKit.label("", 22, UIKit.C_TEXT_GOLD)
	_lbl_music_val.custom_minimum_size = Vector2(70, 0)
	grid.add_child(_lbl_music_val)
	_slider_music.value_changed.connect(func(v):
		_lbl_music_val.text = "%d%%" % int(v)
		Settings.set_music_volume(v / 100.0))

	# Efeitos
	grid.add_child(UIKit.label("Efeitos sonoros", 24, UIKit.C_TEXT_WHITE))
	_slider_sfx = UIKit.slider(Settings.sfx_volume)
	grid.add_child(_slider_sfx)
	_lbl_sfx_val = UIKit.label("", 22, UIKit.C_TEXT_GOLD)
	grid.add_child(_lbl_sfx_val)
	_slider_sfx.value_changed.connect(func(v):
		_lbl_sfx_val.text = "%d%%" % int(v)
		Settings.set_sfx_volume(v / 100.0)
		if AudioManager: AudioManager.play_sfx("ui_click"))

	# Tela cheia
	grid.add_child(UIKit.label("Tela cheia", 24, UIKit.C_TEXT_WHITE))
	_chk_full = CheckButton.new()
	_chk_full.text = "  (F11)"
	_chk_full.add_theme_color_override("font_color", UIKit.C_TEXT_MUTED)
	_chk_full.add_theme_font_size_override("font_size", 18)
	_chk_full.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_chk_full.toggled.connect(func(on): Settings.set_fullscreen(on))
	UIKit.add_sounds(_chk_full)
	grid.add_child(_chk_full)
	grid.add_child(Control.new())

	vb.add_child(UIKit.hline())

	# Dificuldade
	var diff_title := UIKit.label("Dificuldade da campanha", 24, UIKit.C_TEXT_WHITE)
	vb.add_child(diff_title)
	var diff_row := HBoxContainer.new()
	diff_row.add_theme_constant_override("separation", 14)
	diff_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(diff_row)
	_diff_buttons.clear()
	for d in [Settings.Difficulty.EASY, Settings.Difficulty.NORMAL, Settings.Difficulty.HARD]:
		var b := UIKit.menu_button(Settings.get_difficulty_name(d).to_upper(), Vector2(210, 56), UIKit.C_BORDER_GOLD, 20)
		b.toggle_mode = true
		b.pressed.connect(func():
			Settings.set_difficulty(d)
			_sync_options())
		diff_row.add_child(b)
		_diff_buttons.append(b)
	_lbl_diff_desc = UIKit.label("", 19, UIKit.C_TEXT_MUTED, UIKit.FONT_SERIF)
	_lbl_diff_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_diff_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_diff_desc.custom_minimum_size = Vector2(660, 56)
	vb.add_child(_lbl_diff_desc)

	vb.add_child(UIKit.hline())

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	vb.add_child(row)
	var b_reset := UIKit.menu_button("RESTAURAR PADRÃO", Vector2(300, 58), UIKit.C_BORDER_GOLD, 20)
	b_reset.pressed.connect(func():
		Settings.reset_to_defaults()
		_sync_options())
	row.add_child(b_reset)
	var b_back := UIKit.menu_button("VOLTAR", Vector2(220, 58), UIKit.C_TEXT_GOLD, 20)
	b_back.pressed.connect(_close_overlays)
	row.add_child(b_back)

	holder.visibility_changed.connect(func(): if holder.visible: _sync_options())
	return holder

func _sync_options() -> void:
	_slider_music.set_value_no_signal(roundf(Settings.music_volume * 100.0))
	_slider_sfx.set_value_no_signal(roundf(Settings.sfx_volume * 100.0))
	_lbl_music_val.text = "%d%%" % int(_slider_music.value)
	_lbl_sfx_val.text = "%d%%" % int(_slider_sfx.value)
	_chk_full.set_pressed_no_signal(Settings.fullscreen)
	for i in _diff_buttons.size():
		var b := _diff_buttons[i]
		b.set_pressed_no_signal(i == Settings.difficulty)
		var active := (i == Settings.difficulty)
		b.add_theme_color_override("font_color", UIKit.C_TEXT_GOLD2 if active else UIKit.C_TEXT_MUTED)
		b.add_theme_stylebox_override("normal",
			UIKit.stylebox(UIKit.C_GREEN_DIM if active else UIKit.C_BTN_DARK,
				UIKit.C_GREEN_LIGHT if active else UIKit.C_SEPARATOR, 2, 6))
	_lbl_diff_desc.text = Settings.get_preset()["desc"]

# ─────────────────────────────────────────────
#  JANELA: CRÉDITOS
# ─────────────────────────────────────────────
func _build_credits_overlay() -> Control:
	var parts := _make_modal("CRÉDITOS", Vector2(760, 0))
	var holder: Control = parts[0]
	var vb: VBoxContainer = parts[1]

	var intro := UIKit.label("Reinos da Área — jogo sério sobre estimativa e comparação de áreas.", 20, UIKit.C_TEXT_WHITE, UIKit.FONT_SERIF)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.custom_minimum_size = Vector2(660, 0)
	vb.add_child(intro)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 10)
	var c := CenterContainer.new()
	c.add_child(grid)
	vb.add_child(c)

	var rows := CREDITS_TEAM.duplicate()
	rows.append(["Motor", "Godot Engine 4.6 (licença MIT)"])
	rows.append(["Fontes", "Cinzel, Libre Baskerville, Source Sans 3 (SIL OFL)"])
	for r in rows:
		var k := UIKit.label(r[0], 19, UIKit.C_TEXT_MUTED)
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(k)
		grid.add_child(UIKit.label(r[1], 19, UIKit.C_TEXT_GOLD))

	var stats := UIKit.label("Campanhas vencidas neste computador: %d" % Settings.campaigns_won, 18, UIKit.C_TEXT_MUTED)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(stats)
	holder.visibility_changed.connect(func():
		stats.text = "Campanhas vencidas neste computador: %d" % Settings.campaigns_won)

	var b_back := UIKit.menu_button("VOLTAR", Vector2(240, 58), UIKit.C_TEXT_GOLD, 20)
	b_back.name = "FirstFocus"
	b_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b_back.pressed.connect(_close_overlays)
	vb.add_child(b_back)
	return holder

# ─────────────────────────────────────────────
#  JANELA: PRIMEIRA PARTIDA
# ─────────────────────────────────────────────
func _build_firstrun_overlay() -> Control:
	var parts := _make_modal("PRIMEIRA VEZ AQUI?", Vector2(720, 0))
	var holder: Control = parts[0]
	var vb: VBoxContainer = parts[1]

	var msg := UIKit.label("O tutorial leva cerca de 3 minutos e inclui uma rodada de treino sem tempo. Recomendamos fazê-lo antes da primeira campanha.", 21, UIKit.C_TEXT_WHITE, UIKit.FONT_SERIF)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.custom_minimum_size = Vector2(620, 0)
	vb.add_child(msg)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	vb.add_child(row)

	var b_tut := UIKit.menu_button("VER TUTORIAL", Vector2(280, 60), UIKit.C_TEXT_GOLD, 22)
	b_tut.name = "FirstFocus"
	b_tut.pressed.connect(func(): UIKit.change_scene(self, TUTORIAL_SCENE))
	row.add_child(b_tut)

	var b_skip := UIKit.menu_button("JOGAR DIRETO", Vector2(280, 60), UIKit.C_BORDER_GOLD, 22)
	b_skip.pressed.connect(func():
		Settings.mark_tutorial_seen()
		_open_overlay(_overlay_mode))
	row.add_child(b_skip)
	return holder

# ─────────────────────────────────────────────
#  JANELA: ESCOLHA DO MODO (aberta pelo botão JOGAR)
# ─────────────────────────────────────────────
func _build_mode_overlay() -> Control:
	var parts := _make_modal("COMO VOCÊ QUER JOGAR?", Vector2(760, 0))
	var holder: Control = parts[0]
	var vb: VBoxContainer = parts[1]

	var b_story := UIKit.menu_button("MODO HISTÓRIA", Vector2(560, 70), UIKit.C_TEXT_GOLD, 28)
	b_story.name = "FirstFocus"
	b_story.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b_story.pressed.connect(func(): UIKit.change_scene(self, Story.STORY_SCENE))
	vb.add_child(b_story)
	var d_story := UIKit.label("20 fases em 5 cenários do continente de Geometria: terrenos, novas formas e a Cartógrafa.", 19, UIKit.C_TEXT_MUTED, UIKit.FONT_SERIF)
	d_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_story.custom_minimum_size = Vector2(660, 0)
	vb.add_child(d_story)

	var b_classic := UIKit.menu_button("CAMPANHA CLÁSSICA", Vector2(560, 70), UIKit.C_BORDER_GOLD, 28)
	b_classic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b_classic.pressed.connect(func():
		Story.leave()
		UIKit.change_scene(self, GAME_SCENE))
	vb.add_child(b_classic)
	var d_classic := UIKit.label("A partida original: 10 rodadas para dominar 70% do mapa.", 19, UIKit.C_TEXT_MUTED, UIKit.FONT_SERIF)
	d_classic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(d_classic)

	vb.add_child(UIKit.hline())
	var b_back := UIKit.menu_button("VOLTAR", Vector2(240, 58), UIKit.C_TEXT_GOLD, 20)
	b_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b_back.pressed.connect(_close_overlays)
	vb.add_child(b_back)
	return holder
