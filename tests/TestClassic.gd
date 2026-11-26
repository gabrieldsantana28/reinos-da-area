extends Node
const MAIN := preload("res://scenes/Main.tscn")
func _ready() -> void:
	Story.leave()
	Engine.time_scale = 40.0
	var m = MAIN.instantiate()
	add_child(m)
	var rounds := 0
	var wrong := 0
	while true:
		var f := 0
		while not (m._summary_open or (m.btn_row.visible and not m.btn_attack.disabled and m.game_manager.current_round == rounds + 1)) and f < 20000:
			await get_tree().process_frame
			f += 1
		if m._summary_open or f >= 20000: break
		rounds += 1
		var gm = m.game_manager
		var act = gm.Action.ATTACK if gm.player_area > gm.enemy_area else gm.Action.DEFEND
		m._on_action(act)
		while not m.result_vbox.visible: await get_tree().process_frame
		if m.lbl_result_title.text != "VITÓRIA": wrong += 1
		m._on_continue_pressed()
	print("classic: rounds=%d wrong=%d title=%s terrain=%s ratio=%s btn_next=%s story_lbl=%s" % [rounds, wrong, m.lbl_sum_title.text, m.lbl_terrain.text, m.game_manager.terrain_ratio, m.btn_next.visible, m.lbl_sum_story.visible])
	get_tree().quit()
