tool
class_name CornerMatchTileset
extends TileSet


# Dictionary<
#   CornerDirection,
#   Dictionary<
#     SubtileCorner, # Self-corner
#     (Vector2|Dictionary<
#       SubtileCorner, # H-opp-corner
#       (Vector2|Dictionary<
#         SubtileCorner, # V-opp-corner
#         (Vector2|Dictionary<
#           SubtileCorner, # H-inbound-corner
#           (Vector2|Dictionary<
#             SubtileCorner, # V-inbound-corner
#             (Vector2|Dictionary<
#               SubtileCorner, # Diagonal-opp-corner
#               (Vector2|Dictionary<
#                 SubtileCorner, # H2-inbound-corner
#                 (Vector2|Dictionary<
#                   SubtileCorner, # V2-inbound-corner
#                   Vector2        # Quadrant coordinates
#                 >)>)>)>)>)>)>)>>
var subtile_corner_types: Dictionary

var are_45_degree_subtiles_used: bool
var are_27_degree_subtiles_used: bool

var inner_tile_id: int
var inner_tile_name: String

var error_quadrants: Array
var empty_quadrants: Array
var clear_quadrants := [Vector2.INF, Vector2.INF, Vector2.INF, Vector2.INF]

# Dictionary<int, int>
var _tile_id_to_angle_type := {}
# Dictionary<int, int>
var _angle_type_to_tile_id := {}


func get_quadrants(
        cell_position: Vector2,
        tile_id: int,
        tile_map: TileMap,
        logs_debug_info := false) -> Array:
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
        
        if logs_debug_info:
            print("")
            print(">>> get_quadrants: %s" % \
                    CornerDirection.get_string(corner_direction))
            print(proximity.to_string())
            print(target_corners.to_string(true))
            print(_get_position_and_weight_results_string(
                        best_position_and_weight))
            _print_subtile_corner_types(
                    corner_direction,
                    target_corners.get_corner_type(corner_direction))
            print(">>>")
            print("")
        
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
            if logs_debug_info:
                _print_subtile_corner_types(
                        corner_direction,
                        target_corners.get_corner_type(corner_direction))
            quadrant_position = error_quadrants[i]
        
        quadrant_positions[i] = quadrant_position
    
    # If the matching quadrants represent the normal empty subtile, with no
    # interesting inbound neighbor matches, then we return Vector2.INF values,
    # so that the tilemap can clear the cell instead of assigning the empty
    # subtile.
    for i in quadrant_positions.size():
        if quadrant_positions[i] != empty_quadrants[i]:
            return quadrant_positions
    return clear_quadrants


# Array<Vector2, float, Dictionary, Dictionary, Dictionary, Dictionary, Dictionary>
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
    var current_iteration_weight_multiplier := 1.0 / pow(100,iteration_exponent)
    var is_inbound_iteration := i > 2
    var is_h_neighbor := i == 1 or i == 4
    var target_corner_type: int = target_corner_types[i]
    
    # FIXME: -------------------------------------------------------------
#    print(">> %s" % str(i))
    
    var best_position_and_weight := [Vector2.INF, -INF]
    var best_weight_contribution := -INF
    var best_type := SubtileCorner.UNKNOWN
    var best_match_label := "-"
    
    # Consider direct corner-type matches.
    if corner_type_map_or_position.has(target_corner_type):
        var direct_match_corner_type_map_or_position = \
                corner_type_map_or_position[target_corner_type]
        var direct_match_weight_contribution := \
                current_iteration_weight_multiplier
        var direct_match_weight := weight + direct_match_weight_contribution
        
        var direct_match_position_and_weight: Array
        if direct_match_corner_type_map_or_position is Vector2:
            # Base case: We found a position.
            direct_match_position_and_weight = [
                direct_match_corner_type_map_or_position,
                direct_match_weight,
            ]
        else:
            # Recursive case: We found another mapping to consider.
            direct_match_position_and_weight = _get_best_quadrant_match(
                    direct_match_corner_type_map_or_position,
                    target_corner_types,
                    i + 1,
                    direct_match_weight)
        
        best_position_and_weight = direct_match_position_and_weight
        best_weight_contribution = direct_match_weight_contribution
        best_type = target_corner_type
        best_match_label = "direct_match"
        # FIXME: -------------------------------------------------------------
#        print("> d %s %s" % [
#            str(i),
#            str(best_position_and_weight[1]),
#        ])
    
    if i == 0 or \
            !Su.subtile_manifest.allows_fallback_corner_matches:
        best_position_and_weight.resize(7)
        best_position_and_weight[i + 2] = {
            weight_contribution = best_weight_contribution,
            corner_type = best_type,
            match_label = best_match_label,
        }
        return best_position_and_weight
    
    # Consider the UNKNOWN value as a fallback.
    if corner_type_map_or_position.has(SubtileCorner.UNKNOWN):
        var fallback_corner_type_map_or_position = \
                corner_type_map_or_position[SubtileCorner.UNKNOWN]
        var fallback_corner_weight_multiplier: float = 0.9999
        var fallback_weight_contribution := \
                current_iteration_weight_multiplier * \
                fallback_corner_weight_multiplier * 0.1
        var fallback_weight := weight + fallback_weight_contribution
        
        var fallback_position_and_weight: Array
        if fallback_corner_type_map_or_position is Vector2:
            # Base case: We found a position.
            fallback_position_and_weight = [
                fallback_corner_type_map_or_position,
                fallback_weight,
            ]
        else:
            # Recursive case: We found another mapping to consider.
            fallback_position_and_weight = _get_best_quadrant_match(
                    fallback_corner_type_map_or_position,
                    target_corner_types,
                    i + 1,
                    fallback_weight)
        
        if fallback_position_and_weight[1] > best_position_and_weight[1]:
            best_position_and_weight = fallback_position_and_weight
            best_weight_contribution = fallback_weight_contribution
            best_type = SubtileCorner.UNKNOWN
            best_match_label = "unknown_match"
        # FIXME: -------------------------------------------------------------
#        print("> u %s %s" % [
#            str(i),
#            str(fallback_position_and_weight[1]),
#        ])
    
    # Consider all explicitly configured fallbacks.
    var fallbacks_for_corner_type: Dictionary = \
            FallbackSubtileCorners.FALLBACKS[target_corner_type]
    for fallback_corner_type in fallbacks_for_corner_type:
        var fallback_multipliers: Array = \
                fallbacks_for_corner_type[fallback_corner_type]
        var fallback_corner_weight_multiplier: float = \
                fallback_multipliers[0] if \
                is_h_neighbor else \
                fallback_multipliers[1]
        
        if fallback_corner_weight_multiplier <= 0.0:
            # Skip this fallback, since it is for the other direction.
            continue
        
        if fallback_corner_weight_multiplier <= 1.0:
            # -   If the weight-multiplier is less than 1.0, then we should
            #     prefer mappings that use UNKNOWN values.
            # -   This offset ensures that a non-unknown fallback will
            #     counter the weight contributed by any match from the other
            #     direction.
            fallback_corner_weight_multiplier = \
                    (-1.0 - (1.0 - fallback_corner_weight_multiplier)) * \
                    10.0
        
        if corner_type_map_or_position.has(fallback_corner_type):
            # There is a quadrant configured for this fallback corner-type.
            
            var fallback_corner_type_map_or_position = \
                    corner_type_map_or_position[fallback_corner_type]
            var fallback_weight_contribution := \
                    current_iteration_weight_multiplier * \
                    fallback_corner_weight_multiplier * 0.1
            var fallback_weight := weight + fallback_weight_contribution
            
            var fallback_position_and_weight: Array
            if fallback_corner_type_map_or_position is Vector2:
                # Base case: We found a position.
                fallback_position_and_weight = [
                    fallback_corner_type_map_or_position,
                    fallback_weight,
                ]
            else:
                # Recursive case: We found another mapping to consider.
                fallback_position_and_weight = _get_best_quadrant_match(
                        fallback_corner_type_map_or_position,
                        target_corner_types,
                        i + 1,
                        fallback_weight)
            
            if fallback_position_and_weight[1] > best_position_and_weight[1]:
                best_position_and_weight = fallback_position_and_weight
                best_weight_contribution = fallback_weight_contribution
                best_type = fallback_corner_type
                best_match_label = \
                        "good_fallback_match" if \
                        fallback_weight_contribution > 0 else \
                        "bad_fallback_match"
            # FIXME: -------------------------------------------------------------
#            print("> f %s %s" % [
#                str(i),
#                str(fallback_position_and_weight[1]),
#            ])
    
    best_position_and_weight.resize(7)
    best_position_and_weight[i + 2] = {
        weight_contribution = best_weight_contribution,
        corner_type = best_type,
        match_label = best_match_label,
    }
    return best_position_and_weight


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


func _print_subtile_corner_types(
        target_corner_direction := -1,
        target_self_corner_type := -1,
        target_h_opp_corner_type := -1,
        target_v_opp_corner_type := -1,
        target_h_inbound_corner_type := -1,
        target_v_inbound_corner_type := -1) -> void:
    print(">>>>> CornerMatchTileset.subtile_corner_types")
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
    print(">>>>>")


func _get_position_and_weight_results_string(
        position_and_weight: Array) -> String:
    var position_and_weight_result_strings := []
    position_and_weight_result_strings.push_back(
            "p=" + str(position_and_weight[0]))
    position_and_weight_result_strings.push_back(
            "w=" + str(position_and_weight[1]))
    var neighbor_labels := [
        "self",
        "h_opp",
        "v_opp",
        "h_inbound",
        "v_inbound",
    ]
    for i in range(2,7):
        var neighbor_result = position_and_weight[i]
        var contribution_string := \
                "NULL" if \
                neighbor_result == null else \
                "(%s, %s, %s)" % [
                    neighbor_result.match_label,
                    Su.subtile_manifest.get_subtile_corner_string(
                        neighbor_result.corner_type),
                    str(neighbor_result.weight_contribution),
                ]
        position_and_weight_result_strings.push_back("%s=%s" % [
                neighbor_labels[i - 2],
                contribution_string,
            ])
    return "quadrant_match(\n    %s\n)" % \
            Sc.utils.join(position_and_weight_result_strings, ",\n    ")


func _sort(arr: Array) -> Array:
    arr.sort()
    return arr
