extends CharacterBody2D

@export var speed: float = 200.0

enum PlayerState { EXPLORATION, TURN_COMBAT }

@export var combat_lock_duration: float = 0.6

signal combat_started

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var combat_detector: Area2D = $CombatDetector

var state: PlayerState = PlayerState.EXPLORATION
var combat_timer: float = 0.0
var touch_target: Vector2 = Vector2.ZERO
var has_touch_target := false
var combat_locked := false

func _physics_process(_delta: float) -> void:
	if state == PlayerState.TURN_COMBAT:
		_handle_turn_combat(_delta)
		return

	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if input_vector.length() > 0.01:
		has_touch_target = false
	else:
		_handle_touch_target()
		if has_touch_target:
			input_vector = (touch_target - global_position).normalized()

	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	velocity = input_vector * speed
	move_and_slide()

	_update_facing(input_vector)
	_update_animation(input_vector)


func _update_animation(input_vector: Vector2) -> void:
	if input_vector.length() > 0.01:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")


func _update_facing(input_vector: Vector2) -> void:
	if abs(input_vector.x) > 0.01:
		animated_sprite.flip_h = input_vector.x < 0


func _ready() -> void:
	animated_sprite.frames = _build_placeholder_frames()
	animated_sprite.play("idle")
	combat_detector.body_entered.connect(_on_combat_body_entered)


func _build_placeholder_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("walk")
	frames.set_animation_speed("idle", 6.0)
	frames.set_animation_speed("walk", 10.0)

	_add_frame_sequence(frames, "idle", "res://blonde/iddle", "iddle", 10)
	_add_frame_sequence(frames, "walk", "res://blonde/walk", "walk", 15)
	return frames


func _add_frame_sequence(frames: SpriteFrames, anim: String, base_path: String, prefix: String, count: int) -> void:
	for index in count:
		var frame_path := "%s/%s%04d.png" % [base_path, prefix, index]
		var texture := load(frame_path)
		if texture:
			frames.add_frame(anim, texture)


func _on_combat_body_entered(_body: Node) -> void:
	if state == PlayerState.EXPLORATION:
		state = PlayerState.TURN_COMBAT
		combat_locked = true
		combat_timer = combat_lock_duration
		velocity = Vector2.ZERO
		_update_animation(Vector2.ZERO)
		combat_started.emit()


func _handle_turn_combat(delta: float) -> void:
	if combat_locked:
		return
	combat_timer -= delta
	if combat_timer <= 0.0:
		state = PlayerState.EXPLORATION


func _handle_touch_target() -> void:
	if not has_touch_target:
		return

	if global_position.distance_to(touch_target) <= 6.0:
		has_touch_target = false


func _input(event: InputEvent) -> void:
	if state != PlayerState.EXPLORATION:
		return

	if event is InputEventMouseButton and event.pressed:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			touch_target = get_global_mouse_position()
			has_touch_target = true
			return

	if event is InputEventScreenTouch and event.pressed:
		touch_target = get_global_mouse_position()
		has_touch_target = true


func set_combat_locked(locked: bool) -> void:
	combat_locked = locked
	if locked:
		state = PlayerState.TURN_COMBAT
		velocity = Vector2.ZERO
		_update_animation(Vector2.ZERO)
	else:
		state = PlayerState.EXPLORATION
		combat_timer = 0.0