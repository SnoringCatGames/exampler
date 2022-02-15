tool
class_name CornerMatchInnerTileset
extends TileSet


var tile_id := -1


func get_cell_size() -> Vector2:
    return autotile_get_size(tile_id)
