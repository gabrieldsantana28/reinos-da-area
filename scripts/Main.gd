## Main.gd
## Cena raiz: orquestra GameManager, TerritoryGenerator, TerritoryRenderer e UI.
## Direcao de arte: HUD medieval cartografico inspirado no hud.png.

extends Node2D

# Scripts carregados explicitamente (nao dependem do cache de classes do editor)
const UIKit = preload("res://scripts/UIKit.gd")
const GameManager = preload("res://scripts/GameManager.gd")
const TerritoryGenerator = preload("res://scripts/TerritoryGenerator.gd")
const TerritoryRenderer = preload("res://scripts/TerritoryRenderer.gd")

# ─────────────────────────────────────────────
#  CONFIGURACOES
# ─────────────────────────────────────────────
const CELL_SIZE         : int   = 60
const GRID_COLS         : int   = 32
const GRID_ROWS         : int   = 13   
const HALF_COLS         : int   = GRID_COLS / 2
const HUD_TOP_HEIGHT    : int   = 80
const HUD_BOTTOM_HEIGHT : int   = 220  
const TOTAL_ROUNDS      : int   = 10

const MENU_SCENE        : String = "res://scenes/Menu.tscn"
const TUTORIAL_SCENE    : String = "res://scenes/Tutorial.tscn"

# Area maxima do jogador. A regiao de cada lado comporta 110 celulas; limitar o
# jogador a 90 garante que o inimigo ainda possa ser MAIOR que ele (sem isso,
# depois de varias vitorias o jogador lotava a regiao e "Atacar" sempre vencia).
const PLAYER_AREA_MAX   : float = 90.0
const PLAYER_AREA_MIN   : float = 10.0

# Na ultima rodada a diferenca entre os territorios cai para 60% do valor inicial
# (a campanha fica mais dificil conforme avanca).
const LATE_GAME_DIFF_FACTOR : float = 0.6

# Controle de diferenca de tamanho do inimigo (0.05 = 5%). Os valores reais vem
# da dificuldade escolhida no menu Opcoes (Settings.DIFFICULTY_PRESETS).
var enemy_diff_min_pct : float = 0.05
var enemy_diff_max_pct : float = 0.15

# ─────────────────────────────────────────────
#  PALETA DE CORES MEDIEVAIS
# ─────────────────────────────────────────────
const C_BG_DARK       := Color8( 18,  14,  10, 255)
const C_BG_PANEL      := Color8( 28,  22,  14, 245)
const C_BORDER_GOLD   := Color8(148, 112,  38, 255)
const C_BORDER_GOLD2  := Color8(196, 156,  60, 180)
const C_TEXT_GOLD     := Color8(212, 180,  90, 255)
const C_TEXT_GOLD2    := Color8(240, 210, 120, 255)
const C_TEXT_WHITE    := Color8(238, 232, 218, 255)
const C_TEXT_MUTED    := Color8(160, 148, 120, 255)
const C_BLUE_MAIN     := Color8( 60, 110, 190, 255)
const C_BLUE_LIGHT    := Color8(120, 175, 255, 255)
const C_BLUE_DIM      := Color8( 35,  65, 120, 200)
const C_RED_MAIN      := Color8(160,  30,  30, 255)
const C_RED_BORDER    := Color8(200,  60,  60, 255)
const C_RED_DIM       := Color8( 90,  18,  18, 200)
const C_GREEN_MAIN    := Color8( 30, 100,  70, 255)
const C_GREEN_LIGHT   := Color8( 80, 180, 120, 255)
const C_GREEN_DIM     := Color8( 18,  58,  40, 200)
const C_BAR_BG        := Color8( 42,  34,  20, 255)
const C_BAR_GREEN     := Color8( 68, 168,  68, 255)
const C_BAR_ORANGE    := Color8(220, 140,  40, 255)
const C_SEPARATOR     := Color8(100,  80,  30, 140)

# ─────────────────────────────────────────────
#  REFERENCIAS DE NOS E VARIAVEIS
# ─────────────────────────────────────────────
var game_manager  : GameManager
var territory_gen : TerritoryGenerator
var renderer      : TerritoryRenderer

var lbl_area_value    : Label
var lbl_area_unit     : Label
var bar_dominance     : ProgressBar
var lbl_dominance_pct : Label
var hud_round_dots    : Array[ColorRect] = []
var lbl_world_phase   : Label

var lbl_terrain      : Label
var lbl_multiplier   : Label
var lbl_streak       : Label
var lbl_atk          : Label
var lbl_def          : Label
var lbl_timer        : Label

var btn_row           : HBoxContainer
var result_vbox       : VBoxContainer
var btn_attack        : Button
var btn_defend        : Button
var btn_retreat       : Button

var lbl_result_title  : Label
var lbl_result_detail : Label
var lbl_result_areas  : Label
var btn_continue      : Button

var panel_summary     : PanelContainer
var lbl_sum_title     : Label
var lbl_sum_stats     : Label
var lbl_sum_dom       : Label
var btn_restart       : Button

var _current_round   : int   = 0
var _player_area_val : float = 0.0
var _dominance_val   : float = 0.0

var _wins            : int   = 0
var _losses          : int   = 0
var _retreats        : int   = 0

var _last_timer_sec  : int   = -1
var _pending_action  : int   = 2

var lbl_score         : Label
var lbl_sum_score     : Label
var lbl_sum_record    : Label
var btn_sum_menu      : Button
var pause_layer       : CanvasLayer
var _paused           : bool  = false
var _summary_open     : bool  = false

# ─────────────────────────────────────────────
#  MODO HISTÓRIA (tudo abaixo fica inativo na campanha clássica)
# ─────────────────────────────────────────────
signal intro_closed
var _story          : bool = false
var _phase_n        : int = 0
var _phase          : Dictionary = {}
var _scen           : Dictionary = {}
var _round_terrain  : String = "plain"
var _round_ratio    : float = 1.0
var _force_end      : bool = false
var _intro_open     : bool = false
var _intro_layer    : CanvasLayer
var carto_panel     : PanelContainer
var lbl_carto       : Label
var _carto_tween    : Tween
var sum_stars       : Control
var lbl_sum_story   : Label
var btn_next        : Button

# ─────────────────────────────────────────────
#  READY
# ─────────────────────────────────────────────
func _ready() -> void:
	# Cursores, tamanho da janela e tela cheia agora sao aplicados pelo autoload
	# Settings (scripts/Settings.gd), valendo para todas as telas do jogo.
	DisplayServer.window_set_title("Reinos da Área")
	_story = Story.active
	if _story:
		_phase_n = Story.current_phase
		_phase = Story.get_phase(_phase_n)
		_scen = Story.get_scenario(_phase_n)

	# Main continua recebendo teclado com o jogo pausado (para o Esc despausar);
	# a logica e o mapa (filhos abaixo) sao pausaveis e congelam na pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_game_manager()
	_build_territory_system()
	game_manager.process_mode = Node.PROCESS_MODE_PAUSABLE
	renderer.process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_ui()
	_build_pause_overlay()
	_connect_signals()

	UIKit.fade_in(self)
	_start_new_campaign()

func _apply_difficulty() -> void:
	var preset: Dictionary = Settings.get_preset()
	enemy_diff_min_pct = preset["diff_min"]
	enemy_diff_max_pct = preset["diff_max"]
	if game_manager:
		game_manager.base_round_time = preset["round_time"]
	if lbl_terrain:
		lbl_terrain.text = "TERRENO:  PLANÍCIE   ·   %s" % String(preset["name"]).to_upper()
	if _story:
		# Cada cenário estreita a diferença entre os reinos e pode limitar o tempo
		var f: float = _scen["diff_factor"]
		enemy_diff_min_pct = preset["diff_min"] * f
		enemy_diff_max_pct = preset["diff_max"] * f
		var t: float = preset["round_time"]
		if float(_scen["round_time"]) > 0.0:
			t = minf(t, float(_scen["round_time"]))
		if game_manager:
			game_manager.base_round_time = t
		renderer.bg_tint = _scen["tint"]
		renderer.bg_overlay = _scen["overlay"]
		renderer.ref_grid_mode = int(_scen["ref_grid"])
		if lbl_world_phase:
			lbl_world_phase.text = "MUNDO %s . FASE %d" % [_scen["num"], _phase_n]
		if lbl_terrain:
			var tag := "   ·   MORTE SÚBITA" if bool(_phase.get("sudden_death", false)) else ""
			lbl_terrain.text = "TERRENO:  %s   ·   %s%s" % [String(Story.TERRAINS[_phase["terrains"][0]]["name"]).to_upper(), String(preset["name"]).to_upper(), tag]

func _start_new_campaign() -> void:
	if AudioManager:
		AudioManager.stop_music()
		AudioManager.play_music("bg_music")

	_apply_difficulty()
	_summary_open    = false
	_player_area_val = float(randi_range(30, 45))
	_force_end       = false
	if _story:
		var sa: Array = _scen["start_area"]
		_player_area_val = float(randi_range(int(sa[0]), int(sa[1])))
	_dominance_val   = 0.0
	_wins            = 0
	_losses          = 0
	_retreats        = 0
	_current_round   = 0
	
	if game_manager:
		game_manager.reset_campaign()
	
	_update_dominance(_dominance_val)
	_update_area_display(_player_area_val)
	if lbl_score: lbl_score.text = "0"
	if lbl_streak: lbl_streak.text = "0 vitórias"

	if _story:
		_set_buttons_enabled(false)
		_show_intro()
		await intro_closed
	await get_tree().create_timer(0.3, false).timeout
	_start_round()

# ─────────────────────────────────────────────
#  SISTEMAS
# ─────────────────────────────────────────────
func _build_game_manager() -> void:
	game_manager = GameManager.new()
	game_manager.name = "GameManager"
	add_child(game_manager)

func _build_territory_system() -> void:
	territory_gen           = TerritoryGenerator.new()
	territory_gen.grid_cols = GRID_COLS
	territory_gen.grid_rows = GRID_ROWS
	
	territory_gen.min_cells = 10 
	territory_gen.max_cells = 200

	renderer           = TerritoryRenderer.new()
	renderer.name      = "Renderer"
	renderer.cell_size = CELL_SIZE
	renderer.grid_cols = GRID_COLS
	renderer.grid_rows = GRID_ROWS
	renderer.position  = Vector2(0, HUD_TOP_HEIGHT)
	
	renderer.textura_fundo = load("res://assets/icons/fundo.jpg")
	
	add_child(renderer)

# ─────────────────────────────────────────────
#  BUILD UI GERAL
# ─────────────────────────────────────────────
func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)

	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(screen)

	_build_top_bar(screen)
	_build_bottom_hud(screen)
	_build_summary_overlay(ui)
	if _story:
		_build_cartographer(screen)

# ─────────────────────────────────────────────
#  BARRA SUPERIOR
# ─────────────────────────────────────────────
func _build_top_bar(parent: Control) -> void:
	var top_bg := PanelContainer.new()
	top_bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bg.custom_minimum_size = Vector2(0, HUD_TOP_HEIGHT)
	top_bg.offset_bottom = HUD_TOP_HEIGHT
	_apply_panel_style(top_bg, C_BG_DARK, C_BORDER_GOLD, 0, 2, 0, 0)
	parent.add_child(top_bg)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 0)
	top_bg.add_child(hbox)

	var sec_area := _make_top_section(0, true)
	hbox.add_child(sec_area)

	var area_inner := HBoxContainer.new()
	area_inner.alignment = BoxContainer.ALIGNMENT_CENTER
	area_inner.add_theme_constant_override("separation", 12)
	area_inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sec_area.add_child(area_inner)

	var area_label_vbox := VBoxContainer.new()
	area_label_vbox.add_theme_constant_override("separation", 0)
	area_inner.add_child(area_label_vbox)

	lbl_area_value = _make_label("0", 32, C_BLUE_LIGHT, "Cinzel")
	lbl_area_unit  = _make_label("ÁREA TOTAL", 16, C_TEXT_MUTED, "Source Sans 3")
	area_label_vbox.add_child(lbl_area_value)
	area_label_vbox.add_child(lbl_area_unit)

	_add_vertical_separator(hbox)

	var sec_dom := _make_top_section(0, true)
	hbox.add_child(sec_dom)

	var dom_vbox := VBoxContainer.new()
	dom_vbox.add_theme_constant_override("separation", 6)
	dom_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dom_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dom_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sec_dom.add_child(dom_vbox)

	var dom_title := _make_label("OBJETIVO: DOMINAR 70% DO MAPA                         ", 16, C_TEXT_MUTED, "Source Sans 3")
	dom_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dom_vbox.add_child(dom_title)

	var dom_bar_row := HBoxContainer.new()
	dom_bar_row.add_theme_constant_override("separation", 10)
	dom_bar_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dom_vbox.add_child(dom_bar_row)

	bar_dominance = _make_progress_bar(260, 18)
	bar_dominance.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dom_bar_row.add_child(bar_dominance)

	lbl_dominance_pct = _make_label("0%", 16, C_TEXT_GOLD, "Source Sans 3")
	lbl_dominance_pct.custom_minimum_size = Vector2(45, 0)
	dom_bar_row.add_child(lbl_dominance_pct)

	_add_vertical_separator(hbox)

	var sec_rounds := _make_top_section(0, true)
	hbox.add_child(sec_rounds)

	var rounds_vbox := VBoxContainer.new()
	rounds_vbox.add_theme_constant_override("separation", 6)
	rounds_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rounds_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rounds_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sec_rounds.add_child(rounds_vbox)

	var rounds_title := _make_label("RODADAS", 16, C_TEXT_MUTED, "Source Sans 3")
	rounds_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rounds_vbox.add_child(rounds_title)

	var dots_row := HBoxContainer.new()
	dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dots_row.add_theme_constant_override("separation", 10)
	rounds_vbox.add_child(dots_row)

	hud_round_dots.clear()
	for i in TOTAL_ROUNDS:
		var dot := _make_round_dot(false)
		dots_row.add_child(dot)
		hud_round_dots.append(dot)

	_add_vertical_separator(hbox)

	var sec_phase := _make_top_section(0, true)
	hbox.add_child(sec_phase)

	var phase_vbox := VBoxContainer.new()
	phase_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	phase_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phase_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phase_vbox.add_theme_constant_override("separation", 2)
	sec_phase.add_child(phase_vbox)

	lbl_world_phase = _make_label("MUNDO I . FASE 1", 18, C_TEXT_GOLD, "Cinzel")
	lbl_world_phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_vbox.add_child(lbl_world_phase)

	lbl_terrain = _make_label("TERRENO:  PLANÍCIE", 16, C_TEXT_WHITE, "Source Sans 3")
	lbl_terrain.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_vbox.add_child(lbl_terrain)
	
	var shield_icon := TextureRect.new()
	shield_icon.texture = load("res://assets/icons/brasao.png")
	shield_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shield_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	shield_icon.custom_minimum_size = Vector2(200, 200)
	shield_icon.size = Vector2(140, 140)
	
	shield_icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	shield_icon.position = Vector2(0, 5) 
	parent.add_child(shield_icon)

# ─────────────────────────────────────────────
#  HUD INFERIOR
# ─────────────────────────────────────────────
func _build_bottom_hud(parent: Control) -> void:
	var bottom_bg := PanelContainer.new()
	bottom_bg.anchor_top    = 1.0
	bottom_bg.anchor_bottom = 1.0
	bottom_bg.anchor_left   = 0.0
	bottom_bg.anchor_right  = 1.0
	bottom_bg.offset_top    = -HUD_BOTTOM_HEIGHT
	bottom_bg.offset_bottom = -20 
	_apply_panel_style(bottom_bg, C_BG_DARK, C_BORDER_GOLD, 0, 2, 0, 0)
	parent.add_child(bottom_bg)

	var main_hbox := HBoxContainer.new()
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_hbox.add_theme_constant_override("separation", 0)
	bottom_bg.add_child(main_hbox)

	# --- LADO ESQUERDO: INFORMAÇÕES DE BATALHA ---
	var left_panel := _make_bottom_section(450)
	main_hbox.add_child(left_panel)

	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 10)
	lv.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.add_child(lv)

	var title_lbl := _make_label("INFORMAÇÕES DE BATALHA", 14, C_TEXT_GOLD2, "Cinzel")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lv.add_child(title_lbl)

	var sep_h := _make_horizontal_line()
	lv.add_child(sep_h)

	var grid_center := CenterContainer.new()
	grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(grid_center)

	var data_grid := GridContainer.new()
	data_grid.columns = 3
	data_grid.add_theme_constant_override("h_separation", 30)
	data_grid.add_theme_constant_override("v_separation", 12)
	grid_center.add_child(data_grid)

	lbl_multiplier = _add_stat_cell(data_grid, "MODIFICADOR TERRENO", "Nenhum", C_TEXT_WHITE)
	lbl_streak     = _add_stat_cell(data_grid, "SEQUÊNCIA", "0 vitórias", C_BAR_ORANGE)
	lbl_timer      = _add_stat_cell(data_grid, "TEMPO", "60s", C_TEXT_GOLD)
	
	lbl_atk        = _add_stat_cell(data_grid, "FORÇA ATAQUE", "1.0x", C_RED_BORDER, "res://assets/icons/swords.png")
	lbl_def        = _add_stat_cell(data_grid, "FORÇA DEFESA", "1.0x", C_BLUE_LIGHT, "res://assets/icons/shield.png")
	lbl_score      = _add_stat_cell(data_grid, "PONTOS", "0", C_TEXT_GOLD2)

	_add_vertical_separator(main_hbox)

	# --- CENTRO: BOTOES / RESULTADOS ---
	var center_panel := _make_bottom_section(0, true)
	main_hbox.add_child(center_panel)

	var center_vbox := VBoxContainer.new()
	center_vbox.add_theme_constant_override("separation", 10)
	center_vbox.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	center_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_vbox.alignment             = BoxContainer.ALIGNMENT_CENTER
	center_panel.add_child(center_vbox)

	btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 25)
	center_vbox.add_child(btn_row)

	# As teclas A / D / R estao no Input Map (project.godot) como ui_attack / ui_defend / ui_retreat
	btn_attack  = _make_action_button("ATACAR", "Sou maior", C_RED_DIM, C_RED_MAIN, C_RED_BORDER, "A", "res://assets/icons/swords.png")
	btn_defend  = _make_action_button("DEFENDER", "Inimigo é maior", C_BLUE_DIM, C_BLUE_MAIN, C_BLUE_LIGHT, "D", "res://assets/icons/shield.png")
	btn_retreat = _make_action_button("RECUAR", "Não arriscar", C_GREEN_DIM, C_GREEN_MAIN, C_GREEN_LIGHT, "R", "res://assets/icons/boot.png")
	
	btn_row.add_child(btn_attack)
	btn_row.add_child(btn_defend)
	btn_row.add_child(btn_retreat)

	btn_attack.pressed.connect(func(): _on_action(GameManager.Action.ATTACK))
	btn_defend.pressed.connect(func(): _on_action(GameManager.Action.DEFEND))
	btn_retreat.pressed.connect(func(): _on_action(GameManager.Action.RETREAT))

	result_vbox = VBoxContainer.new()
	result_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	result_vbox.add_theme_constant_override("separation", 6)
	result_vbox.visible = false
	center_vbox.add_child(result_vbox)

	lbl_result_title  = _make_label("", 24, Color.WHITE, "Cinzel")
	lbl_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_vbox.add_child(lbl_result_title)

	lbl_result_detail = _make_label("", 14, C_TEXT_WHITE, "Libre Baskerville")
	lbl_result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_result_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_result_detail.custom_minimum_size = Vector2(480, 0)
	result_vbox.add_child(lbl_result_detail)

	lbl_result_areas  = _make_label("", 15, C_TEXT_MUTED, "Source Sans 3")
	lbl_result_areas.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_vbox.add_child(lbl_result_areas)

	btn_continue = _make_action_button("PRÓXIMA RODADA", "", C_GREEN_DIM, C_GREEN_MAIN, C_GREEN_LIGHT, "")
	btn_continue.custom_minimum_size = Vector2(260, 60)
	btn_continue.pressed.connect(_on_continue_pressed)
	result_vbox.add_child(btn_continue)

	_add_vertical_separator(main_hbox)

	# --- LADO DIREITO: ARQUETIPO ---
	var right_panel := _make_bottom_section(500)
	main_hbox.add_child(right_panel)

	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 8)
	rv.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	rv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_child(rv)

	var arch_header_hbox := HBoxContainer.new()
	arch_header_hbox.add_theme_constant_override("separation", 10)
	rv.add_child(arch_header_hbox)

	var arch_title := _make_label("ARQUÉTIPO ATIVO", 16, C_TEXT_MUTED, "Source Sans 3")
	arch_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	arch_header_hbox.add_child(arch_title)

	var badge_panel := PanelContainer.new()
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = C_RED_DIM
	badge_sb.border_color = C_RED_BORDER
	badge_sb.set_border_width_all(1)
	badge_sb.corner_radius_top_left = 6
	badge_sb.corner_radius_top_right = 6
	badge_sb.corner_radius_bottom_left = 6
	badge_sb.corner_radius_bottom_right = 6
	badge_panel.add_theme_stylebox_override("panel", badge_sb)
	arch_header_hbox.add_child(badge_panel)

	var badge_margin := MarginContainer.new()
	badge_margin.add_theme_constant_override("margin_left", 8)
	badge_margin.add_theme_constant_override("margin_right", 8)
	badge_margin.add_theme_constant_override("margin_top", 3)
	badge_margin.add_theme_constant_override("margin_bottom", 3)
	badge_panel.add_child(badge_margin)

	var arch_name := _make_label("GUERREIRO Nv.2", 12, C_TEXT_WHITE, "Cinzel")
	badge_margin.add_child(arch_name)

	var skill_sep := _make_horizontal_line()
	rv.add_child(skill_sep)

	var passiva_title := _make_label("PASSIVA: Legião de Cativos", 14, C_TEXT_GOLD, "Source Sans 3")
	var passiva_desc := _make_label("Cada vitória soma +2% de bônus de área ao Ataque (max +10%). Ao perder, a moral quebra e o bônus zera.", 12, C_TEXT_WHITE, "Libre Baskerville")
	passiva_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passiva_desc.custom_minimum_size = Vector2(400, 0)
	rv.add_child(passiva_title)
	rv.add_child(passiva_desc)
	
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	rv.add_child(spacer)

	var ativa_header := HBoxContainer.new()
	ativa_header.add_theme_constant_override("separation", 15)
	rv.add_child(ativa_header)

	var ativa_title := _make_label("ATIVA: Aço Duplo", 14, C_TEXT_GOLD, "Source Sans 3")
	ativa_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ativa_header.add_child(ativa_title)

	var btn_fake_skill := Button.new()
	btn_fake_skill.text = " ATIVAR (1) "
	btn_fake_skill.custom_minimum_size = Vector2(90, 26)
	btn_fake_skill.add_theme_font_size_override("font_size", 12)
	btn_fake_skill.add_theme_color_override("font_color", C_BG_DARK)
	btn_fake_skill.add_theme_color_override("font_hover_color", C_BG_DARK)
	btn_fake_skill.focus_mode = Control.FOCUS_NONE
	btn_fake_skill.tooltip_text = "Habilidades de arquétipo chegam na próxima versão (v0.3)."
	
	# Define a mãozinha também para o botão de habilidade
	btn_fake_skill.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var sb_skill_normal := StyleBoxFlat.new()
	sb_skill_normal.bg_color = C_TEXT_GOLD
	sb_skill_normal.corner_radius_top_left = 4
	sb_skill_normal.corner_radius_top_right = 4
	sb_skill_normal.corner_radius_bottom_left = 4
	sb_skill_normal.corner_radius_bottom_right = 4
	var sb_skill_hover := sb_skill_normal.duplicate()
	sb_skill_hover.bg_color = C_TEXT_GOLD2

	btn_fake_skill.add_theme_stylebox_override("normal", sb_skill_normal)
	btn_fake_skill.add_theme_stylebox_override("hover", sb_skill_hover)
	btn_fake_skill.add_theme_stylebox_override("pressed", sb_skill_normal)
	ativa_header.add_child(btn_fake_skill)
	
	btn_fake_skill.mouse_entered.connect(func(): if AudioManager: AudioManager.play_sfx("ui_hover", 0.1))
	btn_fake_skill.pressed.connect(func(): if AudioManager: AudioManager.play_sfx("ui_click"))

	var ativa_desc := _make_label("Dobra o poder atual da Legião de Cativos apenas para esta rodada.", 12, C_TEXT_WHITE, "Libre Baskerville")
	ativa_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ativa_desc.custom_minimum_size = Vector2(400, 0)
	rv.add_child(ativa_desc)

# ─────────────────────────────────────────────
#  RESUMO OVERLAY
# ─────────────────────────────────────────────
func _build_summary_overlay(ui: CanvasLayer) -> void:
	panel_summary = PanelContainer.new()
	panel_summary.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	panel_summary.custom_minimum_size = Vector2(760, 520)
	panel_summary.offset_left   = -380
	panel_summary.offset_top    = -260
	panel_summary.offset_right  = 380
	panel_summary.offset_bottom = 260
	
	_apply_panel_style(panel_summary, C_BG_DARK, C_BORDER_GOLD, 3, 3, 3, 3, 8, 12)
	panel_summary.visible = false
	ui.add_child(panel_summary)

	var rv := VBoxContainer.new()
	rv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rv.alignment = BoxContainer.ALIGNMENT_CENTER
	rv.add_theme_constant_override("separation", 24)
	panel_summary.add_child(rv)

	lbl_sum_title = _make_label("FIM DA FASE", 40, C_TEXT_GOLD, "Cinzel")
	lbl_sum_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(lbl_sum_title)

	var sep_h := _make_horizontal_line()
	sep_h.custom_minimum_size = Vector2(460, 2)
	rv.add_child(sep_h)

	lbl_sum_stats = _make_label("Vitórias: 0  |  Derrotas: 0  |  Recuos: 0", 22, C_TEXT_WHITE, "Source Sans 3")
	lbl_sum_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(lbl_sum_stats)

	lbl_sum_dom = _make_label("DOMÍNIO FINAL: 0%", 28, C_BLUE_LIGHT, "Cinzel")
	lbl_sum_dom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(lbl_sum_dom)

	lbl_sum_score = _make_label("PONTUAÇÃO: 0", 24, C_TEXT_GOLD2, "Cinzel")
	lbl_sum_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(lbl_sum_score)

	lbl_sum_record = _make_label("", 18, C_TEXT_MUTED, "Source Sans 3")
	lbl_sum_record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rv.add_child(lbl_sum_record)

	# Modo História: estrelas da fase e texto da história
	var stars_center := CenterContainer.new()
	sum_stars = UIKit.stars(0, 44)
	stars_center.add_child(sum_stars)
	stars_center.visible = _story
	rv.add_child(stars_center)
	lbl_sum_story = _make_label("", 17, C_TEXT_WHITE, "Libre Baskerville")
	lbl_sum_story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sum_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_sum_story.custom_minimum_size = Vector2(660, 0)
	lbl_sum_story.visible = false
	rv.add_child(lbl_sum_story)
	panel_summary.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel_summary.grow_vertical = Control.GROW_DIRECTION_BOTH

	var sum_btns := HBoxContainer.new()
	sum_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	sum_btns.add_theme_constant_override("separation", 24)
	rv.add_child(sum_btns)

	btn_restart = _make_action_button("JOGAR NOVAMENTE", "", C_GREEN_DIM, C_GREEN_MAIN, C_GREEN_LIGHT, "")
	btn_restart.custom_minimum_size = Vector2(300, 60)
	btn_restart.pressed.connect(func():
		if _story:
			UIKit.change_scene(self, scene_file_path)
			return
		panel_summary.visible = false
		_start_new_campaign()
	)
	sum_btns.add_child(btn_restart)

	btn_next = _make_action_button("PRÓXIMA FASE", "", C_BLUE_DIM, C_BLUE_MAIN, C_BLUE_LIGHT, "")
	btn_next.custom_minimum_size = Vector2(260, 60)
	btn_next.visible = false
	btn_next.pressed.connect(func():
		Story.start_phase(_phase_n + 1)
		UIKit.change_scene(self, scene_file_path))
	sum_btns.add_child(btn_next)

	btn_sum_menu = _make_action_button("MENU PRINCIPAL", "", C_BG_PANEL, C_BORDER_GOLD, C_TEXT_GOLD, "")
	btn_sum_menu.custom_minimum_size = Vector2(300, 60)
	btn_sum_menu.pressed.connect(func():
		if _story:
			Story.leave()
			UIKit.change_scene(self, Story.STORY_SCENE)
		else:
			UIKit.change_scene(self, MENU_SCENE))
	sum_btns.add_child(btn_sum_menu)

func _connect_signals() -> void:
	game_manager.phase_changed.connect(_on_phase_changed)
	game_manager.round_result.connect(_on_round_result)
	game_manager.score_updated.connect(_on_score_updated)
	game_manager.timer_tick.connect(_on_timer_tick)
	game_manager.new_round_started.connect(_on_new_round_started)

# ─────────────────────────────────────────────
#  LOGICA DE RODADA
# ─────────────────────────────────────────────
func _start_round() -> void:
	_pending_action = GameManager.Action.RETREAT
	
	_player_area_val = clampf(_player_area_val, PLAYER_AREA_MIN, PLAYER_AREA_MAX)
	var p_cells_target = int(_player_area_val)
	var e_cells_target : int

	# A diferenca diminui conforme as rodadas avancam (rodada 1 = 100%, ultima = 60%)
	var progress := clampf(float(_current_round) / float(TOTAL_ROUNDS - 1), 0.0, 1.0)
	var factor := lerpf(1.0, LATE_GAME_DIFF_FACTOR, progress)
	var diff_min := maxf(0.02, enemy_diff_min_pct * factor)
	var diff_max := maxf(diff_min + 0.01, enemy_diff_max_pct * factor)
	var diff_pct = randf_range(diff_min, diff_max)

	if randi() % 2 == 0:
		e_cells_target = int(p_cells_target * (1.0 + diff_pct))
	else:
		e_cells_target = int(p_cells_target * (1.0 - diff_pct))

	if p_cells_target == e_cells_target:
		e_cells_target += 1 if randi() % 2 == 0 else -1

	p_cells_target = clampi(p_cells_target, territory_gen.min_cells, territory_gen.max_cells)
	e_cells_target = clampi(e_cells_target, territory_gen.min_cells, territory_gen.max_cells)

	var spawn_width := 12
	var p_offset := HALF_COLS - spawn_width
	var e_offset := HALF_COLS
	
	var player_cells : Dictionary
	var enemy_cells  : Dictionary
	if _story:
		var gen := _generate_story_round(p_cells_target, diff_pct, p_offset, e_offset, spawn_width)
		player_cells = gen[0]
		enemy_cells = gen[1]
	else:
		game_manager.terrain_ratio = 1.0
		player_cells = territory_gen.generate(p_cells_target, p_offset, spawn_width, 1)
		enemy_cells  = territory_gen.generate(e_cells_target, e_offset, spawn_width, 1)

	var guard := 0
	while not _story and player_cells.size() == enemy_cells.size() and guard < 50:
		guard += 1
		e_cells_target += 1 if randi() % 2 == 0 else -1
		e_cells_target = clampi(e_cells_target, territory_gen.min_cells, territory_gen.max_cells)
		enemy_cells = territory_gen.generate(e_cells_target, e_offset, spawn_width, 1)

	renderer.set_territories(player_cells, enemy_cells)
	
	if AudioManager: AudioManager.play_sfx("map_unroll")
	renderer.play_vs_animation()

	_player_area_val = float(player_cells.size())
	var actual_e_area = float(enemy_cells.size())

	_update_area_display(_player_area_val)
	game_manager.start_new_round(_player_area_val, actual_e_area)
	if _story and Story.cartographer_mode(_phase_n) == "active":
		await get_tree().create_timer(1.3, false).timeout
		if game_manager.current_phase != GameManager.Phase.RESULT:
			_say(Story.line_before_round(String(_scen["shape"]), _round_terrain), 8.0)

func _on_phase_changed(phase: String) -> void:
	match phase:
		"ANALYSIS":
			_set_buttons_enabled(false)
			btn_row.visible = true
			result_vbox.visible = false
			await get_tree().create_timer(1.5, false).timeout
			_set_buttons_enabled(true)
		"DECISION":
			_set_buttons_enabled(true)
		"RESULT":
			_set_buttons_enabled(false)
		"RESTART":
			btn_row.visible = true
			result_vbox.visible = false
			await get_tree().create_timer(0.4, false).timeout
			_start_round()

func _on_round_result(result: String, p_area: float, e_area: float) -> void:
	_play_result_sequence(result, p_area, e_area)

func _play_result_sequence(result: String, p_area: float, e_area: float) -> void:
	await get_tree().create_timer(1.0, false).timeout
	
	var delay_acao := 2.0
	
	if AudioManager:
		match _pending_action:
			GameManager.Action.ATTACK:
				AudioManager.play_sfx("action_attack")
				delay_acao = 3.0
			GameManager.Action.DEFEND:
				AudioManager.play_sfx("action_defend")
				delay_acao = 3.0
			GameManager.Action.RETREAT:
				AudioManager.play_sfx("action_retreat")
				delay_acao = 2.0
				
	await get_tree().create_timer(delay_acao, false).timeout
	
	renderer.reveal_enemy_grid()
	renderer.play_result_flash(result)
	
	if AudioManager: AudioManager.play_sfx("result_" + result.to_lower())
	
	var e_eff := e_area * _round_ratio

	if result == "WIN":
		_wins += 1
		lbl_result_title.text = "VITÓRIA"
		lbl_result_title.add_theme_color_override("font_color", Color(0.30, 0.95, 0.45))
		
		_dominance_val += 10.0
		
		if p_area > e_eff:
			lbl_result_detail.text = "ATACAR: Seu território era MAIOR. Você venceu, ganhou 10% de Domínio e expandiu sua área em 10%!"
			_player_area_val += _player_area_val * 0.10 
		else:
			lbl_result_detail.text = "DEFENDER: O inimigo era maior e você resistiu! Ganhou 10% de Domínio e a área cresceu 5%!"
			_player_area_val += _player_area_val * 0.05
			
	elif result == "LOSE":
		_losses += 1
		lbl_result_title.text = "DERROTA"
		lbl_result_title.add_theme_color_override("font_color", Color(0.95, 0.28, 0.28))
		
		if p_area < e_eff:
			lbl_result_detail.text = "ATACAR FALHOU: O inimigo era maior. Você sofreu um duro golpe e perdeu 20% da sua área."
			_player_area_val -= _player_area_val * 0.20
		else:
			lbl_result_detail.text = "DEFENDER FALHOU: Você era o maior, deveria ter atacado! O erro de cálculo custou 10% da sua área."
			_player_area_val -= _player_area_val * 0.10
			
	elif result == "DRAW":
		_retreats += 1
		if game_manager.last_was_timeout:
			lbl_result_title.text = "TEMPO ESGOTADO"
			lbl_result_detail.text = "O tempo acabou e suas tropas recuaram sozinhas. O Domínio se mantém, mas você perdeu 5% do território."
		else:
			lbl_result_title.text = "RECUO"
			lbl_result_detail.text = "RECUAR: Ação segura. Seu Domínio se mantém intacto, mas a inércia fez você perder 5% do território."
		lbl_result_title.add_theme_color_override("font_color", Color(0.90, 0.80, 0.30))
		_player_area_val -= _player_area_val * 0.05

	_dominance_val = clampf(_dominance_val, 0.0, 100.0)
	_player_area_val = clampf(_player_area_val, PLAYER_AREA_MIN, PLAYER_AREA_MAX)

	_update_dominance(_dominance_val)

	var diff_pct := absf((p_area - e_eff) / maxf(p_area, e_eff)) * 100.0
	lbl_result_areas.text  = "Seu território: %d   Inimigo: %d   Diferença: %s%%" % [int(p_area), int(e_area), ("%.1f" % diff_pct).replace(".", ",")]
	if _story and not is_equal_approx(_round_ratio, 1.0):
		var tname: String = Story.TERRAINS[_round_terrain]["name"]
		lbl_result_areas.text = "Seu território: %d   Inimigo: %d × %s (%s) = %s   Diferença: %s%%" % [
			int(p_area), int(e_area), _fmt(_round_ratio), tname, _fmt(e_eff), ("%.1f" % diff_pct).replace(".", ",")]

	if _story:
		if result == "LOSE" and bool(_phase.get("sudden_death", false)):
			_force_end = true
			lbl_result_detail.text += "  MORTE SÚBITA: a primeira derrota encerra a fase."
		var mode := Story.cartographer_mode(_phase_n)
		if mode == "active" or (mode == "silent" and result == "LOSE"):
			_say(Story.line_after_result(result), 6.0)
	
	btn_continue.text = "" 
	var custom_lbl = btn_continue.find_child("LblTitle", true, false)
	
	if _current_round >= TOTAL_ROUNDS or _force_end:
		if custom_lbl: custom_lbl.text = "VER RESUMO"
	else:
		if custom_lbl: custom_lbl.text = "PRÓXIMA RODADA"
		
	btn_row.visible = false
	result_vbox.visible = true

func _on_continue_pressed() -> void:
	if not result_vbox.visible:
		return
	if _current_round >= TOTAL_ROUNDS or _force_end:
		result_vbox.visible = false
		btn_row.visible = true
		_show_summary()
		btn_restart.grab_focus()
	else:
		# Esconde na hora para que um duplo clique / Enter repetido nao inicie duas rodadas
		result_vbox.visible = false
		game_manager.request_restart()

func _show_summary() -> void:
	lbl_sum_stats.text = "Vitórias: %d  |  Derrotas: %d  |  Recuos: %d" % [_wins, _losses, _retreats]
	lbl_sum_dom.text = "DOMÍNIO FINAL: %.0f%%" % _dominance_val
	
	if AudioManager: AudioManager.stop_music()
	
	if _dominance_val >= 70.0:
		lbl_sum_dom.add_theme_color_override("font_color", C_BAR_GREEN)
		lbl_sum_title.text = "FASE CONCLUÍDA!"
		if AudioManager: AudioManager.play_music("phase_win")
	else:
		lbl_sum_dom.add_theme_color_override("font_color", C_BAR_ORANGE)
		lbl_sum_title.text = "FASE FRACASSADA"
		if AudioManager: AudioManager.play_music("phase_lose")

	if _story:
		_show_story_summary()
		return

	var score := game_manager.player_score
	var won := _dominance_val >= 70.0
	var previous_best := Settings.best_score
	var new_record := Settings.register_campaign(score, _dominance_val, won)
	lbl_sum_score.text = "PONTUAÇÃO: %d" % score
	if new_record:
		lbl_sum_record.text = "NOVO RECORDE!  (anterior: %d pts)  ·  Dificuldade: %s" % [previous_best, Settings.get_difficulty_name()]
		lbl_sum_record.add_theme_color_override("font_color", C_TEXT_GOLD2)
	else:
		lbl_sum_record.text = "Recorde: %d pts  ·  Dificuldade: %s" % [Settings.best_score, Settings.get_difficulty_name()]
		lbl_sum_record.add_theme_color_override("font_color", C_TEXT_MUTED)

	_summary_open = true
	panel_summary.visible = true

func _on_score_updated(score: int, streak: int) -> void: 
	if lbl_streak:
		lbl_streak.text = "%d vitórias" % streak
	if lbl_score:
		lbl_score.text = "%d" % score

func _on_timer_tick(secs_left: float) -> void:
	if lbl_timer:
		var sec_int = ceili(secs_left)
		lbl_timer.text = "%ds" % sec_int
		if secs_left <= 10.0:
			lbl_timer.add_theme_color_override("font_color", C_RED_MAIN)
			if _last_timer_sec == -1 and sec_int > 0:
				_last_timer_sec = 10 
				if AudioManager: AudioManager.play_sfx("timer_tick")
		else:
			lbl_timer.add_theme_color_override("font_color", C_TEXT_GOLD)
			_last_timer_sec = -1

func _on_new_round_started(round_num: int, _diff: float) -> void:
	_current_round = min(round_num, TOTAL_ROUNDS)
	_update_round_dots(_current_round)
	
	var world  := 1
	var phase  := 1
	var labels: Array[String] = ["I", "II", "III", "IV", "V"]
	var world_label: String = labels[clampi(world - 1, 0, labels.size() - 1)]
	if _story:
		world_label = String(_scen["num"])
		phase = _phase_n
	lbl_world_phase.text = "MUNDO %s . FASE %d" % [world_label, phase]

func _on_action(action: GameManager.Action) -> void:
	_set_buttons_enabled(false) 
	_pending_action = action
	game_manager.resolve_action(action)

func _set_buttons_enabled(enabled: bool) -> void:
	btn_attack.disabled  = not enabled
	btn_defend.disabled  = not enabled
	btn_retreat.disabled = not enabled
	var alpha := 1.0 if enabled else 0.38
	btn_attack.modulate.a  = alpha
	btn_defend.modulate.a  = alpha
	btn_retreat.modulate.a = alpha

func _update_area_display(area: float) -> void:
	var a_int = int(area)
	lbl_area_value.text = "%d" % a_int
	if lbl_atk: lbl_atk.text = "1.0x"
	if lbl_def: lbl_def.text = "1.0x"
	if _story:
		var t: Dictionary = Story.TERRAINS[_round_terrain]
		if lbl_atk: lbl_atk.text = "%sx" % _fmt(float(t["atk"]))
		if lbl_def: lbl_def.text = "%sx" % _fmt(float(t["def"]))

func _update_dominance(pct: float) -> void:
	bar_dominance.value    = pct
	lbl_dominance_pct.text = "%.0f%%" % pct
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = C_BAR_GREEN if pct >= 70.0 else (C_BAR_ORANGE if pct >= 40.0 else C_BAR_GREEN.darkened(0.3))
	bar_fill.corner_radius_top_left     = 3
	bar_fill.corner_radius_top_right    = 3
	bar_fill.corner_radius_bottom_left  = 3
	bar_fill.corner_radius_bottom_right = 3
	bar_dominance.add_theme_stylebox_override("fill", bar_fill)

func _update_round_dots(completed: int) -> void:
	for i in hud_round_dots.size():
		var dot := hud_round_dots[i]
		if i < completed - 1: dot.color = C_BORDER_GOLD
		elif i == completed - 1: dot.color = C_BAR_ORANGE
		else: dot.color = C_SEPARATOR

func _make_top_section(min_width: int, expand: bool = false) -> MarginContainer:
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   20)
	mc.add_theme_constant_override("margin_right",  20)
	mc.add_theme_constant_override("margin_top",    12)
	mc.add_theme_constant_override("margin_bottom", 12)
	if min_width > 0: mc.custom_minimum_size = Vector2(min_width, 0)
	if expand: mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return mc

func _make_bottom_section(min_width: int, expand: bool = false) -> MarginContainer:
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left",   24)
	mc.add_theme_constant_override("margin_right",  24)
	mc.add_theme_constant_override("margin_top",    16)
	mc.add_theme_constant_override("margin_bottom", 16)
	mc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if min_width > 0: mc.custom_minimum_size = Vector2(min_width, 0)
	if expand: mc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return mc

func _add_vertical_separator(parent: Container) -> void:
	var sep := VSeparator.new()
	
	var linha := StyleBoxLine.new()
	linha.color = C_SEPARATOR
	linha.vertical = true
	linha.thickness = 3
	
	linha.grow_end = -10.0 
	linha.grow_begin = -10.0 
	
	sep.add_theme_stylebox_override("separator", linha)
	
	parent.add_child(sep)

func _make_horizontal_line() -> Control:
	var c := ColorRect.new()
	c.custom_minimum_size = Vector2(0, 1)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.color = C_SEPARATOR
	return c

func _make_round_dot(active: bool) -> ColorRect:
	var dot := ColorRect.new()
	dot.custom_minimum_size = Vector2(20, 20)
	dot.color = C_BORDER_GOLD if active else C_SEPARATOR
	return dot

func _make_progress_bar(min_w: int, height: int) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.min_value = 0.0; pb.max_value = 100.0; pb.value = 0.0
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(min_w, height)
	var bg := StyleBoxFlat.new()
	bg.bg_color = C_BAR_BG; bg.border_color = C_BORDER_GOLD; bg.set_border_width_all(1)
	bg.corner_radius_top_left = 3; bg.corner_radius_top_right = 3; bg.corner_radius_bottom_left = 3; bg.corner_radius_bottom_right = 3
	pb.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = C_BAR_GREEN
	fill.corner_radius_top_left = 3; fill.corner_radius_top_right = 3; fill.corner_radius_bottom_left = 3; fill.corner_radius_bottom_right = 3
	pb.add_theme_stylebox_override("fill", fill)
	return pb

func _make_label(txt: String, size: int, color: Color, font_hint: String = "Source Sans 3") -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	
	var font_path := ""
	
	if font_hint == "Cinzel":
		font_path = "res://assets/fonts/Cinzel.ttf"
	elif font_hint == "Libre Baskerville":
		font_path = "res://assets/fonts/Baskerville.ttf"
	else:
		font_path = "res://assets/fonts/SourceSans.ttf"
		
	if ResourceLoader.exists(font_path):
		var custom_font = load(font_path)
		lbl.add_theme_font_override("font", custom_font)
		
	return lbl

func _make_action_button(titulo: String, subtitulo: String, bg_dark: Color, col_mid: Color, col_light: Color, key_hint: String, icon_path: String = "") -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(210, 100) 
	btn.focus_mode = Control.FOCUS_NONE
	
	# Define a mãozinha também para os botões de ação e navegação!
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)    
	margin.add_theme_constant_override("margin_bottom", 10) 
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	btn.add_child(margin)
	
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL 
	hbox.add_theme_constant_override("separation", 16)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)
	
	var icon_box := CenterContainer.new()
	icon_box.custom_minimum_size = Vector2(50, 50)
	icon_box.size_flags_vertical = Control.SIZE_EXPAND_FILL 
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon_box)
	
	if icon_path != "":
		var icon_rect := TextureRect.new()
		icon_rect.texture = load(icon_path)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(50, 50)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_box.add_child(icon_rect)
	else:
		icon_box.visible = false
		
	var text_vbox := VBoxContainer.new()
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL 
	text_vbox.add_theme_constant_override("separation", 0) 
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(text_vbox)
	
	var lbl_title := _make_label(titulo, 18, C_TEXT_GOLD, "Cinzel")
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_title.custom_minimum_size = Vector2(0, 30) 
	lbl_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_title.name = "LblTitle"
	text_vbox.add_child(lbl_title)
	
	if subtitulo != "":
		var lbl_sub := _make_label(subtitulo, 16, C_TEXT_WHITE, "Source Sans 3")
		lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_sub.custom_minimum_size = Vector2(0, 22)
		lbl_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_vbox.add_child(lbl_sub)

	# Selo com a tecla de atalho no canto superior direito do botao
	if key_hint != "":
		var key_lbl := _make_label(key_hint, 14, C_TEXT_GOLD2, "Source Sans 3")
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		key_lbl.custom_minimum_size = Vector2(24, 22)
		var key_sb := StyleBoxFlat.new()
		key_sb.bg_color = Color(0, 0, 0, 0.45)
		key_sb.border_color = C_BORDER_GOLD
		key_sb.set_border_width_all(1)
		key_sb.set_corner_radius_all(4)
		key_lbl.add_theme_stylebox_override("normal", key_sb)
		key_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		key_lbl.offset_left = -32
		key_lbl.offset_right = -6
		key_lbl.offset_top = 6
		key_lbl.offset_bottom = 28
		btn.add_child(key_lbl)

	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = bg_dark
	sb_normal.border_color = C_BORDER_GOLD
	sb_normal.set_border_width_all(2)
	sb_normal.corner_radius_top_left = 6
	sb_normal.corner_radius_top_right = 6
	sb_normal.corner_radius_bottom_left = 6
	sb_normal.corner_radius_bottom_right = 6
	
	var sb_hover := sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = bg_dark.lightened(0.14)
	sb_hover.border_color = C_TEXT_GOLD2
	
	var sb_pressed := sb_normal.duplicate() as StyleBoxFlat
	sb_pressed.bg_color = bg_dark.darkened(0.12)
	
	var sb_disabled := sb_normal.duplicate() as StyleBoxFlat
	sb_disabled.bg_color = bg_dark.darkened(0.30)
	sb_disabled.border_color = C_SEPARATOR

	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("disabled", sb_disabled)
	
	btn.mouse_entered.connect(func(): if AudioManager and not btn.disabled: AudioManager.play_sfx("ui_hover", 0.05))
	btn.pressed.connect(func(): if AudioManager: AudioManager.play_sfx("ui_click"))
	
	return btn

func _apply_panel_style(p: PanelContainer, bg: Color, border: Color, bw_top: float = 1.5, bw_bot: float = 1.5, bw_left: float = 1.5, bw_right: float = 1.5, radius: int = 0, padding: int = 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg; sb.border_color = border
	sb.border_width_top = bw_top; sb.border_width_bottom = bw_bot; sb.border_width_left = bw_left; sb.border_width_right = bw_right
	
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	
	if padding > 0:
		sb.content_margin_left = padding
		sb.content_margin_right = padding
		sb.content_margin_top = padding
		sb.content_margin_bottom = padding
		
	p.add_theme_stylebox_override("panel", sb)

func _add_stat_cell(grid: GridContainer, label: String, value: String, color: Color, icon_path: String = "") -> Label:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	grid.add_child(vb)
	
	var lbl_title := _make_label(label, 14, C_TEXT_MUTED, "Source Sans 3")
	vb.add_child(lbl_title)
	
	var lbl_val := _make_label(value, 20, color, "Source Sans 3")
	
	if icon_path != "":
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		hb.alignment = BoxContainer.ALIGNMENT_BEGIN
		
		var icon_rect := TextureRect.new()
		icon_rect.texture = load(icon_path)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(24, 24)
		
		hb.add_child(icon_rect)
		hb.add_child(lbl_val)
		vb.add_child(hb)
	else:
		vb.add_child(lbl_val)
		
	return lbl_val

# ─────────────────────────────────────────────
#  TECLADO: ATALHOS E PAUSA
# ─────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	var is_pause_key: bool = event.is_action_pressed("ui_cancel") or \
		(event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P)
	if _intro_open:
		return
	if is_pause_key:
		if not _summary_open:
			_set_paused(not _paused)
		get_viewport().set_input_as_handled()
		return

	if _paused or _summary_open:
		return

	# Enter / Espaco avancam para a proxima rodada depois do resultado
	if result_vbox.visible and event.is_action_pressed("ui_accept"):
		_on_continue_pressed()
		get_viewport().set_input_as_handled()
		return

	# A / D / R escolhem a acao enquanto os botoes estao liberados
	if btn_row.visible and not btn_attack.disabled:
		if event.is_action_pressed("ui_attack"):
			if AudioManager: AudioManager.play_sfx("ui_click")
			_on_action(GameManager.Action.ATTACK)
		elif event.is_action_pressed("ui_defend"):
			if AudioManager: AudioManager.play_sfx("ui_click")
			_on_action(GameManager.Action.DEFEND)
		elif event.is_action_pressed("ui_retreat"):
			if AudioManager: AudioManager.play_sfx("ui_click")
			_on_action(GameManager.Action.RETREAT)

# Pausa automaticamente se a janela perder o foco (Alt+Tab), para o tempo nao correr.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and not _paused and not _summary_open and not _intro_open and is_inside_tree():
		_set_paused(true)

func _set_paused(on: bool) -> void:
	_paused = on
	get_tree().paused = on
	pause_layer.visible = on
	if on:
		var first := pause_layer.find_child("FirstFocus", true, false)
		if first is Control: (first as Control).grab_focus()

func _build_pause_overlay() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 50
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.visible = false
	add_child(pause_layer)

	pause_layer.add_child(UIKit.dimmer(0.65))

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(center)

	var p := UIKit.panel(Vector2(560, 0), 40)
	center.add_child(p)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	p.add_child(vb)

	var t := UIKit.label("PAUSADO", 44, C_TEXT_GOLD, UIKit.FONT_TITLE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var hint := UIKit.label("O relógio da rodada está parado.", 18, C_TEXT_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hint)
	vb.add_child(UIKit.hline())

	var b_resume := UIKit.menu_button("CONTINUAR", Vector2(460, 62), C_TEXT_GOLD, 24)
	b_resume.name = "FirstFocus"
	b_resume.pressed.connect(func(): _set_paused(false))
	vb.add_child(b_resume)

	var b_restart := UIKit.menu_button("REINICIAR FASE" if _story else "REINICIAR CAMPANHA", Vector2(460, 62))
	b_restart.pressed.connect(func(): UIKit.change_scene(self, scene_file_path))
	vb.add_child(b_restart)

	var b_tutorial := UIKit.menu_button("VER TUTORIAL", Vector2(460, 62))
	b_tutorial.pressed.connect(func():
		Story.leave()
		UIKit.change_scene(self, TUTORIAL_SCENE))
	vb.add_child(b_tutorial)

	var b_menu := UIKit.menu_button("MAPA DA HISTÓRIA" if _story else "MENU PRINCIPAL", Vector2(460, 62))
	b_menu.pressed.connect(func():
		if _story:
			Story.leave()
			UIKit.change_scene(self, Story.STORY_SCENE)
		else:
			UIKit.change_scene(self, MENU_SCENE))
	vb.add_child(b_menu)

	vb.add_child(UIKit.hline())

	# Volumes rapidos
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 12)
	vb.add_child(grid)
	grid.add_child(UIKit.label("Música", 20, C_TEXT_WHITE))
	var s_music := UIKit.slider(Settings.music_volume)
	s_music.value_changed.connect(func(v): Settings.set_music_volume(v / 100.0))
	grid.add_child(s_music)
	grid.add_child(UIKit.label("Efeitos", 20, C_TEXT_WHITE))
	var s_sfx := UIKit.slider(Settings.sfx_volume)
	s_sfx.value_changed.connect(func(v): Settings.set_sfx_volume(v / 100.0))
	grid.add_child(s_sfx)

	var keys := UIKit.label("Esc / P: pausar   ·   A D R: ações   ·   Enter: próxima rodada   ·   F11: tela cheia", 15, C_TEXT_MUTED)
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(keys)

# ─────────────────────────────────────────────
#  MODO HISTÓRIA
# ─────────────────────────────────────────────
func _fmt(v: float) -> String:
	return ("%.2f" % v).replace(".", ",")

## Gera os dois reinos da rodada com a forma do cenário e o terreno sorteado.
## O inimigo é dimensionado para que a comparação JÁ CONSIDERANDO o terreno fique
## perto da área do jogador: na Serra ele parece menor, mas pode resistir.
func _generate_story_round(p_target: int, diff_pct: float, p_off: int, e_off: int, width: int) -> Array:
	var terrains: Array = _phase["terrains"]
	_round_terrain = String(terrains[randi() % terrains.size()])
	_round_ratio = Story.terrain_ratio(_round_terrain)
	game_manager.terrain_ratio = _round_ratio
	var kind: String = _scen["shape"]
	var cap := (width - 2) * (GRID_ROWS - 2) - 10
	var e_eff := float(p_target) * ((1.0 + diff_pct) if randi() % 2 == 0 else (1.0 - diff_pct))
	var e_target := int(round(e_eff / _round_ratio))
	if e_target > cap:
		p_target = int(float(p_target) * float(cap) / float(e_target))
		e_target = cap
	p_target = clampi(p_target, territory_gen.min_cells, cap)
	e_target = clampi(e_target, territory_gen.min_cells, cap)
	var pc := territory_gen.generate_shape(kind, p_target, p_off, width, 1)
	var ec := territory_gen.generate_shape(kind, e_target, e_off, width, 1)
	var guard := 0
	while absf(float(pc.size()) - float(ec.size()) * _round_ratio) < 0.75 and guard < 50:
		guard += 1
		e_target = clampi(e_target + (1 if randi() % 2 == 0 else -1), territory_gen.min_cells, cap)
		ec = territory_gen.generate_shape(kind, e_target, e_off, width, 1)

	var t: Dictionary = Story.TERRAINS[_round_terrain]
	if lbl_multiplier:
		lbl_multiplier.text = "Nenhum" if _round_terrain == "plain" else "%s ×%s" % [t["name"], _fmt(_round_ratio)]
	if lbl_terrain:
		var tag := "   ·   MORTE SÚBITA" if bool(_phase.get("sudden_death", false)) else ""
		lbl_terrain.text = "TERRENO:  %s   ·   %s%s" % [String(t["name"]).to_upper(), Settings.get_difficulty_name().to_upper(), tag]
	return [pc, ec]

## Faixa da Cartógrafa na linha vazia do topo do mapa.
func _build_cartographer(parent: Control) -> void:
	carto_panel = PanelContainer.new()
	carto_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_panel_style(carto_panel, Color(0.07, 0.05, 0.03, 0.90), C_BORDER_GOLD, 1.5, 1.5, 1.5, 1.5, 8, 10)
	carto_panel.anchor_left = 0.5
	carto_panel.anchor_right = 0.5
	carto_panel.offset_left = -620
	carto_panel.offset_right = 620
	carto_panel.offset_top = HUD_TOP_HEIGHT + 6
	carto_panel.offset_bottom = HUD_TOP_HEIGHT + 54
	carto_panel.modulate.a = 0.0
	parent.add_child(carto_panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	carto_panel.add_child(hb)
	var who := _make_label("A CARTÓGRAFA", 16, C_TEXT_GOLD2, "Cinzel")
	who.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(who)
	lbl_carto = _make_label("", 18, C_TEXT_WHITE, "Libre Baskerville")
	lbl_carto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_carto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(lbl_carto)

func _say(text: String, duration: float) -> void:
	if carto_panel == null:
		return
	lbl_carto.text = text
	if _carto_tween:
		_carto_tween.kill()
	_carto_tween = create_tween()
	_carto_tween.tween_property(carto_panel, "modulate:a", 1.0, 0.3)
	_carto_tween.tween_interval(duration)
	_carto_tween.tween_property(carto_panel, "modulate:a", 0.0, 0.5)

## Cartão de abertura da fase: cenário, história e regras da fase.
func _show_intro() -> void:
	_intro_open = true
	_intro_layer = CanvasLayer.new()
	_intro_layer.layer = 45
	add_child(_intro_layer)
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro_layer.add_child(holder)
	holder.add_child(UIKit.dimmer(0.74))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(center)
	var p := UIKit.panel(Vector2(1040, 0), 40)
	center.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	p.add_child(vb)

	var l_num := UIKit.label("CENÁRIO %s" % _scen["num"], 22, C_TEXT_GOLD, UIKit.FONT_TITLE)
	l_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l_num)
	var l_name := UIKit.label(String(_scen["name"]).to_upper(), 46, C_TEXT_GOLD2, UIKit.FONT_TITLE)
	l_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l_name)
	var l_phase := UIKit.label("Fase %d  ·  %s" % [_phase_n, _phase["title"]], 24, C_TEXT_WHITE, UIKit.FONT_SERIF)
	l_phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l_phase)
	vb.add_child(UIKit.hline())

	var l_text := UIKit.label(String(_scen["text"]), 20, C_TEXT_WHITE, UIKit.FONT_SERIF)
	l_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_text.custom_minimum_size = Vector2(940, 0)
	vb.add_child(l_text)
	if _phase_n == 10:
		var l_bye := UIKit.label("A Cartógrafa: “%s”" % Story.FAREWELL, 20, C_TEXT_GOLD2, UIKit.FONT_SERIF)
		l_bye.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l_bye.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l_bye.custom_minimum_size = Vector2(940, 0)
		vb.add_child(l_bye)
	vb.add_child(UIKit.hline())

	var terrain_txt: Array[String] = []
	for k in _phase["terrains"]:
		var t: Dictionary = Story.TERRAINS[k]
		if k == "plain":
			terrain_txt.append("Planície (sem modificador)")
		else:
			terrain_txt.append("%s (defensor ×%s, atacante ×%s)" % [t["name"], _fmt(float(t["def"])), _fmt(float(t["atk"]))])
	var terrain_line := " · ".join(terrain_txt)
	if terrain_txt.size() > 1:
		terrain_line = "Muda a cada rodada: " + terrain_line
	var grid_txt: Array[String] = ["Completo ao redor do inimigo", "Só 1 célula ao redor do inimigo", "Nenhum ao redor do inimigo"]
	var carto_txt := {"active": "Presente, com dicas", "silent": "Só comenta nas derrotas", "absent": "Ausente"}
	var goal := "Dominar 70% do mapa em 10 rodadas"
	if bool(_phase.get("sudden_death", false)):
		goal += " · a primeira derrota encerra a fase"
	var rows := [
		["Terreno", terrain_line],
		["Tempo por rodada", "%d segundos" % int(game_manager.base_round_time)],
		["Grid de referência", grid_txt[int(_scen["ref_grid"])]],
		["Cartógrafa", carto_txt[Story.cartographer_mode(_phase_n)]],
		["Objetivo", goal],
		["Estrelas", "1: Domínio de 70%  ·  2: 80%  ·  3: 80% sem nenhuma derrota"],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	vb.add_child(grid)
	for r in rows:
		var k := UIKit.label(r[0], 19, C_TEXT_MUTED)
		k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(k)
		var v := UIKit.label(r[1], 19, C_TEXT_GOLD)
		v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.custom_minimum_size = Vector2(700, 0)
		grid.add_child(v)

	var best: int = Story.stars[_phase_n]
	if best > 0:
		var sc := CenterContainer.new()
		sc.add_child(UIKit.stars(best, 30))
		vb.add_child(sc)

	var b_go := UIKit.menu_button("COMEÇAR", Vector2(340, 64), C_TEXT_GOLD, 26)
	b_go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b_go.pressed.connect(_close_intro)
	vb.add_child(b_go)
	if AudioManager: AudioManager.play_sfx("map_unroll")
	await get_tree().process_frame
	if is_instance_valid(b_go) and b_go.is_inside_tree():
		b_go.grab_focus()

func _close_intro() -> void:
	if not _intro_open:
		return
	_intro_open = false
	var layer := _intro_layer
	layer.queue_free()
	intro_closed.emit()

func _show_story_summary() -> void:
	var won := _dominance_val >= 70.0 and not _force_end
	var got := Story.compute_stars(_dominance_val, _losses) if won else 0
	var prev: int = Story.stars[_phase_n]
	Story.register_result(_phase_n, got)

	if won:
		lbl_sum_title.text = "FASE CONCLUÍDA!"
		lbl_sum_dom.add_theme_color_override("font_color", C_BAR_GREEN)
	else:
		lbl_sum_title.text = "FASE FRACASSADA"
		lbl_sum_dom.add_theme_color_override("font_color", C_BAR_ORANGE)
		if AudioManager:
			AudioManager.stop_music()
			AudioManager.play_music("phase_lose")
	UIKit.set_stars(sum_stars, got)
	lbl_sum_score.text = "PONTUAÇÃO: %d" % game_manager.player_score
	lbl_sum_record.text = "Fase %d · %s   ·   Melhor resultado: %d de 3 estrelas" % [_phase_n, _phase["title"], maxi(prev, got)]
	lbl_sum_record.add_theme_color_override("font_color", C_TEXT_MUTED)

	if won and _phase_n == Story.TOTAL_PHASES:
		lbl_sum_story.text = Story.EPILOGUE
	elif won:
		lbl_sum_story.text = "Fase %d liberada: %s." % [_phase_n + 1, Story.get_phase(_phase_n + 1)["title"]]
	elif _force_end:
		lbl_sum_story.text = "Morte Súbita: a primeira derrota encerrou a fase. Respire e tente de novo."
	else:
		lbl_sum_story.text = "Domine pelo menos 70% do mapa para ganhar estrelas e liberar a próxima fase."
	lbl_sum_story.visible = true

	var t_restart = btn_restart.find_child("LblTitle", true, false)
	if t_restart: t_restart.text = "REPETIR FASE"
	var t_menu = btn_sum_menu.find_child("LblTitle", true, false)
	if t_menu: t_menu.text = "MAPA DA HISTÓRIA"
	btn_next.visible = won and _phase_n < Story.TOTAL_PHASES

	_summary_open = true
	panel_summary.visible = true
