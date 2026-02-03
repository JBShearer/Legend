extends CharacterBody2D

@export var speed: float = 120.0
@export var roam_time_min: float = 1.2
@export var roam_time_max: float = 3.2
@export var idle_time_min: float = 1.4
@export var idle_time_max: float = 3.6
@export var roam_bounds: Rect2 = Rect2(Vector2(-500, -300), Vector2(1000, 600))

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var move_timer: float = 0.0
var idle_timer: float = 0.0
var roam_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	_setup_frames()
	_start_idle()


func _physics_process(delta: float) -> void:
	if idle_timer > 0.0:
		idle_timer -= delta
		velocity = Vector2.ZERO
		if idle_timer <= 0.0:
			_start_roam()
		return

	if move_timer > 0.0:
		move_timer -= delta
		velocity = roam_direction * speed
		move_and_slide()
		_ensure_bounds()
		_update_facing()
		if move_timer <= 0.0:
			_start_idle()
		return

	_start_idle()


func _start_idle() -> void:
	idle_timer = randf_range(idle_time_min, idle_time_max)
	move_timer = 0.0
	velocity = Vector2.ZERO
	if animated_sprite.animation != "idle":
		animated_sprite.play("idle")


func _start_roam() -> void:
	move_timer = randf_range(roam_time_min, roam_time_max)
	idle_timer = 0.0
	roam_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	if roam_direction == Vector2.ZERO:
		roam_direction = Vector2.RIGHT
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")


func _ensure_bounds() -> void:
	var pos := global_position
	var min_x := roam_bounds.position.x
	var max_x := roam_bounds.position.x + roam_bounds.size.x
	var min_y := roam_bounds.position.y
	var max_y := roam_bounds.position.y + roam_bounds.size.y

	var clamped_x := clampf(pos.x, min_x, max_x)
	var clamped_y := clampf(pos.y, min_y, max_y)
	if clamped_x != pos.x or clamped_y != pos.y:
		global_position = Vector2(clamped_x, clamped_y)
		roam_direction = (roam_direction * -1.0).normalized()


func _update_facing() -> void:
	if abs(roam_direction.x) > 0.01:
		animated_sprite.flip_h = roam_direction.x < 0


func _setup_frames() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("walk")
	frames.set_animation_speed("idle", 6.0)
	frames.set_animation_speed("walk", 10.0)

	_add_frames(frames, "idle", "res://ninja/idle", "iddle", 10)
	_add_frames(frames, "walk", "res://ninja/run", "run", 10)
	frames.set_animation_loop("idle", true)
	frames.set_animation_loop("walk", true)

	animated_sprite.frames = frames
	animated_sprite.play("idle")


func _add_frames(frames: SpriteFrames, anim: String, base_path: String, prefix: String, count: int) -> void:
	for index in count:
		var path := "%s/%s%04d.png" % [base_path, prefix, index]
		var texture := load(path)
		if texture:
			frames.add_frame(anim, texture)