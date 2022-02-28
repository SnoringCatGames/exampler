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

export var logs_autotiling_state_for_selected_tile := false \
        setget _set_logs_autotiling_state_for_selected_tile
export var logs_autotiling_errors := true \
        setget _set_logs_autotiling_errors

var inner_tilemap: CornerMatchInnerTilemap


func _ready() -> void:
    if !is_instance_valid(tile_set) or \
            tile_set.resource_path == Su.PLACEHOLDER_SURFACES_TILE_SET_PATH:
        tile_set = Su.default_tile_set
        property_list_changed_notify()
    assert(tile_set is CornerMatchTileset)
    
    var children := Sc.utils.get_children_by_type(self, CornerMatchInnerTilemap)
    if children.empty():
        inner_tilemap = CornerMatchInnerTilemap.new()
        inner_tilemap.name = "InnerTileMap"
        add_child(inner_tilemap)
        var ancestor := Sc.utils.get_ancestor_by_type(self, ScaffolderLevel)
        inner_tilemap.owner = ancestor
    else:
        inner_tilemap = children[0]
    inner_tilemap.tile_set = tile_set
    
    self.cell_size = tile_set.get_outer_cell_size()
    inner_tilemap.cell_size = tile_set.get_inner_cell_size()
    
    assert(cell_size == Sc.level_session.config.cell_size)


func _enter_tree() -> void:
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


func _set_logs_autotiling_state_for_selected_tile(value: bool) -> void:
    logs_autotiling_state_for_selected_tile = value
    property_list_changed_notify()
    update()


func _set_logs_autotiling_errors(value: bool) -> void:
    logs_autotiling_errors = value
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
    if tile_id == INVALID_CELL or \
            previous_tile_id == INVALID_CELL:
        _delegate_quadrant_updates(cell_position, tile_id)
        
        # Update all nearby neighbor cells.
        for y in 7:
            for x in 7:
                if (y < 1 or y > 5) and (x < 1 or x > 5):
                    # Skip the corners, since they won't trigger any changes.
                    continue
                var neighbor_position := cell_position + Vector2(x - 3, y - 3)
                if neighbor_position == cell_position:
                    # We already updated this cell.
                    continue
                _delegate_quadrant_updates(neighbor_position, tile_id)
    
    # FIXME: --------------
    # - Trigger debug printing somewhere else (probably through a
    #   click-to-inspect mode that's toggled through the plugin UI).
    tile_set.get_quadrants(
            cell_position,
            tile_id,
            self,
            logs_autotiling_state_for_selected_tile,
            logs_autotiling_errors)
    
    emit_signal(
            "cell_tile_changed",
            cell_position,
            tile_id,
            previous_tile_id)


func _delegate_quadrant_updates(
        cell_position: Vector2,
        tile_id: int) -> void:
    var quadrants: Array = tile_set.get_quadrants(
            cell_position,
            tile_id,
            self,
            false,
            logs_autotiling_errors)
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
        if quadrant_position == Vector2.INF:
            # Clear the cell.
            inner_tilemap.set_cell(
                    inner_cell_position.x,
                    inner_cell_position.y,
                    -1)
        else:
            inner_tilemap.set_cell(
                    inner_cell_position.x,
                    inner_cell_position.y,
                    tile_set.inner_tile_id,
                    false,
                    false,
                    false,
                    quadrant_position)
