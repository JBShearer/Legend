extends TileMap

@export var map_width: int = 40
@export var map_height: int = 24
@export var tile_size: int = 32

const GRASS_COLOR := Color("#2F855A")
const PATH_COLOR := Color("#D9A441")
const BORDER_COLOR := Color("#1F5A3B")

const GRASS_SOURCE_ID := 0
const PATH_SOURCE_ID := 1
const BORDER_SOURCE_ID := 2

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	_setup_tileset()
	_generate_ground()


func _setup_tileset() -> void:
	var tileset := TileSet.new()
	var physics_layer_id := tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(physics_layer_id, 1)
	tileset.set_physics_layer_collision_mask(physics_layer_id, 1)

	_add_solid_source(tileset, GRASS_COLOR)
	_add_solid_source(tileset, PATH_COLOR)
	_add_solid_source(tileset, BORDER_COLOR)

	self.tile_set = tileset
	self.tile_set.tile_size = Vector2i(tile_size, tile_size)



func _add_solid_source(tileset: TileSet, color: Color) -> void:
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
		if source_id == BORDER_SOURCE_ID:
			var polygon := PackedVector2Array([
				Vector2(0, 0),
				Vector2(tile_size, 0),
				Vector2(tile_size, tile_size),
				Vector2(0, tile_size)
			])
			tile_data.set_collision_polygons_count(0, 1)
			tile_data.set_collision_polygon(0, 0, polygon)


func _make_solid_tile(color: Color) -> Image:
	var image := Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image


func _generate_ground() -> void:
	clear()
	var offset := Vector2i(-map_width / 2, -map_height / 2)
	for x in map_width:
		for y in map_height:
			var is_border := x == 0 or y == 0 or x == map_width - 1 or y == map_height - 1
			if is_border:
				set_cell(0, Vector2i(x, y) + offset, BORDER_SOURCE_ID, Vector2i(0, 0))
				continue

			var is_path := y == map_height / 2 or x == map_width / 2
			if is_path:
				set_cell(0, Vector2i(x, y) + offset, PATH_SOURCE_ID, Vector2i(0, 0))
			else:
				set_cell(0, Vector2i(x, y) + offset, GRASS_SOURCE_ID, Vector2i(0, 0))