extends SceneTree

var runner: Node


func _initialize() -> void:
	var runner_scene: PackedScene = load("res://main.tscn")
	runner = runner_scene.instantiate()
	root.add_child(runner)
	_run_tests.call_deferred()


func _run_tests() -> void:
	await process_frame
	runner.set_physics_process(false)

	# Ground jump, one airborne reset, then no third jump.
	runner.jump_buffer_timer = 0.12
	runner._consume_jump_buffer()
	assert(is_equal_approx(runner.vertical_speed, -144.0))
	assert(runner.jumps_remaining == 1)
	runner.coyote_timer = 0.0
	runner.vertical_speed = -20.0
	runner.jump_buffer_timer = 0.12
	runner._consume_jump_buffer()
	assert(is_equal_approx(runner.vertical_speed, -144.0))
	assert(runner.jumps_remaining == 0)
	runner.vertical_speed = -30.0
	runner.jump_buffer_timer = 0.12
	runner._consume_jump_buffer()
	assert(is_equal_approx(runner.vertical_speed, -30.0))

	# Releasing jump early produces a much lower theoretical apex.
	var held_apex: float = runner.JUMP_SPEED * runner.JUMP_SPEED / (2.0 * runner.GRAVITY)
	var cut_speed: float = runner.JUMP_SPEED * runner.JUMP_CUT
	var tap_apex: float = cut_speed * cut_speed / (2.0 * runner.GRAVITY)
	assert(tap_apex < held_apex * 0.25)

	# Score components and final-score freeze.
	runner.reset_run()
	runner.player_pos.x = runner.PLAYER_START.x + 32.0
	runner.relic_count = 2
	runner.broken_count = 1
	assert(runner._current_score() == 170)
	runner._die()
	assert(runner.final_score == 170)
	runner.player_pos.x += 1000.0
	assert(runner._current_score() == 170)

	# Runestones are lethal normally and break exactly once while dashing.
	runner.reset_run()
	runner.runestones.clear()
	runner.runestones.append({"rect": runner._player_rect(), "broken": false})
	runner._check_runestones(false)
	assert(not runner.alive)
	runner.reset_run()
	runner.runestones.clear()
	runner.runestones.append({"rect": runner._player_rect(), "broken": false})
	runner._check_runestones(true)
	assert(runner.alive)
	assert(runner.broken_count == 1)
	assert(runner.runestones[0]["broken"])
	runner._check_runestones(true)
	assert(runner.broken_count == 1)

	# Retry restores every gameplay resource.
	runner.relic_count = 99
	runner.broken_count = 7
	runner.dash_cooldown = 0.4
	runner.jumps_remaining = 0
	runner.reset_run()
	assert(runner.relic_count == 0)
	assert(runner.broken_count == 0)
	assert(runner.jumps_remaining == 2)
	assert(runner.dash_cooldown == 0.0)
	assert(runner.camera_x == 0.0)
	assert(runner.alive and runner.player_visible)

	# At maximum difficulty, generated gaps remain within single-jump reach,
	# elevations stay bounded, and runestone cooldown spacing is preserved.
	runner.run_time = 120.0
	runner._generate_until(20000.0)
	var single_jump_reach: float = runner.RUN_SPEED_MAX * (2.0 * runner.JUMP_SPEED / runner.GRAVITY)
	for i in range(1, runner.platforms.size()):
		var previous: Rect2 = runner.platforms[i - 1]["rect"]
		var current: Rect2 = runner.platforms[i]["rect"]
		var gap: float = current.position.x - previous.end.x
		assert(gap <= single_jump_reach - 20.0)
		assert(absf(current.position.y - previous.position.y) <= 8.0)
		assert(current.position.y >= runner.INITIAL_TOP - runner.UNIT)
		assert(current.position.y <= runner.INITIAL_TOP + runner.UNIT)
	for i in range(1, runner.runestones.size()):
		var prior: Rect2 = runner.runestones[i - 1]["rect"]
		var current: Rect2 = runner.runestones[i]["rect"]
		assert(current.get_center().x - prior.get_center().x >= 12.9 * runner.UNIT)

	print("PIXEL_UNICORN_MECHANICS_OK platforms=%d runestones=%d reach=%.2f" % [runner.platforms.size(), runner.runestones.size(), single_jump_reach])
	quit()
