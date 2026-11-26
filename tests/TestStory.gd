extends Node
const TerritoryGenerator = preload("res://scripts/TerritoryGenerator.gd")
const MAIN := preload("res://scenes/Main.tscn")
var fails := 0

func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: ", msg)

func _ready() -> void:
	Story.reset_progress()
	_test_shapes()
	await _test_phases()
	Story.reset_progress()
	print("RESULT: ", "OK" if fails == 0 else "%d FAILS" % fails)
	get_tree().quit()

func _connected(cells: Dictionary) -> bool:
	if cells.is_empty(): return false
	var start: Vector2i = cells.keys()[0]
	var seen := {start: true}
	var q: Array[Vector2i] = [start]
	while q.size() > 0:
		var c: Vector2i = q.pop_back()
		for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var n: Vector2i = c + d
			if cells.has(n) and not seen.has(n):
				seen[n] = true
				q.append(n)
	return seen.size() == cells.size()

func _test_shapes() -> void:
	var g := TerritoryGenerator.new()
	g.grid_cols = 32; g.grid_rows = 13; g.min_cells = 10; g.max_cells = 200
	var exact := 0; var total := 0
	for kind in ["rect", "notched", "composite", "diagonal", "organic"]:
		for target in range(10, 101, 3):
			for rep in 4:
				var ox := 4 if rep % 2 == 0 else 16
				var cells := g.generate_shape(kind, target, ox, 12, 1)
				total += 1
				if cells.size() == target: exact += 1
				check(cells.size() == target, "%s target %d got %d" % [kind, target, cells.size()])
				check(_connected(cells), "%s target %d not connected" % [kind, target])
				for k in cells.keys():
					var c: Vector2i = k
					check(c.x >= ox + 1 and c.x < ox + 11 and c.y >= 1 and c.y < 12, "%s out of region %s" % [kind, c])
	print("shapes exact: %d / %d" % [exact, total])

func _wait(cond: Callable, max_frames := 20000) -> bool:
	var f := 0
	while not cond.call() and f < max_frames:
		await get_tree().process_frame
		f += 1
	return f < max_frames

func _play_phase(n: int, wrong_at_round: int = -1) -> Dictionary:
	Story.start_phase(n)
	var m = MAIN.instantiate()
	add_child(m)
	check(await _wait(func(): return m._intro_open), "phase %d intro never opened" % n)
	m._close_intro()
	var rounds := 0
	var info := {"terrains": {}, "areas": []}
	while true:
		var ok := await _wait(func(): return m._summary_open or (m.btn_row.visible and not m.btn_attack.disabled and m.game_manager.current_phase != 2 and m.game_manager.current_round == rounds + 1))
		check(ok, "phase %d stuck at round %d" % [n, rounds])
		if not ok or m._summary_open: break
		rounds += 1
		var gm = m.game_manager
		var p: float = gm.player_area
		var e: float = gm.enemy_area
		var r: float = gm.terrain_ratio
		info["terrains"][m._round_terrain] = true
		info["areas"].append([int(p), int(e), r])
		check(absf(p - e * r) >= 0.5, "phase %d tie p=%s e=%s r=%s" % [n, p, e, r])
		check(is_equal_approx(r, Story.terrain_ratio(m._round_terrain)), "ratio mismatch")
		var correct = gm.Action.ATTACK if p > e * r else gm.Action.DEFEND
		var act = correct
		if rounds == wrong_at_round:
			act = gm.Action.DEFEND if correct == gm.Action.ATTACK else gm.Action.ATTACK
		m._on_action(act)
		check(await _wait(func(): return m.result_vbox.visible), "phase %d no result" % n)
		var expected := "VITÓRIA" if act == correct else "DERROTA"
		check(m.lbl_result_title.text == expected, "phase %d round %d expected %s got %s" % [n, rounds, expected, m.lbl_result_title.text])
		m._on_continue_pressed()
	info["rounds"] = rounds
	info["title"] = m.lbl_sum_title.text
	info["stars"] = Story.stars[n]
	info["next_visible"] = m.btn_next.visible
	info["story"] = m.lbl_sum_story.text
	info["world"] = m.lbl_world_phase.text
	m.queue_free()
	get_tree().paused = false
	await get_tree().process_frame
	return info

func _test_phases() -> void:
	Engine.time_scale = 40.0
	for n in [1, 5, 6, 9, 10, 13, 17]:
		var i := await _play_phase(n)
		print("phase %d: rounds=%d stars=%d title=%s terrains=%s world=%s" % [n, i["rounds"], i["stars"], i["title"], i["terrains"].keys(), i["world"]])
		check(i["rounds"] == 10 and i["stars"] == 3, "phase %d perfect play should give 3 stars" % n)
		check(i["next_visible"], "phase %d next button" % n)
		check(Story.is_unlocked(n + 1), "phase %d+1 unlocked" % n)
		print("   sample areas: ", i["areas"].slice(0, 4))
	# Morte súbita: erro na rodada 3 encerra a fase 20
	var s := await _play_phase(20, 3)
	print("phase 20 sudden: rounds=%d stars=%d title=%s story=%s" % [s["rounds"], s["stars"], s["title"], s["story"]])
	check(s["rounds"] == 3 and s["stars"] == 0 and s["title"] == "FASE FRACASSADA", "sudden death")
	# Fase 20 perfeita: epílogo
	var w := await _play_phase(20)
	print("phase 20 win: stars=%d next=%s story=%s" % [w["stars"], w["next_visible"], w["story"].substr(0, 40)])
	check(w["stars"] == 3 and not w["next_visible"] and Story.finished, "phase 20 win")
	# Fase com uma derrota: 2 estrelas
	var d := await _play_phase(2, 5)
	print("phase 2 one loss: stars=%d" % d["stars"])
	check(d["stars"] == 2, "one loss -> 2 stars")
	Engine.time_scale = 1.0
