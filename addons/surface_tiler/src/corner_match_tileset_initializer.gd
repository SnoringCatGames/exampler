tool
class_name CornerMatchTilesetInitializer
extends Node


func initialize_tileset(tile_set_config: Dictionary) -> void:
    var tile_set: CornerMatchTileset = tile_set_config.tile_set
    tile_set.are_45_degree_subtiles_used = \
            tile_set_config.are_45_degree_subtiles_used
    tile_set.are_27_degree_subtiles_used = \
            tile_set_config.are_27_degree_subtiles_used
    
    tile_set_config.tile_set_quadrants_texture = \
            load(tile_set_config.tile_set_quadrants_path)
    
    var corner_type_annotation_key: Dictionary = \
            Su.subtile_manifest.tile_set_image_parser \
                .parse_corner_type_annotation_key(
                    Su.subtile_manifest.corner_type_annotation_key_path,
                    tile_set_config.quadrant_size)
    var subtile_corner_types: Dictionary = \
            Su.subtile_manifest.tile_set_image_parser \
                .parse_tile_set_corner_type_annotations(
                    corner_type_annotation_key,
                    Su.subtile_manifest \
                        .corner_types_to_swap_for_bottom_quadrants,
                    tile_set_config.tile_set_corner_type_annotations_path,
                    tile_set_config.quadrant_size,
                    tile_set)
    tile_set.subtile_corner_types = subtile_corner_types
    tile_set.empty_quadrants = _get_empty_quadrants(subtile_corner_types)
    tile_set.error_quadrants = _get_error_quadrants(subtile_corner_types)
    
    var shapes: Dictionary = Su.subtile_manifest.shape_calculator \
            .create_tileset_shapes(subtile_corner_types, tile_set_config)
    # Dictionary<
    #   CornerDirection,
    #   Dictionary<
    #     SubtileCorner,
    #     Dictionary<
    #       SubtileCorner,
    #       Dictionary<
    #         SubtileCorner,
    #         Shape2D>>>>
    var collision_shapes: Dictionary = shapes.collision_shapes
    # Dictionary<
    #   CornerDirection,
    #   Dictionary<
    #     SubtileCorner,
    #     Dictionary<
    #       SubtileCorner,
    #       Dictionary<
    #         SubtileCorner,
    #         OccluderPolygon2D>>>>
    var occlusion_shapes: Dictionary = shapes.occlusion_shapes
    
    _initialize_inner_tile(
            tile_set,
            subtile_corner_types,
            collision_shapes,
            occlusion_shapes,
            tile_set_config)
    tile_set.inner_tile_id = tile_set.inner_tile_id
    
    _initialize_outer_tile(
            tile_set,
            CellAngleType.A90,
            tile_set_config)
    if tile_set_config.are_45_degree_subtiles_used:
        _initialize_outer_tile(
                tile_set,
                CellAngleType.A45,
                tile_set_config)
    if tile_set_config.are_27_degree_subtiles_used:
        _initialize_outer_tile(
                tile_set,
                CellAngleType.A27,
                tile_set_config)


func _initialize_inner_tile(
        tile_set: CornerMatchTileset,
        subtile_corner_types: Dictionary,
        collision_shapes: Dictionary,
        occlusion_shapes: Dictionary,
        tile_set_config: Dictionary) -> void:
    var tile_name: String = "*" + Su.subtile_manifest.inner_autotile_name
    
    var tile_id := tile_set.find_tile_by_name(tile_name)
    if tile_id >= 0:
        # Clear any pre-existing state for this tile.
        tile_set.remove_tile(tile_id)
    else:
        tile_id = tile_set.get_last_unused_tile_id()
    tile_set.create_tile(tile_id)
    tile_set.inner_tile_id = tile_id
    tile_set.inner_tile_name = tile_name
    
    var quadrants_texture_size: Vector2 = \
            tile_set_config.tile_set_quadrants_texture.get_size()
    var tile_region := Rect2(Vector2.ZERO, quadrants_texture_size)
    
    var subtile_size: Vector2 = Vector2.ONE * tile_set_config.quadrant_size
    
    tile_set.tile_set_name(tile_id, tile_name)
    tile_set.tile_set_texture(tile_id, \
            tile_set_config.tile_set_quadrants_texture)
    tile_set.tile_set_region(tile_id, tile_region)
    tile_set.tile_set_tile_mode(tile_id, TileSet.AUTO_TILE)
    tile_set.autotile_set_size(tile_id, subtile_size)
    tile_set.autotile_set_bitmask_mode(tile_id, TileSet.BITMASK_3X3_MINIMAL)
    
    _set_inner_tile_shapes_for_quadrants(
            tile_set,
            tile_id,
            subtile_corner_types,
            collision_shapes,
            occlusion_shapes)


func _initialize_outer_tile(
        tile_set: CornerMatchTileset,
        angle_type: int,
        tile_set_config: Dictionary) -> void:
    var tile_name_prefix: String
    var tile_name_suffix: String
    match angle_type:
        CellAngleType.A90:
            tile_name_prefix = "***"
            tile_name_suffix = "90"
        CellAngleType.A45:
            tile_name_prefix = "**"
            tile_name_suffix = "45"
        CellAngleType.A27:
            tile_name_prefix = "*"
            tile_name_suffix = "27"
        _:
            Sc.logger.error("CornerMatchTilesetInitializer._initialize_tile")
    
    var tile_name: String = \
            tile_name_prefix + \
            Su.subtile_manifest.outer_autotile_name + \
            tile_name_suffix
    
    var tile_id := tile_set.find_tile_by_name(tile_name)
    if tile_id >= 0:
        # Clear any pre-existing state for this tile.
        tile_set.remove_tile(tile_id)
    else:
        tile_id = tile_set.get_last_unused_tile_id()
    tile_set.create_tile(tile_id)
    
    tile_set._tile_id_to_angle_type[tile_id] = angle_type
    tile_set._angle_type_to_tile_id[angle_type] = tile_id
    
    var empty_texture: Texture = load(Sc.images.TRANSPARENT_PIXEL_PATH)
    var empty_texture_size: Vector2 = empty_texture.get_size()
    var tile_region := Rect2(Vector2.ZERO, empty_texture_size)
    
    # FIXME: LEFT OFF HERE: -------------------------
    # - Do I need to scale the subtile/texture?
    # - Maybe I actually need to use the underlying quadrants texture, so that
    #   I can show the correct tile icon.
    
    var subtile_size: Vector2 = \
            Vector2.ONE * tile_set_config.quadrant_size * 2
    
    tile_set.tile_set_name(tile_id, tile_name)
    tile_set.tile_set_texture(tile_id, empty_texture)
    tile_set.tile_set_region(tile_id, tile_region)
    tile_set.tile_set_tile_mode(tile_id, TileSet.AUTO_TILE)
    tile_set.autotile_set_size(tile_id, subtile_size)
    tile_set.autotile_set_bitmask_mode(tile_id, TileSet.BITMASK_3X3_MINIMAL)
    
    _set_outer_tile_icon_coordinates(
            tile_set,
            tile_id)


func _set_outer_tile_icon_coordinates(
        tile_set: CornerMatchTileset,
        tile_id: int) -> void:
    # FIXME: LEFT OFF HERE: ----------------------------
    var icon_coordinate := Vector2.ZERO
    tile_set.autotile_set_icon_coordinate(tile_id, icon_coordinate)


func _set_inner_tile_shapes_for_quadrants(
        tile_set: CornerMatchTileset,
        tile_id: int,
        subtile_corner_types: Dictionary,
        collision_shapes: Dictionary,
        occlusion_shapes: Dictionary) -> void:
    for corner_direction in subtile_corner_types:
        var self_corner_type_map: Dictionary = \
                subtile_corner_types[corner_direction]
        for self_corner_type in self_corner_type_map:
            var h_opp_corner_type_map: Dictionary = \
                    self_corner_type_map[self_corner_type]
            for h_opp_corner_type in h_opp_corner_type_map:
                var v_opp_corner_type_map: Dictionary = \
                        h_opp_corner_type_map[h_opp_corner_type]
                for v_opp_corner_type in v_opp_corner_type_map:
                    var position_or_h_inbound_corner_type_map = \
                            v_opp_corner_type_map[v_opp_corner_type]
                    if position_or_h_inbound_corner_type_map is Vector2:
                        _set_shapes_for_quadrant(
                                tile_set,
                                tile_id,
                                position_or_h_inbound_corner_type_map,
                                self_corner_type,
                                h_opp_corner_type,
                                v_opp_corner_type,
                                corner_direction,
                                collision_shapes,
                                occlusion_shapes)
                    else:
                        for v_inbound_corner_type_map in \
                                position_or_h_inbound_corner_type_map.values():
                            for position in v_inbound_corner_type_map.values():
                                _set_shapes_for_quadrant(
                                        tile_set,
                                        tile_id,
                                        position,
                                        self_corner_type,
                                        h_opp_corner_type,
                                        v_opp_corner_type,
                                        corner_direction,
                                        collision_shapes,
                                        occlusion_shapes)


func _set_shapes_for_quadrant(
        tile_set: CornerMatchTileset,
        tile_id: int,
        quadrant_position: Vector2,
        self_corner_type: int,
        h_opp_corner_type: int,
        v_opp_corner_type: int,
        corner_direction: int,
        collision_shapes: Dictionary,
        occlusion_shapes: Dictionary) -> void:
    var collision_shape: Shape2D = collision_shapes \
            [corner_direction] \
            [self_corner_type] \
            [h_opp_corner_type] \
            [v_opp_corner_type]
    var occlusion_shape: OccluderPolygon2D = occlusion_shapes \
            [corner_direction] \
            [self_corner_type] \
            [h_opp_corner_type] \
            [v_opp_corner_type]
    
    if is_instance_valid(collision_shape):
        tile_set.tile_add_shape(
                tile_id,
                collision_shape,
                Transform2D.IDENTITY,
                false,
                quadrant_position)
        tile_set.autotile_set_light_occluder(
                tile_id,
                occlusion_shape,
                quadrant_position)
    
    var bitmask := \
            TileSet.BIND_TOPLEFT | \
            TileSet.BIND_TOP | \
            TileSet.BIND_TOPRIGHT | \
            TileSet.BIND_LEFT | \
            TileSet.BIND_CENTER | \
            TileSet.BIND_RIGHT | \
            TileSet.BIND_BOTTOMLEFT | \
            TileSet.BIND_BOTTOM | \
            TileSet.BIND_BOTTOMRIGHT if \
            is_instance_valid(collision_shape) else \
            TileSet.BIND_CENTER
    tile_set.autotile_set_bitmask(
            tile_id,
            quadrant_position,
            bitmask)


func _get_error_quadrants(subtile_corner_types: Dictionary) -> Array:
    var tl_quadrant_position: Vector2 = subtile_corner_types \
            [CornerDirection.TOP_LEFT] \
            [SubtileCorner.ERROR] \
            [SubtileCorner.ERROR] \
            [SubtileCorner.ERROR]
    var tr_quadrant_position: Vector2 = subtile_corner_types \
            [CornerDirection.TOP_RIGHT] \
            [SubtileCorner.ERROR] \
            [SubtileCorner.ERROR] \
            [SubtileCorner.ERROR]
    var bl_quadrant_position: Vector2 = subtile_corner_types \
            [CornerDirection.BOTTOM_LEFT] \
            [SubtileCorner.ERROR] \
            [SubtileCorner.ERROR] \
            [SubtileCorner.ERROR]
    var br_quadrant_position: Vector2 = subtile_corner_types \
            [CornerDirection.BOTTOM_RIGHT] \
            [SubtileCorner.ERROR] \
            [SubtileCorner.ERROR] \
            [SubtileCorner.ERROR]
    return [
        tl_quadrant_position,
        tr_quadrant_position,
        bl_quadrant_position,
        br_quadrant_position,
    ]


func _get_empty_quadrants(subtile_corner_types: Dictionary) -> Array:
    var tl_quadrant_position_or_h_inbound_map = subtile_corner_types \
            [CornerDirection.TOP_LEFT] \
            [SubtileCorner.EMPTY] \
            [SubtileCorner.EMPTY] \
            [SubtileCorner.EMPTY]
    var tl_quadrant_position: Vector2
    if tl_quadrant_position_or_h_inbound_map is Vector2:
        tl_quadrant_position = tl_quadrant_position_or_h_inbound_map
    else:
        tl_quadrant_position = tl_quadrant_position_or_h_inbound_map \
                [SubtileCorner.UNKNOWN] \
                [SubtileCorner.UNKNOWN]
    var tr_quadrant_position_or_h_inbound_map = subtile_corner_types \
            [CornerDirection.TOP_RIGHT] \
            [SubtileCorner.EMPTY] \
            [SubtileCorner.EMPTY] \
            [SubtileCorner.EMPTY]
    var tr_quadrant_position: Vector2
    if tr_quadrant_position_or_h_inbound_map is Vector2:
        tr_quadrant_position = tr_quadrant_position_or_h_inbound_map
    else:
        tr_quadrant_position = tr_quadrant_position_or_h_inbound_map \
                [SubtileCorner.UNKNOWN] \
                [SubtileCorner.UNKNOWN]
    var bl_quadrant_position_or_h_inbound_map = subtile_corner_types \
            [CornerDirection.BOTTOM_LEFT] \
            [SubtileCorner.EMPTY] \
            [SubtileCorner.EMPTY] \
            [SubtileCorner.EMPTY]
    var bl_quadrant_position: Vector2
    if bl_quadrant_position_or_h_inbound_map is Vector2:
        bl_quadrant_position = bl_quadrant_position_or_h_inbound_map
    else:
        bl_quadrant_position = bl_quadrant_position_or_h_inbound_map \
                [SubtileCorner.UNKNOWN] \
                [SubtileCorner.UNKNOWN]
    var br_quadrant_position_or_h_inbound_map = subtile_corner_types \
            [CornerDirection.BOTTOM_RIGHT] \
            [SubtileCorner.EMPTY] \
            [SubtileCorner.EMPTY] \
            [SubtileCorner.EMPTY]
    var br_quadrant_position: Vector2
    if br_quadrant_position_or_h_inbound_map is Vector2:
        br_quadrant_position = br_quadrant_position_or_h_inbound_map
    else:
        br_quadrant_position = br_quadrant_position_or_h_inbound_map \
                [SubtileCorner.UNKNOWN] \
                [SubtileCorner.UNKNOWN]
    return [
        tl_quadrant_position,
        tr_quadrant_position,
        bl_quadrant_position,
        br_quadrant_position,
    ]
