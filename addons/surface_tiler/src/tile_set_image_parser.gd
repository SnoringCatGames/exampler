tool
class_name TileSetImageParser
extends Node


const ANNOTATION_SIZE := Vector2(4,4)

# This is an int with the first 10 bits set.
const _CORNER_TYPE_BIT_MASK := (1 << 10) - 1


# -   Returns a mapping from pixel-color to pixel-bit-flag to corner-type.
# Dictionary<int, Dictionary<int, int>>
func parse_corner_type_annotation_key(
        corner_type_annotation_key_path: String,
        quadrant_size: int) -> Dictionary:
    assert(quadrant_size >= ANNOTATION_SIZE.x * 2)
    assert(quadrant_size >= ANNOTATION_SIZE.y * 2)
    
    var texture: Texture = load(corner_type_annotation_key_path)
    var image: Image = texture.get_data()
    
    var size := image.get_size()
    assert(int(size.x) % quadrant_size == 0)
    assert(int(size.y) % quadrant_size == 0)
    
    var quadrant_row_count := int(size.y) / quadrant_size
    var quadrant_column_count := int(size.x) / quadrant_size
    
    var quadrant_count := quadrant_row_count * quadrant_column_count
    var corner_type_count := SubtileCorner.get_script_constant_map().size()
    assert(quadrant_count >= corner_type_count or \
            quadrant_count <= corner_type_count + quadrant_row_count - 1,
            "The corner-type annotation key must have an entry for each " +
            "corner-type enum and no extras.")
    
    var corner_type_annotation_key := {}
    
    image.lock()
    
    for quadrant_row_index in quadrant_row_count:
        for quadrant_column_index in quadrant_column_count:
            var quadrant_position := \
                    Vector2(quadrant_column_index, quadrant_row_index) * \
                    quadrant_size
            _check_for_empty_quadrant_non_annotation_pixels(
                    quadrant_position,
                    quadrant_size,
                    image,
                    corner_type_annotation_key_path,
                    CornerDirection.TOP_LEFT)
            # This int corresponds to the SubtileCorner enum value.
            var corner_type := int(
                    quadrant_row_index * quadrant_column_count + \
                    quadrant_column_index)
            if corner_type >= \
                    Su.subtile_manifest.SUBTILE_CORNER_TYPE_VALUE_TO_KEY.size():
                # We've reached the end of the annotation key, and any remaining
                # cells should be empty.
                break
            var annotation := _get_quadrant_annotation(
                    quadrant_position,
                    quadrant_size,
                    image,
                    corner_type_annotation_key_path,
                    CornerDirection.TOP_LEFT)
            var color: int = annotation.color
            var bits: int = annotation.bits
            if quadrant_position == Vector2.ZERO:
                assert(bits == 0,
                        "The first corner-type annotation in the " +
                        "annotation-key corresponds to UNKNOWN and must be " +
                        "empty.")
                continue
            else:
                assert(bits != 0,
                        "Corner-type annotations cannot be empty: %s" % \
                        _get_log_string(
                            quadrant_position,
                            quadrant_size,
                            CornerDirection.TOP_LEFT,
                            corner_type_annotation_key_path))
            if !corner_type_annotation_key.has(color):
                corner_type_annotation_key[color] = {}
            assert(!corner_type_annotation_key[color].has(bits),
                    "Multiple corner-type annotations have the same shape " +
                    "and color: %s" % _get_log_string(
                        quadrant_position,
                        quadrant_size,
                        CornerDirection.TOP_LEFT,
                        corner_type_annotation_key_path))
            corner_type_annotation_key[color][bits] = corner_type
    
    image.unlock()
    
    return corner_type_annotation_key


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
func parse_tile_set_corner_type_annotations(
        corner_type_annotation_key: Dictionary,
        tile_set_corner_type_annotations_path: String,
        quadrant_size: int,
        outer_tile_set: CornerMatchTileset) -> Dictionary:
    var subtile_size := quadrant_size * 2
    
    var texture: Texture = load(tile_set_corner_type_annotations_path)
    var image: Image = texture.get_data()
    
    var size := image.get_size()
    assert(int(size.x) % subtile_size == 0)
    assert(int(size.y) % subtile_size == 0)
    
    var subtile_row_count := int(size.y) / subtile_size
    var subtile_column_count := int(size.x) / subtile_size
    
    var subtile_corner_types := {
        CornerDirection.TOP_LEFT: {},
        CornerDirection.TOP_RIGHT: {},
        CornerDirection.BOTTOM_LEFT: {},
        CornerDirection.BOTTOM_RIGHT: {},
    }
    
    image.lock()
    
    for subtile_row_index in subtile_row_count:
        for subtile_column_index in subtile_column_count:
            var subtile_position := \
                    Vector2(subtile_column_index, subtile_row_index)
            _parse_corner_type_annotation(
                    subtile_corner_types,
                    corner_type_annotation_key,
                    subtile_position,
                    quadrant_size,
                    image,
                    tile_set_corner_type_annotations_path)
    
    _validate_quadrants(subtile_corner_types, outer_tile_set)
    
    image.unlock()
    
    return subtile_corner_types


func _parse_corner_type_annotation(
        subtile_corner_types: Dictionary,
        corner_type_annotation_key: Dictionary,
        subtile_position: Vector2,
        quadrant_size: int,
        image: Image,
        tile_set_corner_type_annotations_path: String) -> void:
    var tl_quadrant_position := \
            (subtile_position * 2 + Vector2(0,0)) * quadrant_size
    var tr_quadrant_position := \
            (subtile_position * 2 + Vector2(1,0)) * quadrant_size
    var bl_quadrant_position := \
            (subtile_position * 2 + Vector2(0,1)) * quadrant_size
    var br_quadrant_position := \
            (subtile_position * 2 + Vector2(1,1)) * quadrant_size
    
    _check_for_empty_quadrant_non_annotation_pixels(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_LEFT)
    _check_for_empty_quadrant_non_annotation_pixels(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_RIGHT)
    _check_for_empty_quadrant_non_annotation_pixels(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_LEFT)
    _check_for_empty_quadrant_non_annotation_pixels(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_RIGHT)
    
    # Parse the corner-type annotations.
    var tl_corner_annotation := _get_quadrant_annotation(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_LEFT)
    var tr_corner_annotation := _get_quadrant_annotation(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_RIGHT)
    var bl_corner_annotation := _get_quadrant_annotation(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_LEFT)
    var br_corner_annotation := _get_quadrant_annotation(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_RIGHT)
    
    # Parse the eight possible internal connection annotations.
    var has_tl_h_internal_implicit_connection := _get_connection_indicator(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_LEFT,
            true,
            true,
            false,
            false)
    var has_tl_v_internal_implicit_connection := _get_connection_indicator(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_LEFT,
            true,
            false,
            false,
            false)
    var has_tl_d_internal_implicit_connection := _get_connection_indicator(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_LEFT,
            true,
            false,
            true,
            false)
    var has_tr_h_internal_implicit_connection := _get_connection_indicator(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_RIGHT,
            true,
            true,
            false,
            false)
    var has_tr_v_internal_implicit_connection := _get_connection_indicator(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_RIGHT,
            true,
            false,
            false,
            false)
    var has_tr_d_internal_implicit_connection := _get_connection_indicator(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_RIGHT,
            true,
            false,
            true,
            false)
    var has_bl_h_internal_implicit_connection := _get_connection_indicator(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_LEFT,
            true,
            true,
            false,
            false)
    var has_bl_v_internal_implicit_connection := _get_connection_indicator(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_LEFT,
            true,
            false,
            false,
            false)
    var has_bl_d_internal_implicit_connection := _get_connection_indicator(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_LEFT,
            true,
            false,
            true,
            false)
    var has_br_h_internal_implicit_connection := _get_connection_indicator(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_RIGHT,
            true,
            true,
            false,
            false)
    var has_br_v_internal_implicit_connection := _get_connection_indicator(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_RIGHT,
            true,
            false,
            false,
            false)
    var has_br_d_internal_implicit_connection := _get_connection_indicator(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_RIGHT,
            true,
            false,
            true,
            false)
    
    # Parse the eight possible axially-aligned inbound connection annotations.
    var has_tl_h_external_implicit_connection := _get_connection_indicator(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_LEFT,
            false,
            true,
            false,
            false)
    var has_tl_v_external_implicit_connection := _get_connection_indicator(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_LEFT,
            false,
            false,
            false,
            false)
    var has_tr_h_external_implicit_connection := _get_connection_indicator(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_RIGHT,
            false,
            true,
            false,
            false)
    var has_tr_v_external_implicit_connection := _get_connection_indicator(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_RIGHT,
            false,
            false,
            false,
            false)
    var has_bl_h_external_implicit_connection := _get_connection_indicator(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_LEFT,
            false,
            true,
            false,
            false)
    var has_bl_v_external_implicit_connection := _get_connection_indicator(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_LEFT,
            false,
            false,
            false,
            false)
    var has_br_h_external_implicit_connection := _get_connection_indicator(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_RIGHT,
            false,
            true,
            false,
            false)
    var has_br_v_external_implicit_connection := _get_connection_indicator(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_RIGHT,
            false,
            false,
            false,
            false)
    
    # Parse the eight possible two-away inbound connection annotations.
    var has_tl_h2_external_implicit_connection := _get_connection_indicator(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_LEFT,
            false,
            true,
            false,
            true)
    var has_tl_v2_external_implicit_connection := _get_connection_indicator(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_LEFT,
            false,
            false,
            false,
            true)
    var has_tr_h2_external_implicit_connection := _get_connection_indicator(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_RIGHT,
            false,
            true,
            false,
            true)
    var has_tr_v2_external_implicit_connection := _get_connection_indicator(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.TOP_RIGHT,
            false,
            false,
            false,
            true)
    var has_bl_h2_external_implicit_connection := _get_connection_indicator(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_LEFT,
            false,
            true,
            false,
            true)
    var has_bl_v2_external_implicit_connection := _get_connection_indicator(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_LEFT,
            false,
            false,
            false,
            true)
    var has_br_h2_external_implicit_connection := _get_connection_indicator(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_RIGHT,
            false,
            true,
            false,
            true)
    var has_br_v2_external_implicit_connection := _get_connection_indicator(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.BOTTOM_RIGHT,
            false,
            false,
            false,
            true)
    
    # Parse the eight possible axially-aligned custom inbound corner-type
    # annotations.
    var tl_h_inbound_corner_annotation := _get_quadrant_annotation(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_TL_L)
    var tl_v_inbound_corner_annotation := _get_quadrant_annotation(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_TL_T)
    var tr_h_inbound_corner_annotation := _get_quadrant_annotation(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_TR_R)
    var tr_v_inbound_corner_annotation := _get_quadrant_annotation(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_TR_T)
    var bl_h_inbound_corner_annotation := _get_quadrant_annotation(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_BL_L)
    var bl_v_inbound_corner_annotation := _get_quadrant_annotation(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_BL_B)
    var br_h_inbound_corner_annotation := _get_quadrant_annotation(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_BR_R)
    var br_v_inbound_corner_annotation := _get_quadrant_annotation(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_BR_B)
    
    # Parse the eight possible two-away custom inbound corner-type annotations.
    var tl_h2_inbound_corner_annotation := _get_quadrant_annotation(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_TL_L2)
    var tl_v2_inbound_corner_annotation := _get_quadrant_annotation(
            tl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_TL_T2)
    var tr_h2_inbound_corner_annotation := _get_quadrant_annotation(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_TR_R2)
    var tr_v2_inbound_corner_annotation := _get_quadrant_annotation(
            tr_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_TR_T2)
    var bl_h2_inbound_corner_annotation := _get_quadrant_annotation(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_BL_L2)
    var bl_v2_inbound_corner_annotation := _get_quadrant_annotation(
            bl_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_BL_B2)
    var br_h2_inbound_corner_annotation := _get_quadrant_annotation(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_BR_R2)
    var br_v2_inbound_corner_annotation := _get_quadrant_annotation(
            br_quadrant_position,
            quadrant_size,
            image,
            tile_set_corner_type_annotations_path,
            CornerDirection.INBOUND_BR_B2)
    
    assert((!has_tl_h_external_implicit_connection or \
                tl_h_inbound_corner_annotation.bits == 0) and \
            (!has_tl_v_external_implicit_connection or \
                tl_v_inbound_corner_annotation.bits == 0) and \
            (!has_tr_h_external_implicit_connection or \
                tr_h_inbound_corner_annotation.bits == 0) and \
            (!has_tr_v_external_implicit_connection or \
                tr_v_inbound_corner_annotation.bits == 0) and \
            (!has_bl_h_external_implicit_connection or \
                bl_h_inbound_corner_annotation.bits == 0) and \
            (!has_bl_v_external_implicit_connection or \
                bl_v_inbound_corner_annotation.bits == 0) and \
            (!has_br_h_external_implicit_connection or \
                br_h_inbound_corner_annotation.bits == 0) and \
            (!has_br_v_external_implicit_connection or \
                br_v_inbound_corner_annotation.bits == 0),
            ("Both a subtile outbound corner-type annotation and the " +
            "corresponding one-pixel connection-indicator is defined for the " +
            "same quadrant: subtile=%s, image=%s") % [
                subtile_position,
                tile_set_corner_type_annotations_path,
            ])
    
    # Parse the eight axially-aligned inbound corner-type annotations.
    if has_tl_h_external_implicit_connection:
        tl_h_inbound_corner_annotation = _get_quadrant_annotation(
                tl_quadrant_position + Vector2(-1,0) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.TOP_RIGHT)
    if has_tl_v_external_implicit_connection:
        tl_v_inbound_corner_annotation = _get_quadrant_annotation(
                tl_quadrant_position + Vector2(0,-1) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.BOTTOM_LEFT)
    if has_tr_h_external_implicit_connection:
        tr_h_inbound_corner_annotation = _get_quadrant_annotation(
                tr_quadrant_position + Vector2(1,0) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.TOP_LEFT)
    if has_tr_v_external_implicit_connection:
        tr_v_inbound_corner_annotation = _get_quadrant_annotation(
                tr_quadrant_position + Vector2(0,-1) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.BOTTOM_RIGHT)
    if has_bl_h_external_implicit_connection:
        bl_h_inbound_corner_annotation = _get_quadrant_annotation(
                bl_quadrant_position + Vector2(-1,0) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.BOTTOM_RIGHT)
    if has_bl_v_external_implicit_connection:
        bl_v_inbound_corner_annotation = _get_quadrant_annotation(
                bl_quadrant_position + Vector2(0,1) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.TOP_LEFT)
    if has_br_h_external_implicit_connection:
        br_h_inbound_corner_annotation = _get_quadrant_annotation(
                br_quadrant_position + Vector2(1,0) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.BOTTOM_LEFT)
    if has_br_v_external_implicit_connection:
        br_v_inbound_corner_annotation = _get_quadrant_annotation(
                br_quadrant_position + Vector2(0,1) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.TOP_RIGHT)
    
    # Parse the eight two-away inbound corner-type annotations.
    if has_tl_h2_external_implicit_connection:
        tl_h2_inbound_corner_annotation = _get_quadrant_annotation(
                tl_quadrant_position + Vector2(-2,0) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.TOP_LEFT)
    if has_tl_v2_external_implicit_connection:
        tl_v2_inbound_corner_annotation = _get_quadrant_annotation(
                tl_quadrant_position + Vector2(0,-2) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.TOP_LEFT)
    if has_tr_h2_external_implicit_connection:
        tr_h2_inbound_corner_annotation = _get_quadrant_annotation(
                tr_quadrant_position + Vector2(2,0) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.TOP_RIGHT)
    if has_tr_v2_external_implicit_connection:
        tr_v2_inbound_corner_annotation = _get_quadrant_annotation(
                tr_quadrant_position + Vector2(0,-2) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.TOP_RIGHT)
    if has_bl_h2_external_implicit_connection:
        bl_h2_inbound_corner_annotation = _get_quadrant_annotation(
                bl_quadrant_position + Vector2(-2,0) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.BOTTOM_LEFT)
    if has_bl_v2_external_implicit_connection:
        bl_v2_inbound_corner_annotation = _get_quadrant_annotation(
                bl_quadrant_position + Vector2(0,2) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.BOTTOM_LEFT)
    if has_br_h2_external_implicit_connection:
        br_h2_inbound_corner_annotation = _get_quadrant_annotation(
                br_quadrant_position + Vector2(2,0) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.BOTTOM_RIGHT)
    if has_br_v2_external_implicit_connection:
        br_v2_inbound_corner_annotation = _get_quadrant_annotation(
                br_quadrant_position + Vector2(0,2) * quadrant_size,
                quadrant_size,
                image,
                tile_set_corner_type_annotations_path,
                CornerDirection.BOTTOM_RIGHT)
    
    var is_subtile_empty: bool = \
            tl_corner_annotation.bits == 0 and \
            tr_corner_annotation.bits == 0 and \
            bl_corner_annotation.bits == 0 and \
            br_corner_annotation.bits == 0
    if is_subtile_empty:
        assert(tl_h_inbound_corner_annotation.bits == 0 and \
                tl_v_inbound_corner_annotation.bits == 0 and \
                tr_h_inbound_corner_annotation.bits == 0 and \
                tr_v_inbound_corner_annotation.bits == 0 and \
                bl_h_inbound_corner_annotation.bits == 0 and \
                bl_v_inbound_corner_annotation.bits == 0 and \
                br_h_inbound_corner_annotation.bits == 0 and \
                br_v_inbound_corner_annotation.bits == 0 and \
                tl_h2_inbound_corner_annotation.bits == 0 and \
                tl_v2_inbound_corner_annotation.bits == 0 and \
                tr_h2_inbound_corner_annotation.bits == 0 and \
                tr_v2_inbound_corner_annotation.bits == 0 and \
                bl_h2_inbound_corner_annotation.bits == 0 and \
                bl_v2_inbound_corner_annotation.bits == 0 and \
                br_h2_inbound_corner_annotation.bits == 0 and \
                br_v2_inbound_corner_annotation.bits == 0,
                ("Subtile outbound corner-type annotations are all empty, " +
                "but not all inbound annotations are empty: " +
                "subtile=%s, image=%s") % [
                    subtile_position,
                    tile_set_corner_type_annotations_path,
                ])
        return
    
    # Validate the corner-type annotations.
    _validate_tileset_annotation(
            tl_corner_annotation,
            corner_type_annotation_key,
            tl_quadrant_position,
            CornerDirection.TOP_LEFT,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            tr_corner_annotation,
            corner_type_annotation_key,
            tr_quadrant_position,
            CornerDirection.TOP_RIGHT,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            bl_corner_annotation,
            corner_type_annotation_key,
            bl_quadrant_position,
            CornerDirection.BOTTOM_LEFT,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            br_corner_annotation,
            corner_type_annotation_key,
            br_quadrant_position,
            CornerDirection.BOTTOM_RIGHT,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    
    # Validate the eight possible axially-aligned inbound corner-type
    # annotations.
    _validate_tileset_annotation(
            tl_h_inbound_corner_annotation,
            corner_type_annotation_key,
            tl_quadrant_position,
            CornerDirection.INBOUND_TL_L,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            tl_v_inbound_corner_annotation,
            corner_type_annotation_key,
            tl_quadrant_position,
            CornerDirection.INBOUND_TL_T,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            tr_h_inbound_corner_annotation,
            corner_type_annotation_key,
            tr_quadrant_position,
            CornerDirection.INBOUND_TR_R,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            tr_v_inbound_corner_annotation,
            corner_type_annotation_key,
            tr_quadrant_position,
            CornerDirection.INBOUND_TR_T,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            bl_h_inbound_corner_annotation,
            corner_type_annotation_key,
            bl_quadrant_position,
            CornerDirection.INBOUND_BL_L,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            bl_v_inbound_corner_annotation,
            corner_type_annotation_key,
            bl_quadrant_position,
            CornerDirection.INBOUND_BL_B,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            br_h_inbound_corner_annotation,
            corner_type_annotation_key,
            br_quadrant_position,
            CornerDirection.INBOUND_BR_R,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            br_v_inbound_corner_annotation,
            corner_type_annotation_key,
            br_quadrant_position,
            CornerDirection.INBOUND_BR_B,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    
    # Validate the eight possible two-away inbound corner-type annotations.
    _validate_tileset_annotation(
            tl_h2_inbound_corner_annotation,
            corner_type_annotation_key,
            tl_quadrant_position,
            CornerDirection.INBOUND_TL_L2,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            tl_v2_inbound_corner_annotation,
            corner_type_annotation_key,
            tl_quadrant_position,
            CornerDirection.INBOUND_TL_T2,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            tr_h2_inbound_corner_annotation,
            corner_type_annotation_key,
            tr_quadrant_position,
            CornerDirection.INBOUND_TR_R2,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            tr_v2_inbound_corner_annotation,
            corner_type_annotation_key,
            tr_quadrant_position,
            CornerDirection.INBOUND_TR_T2,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            bl_h2_inbound_corner_annotation,
            corner_type_annotation_key,
            bl_quadrant_position,
            CornerDirection.INBOUND_BL_L2,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            bl_v2_inbound_corner_annotation,
            corner_type_annotation_key,
            bl_quadrant_position,
            CornerDirection.INBOUND_BL_B2,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            br_h2_inbound_corner_annotation,
            corner_type_annotation_key,
            br_quadrant_position,
            CornerDirection.INBOUND_BR_R2,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    _validate_tileset_annotation(
            br_v2_inbound_corner_annotation,
            corner_type_annotation_key,
            br_quadrant_position,
            CornerDirection.INBOUND_BR_B2,
            tile_set_corner_type_annotations_path,
            quadrant_size)
    
    # Map annotations to their corner-types.
    var tl_corner_type := _get_corner_type_from_annotation(
            tl_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.TOP_LEFT)
    var tr_corner_type := _get_corner_type_from_annotation(
            tr_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.TOP_RIGHT)
    var bl_corner_type := _get_corner_type_from_annotation(
            bl_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.BOTTOM_LEFT)
    var br_corner_type := _get_corner_type_from_annotation(
            br_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.BOTTOM_RIGHT)
    
    # Also map axially-aligned inbound annotations to their corner-types.
    var tl_h_inbound_corner_type := _get_corner_type_from_annotation(
            tl_h_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_TL_L)
    var tl_v_inbound_corner_type := _get_corner_type_from_annotation(
            tl_v_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_TL_T)
    var tr_h_inbound_corner_type := _get_corner_type_from_annotation(
            tr_h_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_TR_R)
    var tr_v_inbound_corner_type := _get_corner_type_from_annotation(
            tr_v_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_TR_T)
    var bl_h_inbound_corner_type := _get_corner_type_from_annotation(
            bl_h_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_BL_L)
    var bl_v_inbound_corner_type := _get_corner_type_from_annotation(
            bl_v_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_BL_B)
    var br_h_inbound_corner_type := _get_corner_type_from_annotation(
            br_h_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_BR_R)
    var br_v_inbound_corner_type := _get_corner_type_from_annotation(
            br_v_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_BR_B)
    
    # Also map two-away inbound annotations to their corner-types.
    var tl_h2_inbound_corner_type := _get_corner_type_from_annotation(
            tl_h2_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_TL_L2)
    var tl_v2_inbound_corner_type := _get_corner_type_from_annotation(
            tl_v2_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_TL_T2)
    var tr_h2_inbound_corner_type := _get_corner_type_from_annotation(
            tr_h2_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_TR_R2)
    var tr_v2_inbound_corner_type := _get_corner_type_from_annotation(
            tr_v2_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_TR_T2)
    var bl_h2_inbound_corner_type := _get_corner_type_from_annotation(
            bl_h2_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_BL_L2)
    var bl_v2_inbound_corner_type := _get_corner_type_from_annotation(
            bl_v2_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_BL_B2)
    var br_h2_inbound_corner_type := _get_corner_type_from_annotation(
            br_h2_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_BR_R2)
    var br_v2_inbound_corner_type := _get_corner_type_from_annotation(
            br_v2_inbound_corner_annotation,
            corner_type_annotation_key,
            CornerDirection.INBOUND_BR_B2)
    
    _record_quadrant_coordinates(
            subtile_corner_types,
            CornerDirection.TOP_LEFT,
            tl_quadrant_position / quadrant_size,
            tl_corner_type,
            tr_corner_type,
            bl_corner_type,
            br_corner_type,
            tl_h_inbound_corner_type,
            tl_v_inbound_corner_type,
            tl_h2_inbound_corner_type,
            tl_v2_inbound_corner_type,
            has_tl_h_internal_implicit_connection,
            has_tl_v_internal_implicit_connection,
            has_tl_d_internal_implicit_connection)
    _record_quadrant_coordinates(
            subtile_corner_types,
            CornerDirection.TOP_RIGHT,
            tr_quadrant_position / quadrant_size,
            tr_corner_type,
            tl_corner_type,
            br_corner_type,
            bl_corner_type,
            tr_h_inbound_corner_type,
            tr_v_inbound_corner_type,
            tr_h2_inbound_corner_type,
            tr_v2_inbound_corner_type,
            has_tr_h_internal_implicit_connection,
            has_tr_v_internal_implicit_connection,
            has_tr_d_internal_implicit_connection)
    _record_quadrant_coordinates(
            subtile_corner_types,
            CornerDirection.BOTTOM_LEFT,
            bl_quadrant_position / quadrant_size,
            bl_corner_type,
            br_corner_type,
            tl_corner_type,
            tr_corner_type,
            bl_h_inbound_corner_type,
            bl_v_inbound_corner_type,
            bl_h2_inbound_corner_type,
            bl_v2_inbound_corner_type,
            has_bl_h_internal_implicit_connection,
            has_bl_v_internal_implicit_connection,
            has_bl_d_internal_implicit_connection)
    _record_quadrant_coordinates(
            subtile_corner_types,
            CornerDirection.BOTTOM_RIGHT,
            br_quadrant_position / quadrant_size,
            br_corner_type,
            bl_corner_type,
            tr_corner_type,
            tl_corner_type,
            br_h_inbound_corner_type,
            br_v_inbound_corner_type,
            br_h2_inbound_corner_type,
            br_v2_inbound_corner_type,
            has_br_h_internal_implicit_connection,
            has_br_v_internal_implicit_connection,
            has_br_d_internal_implicit_connection)


static func _record_quadrant_coordinates(
        subtile_corner_types: Dictionary,
        corner_direction: int,
        quadrant_coordinates: Vector2,
        self_corner_type: int,
        h_opp_corner_type: int,
        v_opp_corner_type: int,
        d_opp_corner_type: int,
        h_inbound_corner_type: int,
        v_inbound_corner_type: int,
        h2_inbound_corner_type: int,
        v2_inbound_corner_type: int,
        is_h_connected_internally: bool,
        is_v_connected_internally: bool,
        is_d_connected_internally: bool) -> void:
    if !is_h_connected_internally:
        h_opp_corner_type = SubtileCorner.UNKNOWN
    if !is_v_connected_internally:
        v_opp_corner_type = SubtileCorner.UNKNOWN
    if !is_d_connected_internally:
        d_opp_corner_type = SubtileCorner.UNKNOWN
    
    var keys := [
        self_corner_type,
        h_opp_corner_type,
        v_opp_corner_type,
        h_inbound_corner_type,
        v_inbound_corner_type,
        d_opp_corner_type,
        h2_inbound_corner_type,
        v2_inbound_corner_type,
        quadrant_coordinates,
    ]
    
    var index_of_last_known_type := 0
    for i in keys.size() - 1:
        if keys[i] != SubtileCorner.UNKNOWN:
            index_of_last_known_type = i
    
    var map: Dictionary = subtile_corner_types[corner_direction]
    
    _record_quadrant_coordinates_recursively(
            map,
            keys,
            0,
            index_of_last_known_type)


static func _record_quadrant_coordinates_recursively(
        map: Dictionary,
        keys: Array,
        index: int,
        index_of_last_known_type: int) -> void:
    var current_key = keys[index]
    var next_key_or_value = keys[index + 1]
    
    assert(current_key is int)
    assert(index < keys.size() - 2 or \
            next_key_or_value is Vector2)
    
    if map.has(current_key):
        var preexisting_value = map[current_key]
        if preexisting_value is Vector2:
            if next_key_or_value is Vector2 or \
                    index >= index_of_last_known_type:
                # Base case:
                # -   Do nothing.
                # -   Keep the earlier coordinates when there are multiple
                #     coordinates with the same corner-types.
                pass
            else:
                # Recursive case:
                # -   Record a new map.
                # -   Record a mapping from UNKNOWN to the preexisting value.
                # -   Recurse.
                var next_map := {}
                map[current_key] = next_map
                next_map[SubtileCorner.UNKNOWN] = preexisting_value
                _record_quadrant_coordinates_recursively(
                        next_map,
                        keys,
                        index + 1,
                        index_of_last_known_type)
        else:
            var next_map: Dictionary = preexisting_value
            _record_quadrant_coordinates_recursively(
                    next_map,
                    keys,
                    index + 1,
                    index_of_last_known_type)
    else:
        if next_key_or_value is Vector2:
            # Base case: Record the quadrant coordinates.
            map[current_key] = next_key_or_value
        elif index >= index_of_last_known_type:
            # Base case:
            # -   Record the quadrant coordinates.
            # -   In this case, some of the connected corner-types are
            #     undefined.
            # -   Rather than create extra nested dictionaries with mappings
            #     from SubtileCorner.UNKNOWN, we just record a mapping from
            #     UNKNOWN directly to the quadrant coordinates on the last
            #     preexisting dictionary in the chain.
            map[current_key] = keys.back()
        else:
            # Recursive case: Record a new map and recurse.
            var next_map := {}
            map[current_key] = next_map
            _record_quadrant_coordinates_recursively(
                    next_map,
                    keys,
                    index + 1,
                    index_of_last_known_type)


static func _get_corner_type_from_annotation(
        annotation: Dictionary,
        corner_type_annotation_key: Dictionary,
        corner_direction: int) -> int:
    if !CornerDirection.get_is_outbound(corner_direction) and \
            annotation.bits == 0:
        return SubtileCorner.UNKNOWN
    var corner_type: int = \
            corner_type_annotation_key[annotation.color][annotation.bits]
    return corner_type


static func _validate_tileset_annotation(
        annotation: Dictionary,
        corner_type_annotation_key: Dictionary,
        quadrant_position: Vector2,
        corner_direction: int,
        image_path: String,
        quadrant_size: int) -> void:
    var bits: int = annotation.bits
    var color: int = annotation.color
    
    if !CornerDirection.get_is_outbound(corner_direction) and \
            bits == 0:
        return
    
    assert(bits != 0, "Corner-type annotations cannot be empty: %s" % 
            _get_log_string(
                quadrant_position,
                quadrant_size,
                corner_direction,
                image_path))
    
    assert(corner_type_annotation_key.has(color),
            ("Corner-type-annotation color doesn't match the " +
            "annotation key: color=%s, %s") % [
                Color(color).to_html(),
                _get_log_string(
                    quadrant_position,
                    quadrant_size,
                    corner_direction,
                    image_path),
            ])
    
    if !corner_type_annotation_key[color].has(bits):
        var shape_string := ""
        for column_index in ANNOTATION_SIZE.x:
            shape_string += "\n"
            for row_index in ANNOTATION_SIZE.y:
                var bit_index := \
                        int(row_index * ANNOTATION_SIZE.x + column_index)
                var pixel_flag := 1 << bit_index
                var is_pixel_present := (bits & pixel_flag) != 0
                shape_string += "*" if is_pixel_present else "."
        Sc.logger.error(
                ("Corner-type-annotation shape doesn't match the " +
                "annotation key: %s\n%s") % [
                    shape_string,
                    _get_log_string(
                        quadrant_position,
                        quadrant_size,
                        corner_direction,
                        image_path),
                ])


static func _check_for_empty_quadrant_non_annotation_pixels(
        quadrant_position: Vector2,
        quadrant_size: int,
        image: Image,
        path: String,
        corner_direction: int) -> void:
    var is_top := CornerDirection.get_is_top(corner_direction)
    var is_left := CornerDirection.get_is_left(corner_direction)
    for quadrant_y in quadrant_size:
        for quadrant_x in quadrant_size:
            var is_pixel_along_top: bool = quadrant_y < ANNOTATION_SIZE.y
            var is_pixel_along_bottom: bool = \
                    quadrant_y >= quadrant_size - ANNOTATION_SIZE.y
            var is_pixel_along_left: bool = quadrant_x < ANNOTATION_SIZE.x
            var is_pixel_along_right: bool = \
                    quadrant_x >= quadrant_size - ANNOTATION_SIZE.x
            var is_pixel_along_triple_top: bool = quadrant_y < ANNOTATION_SIZE.y * 3
            var is_pixel_along_triple_bottom: bool = \
                    quadrant_y >= quadrant_size - ANNOTATION_SIZE.y * 3
            var is_pixel_along_triple_left: bool = quadrant_x < ANNOTATION_SIZE.x * 3
            var is_pixel_along_triple_right: bool = \
                    quadrant_x >= quadrant_size - ANNOTATION_SIZE.x * 3
            var is_pixel_in_a_corner := \
                    (is_pixel_along_top or is_pixel_along_bottom) and \
                    (is_pixel_along_triple_left or is_pixel_along_triple_right) or \
                    (is_pixel_along_triple_top or is_pixel_along_triple_bottom) and \
                    (is_pixel_along_left or is_pixel_along_right)
            var is_pixel_along_correct_horizontal_side := \
                    is_left and is_pixel_along_triple_left or \
                    !is_left and is_pixel_along_triple_right
            var is_pixel_along_correct_vertical_side := \
                    is_top and is_pixel_along_triple_top or \
                    !is_top and is_pixel_along_triple_bottom
            var is_pixel_in_a_corner_annotation_position := \
                    is_pixel_in_a_corner and \
                    (is_pixel_along_correct_horizontal_side or \
                    is_pixel_along_correct_vertical_side)
            var is_pixel_in_a_connection_annotation_position: bool = \
                    (quadrant_x <= 1 or quadrant_x >= quadrant_size - 2) and \
                    (quadrant_y <= 1 or quadrant_y >= quadrant_size - 2)
            
            if is_pixel_in_a_corner_annotation_position or \
                    is_pixel_in_a_connection_annotation_position:
                # Ignore pixels that would belong to an annotation.
                continue
            
            var color := image.get_pixel(
                    quadrant_position.x + quadrant_x,
                    quadrant_position.y + quadrant_y)
            assert(color.a == 0,
                    ("Quadrant non-annotation-corner pixels must be empty: " +
                    "pixel_position=(%s,%s), " +
                    "pixel_position=(%s,%s), " +
                    "color=%s, " +
                    "image=%s") % [
                        quadrant_x,
                        quadrant_y,
                        quadrant_position.x + quadrant_x,
                        quadrant_position.y + quadrant_y,
                        str(color),
                        _get_log_string(
                            quadrant_position,
                            quadrant_size,
                            corner_direction,
                            path),
                    ])


static func _get_connection_indicator(
        quadrant_position: Vector2,
        quadrant_size: int,
        image: Image,
        path: String,
        corner_direction: int,
        is_internal: bool,
        is_horizontal: bool,
        is_diagonal: bool,
        is_two_away: bool) -> bool:
    assert(is_internal or !is_diagonal)
    assert(!is_internal or !is_two_away)
    
    var x_offset: int
    var y_offset: int
    
    if is_internal:
        if is_diagonal:
            x_offset = quadrant_size - 1
            y_offset = quadrant_size - 1
        else:
            if is_horizontal:
                x_offset = quadrant_size - 1
                y_offset = quadrant_size - 2
            else:
                x_offset = quadrant_size - 2
                y_offset = quadrant_size - 1
    else:
        if is_two_away:
            if is_horizontal:
                x_offset = 1
                y_offset = quadrant_size - 2
            else:
                x_offset = quadrant_size - 2
                y_offset = 1
        else:
            if is_horizontal:
                x_offset = 0
                y_offset = quadrant_size - 2
            else:
                x_offset = quadrant_size - 2
                y_offset = 0
    
    if !CornerDirection.get_is_top(corner_direction):
        y_offset = quadrant_size - 1 - y_offset
    if !CornerDirection.get_is_left(corner_direction):
        x_offset = quadrant_size - 1 - x_offset
    
    var x := int(quadrant_position.x + x_offset)
    var y := int(quadrant_position.y + y_offset)
    var color := image.get_pixel(x, y)
    
    return color.a > 0.0


static func _get_annotation_in_region(
        region_start: Vector2,
        image: Image,
        path: String,
        is_top: bool,
        is_left: bool) -> Dictionary:
    var annotation_bits := 0
    var annotation_color := Color.transparent
    
    for annotation_row_index in ANNOTATION_SIZE.y:
        for annotation_column_index in ANNOTATION_SIZE.x:
            var x := int(region_start.x + (
                    annotation_column_index if \
                    is_left else \
                    ANNOTATION_SIZE.x - 1 - annotation_column_index))
            var y := int(region_start.y + (
                    annotation_row_index if \
                    is_top else \
                    ANNOTATION_SIZE.y - 1 - annotation_row_index))
            
            var color := image.get_pixel(x, y)
            if color.a == 0:
                # Ignore empty pixels.
                continue
            if color.a != 0 and \
                    color != annotation_color and \
                    annotation_color.a != 0:
                # This is an error indication.
                return {color = -1}
            
            var bit_index := int(
                    annotation_row_index * ANNOTATION_SIZE.x + \
                    annotation_column_index)
            
            annotation_color = color
            annotation_bits |= 1 << bit_index
    
    return {
        bits = annotation_bits,
        color = annotation_color.to_rgba32(),
    }


static func _get_quadrant_annotation(
        quadrant_position: Vector2,
        quadrant_size: int,
        image: Image,
        path: String,
        corner_direction: int) -> Dictionary:
    var is_left := CornerDirection.get_is_left(corner_direction)
    var is_top := CornerDirection.get_is_top(corner_direction)
    
    var region_start: Vector2
    match corner_direction:
        CornerDirection.TOP_LEFT:
            region_start = Vector2(
                    0,
                    0)
        CornerDirection.TOP_RIGHT:
            region_start = Vector2(
                    quadrant_size - ANNOTATION_SIZE.x,
                    0)
        CornerDirection.BOTTOM_LEFT:
            region_start = Vector2(
                    0,
                    quadrant_size - ANNOTATION_SIZE.y)
        CornerDirection.BOTTOM_RIGHT:
            region_start = Vector2(
                    quadrant_size - ANNOTATION_SIZE.x,
                    quadrant_size - ANNOTATION_SIZE.y)
        
        CornerDirection.INBOUND_TL_T:
            region_start = Vector2(
                    0,
                    ANNOTATION_SIZE.y)
        CornerDirection.INBOUND_TL_L:
            region_start = Vector2(
                    ANNOTATION_SIZE.x,
                    0)
        CornerDirection.INBOUND_TR_T:
            region_start = Vector2(
                    quadrant_size - ANNOTATION_SIZE.x,
                    ANNOTATION_SIZE.y)
        CornerDirection.INBOUND_TR_R:
            region_start = Vector2(
                    quadrant_size - ANNOTATION_SIZE.x * 2,
                    0)
        CornerDirection.INBOUND_BL_B:
            region_start = Vector2(
                    0,
                    quadrant_size - ANNOTATION_SIZE.y * 2)
        CornerDirection.INBOUND_BL_L:
            region_start = Vector2(
                    ANNOTATION_SIZE.x,
                    quadrant_size - ANNOTATION_SIZE.y)
        CornerDirection.INBOUND_BR_B:
            region_start = Vector2(
                    quadrant_size - ANNOTATION_SIZE.x,
                    quadrant_size - ANNOTATION_SIZE.y * 2)
        CornerDirection.INBOUND_BR_R:
            region_start = Vector2(
                    quadrant_size - ANNOTATION_SIZE.x * 2,
                    quadrant_size - ANNOTATION_SIZE.y)
        
        CornerDirection.INBOUND_TL_T2:
            region_start = Vector2(
                    0,
                    ANNOTATION_SIZE.y * 2)
        CornerDirection.INBOUND_TL_L2:
            region_start = Vector2(
                    ANNOTATION_SIZE.x * 2,
                    0)
        CornerDirection.INBOUND_TR_T2:
            region_start = Vector2(
                    quadrant_size - ANNOTATION_SIZE.x,
                    ANNOTATION_SIZE.y * 2)
        CornerDirection.INBOUND_TR_R2:
            region_start = Vector2(
                    quadrant_size - ANNOTATION_SIZE.x * 3,
                    0)
        CornerDirection.INBOUND_BL_B2:
            region_start = Vector2(
                    0,
                    quadrant_size - ANNOTATION_SIZE.y * 3)
        CornerDirection.INBOUND_BL_L2:
            region_start = Vector2(
                    ANNOTATION_SIZE.x * 2,
                    quadrant_size - ANNOTATION_SIZE.y)
        CornerDirection.INBOUND_BR_B2:
            region_start = Vector2(
                    quadrant_size - ANNOTATION_SIZE.x,
                    quadrant_size - ANNOTATION_SIZE.y * 3)
        CornerDirection.INBOUND_BR_R2:
            region_start = Vector2(
                    quadrant_size - ANNOTATION_SIZE.x * 3,
                    quadrant_size - ANNOTATION_SIZE.y)
        
        _:
            Sc.logger.error("TileSetImageParser._get_quadrant_annotation")
    
    var annotation := _get_annotation_in_region(
            quadrant_position + region_start,
            image,
            path,
            is_top,
            is_left)
    assert(annotation.color >= 0,
            ("Each corner-type annotation should use only a " +
            "single color: %s") % _get_log_string(
                quadrant_position,
                quadrant_size,
                corner_direction,
                path))
    return annotation


static func _validate_quadrants(
        subtile_corner_types: Dictionary,
        outer_tile_set: CornerMatchTileset) -> void:
    # FIXME: LEFT OFF HERE: ----------------------
    # - Check that many corner-types are defined at least once for all four
    #   corner-directions.
    # - ERROR
    # - EMPTY
    # - FULLY_INTERNAL
    # - All 90s
    # - Some basic 45s, if configured to use 45s
    # - Some basic 27s, if configured to use 27s
    
    # FIXME: LEFT OFF HERE: --------------------------------------
    # - Anything else to validate?
    # - Check notes...
    
    # FIXME: LEFT OFF HERE: --------------------------------------
    # - Abandon the below config-based checks, and instead parse a separate
    #   min-required-corner-types image.
    
    # [self, h_opp, v_opp]
    var REQUIRED_90_QUADRANT_CORNER_TYPES := [
#        [SubtileCorner.ERROR, SubtileCorner.ERROR, SubtileCorner.ERROR],
#        [SubtileCorner.EMPTY, SubtileCorner.EMPTY, SubtileCorner.EMPTY],
        
        # FIXME: LEFT OFF HERE: ------------------
        # - Update these to include more h-opp/v-opp UNKNOWN values, now that
        #   I've added the simple interior connection annotation.
#        [SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90_90_CONVEX],
#        [SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90V],
#        [SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90H, SubtileCorner.EXT_90_90_CONVEX],
#        [SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90H, SubtileCorner.EXT_90V],
#        [SubtileCorner.EXT_90H, SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_INT_90_90_CONVEX],
#        [SubtileCorner.EXT_90V, SubtileCorner.EXT_INT_90_90_CONVEX, SubtileCorner.EXT_90_90_CONVEX],
#        [SubtileCorner.EXT_90H, SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90_90_CONCAVE],
#        [SubtileCorner.EXT_90V, SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90_90_CONVEX],
#
#        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90_90_CONCAVE],
#        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90V, SubtileCorner.EXT_90_90_CONCAVE],
#        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90H],
#        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90V, SubtileCorner.EXT_90H],
#        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_INT_90_90_CONVEX],
#        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_INT_90_90_CONVEX, SubtileCorner.EXT_90_90_CONCAVE],
#        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90V, SubtileCorner.EXT_INT_90_90_CONVEX],
#        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_INT_90_90_CONVEX, SubtileCorner.EXT_90H],
#        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_INT_90_90_CONVEX, SubtileCorner.EXT_INT_90_90_CONVEX],
#        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_INT_90H],
#        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_INT_90V, SubtileCorner.EXT_90_90_CONCAVE],
        
        # FIXME: LEFT OFF HERE: --------------------
        # - Finish adding 90 cases.
        #   - All self-types that include an EXT_90_90_CONCAVE neighbor.
        #   - All int-based types.
#        [SubtileCorner., SubtileCorner., SubtileCorner.],
        
#        [SubtileCorner.EXT_90H, SubtileCorner.EXT_90H, SubtileCorner.EXT_90_90_CONCAVE],
#        [SubtileCorner.EXT_90V, SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90V],
#
#        [SubtileCorner.EXT_90H, SubtileCorner.EXT_90H, SubtileCorner.EXT_90H],
#        [SubtileCorner.EXT_90V, SubtileCorner.EXT_90V, SubtileCorner.EXT_90V],
#        [SubtileCorner.EXT_90H, SubtileCorner.EXT_90H, SubtileCorner.EXT_INT_90H],
#        [SubtileCorner.EXT_90V, SubtileCorner.EXT_INT_90V, SubtileCorner.EXT_90V],
    ]
    
    # [self, h_opp, v_opp]
    var REQUIRED_45_QUADRANT_CORNER_TYPES := [
#        [SubtileCorner., SubtileCorner., SubtileCorner.],
    ]
    
    # [self, h_opp, v_opp]
    var REQUIRED_27_QUADRANT_CORNER_TYPES := [
#        [SubtileCorner., SubtileCorner., SubtileCorner.],
    ]
    
    var required_corner_types_collection := \
            [REQUIRED_90_QUADRANT_CORNER_TYPES]
    if outer_tile_set.are_45_degree_subtiles_used:
        required_corner_types_collection.push_back(
                REQUIRED_45_QUADRANT_CORNER_TYPES)
    if outer_tile_set.are_27_degree_subtiles_used:
        required_corner_types_collection.push_back(
                REQUIRED_27_QUADRANT_CORNER_TYPES)
    
    for corner_direction in CornerDirection.OUTBOUND_CORNERS:
        var direction_map: Dictionary = subtile_corner_types[corner_direction]
        for required_corner_types in required_corner_types_collection:
            for corner_types in required_corner_types:
                var self_corner_type: int = corner_types[0]
                var h_opp_corner_type: int = corner_types[1]
                var v_opp_corner_type: int = corner_types[2]
                assert(direction_map.has(self_corner_type))
                var self_map: Dictionary = direction_map[self_corner_type]
                assert(self_map.has(h_opp_corner_type))
                var h_opp_map: Dictionary = self_map[h_opp_corner_type]
                assert(h_opp_map.has(v_opp_corner_type))


static func _get_log_string(
        quadrant_position: Vector2,
        quadrant_size: int,
        corner_direction: int,
        image_path: String) -> String:
    return (
            "subtile=%s, " +
            "%s, " +
            "quadrant=%s, " +
            "image=%s"
        ) % [
            Sc.utils.get_vector_string(
                Sc.utils.floor_vector(quadrant_position / quadrant_size / 2.0),
                0),
            CornerDirection.get_string(corner_direction),
            Sc.utils.get_vector_string(quadrant_position / quadrant_size, 0),
            image_path,
        ]
