class_name TileSetImageParser
extends Node


# FIXME: LEFT OFF HERE: -------------------------------
# - Refactor this to not use the combined-corner-types-int pattern!
#   - Why did I ever create this??
#   - I need to be able to query partial matches.
# # subtile_corner_types[corner_direction][self_corner_type][h_opp_corner_type][v_opp_corner_type] = (Vector2|Dictionary<SubtileCorner, Dictionary<SubtileCorner, Vector2>>)


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
func parse_tile_set_corner_type_annotations(
        corner_type_annotation_key: Dictionary,
        corner_types_to_swap_for_bottom_quadrants: Dictionary,
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
                    corner_types_to_swap_for_bottom_quadrants,
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
        corner_types_to_swap_for_bottom_quadrants: Dictionary,
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
    
    # Also parse the eight possible inbound corner-type annotations.
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
                br_v_inbound_corner_annotation.bits == 0,
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
    
    # Also validate the eight possible inbound corner-type annotations.
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
    
    # Map annotations to their corner-types.
    var tl_corner_type := _get_corner_type_from_annotation(
            tl_corner_annotation,
            corner_type_annotation_key,
            corner_types_to_swap_for_bottom_quadrants,
            CornerDirection.TOP_LEFT)
    var tr_corner_type := _get_corner_type_from_annotation(
            tr_corner_annotation,
            corner_type_annotation_key,
            corner_types_to_swap_for_bottom_quadrants,
            CornerDirection.TOP_RIGHT)
    var bl_corner_type := _get_corner_type_from_annotation(
            bl_corner_annotation,
            corner_type_annotation_key,
            corner_types_to_swap_for_bottom_quadrants,
            CornerDirection.BOTTOM_LEFT)
    var br_corner_type := _get_corner_type_from_annotation(
            br_corner_annotation,
            corner_type_annotation_key,
            corner_types_to_swap_for_bottom_quadrants,
            CornerDirection.BOTTOM_RIGHT)
    
    # Also map inbound annotations to their corner-types.
    var tl_h_inbound_corner_type := \
            _get_corner_type_from_annotation(
                tl_h_inbound_corner_annotation,
                corner_type_annotation_key,
                corner_types_to_swap_for_bottom_quadrants,
                CornerDirection.INBOUND_TL_L)
    var tl_v_inbound_corner_type := \
            _get_corner_type_from_annotation(
                tl_v_inbound_corner_annotation,
                corner_type_annotation_key,
                corner_types_to_swap_for_bottom_quadrants,
                CornerDirection.INBOUND_TL_T)
    var tr_h_inbound_corner_type := \
            _get_corner_type_from_annotation(
                tr_h_inbound_corner_annotation,
                corner_type_annotation_key,
                corner_types_to_swap_for_bottom_quadrants,
                CornerDirection.INBOUND_TR_R)
    var tr_v_inbound_corner_type := \
            _get_corner_type_from_annotation(
                tr_v_inbound_corner_annotation,
                corner_type_annotation_key,
                corner_types_to_swap_for_bottom_quadrants,
                CornerDirection.INBOUND_TR_T)
    var bl_h_inbound_corner_type := \
            _get_corner_type_from_annotation(
                bl_h_inbound_corner_annotation,
                corner_type_annotation_key,
                corner_types_to_swap_for_bottom_quadrants,
                CornerDirection.INBOUND_BL_L)
    var bl_v_inbound_corner_type := \
            _get_corner_type_from_annotation(
                bl_v_inbound_corner_annotation,
                corner_type_annotation_key,
                corner_types_to_swap_for_bottom_quadrants,
                CornerDirection.INBOUND_BL_B)
    var br_h_inbound_corner_type := \
            _get_corner_type_from_annotation(
                br_h_inbound_corner_annotation,
                corner_type_annotation_key,
                corner_types_to_swap_for_bottom_quadrants,
                CornerDirection.INBOUND_BR_R)
    var br_v_inbound_corner_type := \
            _get_corner_type_from_annotation(
                br_v_inbound_corner_annotation,
                corner_type_annotation_key,
                corner_types_to_swap_for_bottom_quadrants,
                CornerDirection.INBOUND_BR_B)
    
    _record_autotile_coord(
            subtile_corner_types,
            CornerDirection.TOP_LEFT,
            tl_quadrant_position / quadrant_size,
            tl_corner_type,
            tr_corner_type,
            bl_corner_type,
            tl_h_inbound_corner_type,
            tl_v_inbound_corner_type)
    _record_autotile_coord(
            subtile_corner_types,
            CornerDirection.TOP_RIGHT,
            tr_quadrant_position / quadrant_size,
            tr_corner_type,
            tl_corner_type,
            br_corner_type,
            tr_h_inbound_corner_type,
            tr_v_inbound_corner_type)
    _record_autotile_coord(
            subtile_corner_types,
            CornerDirection.BOTTOM_LEFT,
            bl_quadrant_position / quadrant_size,
            bl_corner_type,
            br_corner_type,
            tl_corner_type,
            bl_h_inbound_corner_type,
            bl_v_inbound_corner_type)
    _record_autotile_coord(
            subtile_corner_types,
            CornerDirection.BOTTOM_RIGHT,
            br_quadrant_position / quadrant_size,
            br_corner_type,
            bl_corner_type,
            tr_corner_type,
            br_h_inbound_corner_type,
            br_v_inbound_corner_type)


static func _record_autotile_coord(
        subtile_corner_types: Dictionary,
        corner_direction: int,
        autotile_coord: Vector2,
        self_corner_type: int,
        h_opp_corner_type: int,
        v_opp_corner_type: int,
        h_inbound_corner_type: int,
        v_inbound_corner_type: int) -> void:
    var includes_inbound := \
            h_inbound_corner_type != SubtileCorner.UNKNOWN or \
            v_inbound_corner_type != SubtileCorner.UNKNOWN
    
    # CornerDirection mapping.
    var map: Dictionary = subtile_corner_types[corner_direction]
    
    # Self corner-type mapping.
    if !map.has(self_corner_type):
        map[self_corner_type] = {}
    map = map[self_corner_type]
    
    # H-opp corner-type mapping.
    if !map.has(h_opp_corner_type):
        map[h_opp_corner_type] = {}
    map = map[h_opp_corner_type]
    
    if includes_inbound:
        if !map.has(v_opp_corner_type):
            # There was no previous mapping for the v-opp corner-type.
            map[v_opp_corner_type] = {}
            
        elif map[v_opp_corner_type] is Vector2:
            # There was a Vector2 value mapped for the v-opp corner-type.
            var previous_position: Vector2 = map[v_opp_corner_type]
            
            # V-opp corner-type mapping (for the previous value).
            map[v_opp_corner_type] = {}
            var new_map = map[v_opp_corner_type]
            
            # H-inbound corner-type mapping (for the previous value).
            if !new_map.has(SubtileCorner.UNKNOWN):
                new_map[SubtileCorner.UNKNOWN] = {}
            new_map = new_map[SubtileCorner.UNKNOWN]
            
            new_map[SubtileCorner.UNKNOWN] = previous_position
        
        # V-opp corner-type mapping.
        map = map[v_opp_corner_type]
        
        # H-inbound corner-type mapping.
        if !map.has(h_inbound_corner_type):
            map[h_inbound_corner_type] = {}
        map = map[h_inbound_corner_type]
        
        map[v_inbound_corner_type] = autotile_coord
        
    else:
        if map.has(v_opp_corner_type) and \
                map[v_opp_corner_type] is Dictionary:
            # There was a Dictionary value (inbound-corner-types) mapped for
            # the v-opp corner-type.
            
            # V-opp corner-type mapping.
            map = map[v_opp_corner_type]
            
            # H-inbound corner-type mapping.
            if !map.has(SubtileCorner.UNKNOWN):
                map[SubtileCorner.UNKNOWN] = {}
            map = map[SubtileCorner.UNKNOWN]
            
            map[SubtileCorner.UNKNOWN] = autotile_coord
        else:
            map[v_opp_corner_type] = autotile_coord


static func _get_corner_type_from_annotation(
        annotation: Dictionary,
        corner_type_annotation_key: Dictionary,
        corner_types_to_swap_for_bottom_quadrants: Dictionary,
        corner_direction: int) -> int:
    if !CornerDirection.get_is_outbound(corner_direction) and \
            annotation.bits == 0:
        return SubtileCorner.UNKNOWN
    var corner_type: int = \
            corner_type_annotation_key[annotation.color][annotation.bits]
    if !CornerDirection.get_is_top(corner_direction) and \
            corner_types_to_swap_for_bottom_quadrants.has(corner_type):
        return corner_types_to_swap_for_bottom_quadrants[corner_type]
    else:
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
            var is_pixel_in_a_corner := \
                    (is_pixel_along_top or is_pixel_along_bottom) and \
                    (is_pixel_along_left or is_pixel_along_right)
            var is_pixel_along_correct_horizontal_side := \
                    is_left and is_pixel_along_left or \
                    !is_left and is_pixel_along_right
            var is_pixel_along_correct_vertical_side := \
                    is_top and is_pixel_along_top or \
                    !is_top and is_pixel_along_bottom
            
            if is_pixel_in_a_corner and \
                    (is_pixel_along_correct_horizontal_side or \
                    is_pixel_along_correct_vertical_side):
                # Ignore pixels that would belong to an annotation.
                continue
            
            var color := image.get_pixel(
                    quadrant_position.x + quadrant_x,
                    quadrant_position.y + quadrant_y)
            assert(color.a == 0,
                    ("Quadrant non-annotation-corner pixels must be empty: " +
                    "pixel_position=(%s,%s), " +
                    "image=%s") % [
                        quadrant_x,
                        quadrant_y,
                        _get_log_string(
                            quadrant_position,
                            quadrant_size,
                            corner_direction,
                            path),
                    ])


static func _get_quadrant_annotation(
        quadrant_position: Vector2,
        quadrant_size: int,
        image: Image,
        path: String,
        corner_direction: int) -> Dictionary:
    if !CornerDirection.get_is_outbound(corner_direction):
        if CornerDirection.get_is_horizontal_inbound(corner_direction):
            var next_corner_direction := \
                    CornerDirection.get_horizontal_flip(
                    CornerDirection.get_outbound_from_inbound(
                        corner_direction))
            return _get_quadrant_annotation(
                    quadrant_position,
                    quadrant_size,
                    image,
                    path,
                    next_corner_direction)
        else:
            var next_corner_direction := \
                    CornerDirection.get_vertical_flip(
                    CornerDirection.get_outbound_from_inbound(
                        corner_direction))
            return _get_quadrant_annotation(
                    quadrant_position,
                    quadrant_size,
                    image,
                    path,
                    next_corner_direction)
    
    var is_left := CornerDirection.get_is_left(corner_direction)
    var is_top := CornerDirection.get_is_top(corner_direction)
    
    var annotation_bits := 0
    var annotation_color := Color.transparent
    
    for annotation_row_index in ANNOTATION_SIZE.y:
        for annotation_column_index in ANNOTATION_SIZE.x:
            var x := int(quadrant_position.x + (
                    annotation_column_index if \
                    is_left else \
                    quadrant_size - 1 - annotation_column_index))
            var y := int(quadrant_position.y + (
                    annotation_row_index if \
                    is_top else \
                    quadrant_size - 1 - annotation_row_index))
            
            var color := image.get_pixel(x, y)
            if color.a == 0:
                # Ignore empty pixels.
                continue
            assert(color.a == 0 or \
                    color == annotation_color or \
                    annotation_color.a == 0,
                    ("Each corner-type annotation should use only a " +
                    "single color: %s") % _get_log_string(
                        quadrant_position,
                        quadrant_size,
                        corner_direction,
                        path))
            
            var bit_index := int(
                    annotation_row_index * ANNOTATION_SIZE.x + \
                    annotation_column_index)
            
            annotation_color = color
            annotation_bits |= 1 << bit_index
    
    return {
        bits = annotation_bits,
        color = annotation_color.to_rgba64(),
    }


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
        [SubtileCorner.ERROR, SubtileCorner.ERROR, SubtileCorner.ERROR],
        [SubtileCorner.EMPTY, SubtileCorner.EMPTY, SubtileCorner.EMPTY],
        
        [SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90_90_CONVEX],
        [SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90V],
        [SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90H, SubtileCorner.EXT_90_90_CONVEX],
        [SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90H, SubtileCorner.EXT_90V],
        [SubtileCorner.EXT_90H, SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_INT_90_90_CONVEX],
        [SubtileCorner.EXT_90V, SubtileCorner.EXT_INT_90_90_CONVEX, SubtileCorner.EXT_90_90_CONVEX],
        [SubtileCorner.EXT_90H, SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90_90_CONCAVE],
        [SubtileCorner.EXT_90V, SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90_90_CONVEX],
        
        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90_90_CONCAVE],
        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90V, SubtileCorner.EXT_90_90_CONCAVE],
        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90H],
        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90V, SubtileCorner.EXT_90H],
        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_INT_90_90_CONVEX],
        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_INT_90_90_CONVEX, SubtileCorner.EXT_90_90_CONCAVE],
        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90V, SubtileCorner.EXT_INT_90_90_CONVEX],
        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_INT_90_90_CONVEX, SubtileCorner.EXT_90H],
        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_INT_90_90_CONVEX, SubtileCorner.EXT_INT_90_90_CONVEX],
        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_INT_90H],
        [SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_INT_90V, SubtileCorner.EXT_90_90_CONCAVE],
        
        # FIXME: LEFT OFF HERE: --------------------
        # - Finish adding 90 cases.
        #   - All self-types that include an EXT_90_90_CONCAVE neighbor.
        #   - All int-based types.
#        [SubtileCorner., SubtileCorner., SubtileCorner.],
        
        [SubtileCorner.EXT_90H, SubtileCorner.EXT_90H, SubtileCorner.EXT_90_90_CONCAVE],
        [SubtileCorner.EXT_90V, SubtileCorner.EXT_90_90_CONCAVE, SubtileCorner.EXT_90V],
        
        [SubtileCorner.EXT_90H, SubtileCorner.EXT_90H, SubtileCorner.EXT_90H],
        [SubtileCorner.EXT_90V, SubtileCorner.EXT_90V, SubtileCorner.EXT_90V],
        [SubtileCorner.EXT_90H, SubtileCorner.EXT_90H, SubtileCorner.EXT_INT_90H],
        [SubtileCorner.EXT_90V, SubtileCorner.EXT_INT_90V, SubtileCorner.EXT_90V],
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
