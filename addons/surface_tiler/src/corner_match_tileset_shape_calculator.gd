tool
class_name CornerMatchTilesetShapeCalculator
extends Node


func create_tileset_shapes(tile_set_config: Dictionary) -> Dictionary:
    # Use this to memoize and dedup shape instances.
    # Dictionary<
    #   QuadrantShapeType,
    #   Dictionary<
    #     CornerDirection,
    #     [Shape2D, OccluderPolygon2D]>>
    var shape_type_to_shapes := _create_shape_type_to_shapes(tile_set_config)
    
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
func _create_shape_type_to_shapes(tile_set_config: Dictionary) -> Dictionary:
    var shape_type_to_shapes := {}
    
    for shape_type in QuadrantShapeType.VALUES:
        var corner_direction_to_shapes := {}
        shape_type_to_shapes[shape_type] = corner_direction_to_shapes
        
        for corner_direction in CornerDirection.OUTBOUND_CORNERS:
            var vertices := _get_shape_vertices(
                    shape_type,
                    corner_direction,
                    tile_set_config)
            
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
        tile_set_config: Dictionary) -> Array:
    var vertices := _get_shape_vertices_for_shape_type_at_top_left(
            shape_type,
            tile_set_config)
    assert(vertices.size() % 2 == 0)
    
    # Flip vertically if needed.
    if !CornerDirection.get_is_top(corner_direction):
        for vertex_index in vertices.size() / 2:
            var coordinate_index: int = vertex_index * 2 + 1
            vertices[coordinate_index] = \
                    tile_set_config.quadrant_size - \
                    vertices[coordinate_index]
    
    # Flip horizontally if needed.
    if !CornerDirection.get_is_left(corner_direction):
        for vertex_index in vertices.size() / 2:
            var coordinate_index: int = vertex_index * 2
            vertices[coordinate_index] = \
                    tile_set_config.quadrant_size - \
                    vertices[coordinate_index]
    
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
                0, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        QuadrantShapeType.CLIPPED_CORNER_90_90:
            return [
                0, collision_margin,
                collision_margin, collision_margin,
                collision_margin, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        QuadrantShapeType.CLIPPED_CORNER_45:
            return [
                0, collision_margin,
                collision_margin, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        QuadrantShapeType.MARGIN_TOP_90:
            return [
                0, collision_margin,
                quadrant_size, collision_margin,
                quadrant_size, quadrant_size,
                0, quadrant_size,
            ]
        QuadrantShapeType.MARGIN_SIDE_90:
            return [
                collision_margin, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size,
                collision_margin, quadrant_size,
            ]
        QuadrantShapeType.MARGIN_TOP_AND_SIDE_90:
            return [
                collision_margin, collision_margin,
                quadrant_size, collision_margin,
                quadrant_size, quadrant_size,
                collision_margin, quadrant_size,
            ]
        QuadrantShapeType.FLOOR_45_N:
            return [
                0, collision_margin,
                quadrant_size - collision_margin, quadrant_size,
                0, quadrant_size,
            ]
        QuadrantShapeType.CEILING_45_N:
            return [
                collision_margin, 0,
                quadrant_size, 0,
                quadrant_size, quadrant_size - collision_margin,
            ]
        QuadrantShapeType.EXT_90H_45_CONVEX_ACUTE:
            return [
                collision_margin * 2, collision_margin,
                quadrant_size, collision_margin,
                quadrant_size, quadrant_size - collision_margin,
            ]
        QuadrantShapeType.EXT_90V_45_CONVEX_ACUTE:
            return [
                collision_margin, collision_margin * 2,
                quadrant_size - collision_margin, quadrant_size,
                collision_margin, quadrant_size,
            ]
        _:
            Sc.logger.error(
                    "CornerMatchTilesetShapeCalculator" +
                    "._get_shape_vertices_for_shape_type_at_top_left")
            return []
