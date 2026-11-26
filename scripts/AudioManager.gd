## AudioManager.gd
## Autoload global para tocar efeitos sonoros e músicas sem interrupções.
## Usa dois barramentos de áudio próprios ("Music" e "SFX"), criados em tempo
## de execução, para que o volume de cada um possa ser ajustado no menu Opções.

extends Node

const BUS_MUSIC := "Music"
const BUS_SFX   := "SFX"
const MUSIC_BASE_DB := -15.0   # volume base da música (antes do ajuste do jogador)

# Dicionário centralizando os caminhos dos arquivos de áudio.
var _sounds := {
	# Músicas
	"bg_music": "res://assets/audios/background.mp3",
	"phase_win": "res://assets/audios/resumo_vitoria.mp3",
	"phase_lose": "res://assets/audios/resumo_derrota.mp3",

	# Interface
	"ui_hover": "res://assets/audios/hover.mp3",
	"ui_click": "res://assets/audios/click.mp3",

	# Ações da Rodada
	"map_unroll": "res://assets/audios/inicio_da_rodada.mp3",
	"action_attack": "res://assets/audios/atacar.mp3",
	"action_defend": "res://assets/audios/defender.mp3",
	"action_retreat": "res://assets/audios/recuar.mp3",
	"timer_tick": "res://assets/audios/tempo_esgotando.mp3",

	# Resultados
	"result_win": "res://assets/audios/brilho_da_vitoria.mp3",
	"result_lose": "res://assets/audios/derrota.mp3",
	"result_draw": "res://assets/audios/vento.mp3"
}

# Cache para armazenar os AudioStreams já carregados
var _loaded_streams := {}

# Players
var bgm_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
const POOL_SIZE = 8 # Quantidade de sons simultâneos permitidos

func _ready() -> void:
	# Continua tocando (e permite cliques no menu de pausa) com o jogo pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)

	# Pré-carrega todos os áudios para não dar travadinhas no jogo
	for key in _sounds.keys():
		var path = _sounds[key]
		if ResourceLoader.exists(path):
			_loaded_streams[key] = load(path)
		else:
			push_warning("AudioManager: Áudio não encontrado no caminho: " + path)

	# A música de fundo deve repetir. MP3 aceita loop direto no stream.
	var bg = _loaded_streams.get("bg_music")
	if bg is AudioStreamMP3:
		bg.loop = true

	# Player de música de fundo
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = BUS_MUSIC
	bgm_player.volume_db = MUSIC_BASE_DB
	add_child(bgm_player)

	# Pool de players de efeitos sonoros
	for i in POOL_SIZE:
		var p = AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		sfx_pool.append(p)

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")

# Toca um efeito sonoro na primeira "fenda" livre da pool
func play_sfx(sound_name: String, pitch_randomness: float = 0.0) -> void:
	if not _loaded_streams.has(sound_name): return

	for p in sfx_pool:
		if not p.playing:
			p.stream = _loaded_streams[sound_name]
			if pitch_randomness > 0.0:
				p.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)
			else:
				p.pitch_scale = 1.0
			p.play()
			return

# Toca uma música de fundo (interrompendo a anterior)
func play_music(sound_name: String) -> void:
	if not _loaded_streams.has(sound_name): return
	if bgm_player.stream == _loaded_streams[sound_name] and bgm_player.playing: return

	bgm_player.stream = _loaded_streams[sound_name]
	bgm_player.play()

# Para a música de fundo
func stop_music() -> void:
	bgm_player.stop()

func set_bgm_volume(volume_db: float) -> void:
	if bgm_player:
		bgm_player.volume_db = volume_db

## Volume linear de 0.0 a 1.0 para cada barramento (usado pelo menu Opções).
func set_music_volume(linear: float) -> void:
	_set_bus_linear(BUS_MUSIC, linear)

func set_sfx_volume(linear: float) -> void:
	_set_bus_linear(BUS_SFX, linear)

func _set_bus_linear(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1: return
	linear = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))
