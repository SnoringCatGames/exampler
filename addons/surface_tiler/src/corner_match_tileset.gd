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
#                   (Vector2|Dictionary<
#                     SubtileCorner, # HD-inbound-corner
#                     (Vector2|Dictionary<
#                       SubtileCorner, # VD-inbound-corner
#                       Vector2        # Quadrant coordinates
#                 >)>)>)>)>)>)>)>)>)>>
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
        logs_debug_info := false,
        logs_error_info := false) -> Array:
    if !Engine.editor_hint and \
            !Su.subtile_manifest.supports_runtime_autotiling:
        return error_quadrants
    
    var proximity := CellProximity.new(
            tile_map,
            self,
            cell_position,
            tile_id)
    var target_corners := CellCorners.new(proximity)
    
    if !target_corners.get_are_corners_valid() and \
            logs_error_info:
        Sc.logger.warning(
            "Not all target corners are valid:\n%s\n%s" % [
            proximity.to_string(),
            target_corners.to_string(true),
        ])
        return error_quadrants
    
    var quadrant_positions := []
    quadrant_positions.resize(4)
    
    for i in CornerDirection.CORNERS.size():
        var corner_direction: int = CornerDirection.CORNERS[i]
        
        var corner_types := [
            target_corners.get_corner_type(
                    corner_direction, ConnectionDirection.SELF),
            target_corners.get_corner_type(
                    corner_direction, ConnectionDirection.H_INTERNAL),
            target_corners.get_corner_type(
                    corner_direction, ConnectionDirection.V_INTERNAL),
            target_corners.get_corner_type(
                    corner_direction, ConnectionDirection.H_EXTERNAL),
            target_corners.get_corner_type(
                    corner_direction, ConnectionDirection.V_EXTERNAL),
            target_corners.get_corner_type(
                    corner_direction, ConnectionDirection.D_INTERNAL),
            target_corners.get_corner_type(
                    corner_direction, ConnectionDirection.H2_EXTERNAL),
            target_corners.get_corner_type(
                    corner_direction, ConnectionDirection.V2_EXTERNAL),
            target_corners.get_corner_type(
                    corner_direction, ConnectionDirection.HD_EXTERNAL),
            target_corners.get_corner_type(
                    corner_direction, ConnectionDirection.VD_EXTERNAL),
        ]
        
        var best_position_and_weight := _get_best_quadrant_match(
                subtile_corner_types[corner_direction],
                corner_types,
                0,
                0,
                corner_direction)
        var quadrant_position: Vector2 = best_position_and_weight[0]
        var quadrant_weight: float = best_position_and_weight[1]
        
        if logs_debug_info:
            Sc.logger.print("")
            Sc.logger.print(">>> get_quadrants: %s" % \
                    CornerDirection.get_string(corner_direction))
            Sc.logger.print(proximity.to_string())
            Sc.logger.print(target_corners.to_string(true))
            Sc.logger.print(_get_position_and_weight_results_string(
                    best_position_and_weight))
            _print_subtile_corner_types(
                    corner_direction,
                    corner_types,
                    [target_corners.get_corner_type(corner_direction)])
            Sc.logger.print(">>>")
            Sc.logger.print("")
        
        if quadrant_weight < \
                Su.subtile_manifest.ACCEPTABLE_MATCH_PRIORITY_THRESHOLD and \
                logs_error_info:
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
                        corner_types,
                        [target_corners.get_corner_type(corner_direction)])
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
        weight: float,
        corner_direction: int) -> Array:
    var iteration_exponent: int
    match i:
        0: iteration_exponent = 0
        1, 2: iteration_exponent = 1
        3, 4, 5, 6, 7, 8, 9: iteration_exponent = 2
        _:
            Sc.logger.error("CornerMatchTileset._get_best_quadrant_match")
    var current_iteration_weight_multiplier := \
            1000.0 / pow(1000,iteration_exponent)
    var is_external_iteration := i > 2 and i != 5
    var is_h_neighbor := i == 1 or i == 3
    var is_v_neighbor := i == 2 or i == 4
    var is_d_neighbor := i == 5 or i == 8 or i == 9
    var is_2_neighbor := i == 6 or i == 7
    var target_corner_type: int = target_corner_types[i]
    
    # FIXME: -------------------------------------------------------------
#    Sc.logger.print(">> %s" % str(i))
    
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
                    direct_match_weight,
                    corner_direction)
        
        best_position_and_weight = direct_match_position_and_weight
        best_weight_contribution = direct_match_weight_contribution
        best_type = target_corner_type
        best_match_label = "direct_match"
        # FIXME: -------------------------------------------------------------
#        Sc.logger.print("> d %s %s" % [
#            str(i),
#            str(best_position_and_weight[1]),
#        ])
    
    if i == 0 or \
            !Su.subtile_manifest.allows_fallback_corner_matches:
        best_position_and_weight.resize(12)
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
        var fallback_corner_weight_multiplier: float = 0.01
        var fallback_weight_contribution := \
                current_iteration_weight_multiplier * \
                fallback_corner_weight_multiplier
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
                    fallback_weight,
                    corner_direction)
        
        if fallback_position_and_weight[1] > best_position_and_weight[1]:
            best_position_and_weight = fallback_position_and_weight
            best_weight_contribution = fallback_weight_contribution
            best_type = SubtileCorner.UNKNOWN
            best_match_label = "unknown_match"
        # FIXME: -------------------------------------------------------------
#        Sc.logger.print("> u %s %s" % [
#            str(i),
#            str(fallback_position_and_weight[1]),
#        ])
    
    # FIXME: LEFT OFF HERE: -----------------------------------------
    # - Should internal and inbound diagonal connections have configurable
    #   fallbacks?
    if !is_d_neighbor and !is_2_neighbor:
        # Consider all explicitly configured fallbacks.
        var fallbacks_for_corner_type: Dictionary = \
                FallbackSubtileCorners.FALLBACKS[target_corner_type]
        for fallback_corner_type in fallbacks_for_corner_type:
            var fallback_multipliers: Array = \
                    fallbacks_for_corner_type[fallback_corner_type]
            var fallback_corner_weight_multiplier: float
            if is_external_iteration:
                if is_h_neighbor:
                    fallback_corner_weight_multiplier = fallback_multipliers[2]
                else:
                    fallback_corner_weight_multiplier = fallback_multipliers[3]
            else:
                if is_h_neighbor:
                    fallback_corner_weight_multiplier = fallback_multipliers[0]
                else:
                    fallback_corner_weight_multiplier = fallback_multipliers[1]
            
            if fallback_corner_weight_multiplier <= 0.0:
                # Skip this fallback, since it is for the other direction.
                continue
            
            var side_label: String
            if is_h_neighbor:
                side_label = "side"
            else:
                var is_top := CornerDirection.get_is_top(corner_direction)
                if is_top == is_external_iteration:
                    side_label = "top"
                else:
                    side_label = "bottom"
            fallback_corner_weight_multiplier *= \
                    CornerConnectionWeightMultipliers.get_multiplier(
                        fallback_corner_type,
                        side_label)
            
            if fallback_corner_weight_multiplier < 1.0:
                # -   If the weight-multiplier is less than 1.0, then we should
                #     prefer mappings that use UNKNOWN values.
                # -   This offset ensures that a non-unknown fallback will
                #     counter the weight contributed by any match from the other
                #     direction.
                fallback_corner_weight_multiplier = \
                        (-1.0 - (1.0 - fallback_corner_weight_multiplier))
            else:
                fallback_corner_weight_multiplier *= 0.1
            
            if corner_type_map_or_position.has(fallback_corner_type):
                # There is a quadrant configured for this fallback corner-type.
                
                var fallback_corner_type_map_or_position = \
                        corner_type_map_or_position[fallback_corner_type]
                var fallback_weight_contribution := \
                        current_iteration_weight_multiplier * \
                        fallback_corner_weight_multiplier
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
                            fallback_weight,
                            corner_direction)
                
                if fallback_position_and_weight[1] > best_position_and_weight[1]:
                    best_position_and_weight = fallback_position_and_weight
                    best_weight_contribution = fallback_weight_contribution
                    best_type = fallback_corner_type
                    best_match_label = \
                            "good_fallback_match" if \
                            fallback_weight_contribution > 0 else \
                            "bad_fallback_match"
                # FIXME: -------------------------------------------------------
#                Sc.logger.print("> f %s %s" % [
#                    str(i),
#                    str(fallback_position_and_weight[1]),
#                ])
    
    best_position_and_weight.resize(12)
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
        target_corner_direction: int,
        target_corner_types: Array,
        filter_connection_types: Array) -> void:
    var connection_labels := [
        "Self",
        "H-opp",
        "V-opp",
        "H-inbound",
        "V-inbound",
        "Diagonal-opp",
        "H2-inbound",
        "V2-inbound",
        "H-diag-inbound",
        "V-diag-inbound",
    ]
    Sc.logger.print(">>>>> CornerMatchTileset.subtile_corner_types")
    for corner_direction in Sc.utils.cascade_sort(subtile_corner_types.keys()):
        if target_corner_direction >= 0 and \
                target_corner_direction != corner_direction:
            continue
        Sc.logger.print(CornerDirection.get_string(corner_direction))
        _print_subtile_corner_types_recursively(
                subtile_corner_types[corner_direction],
                target_corner_types,
                filter_connection_types,
                connection_labels,
                0)
    Sc.logger.print(">>>>>")


func _print_subtile_corner_types_recursively(
        map: Dictionary,
        target_corner_types: Array,
        filter_connection_types: Array,
        connection_labels: Array,
        index: int) -> void:
    if filter_connection_types.size() > index:
        var target_connection_type: int = filter_connection_types[index]
        if !map.has(target_connection_type):
            Sc.logger.warning(
                    ("subtile_corner_types does not contain the target " +
                    "connection type: " +
                    "target_type=%s, index=%s, target_types=%s") % [
                        Su.subtile_manifest.get_subtile_corner_string(
                                target_connection_type),
                        str(index),
                        str(filter_connection_types),
                    ])
            return
        var next_value = map[target_connection_type]
        if next_value is Vector2:
            _print_subtile_connection_entry(
                    connection_labels,
                    index,
                    target_connection_type,
                    target_corner_types,
                    next_value)
        else:
            _print_subtile_connection_entry(
                    connection_labels,
                    index,
                    target_connection_type,
                    target_corner_types)
            _print_subtile_corner_types_recursively(
                    next_value,
                    target_corner_types,
                    filter_connection_types,
                    connection_labels,
                    index + 1)
    else:
        for connection_type in Sc.utils.cascade_sort(map.keys()):
            var next_value = map[connection_type]
            if next_value is Vector2:
                _print_subtile_connection_entry(
                        connection_labels,
                        index,
                        connection_type,
                        target_corner_types,
                        next_value)
            else:
                _print_subtile_connection_entry(
                        connection_labels,
                        index,
                        connection_type,
                        target_corner_types)
                _print_subtile_corner_types_recursively(
                        next_value,
                        target_corner_types,
                        filter_connection_types,
                        connection_labels,
                        index + 1)


func _print_subtile_connection_entry(
        connection_labels: Array,
        index: int,
        connection_type: int,
        target_corner_types: Array,
        quadrant_coordinates := Vector2.INF) -> void:
    var target_connection_type: int = target_corner_types[index]
    var is_direct_match_to_target := connection_type == target_connection_type
    var is_index_valid_for_fallback := index >= 1 and index <= 4
    
    var fallback_weight := -INF
    if is_direct_match_to_target:
        fallback_weight = 1.0
    elif is_index_valid_for_fallback:
        if FallbackSubtileCorners.FALLBACKS[target_connection_type] \
                .has(connection_type):
            fallback_weight = FallbackSubtileCorners.FALLBACKS \
                    [target_connection_type][connection_type][index - 1]
    
    var fallback_weight_string: String
    if is_index_valid_for_fallback or is_direct_match_to_target:
        if fallback_weight >= 0:
            fallback_weight_string = "%.2f" % fallback_weight
        else:
            fallback_weight_string = "--"
    else:
        fallback_weight_string = "N/A"
    
    var spaces := Sc.utils.get_spaces((index + 1) * 2)
    var quadrant_coordinates_string := \
            " => %s" % str(quadrant_coordinates) if \
            quadrant_coordinates != Vector2.INF else \
            ""
    
    var message := "%s%s: %s%s [%s]" % [
        spaces,
        connection_labels[index],
        Su.subtile_manifest.get_subtile_corner_string(connection_type),
        quadrant_coordinates_string,
        fallback_weight_string,
    ]
    Sc.logger.print(message)


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
        "diag_opp",
        "h2_inbound",
        "v2_inbound",
        "hd_inbound",
        "vd_inbound",
    ]
    for i in range(2,10):
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
