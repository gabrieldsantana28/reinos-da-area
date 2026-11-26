## Settings.gd
## Autoload global: guarda e aplica as preferências do jogador e os recordes.
## Tudo é salvo em user://settings.cfg (veja a documentação para saber onde
## essa pasta fica em cada sistema operacional).

extends Node

signal changed

const SAVE_PATH := "user://settings.cfg"

enum Difficulty { EASY, NORMAL, HARD }

## Parâmetros de cada dificuldade.
## diff_min / diff_max: diferença de tamanho entre os territórios (0.10 = 10%).
## round_time: segundos para decidir em cada rodada.
const DIFFICULTY_PRESETS := {
	Difficulty.EASY:   {"name": "Fácil",   "diff_min": 0.12, "diff_max": 0.25, "round_time": 75.0,
		"desc": "Territórios bem diferentes (12% a 25%) e 75 s por rodada. Ideal para começar."},
	Difficulty.NORMAL: {"name": "Normal",  "diff_min": 0.05, "diff_max": 0.15, "round_time": 60.0,
		"desc": "Diferença de 5% a 15% e 60 s por rodada. A experiência original do jogo."},
	Difficulty.HARD:   {"name": "Difícil", "diff_min": 0.03, "diff_max": 0.08, "round_time": 40.0,
		"desc": "Diferença de apenas 3% a 8% e 40 s por rodada. Para olhos treinados."},
}

# Preferências (valores padrão)
var music_volume  : float = 0.8
var sfx_volume    : float = 0.9
var fullscreen    : bool  = true
var difficulty    : int   = Difficulty.NORMAL
var tutorial_seen : bool  = false

# Recordes
var best_score     : int   = 0
var best_dominance : float = 0.0
var campaigns_won  : int   = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	_apply_cursors()
	apply_all()

# ─────────────────────────────────────────────
#  SALVAR / CARREGAR
# ─────────────────────────────────────────────
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	music_volume   = clampf(cfg.get_value("audio", "music_volume", music_volume), 0.0, 1.0)
	sfx_volume     = clampf(cfg.get_value("audio", "sfx_volume", sfx_volume), 0.0, 1.0)
	fullscreen     = cfg.get_value("video", "fullscreen", fullscreen)
	difficulty     = clampi(cfg.get_value("game", "difficulty", difficulty), 0, 2)
	tutorial_seen  = cfg.get_value("game", "tutorial_seen", tutorial_seen)
	best_score     = cfg.get_value("records", "best_score", best_score)
	best_dominance = cfg.get_value("records", "best_dominance", best_dominance)
	campaigns_won  = cfg.get_value("records", "campaigns_won", campaigns_won)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("game", "difficulty", difficulty)
	cfg.set_value("game", "tutorial_seen", tutorial_seen)
	cfg.set_value("records", "best_score", best_score)
	cfg.set_value("records", "best_dominance", best_dominance)
	cfg.set_value("records", "campaigns_won", campaigns_won)
	cfg.save(SAVE_PATH)
	changed.emit()

func reset_to_defaults() -> void:
	music_volume = 0.8
	sfx_volume   = 0.9
	fullscreen   = true
	difficulty   = Difficulty.NORMAL
	apply_all()
	save_settings()

# ─────────────────────────────────────────────
#  APLICAR
# ─────────────────────────────────────────────
func apply_all() -> void:
	apply_audio()
	apply_window()

func apply_audio() -> void:
	if AudioManager:
		AudioManager.set_music_volume(music_volume)
		AudioManager.set_sfx_volume(sfx_volume)

func apply_window() -> void:
	# Em servidores sem tela (testes automáticos) não há janela para ajustar.
	if DisplayServer.get_name() == "headless":
		return
	var win := get_window()
	if fullscreen:
		win.mode = Window.MODE_FULLSCREEN
	else:
		win.mode = Window.MODE_WINDOWED
		var screen := DisplayServer.screen_get_usable_rect(win.current_screen)
		# 16:9 ocupando no máximo 85% da tela
		var w := mini(1600, int(screen.size.x * 0.85))
		var h := int(w * 9.0 / 16.0)
		if h > int(screen.size.y * 0.85):
			h = int(screen.size.y * 0.85)
			w = int(h * 16.0 / 9.0)
		win.size = Vector2i(w, h)
		win.position = screen.position + (screen.size - win.size) / 2

func _apply_cursors() -> void:
	var cursor_default = load("res://assets/cursor/default.png")
	if cursor_default:
		Input.set_custom_mouse_cursor(cursor_default, Input.CURSOR_ARROW, Vector2(0, 0))
	var cursor_pointer = load("res://assets/cursor/pointer.png")
	if cursor_pointer:
		Input.set_custom_mouse_cursor(cursor_pointer, Input.CURSOR_POINTING_HAND, Vector2(0, 0))

# ─────────────────────────────────────────────
#  SETTERS USADOS PELO MENU
# ─────────────────────────────────────────────
func set_music_volume(v: float) -> void:
	music_volume = clampf(v, 0.0, 1.0)
	apply_audio()
	save_settings()

func set_sfx_volume(v: float) -> void:
	sfx_volume = clampf(v, 0.0, 1.0)
	apply_audio()
	save_settings()

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	apply_window()
	save_settings()

func toggle_fullscreen() -> void:
	set_fullscreen(not fullscreen)

func set_difficulty(d: int) -> void:
	difficulty = clampi(d, 0, 2)
	save_settings()

func mark_tutorial_seen() -> void:
	if not tutorial_seen:
		tutorial_seen = true
		save_settings()

## Registra o fim de uma campanha. Devolve true se for um novo recorde de pontos.
func register_campaign(score: int, dominance: float, won: bool) -> bool:
	var new_record := score > best_score
	best_score     = maxi(best_score, score)
	best_dominance = maxf(best_dominance, dominance)
	if won:
		campaigns_won += 1
	save_settings()
	return new_record

func get_preset() -> Dictionary:
	return DIFFICULTY_PRESETS[difficulty]

func get_difficulty_name(d: int = -1) -> String:
	if d < 0: d = difficulty
	return DIFFICULTY_PRESETS[d]["name"]

# F11 alterna tela cheia em qualquer tela do jogo.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
