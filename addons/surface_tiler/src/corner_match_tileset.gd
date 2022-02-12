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

# Dictionary<SubtileCorner, Dictionary<SubtileCorner, bool>>
var fallback_corner_type_matches := {}


func _forward_subtile_selection(
        tile_id: int,
        bitmask: int,
        tile_map: Object,
        cell_position: Vector2):
    var subtile_position := Vector2.INF
    
    if Engine.editor_hint or \
            Su.subtile_manifest.supports_runtime_autotiling:
        var proximity := CellProximity.new(
                tile_map,
                self,
                cell_position,
                tile_id)
        # FIXME: LEFT OFF HERE: -----------------------------
        var corner_direction := CornerDirection.TOP_LEFT
        subtile_position = _choose_subtile(proximity, corner_direction)
    
    if subtile_position != Vector2.INF:
        return subtile_position
    else:
        # Fallback to Godot's default autotiling behavior.
        # NOTE:
        # -   Not returning any value here is terrible.
        # -   However, the underlying API apparently doesn't support returning
        #     any actual values that would indicate redirecting back to the
        #     default behavior.
        return


func _choose_subtile(
        proximity: CellProximity,
        corner_direction: int) -> Vector2:
    var target_corners := CellCorners.new(proximity)
    
    if !target_corners.get_are_corners_valid():
        return subtile_corner_types \
                [corner_direction] \
                [SubtileCorner.ERROR] \
                [SubtileCorner.ERROR] \
                [SubtileCorner.ERROR]
    
    # FIXME: LEFT OFF HERE: ---------------------------
    # FIXME: LEFT OFF HERE: ---------------------------
    # FIXME: LEFT OFF HERE: ---------------------------
    return subtile_corner_types \
            [corner_direction] \
            [SubtileCorner.ERROR] \
            [SubtileCorner.ERROR] \
            [SubtileCorner.ERROR]
    
#    # FIXME: Uncomment this to help with debugging.
##    Sc.logger.print(">>>>>>>>>>_choose_subtile: %s, corners=%s" % [
##        proximity.to_string(),
##        get_subtile_config_string(target_corners),
##    ])
#
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


func _get_does_angle_type_match(
        actual_corners: Dictionary,
        expected_corners: Dictionary) -> bool:
    return expected_corners.is_a90 and actual_corners.is_a90 or \
            expected_corners.is_a45 and actual_corners.is_a45 or \
            expected_corners.is_a27 and actual_corners.is_a27


func _get_match_priority(
        actual_corners: Dictionary,
        expected_corners: Dictionary) -> float:
    var priority := 0.0
    
    for corner in CornerDirection.OUTBOUND_CORNERS:
        var actual_corner: int = actual_corners[corner]
        var expected_corner: int = expected_corners[corner]
        var additional_matching_types: Dictionary = Su.subtile_manifest \
                .fallback_corner_type_matches[expected_corner]
        # Determine the priority-contribution for this corner.
        if actual_corner == expected_corner or \
                additional_matching_types.has(actual_corner):
            priority += 1.0
        elif additional_matching_types.has(-actual_corner):
            priority += 0.1
        else:
            # FIXME: -------------- Is there a more elegant fallback for this?
            priority -= 5.0
    
    for inbound_corner in CornerDirection.INBOUND_CORNERS:
        if !actual_corners.has(inbound_corner):
            continue
        var actual_corner: int = actual_corners[inbound_corner]
        var expected_corner: int = expected_corners[inbound_corner]
        var additional_matching_types: Dictionary = Su.subtile_manifest \
                .fallback_corner_type_matches[expected_corner]
        # Determine the priority-contribution for this inbound corner.
        if actual_corner == expected_corner or \
                additional_matching_types.has(actual_corner):
            priority += 0.01
        elif additional_matching_types.has(-actual_corner):
            priority += 0.001
        else:
            # Do nothing for non-matching corners.
            pass
    
    return priority
