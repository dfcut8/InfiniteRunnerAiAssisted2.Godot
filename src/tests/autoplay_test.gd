extends SceneTree

const DELTA := 1.0 / 60.0
const TEST_SECONDS := 180.0

var runner: Node


func _initialize() -> void:
	var runner_scene: PackedScene = load("res://main.tscn")
	runner = runner_scene.instantiate()
	root.add_child(runner)
	_run_autoplay.call_deferred()


func _run_autoplay() -> void:
	await process_frame
	runner.set_physics_process(false)
	runner.rng.seed = 424242
	runner.reset_run()

	for tick in range(int(TEST_SECONDS / DELTA)):
		if runner.grounded:
			var edge_distance := INF
			for platform in runner.platforms:
				var rect: Rect2 = platform["rect"]
				if runner.player_pos.x >= rect.position.x and runner.player_pos.x <= rect.end.x:
					edge_distance = rect.end.x - runner.player_pos.x
					break
			if edge_distance <= 24.0:
				runner.jump_buffer_timer = runner.JUMP_BUFFER_TIME

		if runner.dash_remaining <= 0.0 and runner.dash_cooldown <= 0.0:
			for stone in runner.runestones:
				if stone["broken"]:
					continue
				var rect: Rect2 = stone["rect"]
				var distance: float = rect.get_center().x - runner.player_pos.x
				if distance > 0.0 and distance <= 32.0:
					runner.dash_remaining = runner.DASH_TIME
					runner.stored_dash_vertical_speed = runner.vertical_speed
					runner.vertical_speed = 0.0
					runner.afterimage_timer = 0.0
					break

		runner._physics_process(DELTA)
		if not runner.alive:
			push_error("Autoplay died unexpectedly at %.2fs, position %s" % [tick * DELTA, runner.player_pos])
			quit(1)
			return

	assert(runner.run_time >= TEST_SECONDS - DELTA)
	assert(runner.run_speed >= runner.RUN_SPEED_MAX - 0.01)
	assert(runner.platforms.size() < 10)
	assert(runner.relics.size() < 50)
	assert(runner._current_score() > 15000)
	print("PIXEL_UNICORN_AUTOPLAY_OK seconds=%.0f score=%d relics=%d broken=%d" % [runner.run_time, runner._current_score(), runner.relic_count, runner.broken_count])
	quit()
