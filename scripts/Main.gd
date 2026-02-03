extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var battle_overlay: CanvasLayer = $BattleOverlay
@onready var enemies: Node2D = $Enemies
@onready var debug_label: Label = $DebugLabel

var in_combat := false
var proximity_triggered := false

func _ready() -> void:
	_setup_enemy_idle()
	player.connect("combat_started", _on_combat_started)
	for child in enemies.get_children():
		var detector := child.get_node_or_null("CombatDetector")
		if detector:
			detector.body_entered.connect(_on_enemy_body_entered)
		var roam_bounds := _get_roam_bounds()
		if child.has_method("set"):
			child.set("roam_bounds", roam_bounds)
	battle_overlay.connect("end_turn", _end_combat)
	battle_overlay.connect("battle_over", _on_battle_over)


func _setup_enemy_idle() -> void:
	pass


func _get_roam_bounds() -> Rect2:
	var tile_size := 32.0
	var map_width := 40.0
	var map_height := 24.0
	var origin := Vector2(-map_width * tile_size * 0.5, -map_height * tile_size * 0.5)
	return Rect2(origin, Vector2(map_width * tile_size, map_height * tile_size))


func _process(_delta: float) -> void:
	if not in_combat:
		_check_proximity()
	
	if not in_combat:
		return

	if Input.is_action_just_pressed("ui_accept"):
		battle_overlay.call("play_punch")
	if Input.is_action_just_pressed("ui_select"):
		battle_overlay.call("play_kick")
	if Input.is_action_just_pressed("ui_cancel"):
		_end_combat()


func _on_combat_started() -> void:
	if in_combat:
		return
	in_combat = true
	battle_overlay.visible = true
	battle_overlay.call("start_battle")
	player.call("set_combat_locked", true)
	debug_label.text = "Combat started!"


func _end_combat() -> void:
	in_combat = false
	battle_overlay.visible = false
	player.call("set_combat_locked", false)
	debug_label.text = ""
	proximity_triggered = false


func _on_enemy_body_entered(body: Node) -> void:
	if body == player:
		_on_combat_started()



func _check_proximity() -> void:
	if proximity_triggered:
		return
	for child in enemies.get_children():
		var distance := player.global_position.distance_to(child.global_position)
		if distance <= 64.0:
			proximity_triggered = true
			_on_combat_started()
			return


func _on_battle_over(winner: String) -> void:
	debug_label.text = "%s wins!" % winner
	await get_tree().create_timer(1.2).timeout
	_end_combat()