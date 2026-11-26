## Tutorial.gd
## Tutorial interativo: explica as regras passo a passo sobre um mapa real e
## termina com uma rodada de treino sem tempo, com feedback da escolha.

extends Node2D

# Scripts carregados explicitamente (nao dependem do cache de classes do editor)
const UIKit = preload("res://scripts/UIKit.gd")
const GameManager = preload("res://scripts/GameManager.gd")
const TerritoryGenerator = preload("res://scripts/TerritoryGenerator.gd")
const TerritoryRenderer = preload("res://scripts/TerritoryRenderer.gd")

const MENU_SCENE := "res://scenes/Menu.tscn"
const GAME_SCENE := "res://scenes/Main.tscn"

const CELL      := 40
const COLS      := 32
const ROWS      := 13
const HALF      := COLS / 2
const MAP_POS   := Vector2((1920 - CELL * COLS) / 2.0, 120)
const SPAWN_W   := 12

const BLUE  := "#78afff"
const RED   := "#e06060"
const GOLD  := "#f0d278"
const GREEN := "#5fd08a"
const ICON_SWORDS := "res://assets/icons/swords.png"
const ICON_SHIELD := "res://assets/icons/shield.png"
const ICON_BOOT   := "res://assets/icons/boot.png"

enum Focus { NONE, PLAYER, ENEMY, BOTH }

## Cada passo: título, texto (BBCode) e qual lado do mapa destacar.
var STEPS := [
	{"title": "Bem-vindo, governante!",
	 "focus": Focus.BOTH,
	 "text": "Seu objetivo é dominar [b][color=%s]70%% do mapa[/color][/b] ao longo de [b]10 rodadas[/b]. Em cada rodada, dois reinos se encaram: o [color=%s][b]seu[/b][/color], à esquerda, e o [color=%s][b]inimigo[/b][/color], à direita. Para vencer, você precisa descobrir [b]qual dos dois tem a maior área[/b]." % [GOLD, BLUE, RED]},
	{"title": "O seu reino",
	 "focus": Focus.PLAYER,
	 "text": "Seu território é [color=%s][b]azul[/b][/color] e mostra a malha quadriculada. Cada quadradinho é [b]1 unidade de área[/b]. Este reino tem [b][color=%s]{player} quadrados[/color][/b] — o mesmo número aparece no topo da tela, em [i]ÁREA TOTAL[/i]." % [BLUE, BLUE]},
	{"title": "O reino inimigo",
	 "focus": Focus.ENEMY,
	 "text": "O inimigo é [color=%s][b]vermelho[/b][/color] e a malha dele fica [b]escondida[/b]: não dá para contar. Você precisa [b]estimar[/b] a área comparando formas, larguras e alturas. A diferença entre os dois costuma ser pequena — entre 5%% e 15%% no modo Normal." % RED},
	{"title": "Suas três escolhas",
	 "focus": Focus.BOTH,
	 "text": "[img=34]%s[/img]  [b][color=%s]ATACAR[/color][/b] (tecla [b]A[/b]) — escolha quando achar que [b]você é maior[/b].\n[img=34]%s[/img]  [b][color=%s]DEFENDER[/color][/b] (tecla [b]D[/b]) — escolha quando achar que [b]o inimigo é maior[/b].\n[img=34]%s[/img]  [b][color=%s]RECUAR[/color][/b] (tecla [b]R[/b]) — não arrisca nada, mas também não ganha nada." % [ICON_SWORDS, RED, ICON_SHIELD, BLUE, ICON_BOOT, GREEN]},
	{"title": "O que acontece depois",
	 "focus": Focus.NONE,
	 "text": "[color=%s][b]Acertou o ataque:[/b][/color] +10%% de domínio e sua área cresce 10%%.   [color=%s][b]Acertou a defesa:[/b][/color] +10%% de domínio e +5%% de área.\n[color=%s][b]Errou o ataque:[/b][/color] perde 20%% da área.   [color=%s][b]Errou a defesa:[/b][/color] perde 10%% da área.   [color=%s][b]Recuou:[/b][/color] domínio igual, perde 5%% da área.\nDepois do combate, a malha inimiga é revelada para você conferir." % [GREEN, GREEN, RED, RED, GOLD]},
	{"title": "Tempo, pontos e vitória",
	 "focus": Focus.NONE,
	 "text": "Você tem [b]60 segundos[/b] por rodada (no modo Normal). Se o tempo acabar, o reino [b]recua sozinho[/b]. Cada vitória vale [b]100 pontos[/b], mais até [b]200 de bônus[/b] por decidir rápido e [b]+50[/b] por vitória seguida. Para concluir a fase, junte [color=%s][b]7 vitórias em 10 rodadas[/b][/color] (70%% de domínio). [b]Esc[/b] pausa o jogo." % GOLD},
	{"title": "Rodada de treino",
	 "focus": Focus.BOTH,
	 "practice": true,
	 "text": "Agora é com você — e sem relógio. Compare os dois reinos e escolha [b][color=%s]ATACAR[/color][/b], [b][color=%s]DEFENDER[/color][/b] ou [b][color=%s]RECUAR[/color][/b]. Dica: compare [b]colunas[/b] e [b]linhas[/b] ocupadas e imagine os buracos sendo preenchidos." % [RED, BLUE, GREEN]},
	{"title": "Pronto para a conquista!",
	 "focus": Focus.NONE,
	 "final": true,
	 "text": "Você já sabe tudo para começar. Lembre-se: [b]na dúvida, compare com calma[/b] — o bônus de velocidade é bom, mas errar custa caro. Você pode rever este tutorial pelo menu principal a qualquer momento."},
]

var _gen       : TerritoryGenerator
var _renderer  : TerritoryRenderer
var _highlight : Highlighter

var _step         : int = 0
var _player_cells : Dictionary = {}
var _enemy_cells  : Dictionary = {}
var _practice_done : bool = false
var _practice_wins : int = 0
var _practice_total: int = 0

var _lbl_step     : Label
var _dots         : Array[ColorRect] = []
var _lbl_title    : Label
var _rt_body      : RichTextLabel
var _lbl_player   : Label
var _lbl_enemy    : Label
var _nav_row      : HBoxContainer
var _btn_prev     : Button
var _btn_next     : Button
var _action_row   : HBoxContainer
var _final_row    : HBoxContainer
var _practice_row : HBoxContainer
var _act_buttons  : Array[Button] = []

func _ready() -> void:
	DisplayServer.window_set_title("Reinos da Área — Tutorial")
	_gen = TerritoryGenerator.new()
	_gen.grid_cols = COLS
	_gen.grid_rows = ROWS
	_gen.min_cells = 10
	_gen.max_cells = 110

	_build_map()
	_build_ui()
	_new_sample_map(false)
	_show_step(0)
	if AudioManager: AudioManager.play_music("bg_music")
	UIKit.fade_in(self)

# ─────────────────────────────────────────────
#  MAPA
# ─────────────────────────────────────────────
func _build_map() -> void:
	# Fundo escuro da tela inteira
	var bg := ColorRect.new()
	bg.color = UIKit.C_BG_DARK
	bg.size = Vector2(1920, 1080)
	bg.z_index = -10
	add_child(bg)

	_renderer = TerritoryRenderer.new()
	_renderer.cell_size = CELL
	_renderer.grid_cols = COLS
	_renderer.grid_rows = ROWS
	_renderer.position = MAP_POS
	_renderer.textura_fundo = load("res://assets/icons/fundo.jpg")
	add_child(_renderer)

	# Moldura dourada em volta do mapa
	var frame := Panel.new()
	frame.position = MAP_POS - Vector2(4, 4)
	frame.size = Vector2(CELL * COLS + 8, CELL * ROWS + 8)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = UIKit.C_BORDER_GOLD
	sb.set_border_width_all(3)
	frame.add_theme_stylebox_override("panel", sb)
	add_child(frame)

	_highlight = Highlighter.new()
	_highlight.position = MAP_POS
	_highlight.cell = CELL
	_highlight.cols = COLS
	_highlight.rows = ROWS
	_highlight.z_index = 20
	add_child(_highlight)

func _new_sample_map(practice: bool) -> void:
	var p_target := randi_range(38, 62)
	var pct := randf_range(0.10, 0.18) if practice else randf_range(0.08, 0.14)
	var e_target := int(p_target * (1.0 + pct)) if randi() % 2 == 0 else int(p_target * (1.0 - pct))
	_player_cells = _gen.generate(p_target, HALF - SPAWN_W, SPAWN_W, 1)
	_enemy_cells  = _gen.generate(e_target, HALF, SPAWN_W, 1)
	var guard := 0
	while _enemy_cells.size() == _player_cells.size() and guard < 20:
		_enemy_cells = _gen.generate(e_target + randi_range(-3, 3), HALF, SPAWN_W, 1)
		guard += 1
	_renderer.set_territories(_player_cells, _enemy_cells)
	if AudioManager: AudioManager.play_sfx("map_unroll")

# ─────────────────────────────────────────────
#  INTERFACE
# ─────────────────────────────────────────────
func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	# --- Barra superior ---
	var top := HBoxContainer.new()
	top.position = Vector2(MAP_POS.x, 30)
	top.size = Vector2(CELL * COLS, 60)
	top.add_theme_constant_override("separation", 20)
	root.add_child(top)

	var t := UIKit.label("TUTORIAL", 34, UIKit.C_TEXT_GOLD, UIKit.FONT_TITLE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)

	var dots_row := HBoxContainer.new()
	dots_row.add_theme_constant_override("separation", 8)
	dots_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(dots_row)
	_dots.clear()
	for i in STEPS.size():
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(18, 18)
		dots_row.add_child(d)
		_dots.append(d)

	_lbl_step = UIKit.label("", 20, UIKit.C_TEXT_MUTED)
	_lbl_step.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_lbl_step.custom_minimum_size = Vector2(150, 0)
	_lbl_step.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_lbl_step)

	var b_skip := UIKit.menu_button("SAIR DO TUTORIAL", Vector2(250, 48), UIKit.C_BORDER_GOLD, 17)
	b_skip.focus_mode = Control.FOCUS_NONE
	b_skip.pressed.connect(_exit_to_menu)
	top.add_child(b_skip)

	# --- Rótulos de área sobre o mapa ---
	_lbl_player = UIKit.label("", 22, UIKit.C_BLUE_LIGHT, UIKit.FONT_TITLE)
	_lbl_player.position = MAP_POS + Vector2(16, 10)
	_lbl_player.add_theme_color_override("font_outline_color", Color.BLACK)
	_lbl_player.add_theme_constant_override("outline_size", 8)
	root.add_child(_lbl_player)
	_lbl_enemy = UIKit.label("", 22, Color8(255, 140, 140), UIKit.FONT_TITLE)
	_lbl_enemy.position = MAP_POS + Vector2(HALF * CELL + 16, 10)
	_lbl_enemy.add_theme_color_override("font_outline_color", Color.BLACK)
	_lbl_enemy.add_theme_constant_override("outline_size", 8)
	root.add_child(_lbl_enemy)

	# --- Painel de texto inferior ---
	var panel := UIKit.panel(Vector2(CELL * COLS, 360), 30)
	panel.position = Vector2(MAP_POS.x, MAP_POS.y + CELL * ROWS + 30)
	panel.size = Vector2(CELL * COLS, 360)
	root.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	_lbl_title = UIKit.label("", 32, UIKit.C_TEXT_GOLD2, UIKit.FONT_TITLE)
	vb.add_child(_lbl_title)
	vb.add_child(UIKit.hline())

	_rt_body = UIKit.rich("", 23)
	_rt_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rt_body.custom_minimum_size = Vector2(0, 150)
	_rt_body.add_theme_constant_override("line_separation", 8)
	vb.add_child(_rt_body)

	var bottom := HBoxContainer.new()
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_theme_constant_override("separation", 16)
	vb.add_child(bottom)

	var hint := UIKit.label("← →  navegar     Esc  voltar ao menu", 16, UIKit.C_TEXT_MUTED)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(hint)

	# Navegação normal
	_nav_row = HBoxContainer.new()
	_nav_row.add_theme_constant_override("separation", 16)
	bottom.add_child(_nav_row)
	_btn_prev = UIKit.menu_button("◀  ANTERIOR", Vector2(230, 58), UIKit.C_BORDER_GOLD, 20)
	_btn_prev.pressed.connect(func(): _show_step(_step - 1))
	_nav_row.add_child(_btn_prev)
	_btn_next = UIKit.menu_button("PRÓXIMO  ▶", Vector2(230, 58), UIKit.C_TEXT_GOLD, 20)
	_btn_next.pressed.connect(func(): _show_step(_step + 1))
	_nav_row.add_child(_btn_next)

	# Botões de ação (rodada de treino)
	_action_row = HBoxContainer.new()
	_action_row.add_theme_constant_override("separation", 16)
	bottom.add_child(_action_row)
	_act_buttons.clear()
	var defs := [
		["ATACAR  (A)", UIKit.C_RED_DIM, UIKit.C_RED_BORDER, GameManager.Action.ATTACK],
		["DEFENDER  (D)", UIKit.C_BLUE_DIM, UIKit.C_BLUE_LIGHT, GameManager.Action.DEFEND],
		["RECUAR  (R)", UIKit.C_GREEN_DIM, UIKit.C_GREEN_LIGHT, GameManager.Action.RETREAT],
	]
	for d in defs:
		var b := UIKit.menu_button(d[0], Vector2(230, 58), d[2], 20)
		b.add_theme_stylebox_override("normal", UIKit.stylebox(d[1], d[2], 2, 6))
		b.add_theme_stylebox_override("hover", UIKit.stylebox(Color(d[1]).lightened(0.15), UIKit.C_TEXT_GOLD2, 3, 6))
		var action: int = d[3]
		b.pressed.connect(func(): _on_practice_action(action))
		_action_row.add_child(b)
		_act_buttons.append(b)

	# Depois da rodada de treino
	_practice_row = HBoxContainer.new()
	_practice_row.add_theme_constant_override("separation", 16)
	bottom.add_child(_practice_row)
	var b_again := UIKit.menu_button("TREINAR DE NOVO", Vector2(270, 58), UIKit.C_BORDER_GOLD, 20)
	b_again.pressed.connect(_start_practice)
	_practice_row.add_child(b_again)
	var b_cont := UIKit.menu_button("PRÓXIMO  ▶", Vector2(230, 58), UIKit.C_TEXT_GOLD, 20)
	b_cont.pressed.connect(func(): _show_step(_step + 1))
	_practice_row.add_child(b_cont)

	# Passo final
	_final_row = HBoxContainer.new()
	_final_row.add_theme_constant_override("separation", 16)
	bottom.add_child(_final_row)
	var b_menu := UIKit.menu_button("VOLTAR AO MENU", Vector2(270, 58), UIKit.C_BORDER_GOLD, 20)
	b_menu.pressed.connect(_exit_to_menu)
	_final_row.add_child(b_menu)
	var b_play := UIKit.menu_button("COMEÇAR CAMPANHA", Vector2(300, 58), UIKit.C_TEXT_GOLD, 20)
	b_play.pressed.connect(func(): UIKit.change_scene(self, GAME_SCENE))
	_final_row.add_child(b_play)

# ─────────────────────────────────────────────
#  PASSOS
# ─────────────────────────────────────────────
func _show_step(i: int) -> void:
	var prev_step := _step
	_step = clampi(i, 0, STEPS.size() - 1)
	var s: Dictionary = STEPS[_step]

	_lbl_step.text = "Passo %d de %d" % [_step + 1, STEPS.size()]
	for k in _dots.size():
		_dots[k].color = UIKit.C_BAR_ORANGE if k == _step else (UIKit.C_BORDER_GOLD if k < _step else UIKit.C_SEPARATOR)

	_lbl_title.text = s["title"]
	_rt_body.text = String(s["text"]).replace("{player}", str(_player_cells.size()))
	_highlight.set_focus(s.get("focus", Focus.NONE))

	var is_practice: bool = s.get("practice", false)
	var is_final: bool = s.get("final", false)

	_nav_row.visible = not is_practice and not is_final
	_action_row.visible = false
	_practice_row.visible = false
	_final_row.visible = is_final
	_btn_prev.disabled = _step == 0

	# Ao sair da rodada de treino, volta a esconder a malha inimiga num mapa novo
	if prev_step != _step and STEPS[prev_step].get("practice", false):
		_new_sample_map(false)
		_rt_body.text = String(s["text"]).replace("{player}", str(_player_cells.size()))

	_update_area_labels(false)

	if is_practice:
		_start_practice()
	elif is_final:
		Settings.mark_tutorial_seen()
		_final_row.get_child(1).grab_focus()
	else:
		_btn_next.grab_focus()

func _update_area_labels(reveal_enemy: bool) -> void:
	var focus: int = STEPS[_step].get("focus", Focus.NONE)
	var show_player: bool = focus == Focus.PLAYER or STEPS[_step].get("practice", false) or reveal_enemy
	_lbl_player.text = "SEU REINO: %d" % _player_cells.size() if show_player else "SEU REINO"
	_lbl_enemy.text = ("INIMIGO: %d" % _enemy_cells.size()) if reveal_enemy else "INIMIGO: ?"

func _start_practice() -> void:
	_practice_done = false
	_new_sample_map(true)
	_rt_body.text = STEPS[_step]["text"]
	_lbl_title.text = STEPS[_step]["title"]
	_highlight.set_focus(Focus.BOTH)
	_update_area_labels(false)
	_practice_row.visible = false
	_action_row.visible = true
	for b in _act_buttons:
		b.disabled = false
	_act_buttons[0].grab_focus()

func _on_practice_action(action: int) -> void:
	if _practice_done: return
	_practice_done = true
	for b in _act_buttons:
		b.disabled = true

	var p := _player_cells.size()
	var e := _enemy_cells.size()
	var player_bigger := p > e
	var result := "DRAW"
	match action:
		GameManager.Action.ATTACK:  result = "WIN" if player_bigger else "LOSE"
		GameManager.Action.DEFEND:  result = "WIN" if not player_bigger else "LOSE"

	if AudioManager:
		match action:
			GameManager.Action.ATTACK:  AudioManager.play_sfx("action_attack")
			GameManager.Action.DEFEND:  AudioManager.play_sfx("action_defend")
			GameManager.Action.RETREAT: AudioManager.play_sfx("action_retreat")

	await get_tree().create_timer(0.8).timeout
	_renderer.reveal_enemy_grid()
	_renderer.play_result_flash(result)
	if AudioManager: AudioManager.play_sfx("result_" + result.to_lower())
	_update_area_labels(true)
	_highlight.set_focus(Focus.NONE)

	_practice_total += 1
	if result == "WIN": _practice_wins += 1

	var diff_pct := absf(float(p - e)) / float(maxi(p, e)) * 100.0
	var right_choice := "[color=%s][b]ATACAR[/b][/color]" % RED if player_bigger else "[color=%s][b]DEFENDER[/b][/color]" % BLUE
	var head := ""
	match result:
		"WIN":  head = "[color=%s][b]Acertou![/b][/color] " % GREEN
		"LOSE": head = "[color=%s][b]Não foi dessa vez.[/b][/color] " % RED
		_:      head = "[color=%s][b]Você recuou.[/b][/color] Seguro, mas na campanha isso custa 5%% da área. " % GOLD

	_lbl_title.text = "Resultado do treino"
	_rt_body.text = head + "Seu reino tinha [color=%s][b]%d[/b][/color] quadrados e o inimigo [color=%s][b]%d[/b][/color] — diferença de [b]%s%%[/b]. A escolha certa era %s. Veja agora a malha inimiga revelada e confira.\nTreinos: [b]%d acerto(s) em %d[/b]." % [BLUE, p, RED, e, ("%.1f" % diff_pct).replace(".", ","), right_choice, _practice_wins, _practice_total]

	_action_row.visible = false
	_practice_row.visible = true
	_practice_row.get_child(1).grab_focus()

func _exit_to_menu() -> void:
	UIKit.change_scene(self, MENU_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_exit_to_menu()
		get_viewport().set_input_as_handled()
		return
	if _action_row.visible and not _practice_done:
		if event.is_action_pressed("ui_attack"):
			_on_practice_action(GameManager.Action.ATTACK)
		elif event.is_action_pressed("ui_defend"):
			_on_practice_action(GameManager.Action.DEFEND)
		elif event.is_action_pressed("ui_retreat"):
			_on_practice_action(GameManager.Action.RETREAT)
		return
	if _nav_row.visible:
		if event.is_action_pressed("ui_right"):
			_show_step(_step + 1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_left") and _step > 0:
			_show_step(_step - 1)
			get_viewport().set_input_as_handled()

# ─────────────────────────────────────────────
#  DESTAQUE PULSANTE SOBRE O MAPA
# ─────────────────────────────────────────────
class Highlighter extends Node2D:
	var cell : int = 40
	var cols : int = 32
	var rows : int = 13
	var focus : int = 0
	var _t : float = 0.0

	func set_focus(f: int) -> void:
		focus = f
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		if focus != 0:
			queue_redraw()

	func _draw() -> void:
		if focus == 0: return
		var half_w := float(cols / 2 * cell)
		var h := float(rows * cell)
		var a := 0.55 + 0.45 * sin(_t * 4.0)
		var rects: Array[Rect2] = []
		var colors: Array[Color] = []
		if focus == 1 or focus == 3:
			rects.append(Rect2(4, 4, half_w - 8, h - 8))
			colors.append(Color(0.47, 0.69, 1.0, a))
		if focus == 2 or focus == 3:
			rects.append(Rect2(half_w + 4, 4, half_w - 8, h - 8))
			colors.append(Color(0.88, 0.38, 0.38, a))
		for i in rects.size():
			draw_rect(rects[i], colors[i], false, 4.0)
