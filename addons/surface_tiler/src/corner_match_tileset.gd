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

var are_45_degree_subtiles_used: bool
var are_27_degree_subtiles_used: bool

var inner_tile_id: int
var inner_tile_name: String

var error_quadrants: Array
var empty_quadrants: Array
var clear_quadarnts := [Vector2.INF, Vector2.INF, Vector2.INF, Vector2.INF]

# Dictionary<int, int>
var _tile_id_to_angle_type := {}
# Dictionary<int, int>
var _angle_type_to_tile_id := {}


func get_quadrants(
        cell_position: Vector2,
        tile_id: int,
        tile_map: TileMap) -> Array:
    if !Engine.editor_hint and \
            !Su.subtile_manifest.supports_runtime_autotiling:
        return error_quadrants
    
    var proximity := CellProximity.new(
            tile_map,
            self,
            cell_position,
            tile_id)
    var target_corners := CellCorners.new(proximity)
    
    if !target_corners.get_are_corners_valid():
        Sc.logger.warning(
            "Not all target corners are valid:\n%s\n%s" % [
            proximity.to_string(),
            target_corners.to_string(true),
        ])
        return error_quadrants
    
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
        var quadrant_weight: float = best_position_and_weight[1]
        
        # TODO: Remove. Useful for debugging.
        if proximity.get_world_position() == Vector2(-32, -160) and \
                corner_direction == CornerDirection.TOP_LEFT:
            print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>")
            print(">>")
            print(proximity.to_string())
            print(target_corners.to_string(true))
            print("_get_best_quadrant_match: " + str(best_position_and_weight))
            print(">>")
            print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>")
            print_subtile_corner_types(
                    CornerDirection.TOP_LEFT,
                    target_corners.top_left)
        
        if quadrant_weight < \
                Su.subtile_manifest.ACCEPTABLE_MATCH_PRIORITY_THRESHOLD:
            Sc.logger.warning(
                ("No matching quadrant was found: " +
                "%s, best_quadrant_match: [position=%s, weight=%s]\n%s\n%s") % [
                CornerDirection.get_string(corner_direction),
                str(quadrant_position),
                str(quadrant_weight),
                proximity.to_string(),
                target_corners.to_string(true),
            ])
            return error_quadrants
        
        quadrant_positions[i] = quadrant_position
    
    # If the matching quadrants represent the normal empty subtile, with no
    # interesting inbound neighbor matches, then we return Vector2.INF values,
    # so that the tilemap can clear the cell instead of assigning the empty
    # subtile.
    for i in quadrant_positions.size():
        if quadrant_positions[i] != empty_quadrants[i]:
            return quadrant_positions
    return clear_quadarnts


# Array<Vector2, float>
func _get_best_quadrant_match(
        corner_type_map_or_position,
        target_corner_types: Array,
        i: int,
        weight: float) -> Array:
    var iteration_exponent: int
    match i:
        0: iteration_exponent = 0
        1, 2: iteration_exponent = 1
        3, 4: iteration_exponent = 2
        _:
            Sc.logger.error("CornerMatchTileset._get_best_quadrant_match")
    
    var current_weight_contribution := 1.0 / pow(10000,iteration_exponent)
    var is_inbound_iteration := i > 2
    var target_corner_type: int = target_corner_types[i]
    
    if corner_type_map_or_position.has(target_corner_type):
        # There is a quadrant configured for this specific corner-type.
        corner_type_map_or_position = \
                corner_type_map_or_position[target_corner_type]
        weight += current_weight_contribution
        
        if corner_type_map_or_position is Vector2:
            # Base case: We found a position.
            var result := [corner_type_map_or_position, weight]
            # FIXME: LEFT OFF HERE: ----------- Remove? Or keep this for debugging?
            result.resize(7)
            result[i + 2] = 1
            return result
            
        else:
            # Recursive case: We found another mapping to consider.
            var result := _get_best_quadrant_match(
                    corner_type_map_or_position,
                    target_corner_types,
                    i + 1,
                    weight)
            # FIXME: LEFT OFF HERE: ----------- Remove? Or keep this for debugging?
            result[i + 2] = 1
            return result
        
    elif i > 0 or \
            Su.subtile_manifest.allows_fallback_corner_matches:
        # Consider possible fallback corner-type matches, since there is no
        # quadrant configured for this specific corner-type.
        var best_fallback_position_and_weight := [Vector2.INF, -INF]
        
        # FIXME: LEFT OFF HERE: ----------- Remove? Or keep this for debugging?
        var is_matched_to_unknown := false
        var did_a_fallback_match := false
        
        # Consider the UNKNOWN value as a valid fallback.
        var fallback_corner_weight_multiplier: float = 0.5
        if corner_type_map_or_position.has(SubtileCorner.UNKNOWN):
            # There is a quadrant configured for this fallback corner-type.
            
            var fallback_corner_type_map_or_position = \
                    corner_type_map_or_position[SubtileCorner.UNKNOWN]
            var fallback_weight := \
                    weight + \
                    current_weight_contribution * \
                    fallback_corner_weight_multiplier * 0.1
            
            if fallback_corner_type_map_or_position is Vector2:
                # Base case: We found a position.
                best_fallback_position_and_weight = [
                    fallback_corner_type_map_or_position,
                    fallback_weight,
                ]
                did_a_fallback_match = true
                
            else:
                # Recursive case: We found another mapping to consider.
                var fallback_position_and_weight := \
                        _get_best_quadrant_match(
                            fallback_corner_type_map_or_position,
                            target_corner_types,
                            i + 1,
                            fallback_weight)
                best_fallback_position_and_weight = \
                        fallback_position_and_weight
                did_a_fallback_match = true
        
        var is_using_h_opp_multiplier := i == 1 or i == 4
        
        # Consider all explicitly configured fallbacks.
        var fallbacks_for_corner_type: Dictionary = \
                FallbackSubtileCorners.FALLBACKS[target_corner_type]
        for fallback_corner_type in fallbacks_for_corner_type:
            var fallback_multipliers: Array = \
                    fallbacks_for_corner_type[fallback_corner_type]
            fallback_corner_weight_multiplier = \
                    fallback_multipliers[0] if \
                    is_using_h_opp_multiplier else \
                    fallback_multipliers[1]
            
            if fallback_corner_weight_multiplier <= 0.0:
                # Skip this fallback, since it is for the other direction.
                continue
            
            if corner_type_map_or_position.has(fallback_corner_type):
                # There is a quadrant configured for this fallback corner-type.
                
                var fallback_corner_type_map_or_position = \
                        corner_type_map_or_position[fallback_corner_type]
                var fallback_weight := \
                        weight + \
                        current_weight_contribution * \
                        fallback_corner_weight_multiplier * 0.1
                
                if fallback_corner_type_map_or_position is Vector2:
                    # Base case: We found a position.
                    if fallback_weight > best_fallback_position_and_weight[1]:
                        best_fallback_position_and_weight = [
                            fallback_corner_type_map_or_position,
                            fallback_weight,
                        ]
                        did_a_fallback_match = true
                    
                else:
                    # Recursive case: We found another mapping to consider.
                    var fallback_position_and_weight := \
                            _get_best_quadrant_match(
                                fallback_corner_type_map_or_position,
                                target_corner_types,
                                i + 1,
                                fallback_weight)
                    if fallback_position_and_weight[1] > \
                            best_fallback_position_and_weight[1]:
                        best_fallback_position_and_weight = \
                                fallback_position_and_weight
                        did_a_fallback_match = true
        
        if (i > 0 or \
                Su.subtile_manifest.allows_non_fallback_corner_matches):
            # Now we consider all other possible corner-types.
            var target_depth: int = \
                    SubtileCornerToDepth.CORNERS_TO_DEPTHS[target_corner_type]
            for other_corner_type in \
                    Su.subtile_manifest.SUBTILE_CORNER_TYPE_VALUE_TO_KEY:
                var other_depth: int = SubtileCornerToDepth.CORNERS_TO_DEPTHS \
                        [other_corner_type]
                
                if corner_type_map_or_position.has(other_corner_type):
                    # There is a quadrant configured for this other corner-type.
                    var other_corner_type_map_or_position = \
                            corner_type_map_or_position[other_corner_type]
                    
                    var other_corner_weight_multiplier: float = \
                            Su.subtile_manifest \
                                .SUBTILE_DEPTH_TO_UNMATCHED_CORNER_WEIGHT_MULTIPLIER \
                                [target_depth][other_depth]
                    
                    var other_weight := \
                            weight + \
                            current_weight_contribution * \
                            other_corner_weight_multiplier * 0.01
                    
                    if other_corner_type_map_or_position is Vector2:
                        # Base case: We found a position.
                        if other_weight > best_fallback_position_and_weight[1]:
                            best_fallback_position_and_weight = [
                                other_corner_type_map_or_position,
                                other_weight,
                            ]
                            is_matched_to_unknown = \
                                    other_corner_type == SubtileCorner.UNKNOWN
                            did_a_fallback_match = false
                        
                    else:
                        # Recursive case: We found another mapping to consider.
                        var other_position_and_weight := \
                                _get_best_quadrant_match(
                                    other_corner_type_map_or_position,
                                    target_corner_types,
                                    i + 1,
                                    other_weight)
                        if other_position_and_weight[1] > \
                                best_fallback_position_and_weight[1]:
                            best_fallback_position_and_weight = \
                                    other_position_and_weight
                            is_matched_to_unknown = \
                                    other_corner_type == SubtileCorner.UNKNOWN
                            did_a_fallback_match = false
        
        # FIXME: LEFT OFF HERE: ----------- Remove? Or keep this for debugging?
        best_fallback_position_and_weight.resize(7)
        best_fallback_position_and_weight[i + 2] = \
                2 if did_a_fallback_match else \
                3 if is_matched_to_unknown else \
                4
        return best_fallback_position_and_weight
        
    else:
        var result := [Vector2.INF, -INF]
        # FIXME: LEFT OFF HERE: ----------- Remove? Or keep this for debugging?
        result.resize(7)
        result[i + 2] = -1
        return result


func _is_tile_bound(
        drawn_id: int,
        neighbor_id: int) -> bool:
    return _tile_id_to_angle_type.has(drawn_id) and \
            _tile_id_to_angle_type.has(neighbor_id)


func tile_get_angle_type(tile_id: int) -> int:
    if tile_id == TileMap.INVALID_CELL:
        return CellAngleType.EMPTY
    elif _tile_id_to_angle_type.has(tile_id):
        return _tile_id_to_angle_type[tile_id]
    else:
        # Non-corner-match-tiles are treated as 90-degree surfaces.
        return CellAngleType.A90


func get_is_a_corner_match_subtile(tile_id: int) -> bool:
    return _tile_id_to_angle_type.has(tile_id)


func get_outer_cell_size() -> Vector2:
    return autotile_get_size(_angle_type_to_tile_id[CellAngleType.A90])


func get_inner_cell_size() -> Vector2:
    return autotile_get_size(inner_tile_id)


func print_subtile_corner_types(
        target_corner_direction := -1,
        target_self_corner_type := -1,
        target_h_opp_corner_type := -1,
        target_v_opp_corner_type := -1,
        target_h_inbound_corner_type := -1,
        target_v_inbound_corner_type := -1) -> void:
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    print(">>> CornerMatchTileset.subtile_corner_types         >>>")
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    for corner_direction in _sort(subtile_corner_types.keys()):
        if target_corner_direction >= 0 and \
                target_corner_direction != corner_direction:
            continue
        print(CornerDirection.get_string(corner_direction))
        var self_corner_type_map: Dictionary = \
                subtile_corner_types[corner_direction]
        for self_corner_type in _sort(self_corner_type_map.keys()):
            if target_self_corner_type >= 0 and \
                    target_self_corner_type != self_corner_type:
                continue
            print("  Self: " + Su.subtile_manifest \
                    .get_subtile_corner_string(self_corner_type))
            var h_opp_corner_type_map: Dictionary = \
                    self_corner_type_map[self_corner_type]
            for h_opp_corner_type in _sort(h_opp_corner_type_map.keys()):
                if target_h_opp_corner_type >= 0 and \
                        target_h_opp_corner_type != corner_direction:
                    continue
                print("    H-opp: " + Su.subtile_manifest \
                        .get_subtile_corner_string(h_opp_corner_type))
                var v_opp_corner_type_map: Dictionary = \
                        h_opp_corner_type_map[h_opp_corner_type]
                for v_opp_corner_type in _sort(v_opp_corner_type_map.keys()):
                    if target_v_opp_corner_type >= 0 and \
                            target_v_opp_corner_type != corner_direction:
                        continue
                    var position_or_h_inbound_corner_type_map = \
                            v_opp_corner_type_map[v_opp_corner_type]
                    if position_or_h_inbound_corner_type_map is Vector2:
                        print("      V-opp: " + Su.subtile_manifest \
                                .get_subtile_corner_string(v_opp_corner_type) +
                                " => Position: " +
                                str(position_or_h_inbound_corner_type_map))
                    else:
                        print("      V-opp: " + Su.subtile_manifest \
                                .get_subtile_corner_string(v_opp_corner_type))
                        for h_inbound_corner_type in \
                                _sort(position_or_h_inbound_corner_type_map \
                                    .keys()):
                            if target_h_inbound_corner_type >= 0 and \
                                    target_h_inbound_corner_type != \
                                        corner_direction:
                                continue
                            print("        H-inbound: " +
                                    Su.subtile_manifest \
                                        .get_subtile_corner_string(
                                            h_inbound_corner_type))
                            var v_inbound_corner_type_map: Dictionary = \
                                    position_or_h_inbound_corner_type_map \
                                        [h_inbound_corner_type]
                            for v_inbound_corner_type in \
                                    _sort(v_inbound_corner_type_map.keys()):
                                if target_v_inbound_corner_type >= 0 and \
                                        target_v_inbound_corner_type != \
                                            corner_direction:
                                    continue
                                var position: Vector2 = \
                                        v_inbound_corner_type_map \
                                            [v_inbound_corner_type]
                                print("          V-inbound: " +
                                        Su.subtile_manifest \
                                            .get_subtile_corner_string(
                                                v_inbound_corner_type) +
                                        " => Position: " + 
                                        str(position))
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")


func _sort(arr: Array) -> Array:
    arr.sort()
    return arr
