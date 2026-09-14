extends SceneTree

var runner: Node

func _initialize() -> void:
	var runner_scene: PackedScene = load("res://main.tscn")
	runner = runner_scene.instantiate()
	root.add_child(runner)
	_run_assertions.call_deferred()


func _run_assertions() -> void:
	await process_frame
	assert(runner.platforms.size() >= 2)
	assert(runner.relics.size() >= 10)
	assert(runner.alive)
	assert(runner.jumps_remaining == 2)
	assert(is_equal_approx(runner.dash_cooldown, 0.0))
	print("PIXEL_UNICORN_SMOKE_OK platforms=%d relics=%d" % [runner.platforms.size(), runner.relics.size()])
	quit()
