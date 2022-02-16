tool
class_name CornerMatchTilesetShapeCalculator
extends Node


func create_tileset_shapes(tile_set_config: Dictionary) -> Dictionary:
    var shape_types_to_swap := {}
    for corner_type_to_swap in \
            Su.subtile_manifest.corner_types_to_swap_for_bottom_quadrants:
        var shape_type_to_swap: int = \
                QuadrantShapeType.get_shape_type_for_corner_type(
                    corner_type_to_swap)
        shape_types_to_swap[shape_type_to_swap] = true
    
    # Use this to memoize and dedup shape instances.
    # Dictionary<
    #   QuadrantShapeType,
    #   Dictionary<
    #     CornerDirection,
    #     [Shape2D, OccluderPolygon2D]>>
    var shape_type_to_shapes := _create_shape_type_to_shapes(
            tile_set_config,
            shape_types_to_swap)
    
    # Dictionary<CornerDirection, Dictionary<SubtileCorner, Shape2D>>
    var collision_shapes := {}
    # Dictionary<CornerDirection, Dictionary<SubtileCorner, OccluderPolygon2D>>
    var occlusion_shapes := {}
    
    for corner_direction in CornerDirection.OUTBOUND_CORNERS:
        collision_shapes[corner_direction] = {}
        occlusion_shapes[corner_direction] = {}
        for corner_type in Su.subtile_manifest.SUBTILE_CORNER_TYPE_VALUE_TO_KEY:
            var shape_type := QuadrantShapeType.get_shape_type_for_corner_type(
                    corner_type)
            var shapes: Array = \
                    shape_type_to_shapes[shape_type][corner_direction]
            collision_shapes[corner_direction][corner_type] = shapes[0]
            occlusion_shapes[corner_direction][corner_type] = shapes[1]
    
    return {
        collision_shapes = collision_shapes,
        occlusion_shapes = occlusion_shapes,
    }

# Dictionary<
#   QuadrantShapeType,
#   Dictionary<
#     CornerDirection,
#     Dictionary<
#       SubtileCorner,
#       [Array<Vector2>, Shape2D, OccluderPolygon2D]>>>
func _create_shape_type_to_shapes(
        tile_set_config: Dictionary,
        shape_types_to_swap: Dictionary) -> Dictionary:
    var shape_type_to_shapes := {}
    
    # FIXME: LEFT OFF HERE: ---------------------------------------
    # - 
    
    for shape_type in QuadrantShapeType.VALUES:
        var corner_direction_to_shapes := {}
        shape_type_to_shapes[shape_type] = corner_direction_to_shapes
        
        for corner_direction in CornerDirection.OUTBOUND_CORNERS:
            var vertices := _get_shape_vertices(
                    shape_type,
                    corner_direction,
                    tile_set_config,
                    shape_types_to_swap)
            
            var collision_shape: Shape2D
            var occlusion_shape: OccluderPolygon2D
            
            if !vertices.empty():
                var vertices_pool := PoolVector2Array(vertices)
                
                if Su.subtile_manifest.forces_convex_collision_shapes or \
                        tile_set_config.subtile_collision_margin == 0.0:
                    collision_shape = ConvexPolygonShape2D.new()
                    collision_shape.points = vertices_pool
                else:
                    collision_shape = ConcavePolygonShape2D.new()
                    collision_shape.segments = vertices_pool
                
                occlusion_shape = OccluderPolygon2D.new()
                occlusion_shape.polygon = vertices_pool
            
            var shapes := [
                collision_shape,
                occlusion_shape,
            ]
            corner_direction_to_shapes[corner_direction] = shapes
    
    return shape_type_to_shapes


func _get_shape_vertices(
        shape_type: int,
        corner_direction: int,
        tile_set_config: Dictionary,
        shape_types_to_swap: Dictionary) -> Array:
    var vertices := _get_shape_vertices_for_shape_type_at_top_left(
            shape_type,
            tile_set_config)
    
    var is_a_shape_type_to_swap := shape_types_to_swap.has(shape_type)
    if is_a_shape_type_to_swap:
        # Flip horizontally if needed.
        if CornerDirection.get_is_top(corner_direction) != \
                CornerDirection.get_is_left(corner_direction):
            for vertex_index in vertices.size():
                vertices[vertex_index].x = \
                        tile_set_config.quadrant_size - vertices[vertex_index].x
    else:
        # Flip vertically if needed.
        if !CornerDirection.get_is_top(corner_direction):
            for vertex_index in vertices.size():
                vertices[vertex_index].y = \
                        tile_set_config.quadrant_size - vertices[vertex_index].y
        # Flip horizontally if needed.
        if !CornerDirection.get_is_left(corner_direction):
            for vertex_index in vertices.size():
                vertices[vertex_index].x = \
                        tile_set_config.quadrant_size - vertices[vertex_index].x
    
    return vertices


func _get_shape_vertices_for_shape_type_at_top_left(
        shape_type: int,
        tile_set_config: Dictionary) -> Array:
    var quadrant_size: int = tile_set_config.quadrant_size
    var collision_margin: float = tile_set_config.subtile_collision_margin
    
    match shape_type:
        QuadrantShapeType.EMPTY:
            return []
        QuadrantShapeType.FULL_SQUARE:
            return [
                Vector2(0, 0),
                Vector2(quadrant_size, 0),
                Vector2(quadrant_size, quadrant_size),
                Vector2(0, quadrant_size),
            ]
        QuadrantShapeType.CLIPPED_CORNER_90_90:
            return [
                Vector2(0, collision_margin),
                Vector2(collision_margin, collision_margin),
                Vector2(collision_margin, 0),
                Vector2(quadrant_size, 0),
                Vector2(quadrant_size, quadrant_size),
                Vector2(0, quadrant_size),
            ]
        QuadrantShapeType.CLIPPED_CORNER_45:
            return [
                Vector2(0, collision_margin),
                Vector2(collision_margin, 0),
                Vector2(quadrant_size, 0),
                Vector2(quadrant_size, quadrant_size),
                Vector2(0, quadrant_size),
            ]
        QuadrantShapeType.MARGIN_TOP_90:
            return [
                Vector2(0, collision_margin),
                Vector2(quadrant_size, collision_margin),
                Vector2(quadrant_size, quadrant_size),
                Vector2(0, quadrant_size),
            ]
        QuadrantShapeType.MARGIN_SIDE_90:
            return [
                Vector2(collision_margin, 0),
                Vector2(quadrant_size, 0),
                Vector2(quadrant_size, quadrant_size),
                Vector2(collision_margin, quadrant_size),
            ]
        QuadrantShapeType.MARGIN_TOP_AND_SIDE_90:
            return [
                Vector2(collision_margin, collision_margin),
                Vector2(quadrant_size, collision_margin),
                Vector2(quadrant_size, quadrant_size),
                Vector2(collision_margin, quadrant_size),
            ]
        QuadrantShapeType.FLOOR_45_N:
            return [
                Vector2(0, collision_margin),
                Vector2(quadrant_size - collision_margin, quadrant_size),
                Vector2(0, quadrant_size),
            ]
        QuadrantShapeType.CEILING_45_N:
            return [
                Vector2(collision_margin, 0),
                Vector2(quadrant_size, 0),
                Vector2(quadrant_size, quadrant_size - collision_margin),
            ]
        QuadrantShapeType.EXT_90H_45_CONVEX_ACUTE:
            return [
                Vector2(collision_margin * 2, collision_margin),
                Vector2(quadrant_size, collision_margin),
                Vector2(quadrant_size, quadrant_size - collision_margin),
            ]
        QuadrantShapeType.EXT_90V_45_CONVEX_ACUTE:
            return [
                Vector2(collision_margin, collision_margin * 2),
                Vector2(quadrant_size - collision_margin, quadrant_size),
                Vector2(collision_margin, quadrant_size),
            ]
        _:
            Sc.logger.error(
                    "CornerMatchTilesetShapeCalculator" +
                    "._get_shape_vertices_for_shape_type_at_top_left")
            return []
