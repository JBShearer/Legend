extends TileMap

@export var map_width: int = 40
@export var map_height: int = 24
@export var tile_size: int = 32

const GRASS_COLOR := Color("#2F855A")
const PATH_COLOR := Color("#D9A441")
const BORDER_COLOR := Color("#1F5A3B")
const PLAZA_COLOR := Color("#C9A77A")
const HOUSE_COLOR := Color("#8B5A2B")

var grass_source_id: int = -1
var path_source_id: int = -1
var border_source_id: int = -1
var plaza_source_id: int = -1
var house_source_id: int = -1
var collision_root: Node2D

func _ready() -> void:
	_setup_tileset()
	_ensure_layer()
	_generate_town()
	_build_colliders()
	_set_ready_message()
	_update_debug_label()


func _setup_tileset() -> void:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(tile_size, tile_size)
	self.tile_set = tileset

	grass_source_id = _add_solid_source(tileset, GRASS_COLOR)
	path_source_id = _add_solid_source(tileset, PATH_COLOR)
	border_source_id = _add_solid_source(tileset, BORDER_COLOR)
	plaza_source_id = _add_solid_source(tileset, PLAZA_COLOR)
	house_source_id = _add_solid_source(tileset, HOUSE_COLOR)



func _add_solid_source(tileset: TileSet, color: Color) -> int:
	var atlas_texture := ImageTexture.create_from_image(_make_solid_tile(color))
	var source := TileSetAtlasSource.new()
	source.texture = atlas_texture
	source.texture_region_size = Vector2i(tile_size, tile_size)
	var source_id := tileset.add_source(source)
	var atlas_coords := Vector2i(0, 0)
	source.create_tile(atlas_coords)
	var tile_data := source.get_tile_data(atlas_coords, 0)
	if tile_data:
		tile_data.material = null

	return source_id


func _make_solid_tile(color: Color) -> Image:
	var image := Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image


func _ensure_layer() -> void:
	if get_layers_count() == 0:
		add_layer(0)
	set_layer_enabled(0, true)
	set_layer_modulate(0, Color.WHITE)
	collision_layer = 0
	collision_mask = 0


func _generate_town() -> void:
	clear()
	var offset := Vector2i(-map_width / 2, -map_height / 2)
	var world_offset := Vector2(offset.x * tile_size, offset.y * tile_size)
	for x in map_width:
		for y in map_height:
			var is_border := x == 0 or y == 0 or x == map_width - 1 or y == map_height - 1
			if is_border:
				set_cell(0, Vector2i(x, y) + offset, border_source_id, Vector2i(0, 0))
				_append_collider(world_offset, Vector2i(x, y))
				continue
			set_cell(0, Vector2i(x, y) + offset, grass_source_id, Vector2i(0, 0))

	_draw_roads(offset)
	_draw_plaza(offset)
	_draw_houses(offset, world_offset)


func _draw_roads(offset: Vector2i) -> void:
	var center_x := map_width / 2
	var center_y := map_height / 2
	for x in map_width:
		var cell := Vector2i(x, center_y) + offset
		set_cell(0, cell, path_source_id, Vector2i(0, 0))
	for y in map_height:
		var cell := Vector2i(center_x, y) + offset
		set_cell(0, cell, path_source_id, Vector2i(0, 0))


func _draw_plaza(offset: Vector2i) -> void:
	var plaza_size := Vector2i(6, 4)
	var start := Vector2i(map_width / 2 - plaza_size.x / 2, map_height / 2 - plaza_size.y / 2)
	for x in plaza_size.x:
		for y in plaza_size.y:
			var cell := Vector2i(start.x + x, start.y + y) + offset
			set_cell(0, cell, plaza_source_id, Vector2i(0, 0))


func _draw_houses(offset: Vector2i, world_offset: Vector2) -> void:
	var house_size := Vector2i(4, 3)
	var padding := Vector2i(4, 4)
	var positions := [
		Vector2i(padding.x, padding.y),
		Vector2i(map_width - house_size.x - padding.x, padding.y),
		Vector2i(padding.x, map_height - house_size.y - padding.y),
		Vector2i(map_width - house_size.x - padding.x, map_height - house_size.y - padding.y)
	]
	for pos in positions:
		for x in house_size.x:
			for y in house_size.y:
				var cell := Vector2i(pos.x + x, pos.y + y) + offset
				set_cell(0, cell, house_source_id, Vector2i(0, 0))
				_append_collider(world_offset, Vector2i(pos.x + x, pos.y + y))


func _update_debug_label() -> void:
	var debug_label := get_parent().get_node_or_null("Hud/DebugLabel")
	if debug_label and debug_label is Label:
		var used_cells := get_used_cells(0).size()
		var sources := 0
		if tile_set:
			sources = tile_set.get_source_count()
		debug_label.text = "Tiles: %d | Sources: %d | Layers: %d" % [used_cells, sources, get_layers_count()]


func _set_ready_message() -> void:
	var debug_label := get_parent().get_node_or_null("Hud/DebugLabel")
	if debug_label and debug_label is Label:
		debug_label.text = "World ready"


func _build_colliders() -> void:
	if collision_root:
		collision_root.queue_free()
	collision_root = Node2D.new()
	collision_root.name = "WorldColliders"
	add_child(collision_root)


func _append_collider(world_offset: Vector2, grid_pos: Vector2i) -> void:
	if collision_root == null:
		return
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(tile_size, tile_size)
	shape.shape = rect
	body.add_child(shape)
	shape.position = Vector2(tile_size * 0.5, tile_size * 0.5)
	body.position = world_offset + Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)
	collision_root.add_child(body)