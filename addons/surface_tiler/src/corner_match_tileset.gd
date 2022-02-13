tool
class_name CornerMatchTileset
extends TileSet


# FIXME: LEFT OFF HERE: ---------------------------------------
#   - Implement _get_quadrants().
#     - Return the quadrants with the greatest weight for the given
#       target_corners.
#       - 
#     - Maybe similar to the old _choose_subtile()?
#   - Implement the inner-TileMap pattern to render quadrants according to the
#     outer TileMap's cells.
#   - Add logic (and configuration) for matching quadrant/corner-type fallbacks.
#   - Hook-up all tile-set configuration.
#   - ...


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


# FIXME: LEFT OFF HERE: ----------------------------- REMOVE?
func get_quadrant_position(
        corner_direction: int,
        target_corners: CellCorners) -> Vector2:
    var position_or_h_inbound_corner_type = subtile_corner_types \
            [corner_direction] \
            [target_corners.get_corner_type(corner_direction)] \
            [target_corners.get_h_opp_corner_type(corner_direction)] \
            [target_corners.get_v_opp_corner_type(corner_direction)]
    if position_or_h_inbound_corner_type is Vector2:
        return position_or_h_inbound_corner_type
    else:
        return position_or_h_inbound_corner_type \
                [target_corners.get_h_inbound_corner_type(corner_direction)] \
                [target_corners.get_v_inbound_corner_type(corner_direction)]


func _choose_quadrants(proximity: CellProximity) -> Array:
    var target_corners := CellCorners.new(proximity)
    
    if !target_corners.get_are_corners_valid():
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
    
    # FIXME: Uncomment this to help with debugging.
#    Sc.logger.print(">>>>>>>>>>>>>>>>_choose_subtile:\n%s\n%s" % [
#        proximity.to_string(),
#        target_corners.to_string(),
#    ])
    
    
    
    
    
    # FIXME: LEFT OFF HERE: ---------------------------
    # FIXME: LEFT OFF HERE: ---------------------------
    
#    var position_or_h_inbound_corner_type = subtile_corner_types \
#            [corner_direction] \
#            [target_corners.get_corner_type(corner_direction)] \
#            [target_corners.get_h_opp_corner_type(corner_direction)] \
#            [target_corners.get_v_opp_corner_type(corner_direction)]
    
    var corner_direction := CornerDirection.TOP_LEFT
    
    var self_target_corner_type := \
            target_corners.get_corner_type(corner_direction)
    var h_opp_target_corner_type := \
            target_corners.get_h_opp_corner_type(corner_direction)
    var v_opp_target_corner_type := \
            target_corners.get_v_opp_corner_type(corner_direction)
    var h_inbound_target_corner_type := \
            target_corners.get_h_inbound_corner_type(corner_direction)
    var v_inbound_target_corner_type := \
            target_corners.get_v_inbound_corner_type(corner_direction)
    
    # FIXME: LEFT OFF HERE: ----------------------------------------
    # - Move this into a recursize function that returns a nested-combined
    #   priority with the base-case match position?
    var self_corner_type_map: Dictionary = \
            subtile_corner_types[corner_direction]
    if self_corner_type_map.has(self_target_corner_type):
        pass
    else:
        for fallback_corner_type in \
                Su.subtile_manifest._FALLBACK_CORNER_TYPE_MATCHES \
                    [self_corner_type_map]:
            if self_corner_type_map.has(self_target_corner_type):
                pass
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    # FIXME: LEFT OFF HERE: ---------------------------
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
    
    
    
    
    
    
    
    
    
#    # Dictionary<CornerDirection, Dictionary<Vector2, Dictionary>>
#    var corner_to_matches := {}
#    for corner in CornerDirection.OUTBOUND_CORNERS:
#        var corner_type: int = target_corners[corner]
#        corner_to_matches[corner] = \
#                _corner_direction_to_type_to_subtiles[corner][corner_type]
#
#    # FIXME: LEFT OFF HERE: ---------------------------
#    # - As an efficiency step, first check if the pre-existing cell in the
#    #   TileMap already has the ideal match?
#
#    var best_match_positions := {}
#    var best_match_priority := -INF
#
#    for corner in CornerDirection.OUTBOUND_CORNERS:
#        for corner_match in corner_to_matches[corner].values():
#            if !_get_does_angle_type_match(corner_match, target_corners):
#                # Skip the possible corner match, since it doesn't match
#                # the angle type.
#                continue
#
#            var priority := _get_match_priority(corner_match, target_corners)
#            var subtile_position: Vector2 = corner_match.p
#
#            if !_allows_partial_matches and \
#                    priority < 4.0:
#                # The subtile config doesn't match all four outbound corners.
#                continue
#
#            if priority > best_match_priority:
#                best_match_priority = priority
#                best_match_positions.clear()
#                best_match_positions[subtile_position] = true
#            elif priority == best_match_priority and \
#                    !best_match_positions.has(subtile_position):
#                best_match_positions[subtile_position] = true
#
#        if _allows_partial_matches and \
#                !best_match_positions.empty() and \
#                best_match_priority >= 4.0:
#            # If we already found a full match from this corner, then we cannot
#            # find a more full match from another corner.
#            break
#
#        if !_allows_partial_matches and \
#                best_match_positions.empty():
#            # If this corner type was interesting, and we didn't find a full
#            # match for it, then we know that none of the other corner mappings
#            # will have a full match either.
#            break
#
#    if !best_match_positions.empty():
#        var best_matches := best_match_positions.keys()
#        var best_match: Vector2 = best_matches[0]
#        if best_matches.size() > 1:
#            Sc.logger.warning(
#                    ("Multiple subtiles have the same priority: " +
#                    "priority=%s, p1=%s, p2=%s, corners=%s") % [
#                        str(best_match_priority),
#                        Sc.utils.get_vector_string(best_matches[0], 0),
#                        Sc.utils.get_vector_string(best_matches[1], 0),
#                        get_subtile_config_string(target_corners),
#                    ])
#        if best_match_priority < \
#                Su.subtile_manifest.ACCEPTABLE_MATCH_PRIORITY_THRESHOLD:
#            Sc.logger.warning(
#                ("No subtile was found with a good match: " +
#                "priority=%s, value=%s") % [
#                    best_match_priority,
#                    Sc.utils.get_vector_string(best_match, 0),
#                ])
#        return best_match
#    else:
#        return _error_indicator_subtile_position


#func _get_does_angle_type_match(
#        actual_corners: Dictionary,
#        expected_corners: Dictionary) -> bool:
#    return expected_corners.is_a90 and actual_corners.is_a90 or \
#            expected_corners.is_a45 and actual_corners.is_a45 or \
#            expected_corners.is_a27 and actual_corners.is_a27


#func _get_match_priority(
#        actual_corners: Dictionary,
#        expected_corners: Dictionary) -> float:
#    var priority := 0.0
#
#    for corner in CornerDirection.OUTBOUND_CORNERS:
#        var actual_corner: int = actual_corners[corner]
#        var expected_corner: int = expected_corners[corner]
#        var additional_matching_types: Dictionary = Su.subtile_manifest \
#                .fallback_corner_type_matches[expected_corner]
#        # Determine the priority-contribution for this corner.
#        if actual_corner == expected_corner or \
#                additional_matching_types.has(actual_corner):
#            priority += 1.0
#        elif additional_matching_types.has(-actual_corner):
#            priority += 0.1
#        else:
#            # FIXME: -------------- Is there a more elegant fallback for this?
#            priority -= 5.0
#
#    for inbound_corner in CornerDirection.INBOUND_CORNERS:
#        if !actual_corners.has(inbound_corner):
#            continue
#        var actual_corner: int = actual_corners[inbound_corner]
#        var expected_corner: int = expected_corners[inbound_corner]
#        var additional_matching_types: Dictionary = Su.subtile_manifest \
#                .fallback_corner_type_matches[expected_corner]
#        # Determine the priority-contribution for this inbound corner.
#        if actual_corner == expected_corner or \
#                additional_matching_types.has(actual_corner):
#            priority += 0.01
#        elif additional_matching_types.has(-actual_corner):
#            priority += 0.001
#        else:
#            # Do nothing for non-matching corners.
#            pass
#
#    return priority
