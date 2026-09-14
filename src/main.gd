extends Node2D

## Pixel Unicorn Runner: a self-contained, fixed-timestep endless runner.
## World units are logical pixels (16 pixels = one gameplay unit).

const VIEW_SIZE := Vector2(320.0, 180.0)
const UNIT := 16.0
const INITIAL_TOP := 132.0
const PLAYER_START := Vector2(32.0, INITIAL_TOP)

const RUN_SPEED_MIN := 5.0 * UNIT
const RUN_SPEED_MAX := 9.0 * UNIT
const SPEED_RAMP_SECONDS := 120.0
const JUMP_SPEED := 9.0 * UNIT
const GRAVITY := 28.0 * UNIT
const JUMP_CUT := 0.45
const COYOTE_TIME := 0.10
const JUMP_BUFFER_TIME := 0.12
const DASH_TIME := 0.20
const DASH_COOLDOWN := 0.70
const DEATH_FALL_Y := INITIAL_TOP + 6.0 * UNIT

const C_NEAR_BLACK := Color("101419")
const C_CHARCOAL := Color("252d32")
const C_STONE := Color("59615d")
const C_BROWN := Color("594b36")
const C_GOLD := Color("b58a43")
const C_MOSS := Color("628548")
const C_PALE := Color("b5cf83")
const C_IVORY := Color("f3efd9")

const FONT: Dictionary = {
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	"B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
	"C": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
	"D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
	"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
	"F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
	"G": ["01111", "10000", "10000", "10111", "10001", "10001", "01111"],
	"H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"J": ["00111", "00010", "00010", "00010", "10010", "10010", "01100"],
	"K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
	"L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
	"M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
	"N": ["10001", "11001", "11001", "10101", "10011", "10011", "10001"],
	"O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
	"P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
	"Q": ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
	"R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
	"S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
	"T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
	"U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
	"V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
	"W": ["10001", "10001", "10001", "10101", "10101", "10101", "01010"],
	"X": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
	"Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
	"Z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
	"0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
	"1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
	"2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
	"3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
	"4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
	"5": ["11111", "10000", "10000", "11110", "00001", "00001", "11110"],
	"6": ["01110", "10000", "10000", "11110", "10001", "10001", "01110"],
	"7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
	"8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
	"9": ["01110", "10001", "10001", "01111", "00001", "00001", "01110"],
	"/": ["00001", "00010", "00010", "00100", "01000", "01000", "10000"],
	"-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
	" ": ["00000", "00000", "00000", "00000", "00000", "00000", "00000"],
}

var rng := RandomNumberGenerator.new()
var platforms: Array[Dictionary] = []
var relics: Array[Dictionary] = []
var runestones: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var afterimages: Array[Dictionary] = []

var player_pos := PLAYER_START
var vertical_speed := 0.0
var stored_dash_vertical_speed := 0.0
var camera_x := 0.0
var run_time := 0.0
var run_speed := RUN_SPEED_MIN
var coyote_timer := COYOTE_TIME
var jump_buffer_timer := 0.0
var jumps_remaining := 2
var dash_remaining := 0.0
var dash_cooldown := 0.0
var afterimage_timer := 0.0
var death_timer := 0.0
var relic_count := 0
var broken_count := 0
var final_score := 0
var last_platform_end := 0.0
var last_platform_top := INITIAL_TOP
var last_runestone_x := -10000.0
var alive := true
var grounded := true
var player_visible := true


func _ready() -> void:
	rng.randomize()
	reset_run()


func _unhandled_input(event: InputEvent) -> void:
	if not alive and event.is_action_pressed("retry"):
		reset_run()


func reset_run() -> void:
	platforms.clear()
	relics.clear()
	runestones.clear()
	particles.clear()
	afterimages.clear()
	player_pos = PLAYER_START
	vertical_speed = 0.0
	stored_dash_vertical_speed = 0.0
	camera_x = 0.0
	run_time = 0.0
	run_speed = RUN_SPEED_MIN
	coyote_timer = COYOTE_TIME
	jump_buffer_timer = 0.0
	jumps_remaining = 2
	dash_remaining = 0.0
	dash_cooldown = 0.0
	afterimage_timer = 0.0
	death_timer = 0.0
	relic_count = 0
	broken_count = 0
	final_score = 0
	alive = true
	grounded = true
	player_visible = true
	last_runestone_x = -10000.0

	var opening := Rect2(-64.0, INITIAL_TOP, 480.0, 80.0)
	platforms.append({"rect": opening, "kind": 0})
	last_platform_end = opening.end.x
	last_platform_top = INITIAL_TOP
	for i in range(5):
		relics.append({"pos": Vector2(PLAYER_START.x + 64.0 + i * UNIT, INITIAL_TOP - 15.0), "taken": false})
	_generate_until(900.0)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_update_effects(delta)
	if not alive:
		death_timer += delta
		if death_timer >= 0.65:
			player_visible = false
		queue_redraw()
		return

	run_time += delta
	run_speed = lerpf(RUN_SPEED_MIN, RUN_SPEED_MAX, minf(run_time / SPEED_RAMP_SECONDS, 1.0))
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	if Input.is_action_just_released("jump") and vertical_speed < 0.0 and dash_remaining <= 0.0:
		vertical_speed *= JUMP_CUT

	if dash_remaining <= 0.0 and dash_cooldown > 0.0:
		dash_cooldown = maxf(0.0, dash_cooldown - delta)
	if Input.is_action_just_pressed("dash") and dash_remaining <= 0.0 and dash_cooldown <= 0.0:
		dash_remaining = DASH_TIME
		stored_dash_vertical_speed = vertical_speed
		vertical_speed = 0.0
		afterimage_timer = 0.0

	_consume_jump_buffer()
	var was_dashing := dash_remaining > 0.0
	if was_dashing:
		dash_remaining = maxf(0.0, dash_remaining - delta)
		afterimage_timer -= delta
		if afterimage_timer <= 0.0:
			afterimages.append({"pos": player_pos, "ttl": 0.13, "max": 0.13})
			afterimage_timer += 0.045
		if dash_remaining <= 0.0:
			vertical_speed = stored_dash_vertical_speed
			dash_cooldown = DASH_COOLDOWN

	var previous_pos := player_pos
	var horizontal_speed := run_speed * (2.0 if was_dashing else 1.0)
	player_pos.x += horizontal_speed * delta

	if _hit_platform_front(previous_pos, player_pos):
		_die()
		return

	if grounded:
		var support_top := _support_top_at(player_pos.x)
		if is_finite(support_top):
			player_pos.y = support_top
			vertical_speed = 0.0
		else:
			grounded = false
			coyote_timer = COYOTE_TIME

	if not grounded:
		if coyote_timer > 0.0:
			coyote_timer = maxf(0.0, coyote_timer - delta)
			if coyote_timer <= 0.0:
				jumps_remaining = mini(jumps_remaining, 1)
		if not was_dashing:
			vertical_speed += GRAVITY * delta
			var next_y := player_pos.y + vertical_speed * delta
			var landing_top := _landing_top(previous_pos.y, next_y, player_pos.x)
			if vertical_speed >= 0.0 and is_finite(landing_top):
				player_pos.y = landing_top
				vertical_speed = 0.0
				grounded = true
				coyote_timer = COYOTE_TIME
				jumps_remaining = 2
				_consume_jump_buffer()
			else:
				player_pos.y = next_y

	_check_relics()
	_check_runestones(was_dashing)
	if player_pos.y > DEATH_FALL_Y:
		_die()
		return

	camera_x = maxf(0.0, player_pos.x - 80.0)
	_generate_until(camera_x + 720.0)
	_cull_behind(camera_x - 180.0)
	queue_redraw()


func _consume_jump_buffer() -> void:
	if jump_buffer_timer <= 0.0 or dash_remaining > 0.0:
		return
	if grounded or coyote_timer > 0.0:
		grounded = false
		coyote_timer = 0.0
		vertical_speed = -JUMP_SPEED
		jumps_remaining = 1
		jump_buffer_timer = 0.0
	elif jumps_remaining > 0:
		vertical_speed = -JUMP_SPEED
		jumps_remaining -= 1
		jump_buffer_timer = 0.0


func _generate_until(target_x: float) -> void:
	while last_platform_end < target_x:
		var gap_units := 1.25
		if run_time >= 8.0:
			var max_gap := lerpf(2.0, 3.5, minf((run_time - 8.0) / 112.0, 1.0))
			gap_units = rng.randf_range(1.5, max_gap)
		var top := last_platform_top
		if run_time >= 20.0:
			var candidates: Array[float] = []
			for step in [-8.0, 0.0, 8.0]:
				var possible: float = last_platform_top + float(step)
				if possible >= INITIAL_TOP - UNIT and possible <= INITIAL_TOP + UNIT:
					candidates.append(possible)
			top = candidates[rng.randi_range(0, candidates.size() - 1)]
		var length_units: int = [14, 16, 18][rng.randi_range(0, 2)]
		var start_x := snappedf(last_platform_end + gap_units * UNIT, 1.0)
		var rect := Rect2(start_x, top, length_units * UNIT, 80.0 + (INITIAL_TOP - top))
		platforms.append({"rect": rect, "kind": rng.randi_range(0, 2)})

		var arched := rng.randi_range(0, 1) == 1
		for i in range(5):
			var relic_x := start_x + 20.0 + i * 13.6
			var lift := 13.0
			if arched:
				var arch_heights: Array[float] = [13.0, 28.0, 37.0, 28.0, 13.0]
				lift = arch_heights[i]
			relics.append({"pos": Vector2(relic_x, top - lift), "taken": false})

		if run_time >= 3.0:
			var stone_x := start_x + 6.0 * UNIT
			if stone_x - last_runestone_x >= 12.9 * UNIT and rng.randf() < 0.44:
				runestones.append({"rect": Rect2(stone_x - 7.0, top - 35.0, 14.0, 35.0), "broken": false})
				last_runestone_x = stone_x

		last_platform_end = rect.end.x
		last_platform_top = top


func _support_top_at(x: float) -> float:
	for platform in platforms:
		var rect: Rect2 = platform["rect"]
		if x + 8.0 >= rect.position.x and x - 8.0 <= rect.end.x and absf(player_pos.y - rect.position.y) <= 2.0:
			return rect.position.y
	return INF


func _landing_top(previous_y: float, next_y: float, x: float) -> float:
	var best := INF
	for platform in platforms:
		var rect: Rect2 = platform["rect"]
		if x + 8.0 < rect.position.x or x - 8.0 > rect.end.x:
			continue
		if previous_y <= rect.position.y and next_y >= rect.position.y:
			best = minf(best, rect.position.y)
	return best


func _hit_platform_front(previous: Vector2, current: Vector2) -> bool:
	var old_right := previous.x + 10.0
	var new_right := current.x + 10.0
	var body_top := current.y - 21.0
	var body_bottom := current.y - 1.0
	for platform in platforms:
		var rect: Rect2 = platform["rect"]
		if old_right <= rect.position.x and new_right > rect.position.x:
			if body_bottom > rect.position.y + 1.0 and body_top < rect.end.y:
				return true
	return false


func _player_rect() -> Rect2:
	return Rect2(player_pos.x - 11.0, player_pos.y - 22.0, 22.0, 22.0)


func _check_relics() -> void:
	var player_box := _player_rect().grow(2.0)
	for relic in relics:
		if relic["taken"]:
			continue
		var pos: Vector2 = relic["pos"]
		if player_box.has_point(pos):
			relic["taken"] = true
			relic_count += 1
			_spawn_burst(pos, C_GOLD, 8, 0.35, 34.0)


func _check_runestones(dashing_this_tick: bool) -> void:
	var player_box := _player_rect()
	for stone in runestones:
		if stone["broken"]:
			continue
		var rect: Rect2 = stone["rect"]
		if player_box.intersects(rect):
			if dashing_this_tick:
				stone["broken"] = true
				broken_count += 1
				_spawn_burst(rect.get_center(), C_GOLD, 12, 0.35, 48.0)
			else:
				_die()
			return


func _die() -> void:
	if not alive:
		return
	final_score = _current_score()
	alive = false
	grounded = false
	death_timer = 0.0
	dash_remaining = 0.0
	_spawn_burst(player_pos - Vector2(0.0, 12.0), C_IVORY, 22, 0.75, 70.0)
	queue_redraw()


func _current_score() -> int:
	if not alive:
		return final_score
	var distance_points := int(floor(maxf(0.0, player_pos.x - PLAYER_START.x) / UNIT * 10.0))
	return distance_points + relic_count * 25 + broken_count * 100


func _spawn_burst(at: Vector2, color: Color, count: int, lifetime: float, speed: float) -> void:
	for i in range(count):
		var angle := rng.randf_range(0.0, TAU)
		var velocity := Vector2(cos(angle), sin(angle)) * rng.randf_range(speed * 0.45, speed)
		particles.append({"pos": at, "vel": velocity, "ttl": lifetime, "max": lifetime, "color": color, "size": rng.randi_range(1, 3)})


func _update_effects(delta: float) -> void:
	for particle in particles:
		particle["ttl"] = float(particle["ttl"]) - delta
		particle["vel"] = Vector2(particle["vel"]) + Vector2(0.0, 38.0) * delta
		particle["pos"] = Vector2(particle["pos"]) + Vector2(particle["vel"]) * delta
	for i in range(particles.size() - 1, -1, -1):
		if float(particles[i]["ttl"]) <= 0.0:
			particles.remove_at(i)
	for ghost in afterimages:
		ghost["ttl"] = float(ghost["ttl"]) - delta
	for i in range(afterimages.size() - 1, -1, -1):
		if float(afterimages[i]["ttl"]) <= 0.0:
			afterimages.remove_at(i)


func _cull_behind(min_x: float) -> void:
	while platforms.size() > 2:
		var rect: Rect2 = platforms[0]["rect"]
		if rect.end.x >= min_x:
			break
		platforms.pop_front()
	for i in range(relics.size() - 1, -1, -1):
		if Vector2(relics[i]["pos"]).x < min_x:
			relics.remove_at(i)
	for i in range(runestones.size() - 1, -1, -1):
		var rect: Rect2 = runestones[i]["rect"]
		if rect.end.x < min_x:
			runestones.remove_at(i)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), C_NEAR_BLACK)
	_draw_background()
	for platform in platforms:
		_draw_platform(platform)
	for relic in relics:
		if not relic["taken"]:
			_draw_relic(Vector2(relic["pos"]) - Vector2(camera_x, 0.0))
	for stone in runestones:
		if not stone["broken"]:
			_draw_runestone(Rect2(stone["rect"]).position - Vector2(camera_x, 0.0))
	for ghost in afterimages:
		_draw_unicorn(Vector2(ghost["pos"]) - Vector2(camera_x, 0.0), C_MOSS, true, 1.0)
	if player_visible:
		_draw_unicorn(player_pos - Vector2(camera_x, 0.0), C_IVORY, false, 1.0)
	for particle in particles:
		var p := Vector2(particle["pos"]) - Vector2(camera_x, 0.0)
		var size := float(particle["size"])
		draw_rect(Rect2(p.floor(), Vector2(size, size)), Color(particle["color"]))
	_draw_hud()


func _draw_background() -> void:
	var far_offset := fmod(camera_x * 0.15, 80.0)
	for i in range(-1, 6):
		var x := i * 80.0 - far_offset
		draw_rect(Rect2(x, 46.0, 5.0, 86.0), C_CHARCOAL)
		draw_rect(Rect2(x + 51.0, 46.0, 5.0, 86.0), C_CHARCOAL)
		draw_rect(Rect2(x + 5.0, 46.0, 46.0, 5.0), C_CHARCOAL)
		draw_arc(Vector2(x + 28.0, 76.0), 23.0, PI, TAU, 16, C_CHARCOAL, 5.0, false)
	var near_offset := fmod(camera_x * 0.40, 64.0)
	for i in range(-1, 7):
		var x := i * 64.0 - near_offset
		var h := 26.0 + float((i + int(camera_x / 64.0)) % 3) * 9.0
		draw_rect(Rect2(x, INITIAL_TOP - h, 38.0, h), C_BROWN)
		draw_rect(Rect2(x + 4.0, INITIAL_TOP - h - 4.0, 9.0, 4.0), C_BROWN)
		draw_rect(Rect2(x + 24.0, INITIAL_TOP - h - 7.0, 10.0, 7.0), C_BROWN)
		draw_rect(Rect2(x + 2.0, INITIAL_TOP - h, 3.0, 15.0), C_MOSS)
	for p in [Vector2(27, 25), Vector2(91, 70), Vector2(154, 30), Vector2(232, 58), Vector2(298, 24)]:
		draw_rect(Rect2(p, Vector2(2, 2)), C_STONE)


func _draw_platform(platform: Dictionary) -> void:
	var world_rect: Rect2 = platform["rect"]
	var rect := Rect2(world_rect.position - Vector2(camera_x, 0.0), world_rect.size)
	if rect.end.x < 0.0 or rect.position.x > VIEW_SIZE.x:
		return
	draw_rect(rect, C_CHARCOAL)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 5.0)), C_STONE)
	draw_rect(Rect2(rect.position + Vector2(0.0, -3.0), Vector2(rect.size.x, 3.0)), C_MOSS)
	var row := 0
	var y := rect.position.y + 9.0
	while y < VIEW_SIZE.y:
		draw_rect(Rect2(rect.position.x, y, rect.size.x, 1.0), C_NEAR_BLACK)
		var block_offset := 8.0 if row % 2 == 0 else 22.0
		var x := rect.position.x + block_offset
		while x < rect.end.x:
			draw_rect(Rect2(x, y - 8.0, 1.0, 8.0), C_NEAR_BLACK)
			x += 32.0
		y += 10.0
		row += 1
	var kind := int(platform["kind"])
	if kind == 1:
		draw_rect(Rect2(rect.position.x + 34.0, rect.position.y - 8.0, 12.0, 5.0), C_STONE)
		draw_rect(Rect2(rect.position.x + 37.0, rect.position.y - 11.0, 6.0, 3.0), C_STONE)
	elif kind == 2:
		draw_rect(Rect2(rect.end.x - 34.0, rect.position.y - 6.0, 15.0, 3.0), C_STONE)
	for vine_x in [rect.position.x + 12.0, rect.position.x + 79.0, rect.position.x + 157.0]:
		if vine_x < rect.end.x:
			draw_rect(Rect2(vine_x, rect.position.y + 2.0, 2.0, 7.0 + fmod(vine_x, 5.0)), C_MOSS)


func _draw_relic(pos: Vector2) -> void:
	var p := pos.round()
	draw_polygon(PackedVector2Array([p + Vector2(0, -5), p + Vector2(4, 0), p + Vector2(0, 5), p + Vector2(-4, 0)]), PackedColorArray([C_GOLD]))
	draw_rect(Rect2(p + Vector2(-1, -3), Vector2(2, 2)), C_IVORY)


func _draw_runestone(top_left: Vector2) -> void:
	var p := top_left.round()
	draw_polygon(PackedVector2Array([p + Vector2(1, 35), p + Vector2(0, 8), p + Vector2(4, 0), p + Vector2(10, 0), p + Vector2(14, 8), p + Vector2(13, 35)]), PackedColorArray([C_GOLD]))
	draw_rect(Rect2(p + Vector2(3, 9), Vector2(8, 22)), C_BROWN)
	draw_rect(Rect2(p + Vector2(6, 12), Vector2(2, 14)), C_IVORY)
	draw_rect(Rect2(p + Vector2(4, 14), Vector2(2, 2)), C_IVORY)
	draw_rect(Rect2(p + Vector2(8, 17), Vector2(2, 2)), C_IVORY)
	draw_rect(Rect2(p + Vector2(4, 23), Vector2(2, 2)), C_IVORY)


func _draw_unicorn(feet: Vector2, body_color: Color, ghost: bool, alpha: float) -> void:
	var p := feet.round()
	var color := Color(body_color, alpha)
	var mane_color := Color(C_PALE if not ghost else C_MOSS, alpha)
	var dark := Color(C_NEAR_BLACK, alpha)
	var gold := Color(C_GOLD, alpha)
	var pose := 0
	if not alive:
		pose = 11
	elif dash_remaining > 0.0 or ghost:
		pose = 10
	elif not grounded:
		pose = 8 if vertical_speed < 0.0 else 9
	else:
		pose = int(floor(run_time * 12.0 * run_speed / RUN_SPEED_MIN)) % 8
	if pose == 11:
		draw_rect(Rect2(p + Vector2(-10, -11), Vector2(18, 9)), color)
		draw_rect(Rect2(p + Vector2(5, -8), Vector2(10, 8)), color)
		draw_rect(Rect2(p + Vector2(10, -12), Vector2(7, 7)), color)
		draw_polygon(PackedVector2Array([p + Vector2(14, -12), p + Vector2(19, -15), p + Vector2(16, -10)]), PackedColorArray([gold]))
		draw_rect(Rect2(p + Vector2(-15, -9), Vector2(6, 3)), mane_color)
		draw_rect(Rect2(p + Vector2(-5, -3), Vector2(4, 5)), color)
		draw_rect(Rect2(p + Vector2(4, -2), Vector2(5, 3)), color)
		return
	if pose == 10:
		draw_rect(Rect2(p + Vector2(-18, -16), Vector2(10, 3)), mane_color)
		draw_rect(Rect2(p + Vector2(-20, -13), Vector2(12, 3)), mane_color)
	else:
		draw_rect(Rect2(p + Vector2(-16, -17), Vector2(7, 4)), mane_color)
		draw_rect(Rect2(p + Vector2(-19, -14), Vector2(9, 3)), mane_color)
	var stretch := 3.0 if pose == 10 else 0.0
	draw_rect(Rect2(p + Vector2(-10 - stretch, -19), Vector2(19 + stretch * 2.0, 10)), color)
	draw_rect(Rect2(p + Vector2(6, -24), Vector2(7, 12)), color)
	draw_rect(Rect2(p + Vector2(9, -27), Vector2(10, 8)), color)
	draw_rect(Rect2(p + Vector2(9, -28), Vector2(3, 3)), mane_color)
	draw_rect(Rect2(p + Vector2(5, -23), Vector2(3, 9)), mane_color)
	draw_polygon(PackedVector2Array([p + Vector2(15, -27), p + Vector2(22, -31), p + Vector2(17, -25)]), PackedColorArray([gold]))
	draw_rect(Rect2(p + Vector2(16, -24), Vector2(2, 2)), dark)
	var legs: Array[Vector2] = [Vector2(-8, 0), Vector2(-5, 2), Vector2(-2, 3), Vector2(2, 1), Vector2(6, 0), Vector2(2, 2), Vector2(-2, 3), Vector2(-6, 1)]
	var leg_shift := legs[pose] if pose < 8 else Vector2(0, -2 if pose == 8 else 2)
	if pose == 10:
		draw_rect(Rect2(p + Vector2(-10, -10), Vector2(8, 3)), color)
		draw_rect(Rect2(p + Vector2(6, -10), Vector2(9, 3)), color)
	else:
		draw_rect(Rect2(p + Vector2(-7 + leg_shift.x, -11), Vector2(4, 11 + leg_shift.y)), color)
		draw_rect(Rect2(p + Vector2(4 - leg_shift.x, -11), Vector2(4, 11 - leg_shift.y)), color)
		draw_rect(Rect2(p + Vector2(-8 + leg_shift.x, -2 + leg_shift.y), Vector2(6, 2)), dark)
		draw_rect(Rect2(p + Vector2(3 - leg_shift.x, -2 - leg_shift.y), Vector2(6, 2)), dark)


func _draw_hud() -> void:
	draw_rect(Rect2(0.0, 0.0, VIEW_SIZE.x, 17.0), C_CHARCOAL)
	draw_rect(Rect2(0.0, 16.0, VIEW_SIZE.x, 1.0), C_STONE)
	_draw_pixel_text(Vector2(5, 5), "SCORE %06d" % _current_score(), C_IVORY)
	var relic_text := "RELICS %03d" % relic_count
	_draw_pixel_text(Vector2(315 - _text_width(relic_text), 5), relic_text, C_GOLD)
	var charge := 1.0
	var dash_label := "DASH READY"
	if dash_remaining > 0.0:
		charge = dash_remaining / DASH_TIME
		dash_label = "DASH"
	elif dash_cooldown > 0.0:
		charge = 1.0 - dash_cooldown / DASH_COOLDOWN
		dash_label = "DASH"
	_draw_pixel_text(Vector2(5, 159), dash_label, C_PALE if charge >= 1.0 else C_IVORY)
	draw_rect(Rect2(5, 169, 55, 4), C_CHARCOAL)
	draw_rect(Rect2(6, 170, 53.0 * clampf(charge, 0.0, 1.0), 2), C_MOSS if charge >= 1.0 else C_GOLD)
	if alive and run_time < 6.0:
		_draw_pixel_text(Vector2(211, 151), "SPACE / Z JUMP", C_IVORY)
		_draw_pixel_text(Vector2(211, 160), "SHIFT / X DASH", C_PALE)
	if not alive:
		var panel := Rect2(102, 66, 116, 48)
		draw_rect(panel, C_CHARCOAL)
		draw_rect(Rect2(panel.position, Vector2(panel.size.x, 2)), C_STONE)
		draw_rect(Rect2(panel.position + Vector2(0, panel.size.y - 2), Vector2(panel.size.x, 2)), C_STONE)
		draw_rect(Rect2(panel.position, Vector2(2, panel.size.y)), C_STONE)
		draw_rect(Rect2(panel.position + Vector2(panel.size.x - 2, 0), Vector2(2, panel.size.y)), C_STONE)
		_draw_centered_text(78, "RUN ENDED", C_GOLD)
		_draw_centered_text(96, "R TO RETRY", C_IVORY)


func _draw_centered_text(y: float, text: String, color: Color) -> void:
	_draw_pixel_text(Vector2((VIEW_SIZE.x - _text_width(text)) * 0.5, y), text, color)


func _text_width(text: String, scale: int = 1) -> int:
	return maxi(0, text.length() * 6 * scale - scale)


func _draw_pixel_text(at: Vector2, text: String, color: Color, scale: int = 1) -> void:
	var cursor_x := int(at.x)
	for character in text.to_upper():
		var glyph: Array = FONT.get(character, FONT[" "])
		for row in range(7):
			var bits: String = glyph[row]
			for column in range(5):
				if bits[column] == "1":
					draw_rect(Rect2(cursor_x + column * scale, int(at.y) + row * scale, scale, scale), color)
		cursor_x += 6 * scale
