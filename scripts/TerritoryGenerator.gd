## TerritoryGenerator.gd
## Gera territórios orgânicos alinhados ao grid usando expansão celular.
## Retorna um Set de células (Vector2i) que representa o território.

extends RefCounted

# ─────────────────────────────────────────────
#  CONFIGURAÇÃO
# ─────────────────────────────────────────────
var grid_cols    : int   = 20
var grid_rows    : int   = 16
var min_cells    : int   = 40
var max_cells    : int   = 80
var seed_value   : int   = 0   # 0 = aleatório

const DIRECTIONS := [
	Vector2i( 1,  0),
	Vector2i(-1,  0),
	Vector2i( 0,  1),
	Vector2i( 0, -1),
]

var _rng : RandomNumberGenerator

func _init() -> void:
	_rng = RandomNumberGenerator.new()

## Gera um território com tamanho alvo (em células).
## region_offset_x: coluna inicial da região disponível (0 = lado esquerdo)
## region_width: largura máxima em colunas para este território
func generate(
	target_cells  : int,
	region_offset_x : int,
	region_width    : int,
	margin          : int = 1
) -> Dictionary:

	if seed_value != 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()

	target_cells = clampi(target_cells, min_cells, max_cells)

	# Ponto de semente no centro da região
	var seed_col := region_offset_x + margin + _rng.randi_range(
		region_width / 4,
		region_width * 3 / 4
	)
	var seed_row := margin + _rng.randi_range(grid_rows / 4, grid_rows * 3 / 4)
	seed_col = clampi(seed_col, region_offset_x + margin, region_offset_x + region_width - margin - 1)
	seed_row = clampi(seed_row, margin, grid_rows - margin - 1)

	var occupied  : Dictionary = {}   # Vector2i -> true
	var frontier  : Array[Vector2i] = []
	var start_cell := Vector2i(seed_col, seed_row)
	occupied[start_cell] = true
	frontier.append(start_cell)

	# Expansão BFS com peso aleatório para forma orgânica
	while occupied.size() < target_cells and frontier.size() > 0:
		# Embaralha a fronteira para crescimento irregular
		_shuffle_array(frontier)
		var current : Vector2i = frontier.pop_front()

		for dir in DIRECTIONS:
			if occupied.size() >= target_cells:
				break
			var neighbor: Vector2i = current + dir
			if _in_region(neighbor, region_offset_x, region_width, margin) \
			   and not occupied.has(neighbor):
				# Probabilidade de expansão decresce com distância do centro (forma blob)
				var dist_factor := _dist_weight(neighbor, start_cell, region_width)
				if _rng.randf() < dist_factor:
					occupied[neighbor] = true
					frontier.append(neighbor)

	# Se não chegou ao alvo, completa com BFS puro
	if occupied.size() < target_cells:
		_fill_remaining(occupied, frontier, target_cells, region_offset_x, region_width, margin)

	return occupied

# ─────────────────────────────────────────────
#  HELPERS INTERNOS
# ─────────────────────────────────────────────
func _in_region(cell: Vector2i, ox: int, rw: int, margin: int) -> bool:
	return (
		cell.x >= ox + margin and
		cell.x <  ox + rw - margin and
		cell.y >= margin and
		cell.y <  grid_rows - margin
	)

func _dist_weight(cell: Vector2i, origin: Vector2i, region_width: int) -> float:
	var dist := float(cell.distance_to(origin))
	var max_d := float(region_width) * 0.6
	return clampf(1.0 - (dist / max_d) * 0.3, 0.45, 1.0)

func _fill_remaining(
	occupied : Dictionary,
	frontier : Array[Vector2i],
	target   : int,
	ox: int, rw: int, margin: int
) -> void:
	# Reconstrói fronteira com todos os vizinhos não ocupados das células atuais
	var new_frontier : Array[Vector2i] = []
	for cell in occupied.keys():
		for dir in DIRECTIONS:
			var nb : Vector2i = cell + dir
			if _in_region(nb, ox, rw, margin) and not occupied.has(nb):
				if not new_frontier.has(nb):
					new_frontier.append(nb)
	_shuffle_array(new_frontier)
	for nb in new_frontier:
		if occupied.size() >= target:
			break
		occupied[nb] = true

# ─────────────────────────────────────────────
#  FORMAS DO MODO HISTÓRIA (GDD, seção 8)
#  Cada forma devolve exatamente target_cells células (quando cabem na região).
#  kind: "rect" | "notched" | "composite" | "diagonal" | "organic"
# ─────────────────────────────────────────────
func generate_shape(kind: String, target_cells: int, region_offset_x: int, region_width: int, margin: int = 1) -> Dictionary:
	_rng.randomize()
	target_cells = clampi(target_cells, min_cells, max_cells)
	var rw := region_width - margin * 2
	var rh := grid_rows - margin * 2
	target_cells = mini(target_cells, rw * rh)
	var local: Array[Vector2i] = []
	match kind:
		"rect":      local = _shape_rect(target_cells, rw, rh)
		"notched":   local = _shape_notched(target_cells, rw, rh)
		"composite": local = _shape_composite(target_cells, rw, rh)
		"diagonal":  local = _shape_diagonal(target_cells, rw, rh)
	if local.is_empty() or local.size() != target_cells:
		return generate(target_cells, region_offset_x, region_width, margin)
	return _place(local, region_offset_x + margin, margin, rw, rh)

## Translada a forma local para uma posição aleatória dentro da região.
func _place(local: Array[Vector2i], x0: int, y0: int, rw: int, rh: int) -> Dictionary:
	var minx := 999; var miny := 999; var maxx := -999; var maxy := -999
	for c in local:
		minx = mini(minx, c.x); miny = mini(miny, c.y)
		maxx = maxi(maxx, c.x); maxy = maxi(maxy, c.y)
	var w := maxx - minx + 1
	var h := maxy - miny + 1
	var ox := x0 + _rng.randi_range(0, maxi(0, rw - w))
	var oy := y0 + _rng.randi_range(0, maxi(0, rh - h))
	var out: Dictionary = {}
	for c in local:
		out[Vector2i(c.x - minx + ox, c.y - miny + oy)] = true
	return out

## Escolhe largura e altura de um retângulo que comporte n células.
func _pick_dims(n: int, rw: int, rh: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_score := 1e9
	var aspect := _rng.randf_range(0.7, 1.6)
	for w in range(2, rw + 1):
		var h := int(ceil(float(n) / float(w)))
		if h > rh or h < 2: continue
		var score := absf(float(w) - float(h) * aspect) + float(w * h - n) * 0.6
		if score < best_score:
			best_score = score
			best = Vector2i(w, h)
	return best

## Retângulo (a última linha pode ficar incompleta).
func _shape_rect(n: int, rw: int, rh: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var d := _pick_dims(n, rw, rh)
	if d.x < 0: return out
	for y in d.y:
		for x in d.x:
			if out.size() < n: out.append(Vector2i(x, y))
	return out

## Retângulo com quinas recortadas (Vales de Kheldorn).
func _shape_notched(n: int, rw: int, rh: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var extra := _rng.randi_range(2, 4)
	var d := _pick_dims(n + extra, rw, rh)
	if d.x < 3 or d.y < 3: return _shape_rect(n, rw, rh)
	var cells: Dictionary = {}
	for y in d.y:
		for x in d.x:
			cells[Vector2i(x, y)] = true
	# Remove células a partir dos quatro cantos, em rodízio, até chegar a n
	var corners := [Vector2i(0, 0), Vector2i(d.x - 1, 0), Vector2i(0, d.y - 1), Vector2i(d.x - 1, d.y - 1)]
	var steps := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 0)]
	var depth := [0, 0, 0, 0]
	var order := [0, 1, 2, 3]
	order.shuffle()
	var k := 0
	var guard := 0
	while cells.size() > n and guard < 200:
		guard += 1
		var ci: int = order[k % 4]
		var cell: Vector2i = corners[ci] + steps[ci] * depth[ci]
		depth[ci] += 1
		if depth[ci] > maxi(1, d.x / 3): depth[ci] = maxi(1, d.x / 3)
		if cells.has(cell): cells.erase(cell)
		k += 1
	for c in cells.keys(): out.append(c)
	if out.size() != n: return _shape_rect(n, rw, rh)
	return out

## Forma em L (Serra das Pedras Vivas): dois braços que crescem a partir de um canto.
func _shape_composite(n: int, rw: int, rh: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var t := _rng.randi_range(2, 4)
	while t * rh + t * (rw - t) < n and t < mini(rw, rh) - 1:
		t += 1
	if t * rh + t * (rw - t) < n: return out
	# ordem: bloco do canto, depois linhas do braço vertical e colunas do horizontal, alternadas
	var seq: Array[Vector2i] = []
	for y in t:
		for x in t:
			seq.append(Vector2i(x, rh - 1 - y))
	var up := t
	var right := t
	while up < rh or right < rw:
		if up < rh:
			for x in t: seq.append(Vector2i(x, rh - 1 - up))
			up += 1
		if right < rw:
			for y in t: seq.append(Vector2i(right, rh - 1 - y))
			right += 1
	var flip_x := _rng.randf() < 0.5
	var flip_y := _rng.randf() < 0.5
	for i in mini(n, seq.size()):
		var c: Vector2i = seq[i]
		if flip_x: c.x = rw - 1 - c.x
		if flip_y: c.y = rh - 1 - c.y
		out.append(c)
	return out

## Losango / paralelogramo em degraus (Arquipélago do Oblívio).
func _shape_diagonal(n: int, rw: int, rh: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var cx := (rw - 1) / 2.0
	var cy := (rh - 1) / 2.0
	var a := _rng.randf_range(0.8, 1.3)
	var skew: float = [-0.6, 0.0, 0.6][_rng.randi_range(0, 2)]
	var scored: Array = []
	for y in rh:
		for x in rw:
			var dx := float(x) - cx
			var dy := float(y) - cy
			var m := absf(dx + skew * dy) / a + absf(dy) + _rng.randf() * 0.01
			scored.append([m, Vector2i(x, y)])
	scored.sort_custom(func(p, q): return p[0] < q[0])
	for i in mini(n, scored.size()):
		out.append(scored[i][1])
	return out

func _shuffle_array(arr: Array[Vector2i]) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: Vector2i = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
