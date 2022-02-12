class_name CellCorners
extends Reference


var top_left := SubtileCorner.UNKNOWN
var top_right := SubtileCorner.UNKNOWN
var bottom_left := SubtileCorner.UNKNOWN
var bottom_right := SubtileCorner.UNKNOWN

var inbound_tl_t := SubtileCorner.UNKNOWN
var inbound_tl_l := SubtileCorner.UNKNOWN
var inbound_tr_t := SubtileCorner.UNKNOWN
var inbound_tr_r := SubtileCorner.UNKNOWN
var inbound_bl_b := SubtileCorner.UNKNOWN
var inbound_bl_l := SubtileCorner.UNKNOWN
var inbound_br_b := SubtileCorner.UNKNOWN
var inbound_br_r := SubtileCorner.UNKNOWN


func _init(proximity: CellProximity) -> void:
    self.top_left = Su.subtile_manifest.subtile_target_corner_calculator \
            .get_target_top_left_corner(proximity)
    self.top_right = Su.subtile_manifest.subtile_target_corner_calculator \
            .get_target_top_right_corner(proximity)
    self.bottom_left = Su.subtile_manifest.subtile_target_corner_calculator \
            .get_target_bottom_left_corner(proximity)
    self.bottom_right = Su.subtile_manifest.subtile_target_corner_calculator \
            .get_target_bottom_right_corner(proximity)
    
    if proximity.get_is_present(0, -1):
        var top_proximity := CellProximity.new(
                proximity.tile_map,
                proximity.tile_set,
                proximity.position + Vector2(0, -1))
        self.inbound_tl_t = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_bottom_left_corner(top_proximity)
        self.inbound_tr_t = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_bottom_right_corner(top_proximity)
    
    if proximity.get_is_present(0, 1):
        var bottom_proximity := CellProximity.new(
                proximity.tile_map,
                proximity.tile_set,
                proximity.position + Vector2(0, 1))
        self.inbound_bl_b = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_top_left_corner(bottom_proximity)
        self.inbound_br_b = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_top_right_corner(bottom_proximity)
    
    if proximity.get_is_present(-1, 0):
        var left_proximity := CellProximity.new(
                proximity.tile_map,
                proximity.tile_set,
                proximity.position + Vector2(-1, 0))
        self.inbound_tl_l = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_top_right_corner(left_proximity)
        self.inbound_bl_l = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_bottom_right_corner(left_proximity)
    
    if proximity.get_is_present(1, 0):
        var right_proximity := CellProximity.new(
                proximity.tile_map,
                proximity.tile_set,
                proximity.position + Vector2(1, 0))
        self.inbound_tr_r = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_top_left_corner(right_proximity)
        self.inbound_br_r = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_bottom_left_corner(right_proximity)


func get_quadrant_position(
        quadrant_direction: int,
        subtile_corner_types: Dictionary) -> Vector2:
    var position_or_h_inbound_corner_type = subtile_corner_types \
            [quadrant_direction] \
            [get_corner_type(quadrant_direction)] \
            [get_h_opp_corner_type(quadrant_direction)] \
            [get_v_opp_corner_type(quadrant_direction)]
    if position_or_h_inbound_corner_type is Vector2:
        return position_or_h_inbound_corner_type
    else:
        return position_or_h_inbound_corner_type \
                [get_h_inbound_corner_type(quadrant_direction)] \
                [get_v_inbound_corner_type(quadrant_direction)]


func get_are_corners_valid() -> bool:
    for corner_directions in [
            CornerDirection.OUTBOUND_CORNERS,
            CornerDirection.INBOUND_CORNERS]:
        for corner_direction in corner_directions:
            var corner_type: int = get_corner_type(corner_direction)
            if corner_type == SubtileCorner.ERROR or \
                    corner_type == SubtileCorner.UNKNOWN:
                return false
    return true


func get_corner_type(corner_direction: int) -> int:
    match corner_direction:
        CornerDirection.TOP_LEFT:
            return top_left
        CornerDirection.TOP_RIGHT:
            return top_right
        CornerDirection.BOTTOM_LEFT:
            return bottom_left
        CornerDirection.BOTTOM_RIGHT:
            return bottom_right
        CornerDirection.INBOUND_TL_T:
            return inbound_tl_t
        CornerDirection.INBOUND_TL_L:
            return inbound_tl_l
        CornerDirection.INBOUND_TR_T:
            return inbound_tr_t
        CornerDirection.INBOUND_TR_R:
            return inbound_tr_r
        CornerDirection.INBOUND_BL_B:
            return inbound_bl_b
        CornerDirection.INBOUND_BL_L:
            return inbound_bl_l
        CornerDirection.INBOUND_BR_B:
            return inbound_br_b
        CornerDirection.INBOUND_BR_R:
            return inbound_br_r
        _:
            Sc.logger.error("CellCorners.get_corner_type")
            return SubtileCorner.UNKNOWN


func get_h_opp_corner_type(corner_direction: int) -> int:
    match corner_direction:
        CornerDirection.TOP_LEFT:
            return top_right
        CornerDirection.TOP_RIGHT:
            return top_left
        CornerDirection.BOTTOM_LEFT:
            return bottom_right
        CornerDirection.BOTTOM_RIGHT:
            return bottom_left
        _:
            Sc.logger.error("CellCorners.get_h_opp_corner_type")
            return SubtileCorner.UNKNOWN


func get_v_opp_corner_type(corner_direction: int) -> int:
    match corner_direction:
        CornerDirection.TOP_LEFT:
            return bottom_left
        CornerDirection.TOP_RIGHT:
            return bottom_right
        CornerDirection.BOTTOM_LEFT:
            return top_left
        CornerDirection.BOTTOM_RIGHT:
            return top_right
        _:
            Sc.logger.error("CellCorners.get_v_opp_corner_type")
            return SubtileCorner.UNKNOWN


func get_h_inbound_corner_type(corner_direction: int) -> int:
    match corner_direction:
        CornerDirection.TOP_LEFT:
            return inbound_tl_l
        CornerDirection.TOP_RIGHT:
            return inbound_tr_r
        CornerDirection.BOTTOM_LEFT:
            return inbound_bl_l
        CornerDirection.BOTTOM_RIGHT:
            return inbound_br_r
        _:
            Sc.logger.error("CellCorners.get_h_inbound_corner_type")
            return SubtileCorner.UNKNOWN


func get_v_inbound_corner_type(corner_direction: int) -> int:
    match corner_direction:
        CornerDirection.TOP_LEFT:
            return inbound_tl_t
        CornerDirection.TOP_RIGHT:
            return inbound_tr_t
        CornerDirection.BOTTOM_LEFT:
            return inbound_bl_b
        CornerDirection.BOTTOM_RIGHT:
            return inbound_br_b
        _:
            Sc.logger.error("CellCorners.get_v_inbound_corner_type")
            return SubtileCorner.UNKNOWN
