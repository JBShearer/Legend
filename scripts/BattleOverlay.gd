extends CanvasLayer

@onready var kdee_sprite: AnimatedSprite2D = $Container/KDee
@onready var enemy_sprite: AnimatedSprite2D = $Container/Enemy
@onready var punch_button: Button = $Menu/MenuMargin/MenuVBox/Punch
@onready var kick_button: Button = $Menu/MenuMargin/MenuVBox/Kick
@onready var end_button: Button = $Menu/MenuMargin/MenuVBox/End
@onready var kdee_hp_label: Label = $HUD/KDeeHP
@onready var ninja_hp_label: Label = $HUD/NinjaHP
@onready var kdee_hp_menu: Label = $Menu/MenuMargin/MenuVBox/HPRow/KDeeHPMenu
@onready var ninja_hp_menu: Label = $Menu/MenuMargin/MenuVBox/HPRow/NinjaHPMenu

signal end_turn
signal battle_over(winner: String)

enum TurnState { PLAYER, ENEMY, RESOLVE }
var turn_state: TurnState = TurnState.PLAYER

@export var max_hp: int = 100
@export var player_damage: int = 18
@export var ninja_damage: int = 14

var kdee_hp: int = 100
var ninja_hp: int = 100

func _ready() -> void:
	_setup_kdee_frames()
	_setup_enemy_visual()
	play_idle()
	_connect_buttons()
	_update_layout()
	get_viewport().size_changed.connect(_update_layout)


func play_idle() -> void:
	kdee_sprite.play("idle")
	enemy_sprite.play("idle")


func play_punch() -> void:
	kdee_sprite.play("punch")
	_resolve_player_attack(player_damage)


func play_kick() -> void:
	kdee_sprite.play("kick")
	_resolve_player_attack(player_damage + 6)


func _connect_buttons() -> void:
	punch_button.pressed.connect(play_punch)
	kick_button.pressed.connect(play_kick)
	end_button.pressed.connect(_on_end_pressed)


func _on_end_pressed() -> void:
	_end_player_turn()


func _setup_kdee_frames() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("punch")
	frames.add_animation("kick")
	frames.set_animation_speed("idle", 6.0)
	frames.set_animation_speed("punch", 12.0)
	frames.set_animation_speed("kick", 12.0)

	_add_frames(frames, "idle", "res://blonde/iddle", "iddle", 10)
	_add_frames(frames, "punch", "res://blonde/attackF", "attack", 10)
	_add_frames(frames, "kick", "res://blonde/attackkck", "attackkick", 15)
	frames.set_animation_loop("punch", false)
	frames.set_animation_loop("kick", false)

	kdee_sprite.frames = frames
	kdee_sprite.play("idle")


func _add_frames(frames: SpriteFrames, anim: String, base_path: String, prefix: String, count: int) -> void:
	for index in count:
		var path := "%s/%s%04d.png" % [base_path, prefix, index]
		var texture := load(path)
		if texture:
			frames.add_frame(anim, texture)


func _setup_enemy_visual() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("attack_sword")
	frames.add_animation("attack_shuriken")
	frames.add_animation("attack_dual")
	frames.set_animation_speed("idle", 6.0)
	frames.set_animation_speed("attack_sword", 12.0)
	frames.set_animation_speed("attack_shuriken", 12.0)
	frames.set_animation_speed("attack_dual", 12.0)

	_add_frames(frames, "idle", "res://ninja/idle", "iddle", 10)
	_add_frames(frames, "attack_sword", "res://ninja/attack_sword", "attack", 10)
	_add_frames(frames, "attack_shuriken", "res://ninja/attack_shuriken", "attackkick", 15)
	_add_frames(frames, "attack_dual", "res://ninja/attack_dual", "attackdouble", 15)
	frames.set_animation_loop("attack_sword", false)
	frames.set_animation_loop("attack_shuriken", false)
	frames.set_animation_loop("attack_dual", false)

	enemy_sprite.frames = frames
	enemy_sprite.play("idle")


func _update_layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var left_pos := Vector2(size.x * 0.28, size.y * 0.42)
	var right_pos := Vector2(size.x * 0.72, size.y * 0.42)
	kdee_sprite.position = left_pos
	enemy_sprite.position = right_pos

	var scale_factor: float = clampf(size.x / 900.0, 0.8, 1.6)
	kdee_sprite.scale = Vector2.ONE * (1.3 * scale_factor)
	enemy_sprite.scale = Vector2.ONE * (0.9 * scale_factor)


func start_battle() -> void:
	kdee_hp = max_hp
	ninja_hp = max_hp
	_update_hp_bars()
	turn_state = TurnState.PLAYER
	_set_menu_enabled(true)
	play_idle()


func _update_hp_bars() -> void:
	kdee_hp_label.text = "HP: %d" % kdee_hp
	ninja_hp_label.text = "HP: %d" % ninja_hp
	kdee_hp_menu.text = "K'Dee HP: %d" % kdee_hp
	ninja_hp_menu.text = "Ninja HP: %d" % ninja_hp


func _resolve_player_attack(damage: int) -> void:
	if turn_state != TurnState.PLAYER:
		return
	turn_state = TurnState.RESOLVE
	ninja_hp = max(0, ninja_hp - damage)
	_update_hp_bars()
	await get_tree().create_timer(0.4).timeout
	if ninja_hp <= 0:
		battle_over.emit("KDee")
		return
	_end_player_turn()


func _end_player_turn() -> void:
	_set_menu_enabled(false)
	turn_state = TurnState.ENEMY
	await _enemy_turn()
	turn_state = TurnState.PLAYER
	_set_menu_enabled(true)
	play_idle()


func _enemy_turn() -> void:
	var move := randi() % 3
	match move:
		0:
			enemy_sprite.play("attack_sword")
		1:
			enemy_sprite.play("attack_shuriken")
		2:
			enemy_sprite.play("attack_dual")

	await get_tree().create_timer(0.6).timeout
	kdee_hp = max(0, kdee_hp - ninja_damage)
	_update_hp_bars()
	if kdee_hp <= 0:
		battle_over.emit("Ninja")
		return


func _set_menu_enabled(enabled: bool) -> void:
	punch_button.disabled = not enabled
	kick_button.disabled = not enabled
	end_button.disabled = not enabled