## Story.gd
## Autoload do MODO HISTÓRIA: define os 5 cenários e as 20 fases do GDD,
## guarda a fase escolhida e o progresso (estrelas) em user://story.cfg.
## A campanha clássica não usa nada daqui (Story.active fica false).

extends Node

const SAVE_PATH := "user://story.cfg"
const TOTAL_PHASES := 20
const STORY_SCENE := "res://scenes/StoryMap.tscn"

# ─────────────────────────────────────────────
#  TERRENOS (GDD, seção 4: modificadores de terreno)
#  def = multiplicador de quem defende; atk = de quem ataca.
#  A razão def/atk muda o limiar da comparação de áreas, sem aleatoriedade.
# ─────────────────────────────────────────────
const TERRAINS := {
	"plain": {"name": "Planície", "def": 1.0,  "atk": 1.0},
	"serra": {"name": "Serra",    "def": 1.25, "atk": 0.85},
	"coast": {"name": "Costeiro", "def": 0.90, "atk": 1.10},
}

# ─────────────────────────────────────────────
#  CENÁRIOS (GDD, seções 8, 10 e 11)
#  shape: forma dos reinos · ref_grid: 0 grid inteiro ao redor do inimigo,
#  1 só 1 célula ao redor, 2 sem grid · round_time: 0 = tempo da dificuldade
# ─────────────────────────────────────────────
const SCENARIOS := [
	{"num": "I", "name": "Planícies de Aldrath", "first": 1, "last": 4,
	 "shape": "rect", "ref_grid": 0, "round_time": 0.0, "diff_factor": 1.3, "start_area": [16, 24],
	 "tint": Color(1.0, 0.96, 0.86), "overlay": Color(1.0, 0.85, 0.55, 0.06),
	 "text": "Campos abertos e castelos de pedra simples. Aqui os reinos são retangulares e o grid ao redor do inimigo ajuda a medir. A Cartógrafa acompanha você em todas as fases."},
	{"num": "II", "name": "Vales de Kheldorn", "first": 5, "last": 8,
	 "shape": "notched", "ref_grid": 1, "round_time": 0.0, "diff_factor": 1.1, "start_area": [26, 36],
	 "tint": Color(0.80, 0.85, 0.88), "overlay": Color(0.62, 0.68, 0.74, 0.38),
	 "text": "Vales profundos e fortalezas sobre penhascos. As quinas ficam irregulares, o grid de referência encolhe para uma célula e surge a Serra: quem defende no alto vale mais."},
	{"num": "III", "name": "Serra das Pedras Vivas", "first": 9, "last": 12,
	 "shape": "composite", "ref_grid": 2, "round_time": 0.0, "diff_factor": 1.0, "start_area": [32, 44],
	 "tint": Color(0.55, 0.72, 0.55), "overlay": Color(0.02, 0.12, 0.05, 0.30),
	 "text": "Floresta densa e reinos em forma de L. Não há mais grid ao redor do inimigo: divida a forma em partes, conte e some. A partir da Fase 10, a Cartógrafa não fala mais."},
	{"num": "IV", "name": "Arquipélago do Oblívio", "first": 13, "last": 16,
	 "shape": "diagonal", "ref_grid": 2, "round_time": 45.0, "diff_factor": 0.9, "start_area": [36, 48],
	 "tint": Color(0.60, 0.62, 0.95), "overlay": Color(0.16, 0.12, 0.42, 0.40),
	 "text": "Ilhas ligadas por pontes de cristal, com bordas em degrau. Na costa o atacante leva vantagem. Você tem no máximo 45 segundos por rodada."},
	{"num": "V", "name": "Abismo Irregular", "first": 17, "last": 20,
	 "shape": "organic", "ref_grid": 2, "round_time": 30.0, "diff_factor": 0.8, "start_area": [40, 55],
	 "tint": Color(0.80, 0.78, 0.72), "overlay": Color(0.27, 0.26, 0.29, 0.66),
	 "text": "Ruínas de uma civilização geométrica, território do Império das Formas. Formas sem padrão, terrenos misturados e 30 segundos por rodada. Na Fase 20, a primeira derrota encerra a fase."},
]

# terrains: um item = terreno fixo; vários = sorteado a cada rodada.
const PHASES := [
	{"title": "Os primeiros marcos",          "terrains": ["plain"]},
	{"title": "As quatro torres de Aldrasq",  "terrains": ["plain"]},
	{"title": "Fronteira do Ducado de Kermith", "terrains": ["plain"]},
	{"title": "Senhor das Planícies",          "terrains": ["plain"]},
	{"title": "Névoa nos vales",               "terrains": ["plain"]},
	{"title": "Fortalezas no penhasco",        "terrains": ["serra"]},
	{"title": "Pontes de pedra",               "terrains": ["plain", "serra"]},
	{"title": "O passo de Kheldorn",           "terrains": ["serra"]},
	{"title": "Entre as árvores",              "terrains": ["plain", "serra"]},
	{"title": "Sem a Cartógrafa",              "terrains": ["plain", "serra"]},
	{"title": "Reinos em L",                   "terrains": ["serra", "plain"]},
	{"title": "O coração da Serra",            "terrains": ["serra"]},
	{"title": "Pontes de cristal",             "terrains": ["coast"]},
	{"title": "Maré alta",                     "terrains": ["coast"]},
	{"title": "Ilhas à deriva",                "terrains": ["coast", "plain"]},
	{"title": "O farol do Oblívio",            "terrains": ["coast", "plain"]},
	{"title": "Ruínas do Abismo",              "terrains": ["plain", "serra", "coast"]},
	{"title": "Polígonos sem nome",            "terrains": ["plain", "serra", "coast"]},
	{"title": "Às portas do Império",          "terrains": ["serra", "coast"]},
	{"title": "Morte Súbita",                  "terrains": ["plain", "serra", "coast"], "sudden_death": true},
]

const PROLOGUE := "No continente de Geometria, a força de um reino nunca foi medida por exércitos, mas pela extensão de suas terras. Durante séculos, as Leis da Forma mantiveram a paz: toda disputa era resolvida comparando áreas.\n\nO equilíbrio se rompeu quando o Império das Formas Irregulares começou a engolir os reinos vizinhos, com territórios deformados de propósito para que ninguém conseguisse calcular sua força.\n\nVocê é o Arquiteto-Rei, herdeiro de um pequeno reino retangular nas Planícies de Aldrath. Guiado pela Cartógrafa, atravesse os cinco cenários do continente e prove que a área de um território é a sua maior arma."

const EPILOGUE := "O Império das Formas recuou. Com o olhar treinado, o Arquiteto-Rei devolveu as Leis da Forma ao continente de Geometria. O mapa agora tem a sua forma."

const FAREWELL := "Daqui em diante... você segue sem mim. Confie no que aprendeu a ver."

# ─────────────────────────────────────────────
#  ESTADO
# ─────────────────────────────────────────────
var active        : bool = false   # true enquanto uma fase da história está em jogo
var current_phase : int  = 1
var stars         : Array = []     # índice 1..20 → 0..3
var prologue_seen : bool = false
var finished      : bool = false   # zerou a Fase 20

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stars.resize(TOTAL_PHASES + 1)
	stars.fill(0)
	load_progress()

func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	for i in range(1, TOTAL_PHASES + 1):
		stars[i] = clampi(int(cfg.get_value("stars", "phase_%d" % i, 0)), 0, 3)
	prologue_seen = cfg.get_value("story", "prologue_seen", false)
	finished = cfg.get_value("story", "finished", false)

func save_progress() -> void:
	var cfg := ConfigFile.new()
	for i in range(1, TOTAL_PHASES + 1):
		cfg.set_value("stars", "phase_%d" % i, stars[i])
	cfg.set_value("story", "prologue_seen", prologue_seen)
	cfg.set_value("story", "finished", finished)
	cfg.save(SAVE_PATH)

func reset_progress() -> void:
	stars.fill(0)
	prologue_seen = false
	finished = false
	save_progress()

# ─────────────────────────────────────────────
#  CONSULTAS
# ─────────────────────────────────────────────
func get_phase(n: int) -> Dictionary:
	return PHASES[clampi(n, 1, TOTAL_PHASES) - 1]

func scenario_index(n: int) -> int:
	return clampi((n - 1) / 4, 0, SCENARIOS.size() - 1)

func get_scenario(n: int) -> Dictionary:
	return SCENARIOS[scenario_index(n)]

## Uma fase fica liberada quando a anterior foi concluída (pelo menos 1 estrela).
func is_unlocked(n: int) -> bool:
	return n == 1 or (n >= 2 and n <= TOTAL_PHASES and stars[n - 1] > 0)

func total_stars() -> int:
	var t := 0
	for i in range(1, TOTAL_PHASES + 1):
		t += stars[i]
	return t

## "active": comenta antes de cada rodada e reage ao resultado (Fases 1–6)
## "silent": aparece, mas só comenta nas derrotas (Fases 7–9)
## "absent": não aparece (Fase 10 em diante) — GDD, seção 16
func cartographer_mode(n: int) -> String:
	if n <= 6: return "active"
	if n <= 9: return "silent"
	return "absent"

func terrain_ratio(key: String) -> float:
	var t: Dictionary = TERRAINS.get(key, TERRAINS["plain"])
	return float(t["def"]) / float(t["atk"])

## Estrelas da fase: 1 = concluiu (Domínio ≥ 70%), 2 = Domínio ≥ 80%,
## 3 = Domínio ≥ 80% sem nenhuma derrota (GDD, seção 7: bronze, prata, ouro).
func compute_stars(dominance: float, losses: int) -> int:
	if dominance < 70.0: return 0
	var s := 1
	if dominance >= 80.0:
		s = 2
		if losses == 0:
			s = 3
	return s

## Guarda o resultado; devolve true se melhorou o recorde de estrelas da fase.
func register_result(n: int, got_stars: int) -> bool:
	var improved: bool = got_stars > stars[n]
	stars[n] = maxi(stars[n], got_stars)
	if n == TOTAL_PHASES and got_stars > 0:
		finished = true
	save_progress()
	return improved

func start_phase(n: int) -> void:
	active = true
	current_phase = clampi(n, 1, TOTAL_PHASES)

func leave() -> void:
	active = false

# ─────────────────────────────────────────────
#  FALAS DA CARTÓGRAFA (dicas sem nunca dar a resposta)
# ─────────────────────────────────────────────
const LINES_SHAPE := {
	"rect":      ["Um reino retangular: conte os quadrados de uma linha e quantas linhas existem.",
				  "Use o grid ao redor do inimigo como régua. Compare larguras e alturas.",
				  "Retângulos não enganam: largura vezes altura."],
	"notched":   ["Quinas faltando enganam o olhar. Imagine o retângulo inteiro e desconte os cantos.",
				  "Só resta uma faixa de grid ao redor do inimigo. Use-a para medir a primeira linha."],
	"composite": ["Formas em L escondem dois reinos em um. Divida, conte cada parte e some."],
	"diagonal":  ["Bordas em degrau: compare as linhas mais longas com as mais curtas."],
	"organic":   ["Sem padrão algum. Procure blocos que você saiba contar."],
}
const LINES_TERRAIN := {
	"serra": "Na Serra, quem defende vale mais. Um reino menor pode resistir ao seu ataque.",
	"coast": "Na costa, o atacante leva vantagem. Um reino um pouco maior ainda pode cair.",
}
const LINES_RESULT := {
	"WIN":  ["Muito bem. Você viu o que precisava ver.", "Bela leitura. O mapa já tem mais azul."],
	"LOSE": ["Olhe o grid agora. Onde o seu olhar falhou?", "Conte de novo, com calma. A forma não mente."],
	"DRAW": ["Recuar também é estratégia. Mas não o tempo todo."],
}

func line_before_round(shape: String, terrain: String) -> String:
	if terrain in LINES_TERRAIN and randf() < 0.6:
		return LINES_TERRAIN[terrain]
	var pool: Array = LINES_SHAPE.get(shape, LINES_SHAPE["organic"])
	return pool[randi() % pool.size()]

func line_after_result(result: String) -> String:
	var pool: Array = LINES_RESULT.get(result, LINES_RESULT["DRAW"])
	return pool[randi() % pool.size()]
