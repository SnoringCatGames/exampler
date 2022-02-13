tool
class_name CornerMatchTileset
extends TileSet


# FIXME: LEFT OFF HERE: ---------------------------------------
#   - Encode fallback_subtile_corner_matches.
#   - Implement the inner-TileMap pattern to render quadrants according to the
#     outer TileMap's cells.
#   - Hook-up all tile-set configuration.
#   - Test and debug!
#   - Add support for A27.


# Dictionary<
#   CornerDirection,
#   Dictionary<
#     SubtileCorner, # Self-corner
#     Dictionary<
#       SubtileCorner, # H-opp-corner
#       Dictionary<
#         SubtileCorner, # V-opp-corner
#         (Vector2|
#         Dictionary<
#           SubtileCorner, # H-inbound-corner
#           Dictionary<
#             SubtileCorner, # V-inbound-corner
#             Vector2>>)>>>>
var subtile_corner_types: Dictionary


func _forward_subtile_selection(
        tile_id: int,
        bitmask: int,
        tile_map: Object,
        cell_position: Vector2):
    if Engine.editor_hint or \
            Su.subtile_manifest.supports_runtime_autotiling:
        var proximity := CellProximity.new(
                tile_map,
                self,
                cell_position,
                tile_id)
        var quadrant_positions := _choose_quadrants(proximity)
        # FIXME: LEFT OFF HERE: -----------------------------
        # - Pass along the quadrant positions to the inner tile-map.
        pass
    
    return Vector2.ZERO


func _choose_quadrants(proximity: CellProximity) -> Array:
    var target_corners := CellCorners.new(proximity)
    
    if !target_corners.get_are_corners_valid():
        Sc.logger.warning(
            "Not all target corners are valid:\n%s\n%s" % [
            proximity.to_string(),
            target_corners.to_string(),
        ])
        return _get_error_quadrants()
    
    var quadrant_positions := []
    quadrant_positions.resize(4)
    
    for i in CornerDirection.OUTBOUND_CORNERS.size():
        var corner_direction: int = CornerDirection.OUTBOUND_CORNERS[i]
        
        var corner_types := [
            target_corners.get_corner_type(corner_direction),
            target_corners.get_h_opp_corner_type(corner_direction),
            target_corners.get_v_opp_corner_type(corner_direction),
            target_corners.get_h_inbound_corner_type(corner_direction),
            target_corners.get_v_inbound_corner_type(corner_direction),
        ]
        
        var best_position_and_weight := _get_best_quadrant_match(
                subtile_corner_types[corner_direction],
                corner_types,
                0,
                0)
        var quadrant_position: Vector2 = best_position_and_weight[0]
        var quadrant_weight: Vector2 = best_position_and_weight[1]
        
        if quadrant_weight < \
                Su.subtile_manifest.ACCEPTABLE_MATCH_PRIORITY_THRESHOLD:
            Sc.logger.warning(
                ("No matching quadrant was found: " +
                "%s, best_quadrant_match: [position=%s, weight=%s]\n%s\n%s") % [
                CornerDirection.get_string(corner_direction),
                str(quadrant_position),
                str(quadrant_weight),
                proximity.to_string(),
                target_corners.to_string(),
            ])
            return _get_error_quadrants()
        
        quadrant_positions[i] = quadrant_position
    
    return quadrant_positions


# Array<Vector2, float>
func _get_best_quadrant_match(
        corner_type_map_or_position,
        corner_types: Array,
        i: int,
        weight: float) -> Array:
    var corner_type: int = corner_types[i]
    var current_weight_contribution := 1.0 / pow(10,i)
    
    if corner_type_map_or_position.has(corner_type):
        # There is a quadrant configured for this specific corner-type.
        corner_type_map_or_position = \
                corner_type_map_or_position[corner_type]
        weight += current_weight_contribution
        
        if corner_type_map_or_position is Vector2:
            # Base case: We found a position.
            return [corner_type_map_or_position, weight]
            
        else:
            # Recursive case: We found another mapping to consider.
            return _get_best_quadrant_match(
                    corner_type_map_or_position,
                    corner_types,
                    i + 1,
                    weight)
        
    elif Su.subtile_manifest.allows_partial_matches:
        # Consider possible fallback corner-type matches, since there is no
        # quadrant configured for this specific corner-type.
        var best_fallback_position := Vector2.INF
        var best_fallback_weight := -INF
        
        for fallback_corner_type in \
                FallbackSubtileCornerMatches.MATCHES[corner_type]:
            if corner_type_map_or_position.has(fallback_corner_type):
                # There is a quadrant configured for this fallback corner-type.
                
                var fallback_corner_type_map_or_position = \
                        corner_type_map_or_position[fallback_corner_type]
                # FIXME: LEFT OFF HERE: ---------------------------------
                # - Scale the weight according to the fallback configuration.
                weight += current_weight_contribution
                
                if fallback_corner_type_map_or_position is Vector2:
                    # Base case: We found a position.
                    if weight > best_fallback_weight:
                        best_fallback_position = \
                                fallback_corner_type_map_or_position
                        best_fallback_weight = weight
                    
                else:
                    # Recursive case: We found another mapping to consider.
                    var fallback_position_and_weight := \
                            _get_best_quadrant_match(
                                fallback_corner_type_map_or_position,
                                corner_types,
                                i + 1,
                                weight)
                    if fallback_position_and_weight[1] > best_fallback_weight:
                        best_fallback_position = fallback_position_and_weight[0]
                        best_fallback_weight = fallback_position_and_weight[1]
        
        return [best_fallback_position, best_fallback_weight]
        
    else:
        return [Vector2.INF, -INF]


func _get_error_quadrants() -> Array:
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
