tool
class_name CornerMatchTilemap
extends TileMap


signal cell_tile_changed(
        cell_position,
        next_tile_id,
        previous_tile_id)
signal cell_autotile_changed(
        cell_position,
        next_autotile_position,
        previous_autotile_position,
        tile_id)

## This can be useful for debugging.
export var draws_tile_indices := false setget _set_draws_tile_indices
## This can be useful for debugging.
export var draws_tile_grid_positions := false \
        setget _set_draws_tile_grid_positions
## This can be useful for debugging.
export var draws_tile_angles := false setget _set_draws_tile_angles
## This can be useful for debugging.
export var draws_target_corner_types := false \
        setget _set_draws_target_corner_types
## This can be useful for debugging.
export var draws_actual_corner_types := false \
        setget _set_draws_actual_corner_types

var inner_tilemap: CornerMatchInnerTilemap


func _ready() -> void:
    if !is_instance_valid(tile_set) or \
            tile_set.resource_path == Su.PLACEHOLDER_SURFACES_TILE_SET_PATH:
        tile_set = Su.default_tile_set
        property_list_changed_notify()
    assert(tile_set is CornerMatchTileset)
    
    # FIXME: LEFT OFF HERE: ----------------------------------
    # - I'm not seeing anything render here.
    # - Pull this out into a separate location, also controlled by the level scene.
    # - Then explicitly set a couple quadrant-subtiles there in order to test that things work.
    # - I will also need to make sure that the inner tilmap saves to the level .tres file.
    inner_tilemap = CornerMatchInnerTilemap.new()
    inner_tilemap.tile_set = tile_set.inner_tile_set
    get_parent().call_deferred("add_child", inner_tilemap)


func _enter_tree() -> void:
    cell_size = Sc.level_session.config.cell_size
    position = Vector2.ZERO
    property_list_changed_notify()


func _draw() -> void:
    if draws_tile_indices:
        Sc.draw.draw_tile_map_indices(
                self,
                self,
                Color.white,
                false)
    if draws_tile_grid_positions:
        Sc.draw.draw_tile_grid_positions(
                self,
                self,
                Color.white,
                false)
    
    # FIXME: LEFT OFF HERE: -----------------------------
    # - Draw new annotations:
    #   - draws_tile_angles
    #   - draws_target_corner_types
    #   - draws_actual_corner_types
    # - Render these using additional nested TileMaps, since that should be
    #   more efficient.


func _set_draws_tile_indices(value: bool) -> void:
    draws_tile_indices = value
    if draws_tile_indices and draws_tile_grid_positions:
        _set_draws_tile_grid_positions(false)
    else:
        property_list_changed_notify()
        update()


func _set_draws_tile_grid_positions(value: bool) -> void:
    draws_tile_grid_positions = value
    if draws_tile_grid_positions and draws_tile_indices:
        _set_draws_tile_indices(false)
    else:
        property_list_changed_notify()
        update()


func _set_draws_tile_angles(value: bool) -> void:
    draws_tile_angles = value
    property_list_changed_notify()
    update()


func _set_draws_target_corner_types(value: bool) -> void:
    draws_target_corner_types = value
    property_list_changed_notify()
    update()


func _set_draws_actual_corner_types(value: bool) -> void:
    draws_actual_corner_types = value
    property_list_changed_notify()
    update()


func set_cell(
        x: int,
        y: int,
        tile_id: int,
        flip_x := false,
        flip_y := false,
        transpose := false,
        autotile_coord := Vector2.ZERO) -> void:
    var previous_tile_id := get_cell(x, y)
    var is_autotile := \
            tile_id != INVALID_CELL and \
            tile_set.tile_get_tile_mode(tile_id) == TileSet.AUTO_TILE
    var previous_autotile_coord := \
            get_cell_autotile_coord(x, y) if \
            is_autotile else \
            Vector2.INF
    .set_cell(x, y, tile_id, flip_x, flip_y, transpose, autotile_coord)
    if previous_tile_id != tile_id:
        _on_cell_tile_changed(
                Vector2(x, y),
                tile_id,
                previous_tile_id)
    else:
        if is_autotile and \
                previous_autotile_coord != autotile_coord:
            emit_signal(
                    "cell_autotile_changed",
                    Vector2(x, y),
                    autotile_coord,
                    previous_autotile_coord,
                    tile_id)


# FIXME: --------------------------------
# - Make sure this doesn't trigger set_cell() under the hood, which would cause
#   our signal to emit twice.
func set_cellv(
        position: Vector2,
        tile_id: int,
        flip_x := false,
        flip_y := false,
        transpose := false) -> void:
    var previous_tile_id := get_cellv(position)
    .set_cellv(position, tile_id, flip_x, flip_y, transpose)
    if previous_tile_id != tile_id:
        _on_cell_tile_changed(
                position,
                tile_id,
                previous_tile_id)


func _on_cell_tile_changed(
        cell_position: Vector2,
        tile_id: int,
        previous_tile_id: int) -> void:
    _delegate_quadrant_updates(cell_position, tile_id)
    emit_signal(
            "cell_tile_changed",
            cell_position,
            tile_id,
            previous_tile_id)
    if tile_id == INVALID_CELL or \
            previous_tile_id == INVALID_CELL:
        # FIXME: LEFT OFF HERE: ------------------
        # - Does this work correctly with the current tile-set setup?
        call_deferred(
                "update_bitmask_region",
                cell_position + Vector2(-2, -2),
                cell_position + Vector2(2, 2))


func _delegate_quadrant_updates(
        cell_position: Vector2,
        tile_id: int) -> void:
    var quadrants: Array = tile_set.get_quadrants(
            cell_position,
            tile_id,
            self)
    
    var cell_offsets := [
        Vector2(0,0),
        Vector2(1,0),
        Vector2(0,1),
        Vector2(1,1),
    ]
    
    for i in quadrants.size():
        var quadrant_position: Vector2 = quadrants[i]
        var inner_cell_offset: Vector2 = cell_offsets[i]
        var inner_cell_position := cell_position * 2 + inner_cell_offset
        # FIXME: LEFT OFF HERE: ------------------------------------ REMOVE
        print(">>>>>>>>>>>>>>>>>>>>>>>>>>>> inner_tilemap.set_cell")
        print("inner_cell_position.x = " + \
                str(Vector2(inner_cell_position.x, inner_cell_position.y)))
        print("quadrant_position = " + \
                str(quadrant_position))
        print(inner_tilemap.tile_set.get_tiles_ids())
        print(inner_tilemap.tile_set.tile_get_texture(tile_set.inner_tile_id).get_size())
        inner_tilemap.set_cell(
                inner_cell_position.x,
                inner_cell_position.y,
                tile_set.inner_tile_id,
                false,
                false,
                false,
                quadrant_position)
