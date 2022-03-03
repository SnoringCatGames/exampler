class_name CellCorners
extends Reference


var top_left := SubtileCorner.UNKNOWN
var top_right := SubtileCorner.UNKNOWN
var bottom_left := SubtileCorner.UNKNOWN
var bottom_right := SubtileCorner.UNKNOWN

var external_tl_t := SubtileCorner.UNKNOWN
var external_tl_l := SubtileCorner.UNKNOWN
var external_tr_t := SubtileCorner.UNKNOWN
var external_tr_r := SubtileCorner.UNKNOWN
var external_bl_b := SubtileCorner.UNKNOWN
var external_bl_l := SubtileCorner.UNKNOWN
var external_br_b := SubtileCorner.UNKNOWN
var external_br_r := SubtileCorner.UNKNOWN

var external_tl_t2 := SubtileCorner.UNKNOWN
var external_tl_l2 := SubtileCorner.UNKNOWN
var external_tr_t2 := SubtileCorner.UNKNOWN
var external_tr_r2 := SubtileCorner.UNKNOWN
var external_bl_b2 := SubtileCorner.UNKNOWN
var external_bl_l2 := SubtileCorner.UNKNOWN
var external_br_b2 := SubtileCorner.UNKNOWN
var external_br_r2 := SubtileCorner.UNKNOWN


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
        self.external_tl_t = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_bottom_left_corner(top_proximity)
        self.external_tr_t = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_bottom_right_corner(top_proximity)
        self.external_tl_t2 = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_top_left_corner(top_proximity)
        self.external_tr_t2 = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_top_right_corner(top_proximity)
    else:
        self.external_tl_t = SubtileCorner.EMPTY
        self.external_tr_t = SubtileCorner.EMPTY
        self.external_tl_t2 = SubtileCorner.EMPTY
        self.external_tr_t2 = SubtileCorner.EMPTY
    
    if proximity.get_is_present(0, 1):
        var bottom_proximity := CellProximity.new(
                proximity.tile_map,
                proximity.tile_set,
                proximity.position + Vector2(0, 1))
        self.external_bl_b = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_top_left_corner(bottom_proximity)
        self.external_br_b = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_top_right_corner(bottom_proximity)
        self.external_bl_b2 = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_bottom_left_corner(bottom_proximity)
        self.external_br_b2 = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_bottom_right_corner(bottom_proximity)
    else:
        self.external_bl_b = SubtileCorner.EMPTY
        self.external_br_b = SubtileCorner.EMPTY
        self.external_bl_b2 = SubtileCorner.EMPTY
        self.external_br_b2 = SubtileCorner.EMPTY
    
    if proximity.get_is_present(-1, 0):
        var left_proximity := CellProximity.new(
                proximity.tile_map,
                proximity.tile_set,
                proximity.position + Vector2(-1, 0))
        self.external_tl_l = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_top_right_corner(left_proximity)
        self.external_bl_l = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_bottom_right_corner(left_proximity)
        self.external_tl_l2 = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_top_left_corner(left_proximity)
        self.external_bl_l2 = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_bottom_left_corner(left_proximity)
    else:
        self.external_tl_l = SubtileCorner.EMPTY
        self.external_bl_l = SubtileCorner.EMPTY
        self.external_tl_l2 = SubtileCorner.EMPTY
        self.external_bl_l2 = SubtileCorner.EMPTY
    
    if proximity.get_is_present(1, 0):
        var right_proximity := CellProximity.new(
                proximity.tile_map,
                proximity.tile_set,
                proximity.position + Vector2(1, 0))
        self.external_tr_r = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_top_left_corner(right_proximity)
        self.external_br_r = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_bottom_left_corner(right_proximity)
        self.external_tr_r2 = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_top_right_corner(right_proximity)
        self.external_br_r2 = \
                Su.subtile_manifest.subtile_target_corner_calculator \
                    .get_target_bottom_right_corner(right_proximity)
    else:
        self.external_tr_r = SubtileCorner.EMPTY
        self.external_br_r = SubtileCorner.EMPTY
        self.external_tr_r2 = SubtileCorner.EMPTY
        self.external_br_r2 = SubtileCorner.EMPTY


func to_string(uses_newlines := false) -> String:
    var corner_strings := []
    for corner_directions in [
            CornerDirection.OUTBOUND_CORNERS,
            CornerDirection.EXTERNAL_CORNERS]:
        for corner_direction in corner_directions:
            var corner_type: int = get_corner_type(corner_direction)
            var corner_direction_string := \
                    CornerDirection.get_string(corner_direction)
            var corner_type_string: String = \
                    Su.subtile_manifest.get_subtile_corner_string(corner_type)
            corner_strings.push_back("%s=%s" % [
                    corner_direction_string,
                    corner_type_string,
               ])
    if uses_newlines:
        return "CellCorners(\n    %s\n)" % \
                Sc.utils.join(corner_strings, ",\n    ")
    else:
        return "CellCorners(%s)" % Sc.utils.join(corner_strings, ", ")


func get_are_corners_valid() -> bool:
    for corner_directions in [
            CornerDirection.OUTBOUND_CORNERS,
            CornerDirection.EXTERNAL_CORNERS]:
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
        CornerDirection.EXTERNAL_TL_T:
            return external_tl_t
        CornerDirection.EXTERNAL_TL_L:
            return external_tl_l
        CornerDirection.EXTERNAL_TR_T:
            return external_tr_t
        CornerDirection.EXTERNAL_TR_R:
            return external_tr_r
        CornerDirection.EXTERNAL_BL_B:
            return external_bl_b
        CornerDirection.EXTERNAL_BL_L:
            return external_bl_l
        CornerDirection.EXTERNAL_BR_B:
            return external_br_b
        CornerDirection.EXTERNAL_BR_R:
            return external_br_r
        CornerDirection.EXTERNAL_TL_T2:
            return external_tl_t2
        CornerDirection.EXTERNAL_TL_L2:
            return external_tl_l2
        CornerDirection.EXTERNAL_TR_T2:
            return external_tr_t2
        CornerDirection.EXTERNAL_TR_R2:
            return external_tr_r2
        CornerDirection.EXTERNAL_BL_B2:
            return external_bl_b2
        CornerDirection.EXTERNAL_BL_L2:
            return external_bl_l2
        CornerDirection.EXTERNAL_BR_B2:
            return external_br_b2
        CornerDirection.EXTERNAL_BR_R2:
            return external_br_r2
        CornerDirection.EXTERNAL_TL_TD:
            return external_tr_t
        CornerDirection.EXTERNAL_TL_LD:
            return external_bl_l
        CornerDirection.EXTERNAL_TR_TD:
            return external_tl_t
        CornerDirection.EXTERNAL_TR_RD:
            return external_br_r
        CornerDirection.EXTERNAL_BL_BD:
            return external_br_b
        CornerDirection.EXTERNAL_BL_LD:
            return external_tl_l
        CornerDirection.EXTERNAL_BR_BD:
            return external_bl_b
        CornerDirection.EXTERNAL_BR_RD:
            return external_tr_r
        _:
            Sc.logger.error("CellCorners.get_corner_type")
            return SubtileCorner.UNKNOWN


func get_h_internal_corner_type(corner_direction: int) -> int:
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
            Sc.logger.error("CellCorners.get_h_internal_corner_type")
            return SubtileCorner.UNKNOWN


func get_v_internal_corner_type(corner_direction: int) -> int:
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
            Sc.logger.error("CellCorners.get_v_internal_corner_type")
            return SubtileCorner.UNKNOWN


func get_h_external_corner_type(corner_direction: int) -> int:
    match corner_direction:
        CornerDirection.TOP_LEFT:
            return external_tl_l
        CornerDirection.TOP_RIGHT:
            return external_tr_r
        CornerDirection.BOTTOM_LEFT:
            return external_bl_l
        CornerDirection.BOTTOM_RIGHT:
            return external_br_r
        _:
            Sc.logger.error("CellCorners.get_h_external_corner_type")
            return SubtileCorner.UNKNOWN


func get_v_external_corner_type(corner_direction: int) -> int:
    match corner_direction:
        CornerDirection.TOP_LEFT:
            return external_tl_t
        CornerDirection.TOP_RIGHT:
            return external_tr_t
        CornerDirection.BOTTOM_LEFT:
            return external_bl_b
        CornerDirection.BOTTOM_RIGHT:
            return external_br_b
        _:
            Sc.logger.error("CellCorners.get_v_external_corner_type")
            return SubtileCorner.UNKNOWN


func get_d_internal_corner_type(corner_direction: int) -> int:
    match corner_direction:
        CornerDirection.TOP_LEFT:
            return bottom_right
        CornerDirection.TOP_RIGHT:
            return bottom_left
        CornerDirection.BOTTOM_LEFT:
            return top_right
        CornerDirection.BOTTOM_RIGHT:
            return top_left
        _:
            Sc.logger.error("CellCorners.get_d_internal_corner_type")
            return SubtileCorner.UNKNOWN


func get_h2_external_corner_type(corner_direction: int) -> int:
    match corner_direction:
        CornerDirection.TOP_LEFT:
            return external_tl_l2
        CornerDirection.TOP_RIGHT:
            return external_tr_r2
        CornerDirection.BOTTOM_LEFT:
            return external_bl_l2
        CornerDirection.BOTTOM_RIGHT:
            return external_br_r2
        _:
            Sc.logger.error("CellCorners.get_h2_external_corner_type")
            return SubtileCorner.UNKNOWN


func get_v2_external_corner_type(corner_direction: int) -> int:
    match corner_direction:
        CornerDirection.TOP_LEFT:
            return external_tl_t2
        CornerDirection.TOP_RIGHT:
            return external_tr_t2
        CornerDirection.BOTTOM_LEFT:
            return external_bl_b2
        CornerDirection.BOTTOM_RIGHT:
            return external_br_b2
        _:
            Sc.logger.error("CellCorners.get_v2_external_corner_type")
            return SubtileCorner.UNKNOWN


func get_hd_external_corner_type(corner_direction: int) -> int:
    match corner_direction:
        CornerDirection.TOP_LEFT:
            return external_bl_l
        CornerDirection.TOP_RIGHT:
            return external_br_r
        CornerDirection.BOTTOM_LEFT:
            return external_tl_l
        CornerDirection.BOTTOM_RIGHT:
            return external_tr_r
        _:
            Sc.logger.error("CellCorners.get_hd_external_corner_type")
            return SubtileCorner.UNKNOWN


func get_vd_external_corner_type(corner_direction: int) -> int:
    match corner_direction:
        CornerDirection.TOP_LEFT:
            return external_tr_t
        CornerDirection.TOP_RIGHT:
            return external_tl_t
        CornerDirection.BOTTOM_LEFT:
            return external_br_b
        CornerDirection.BOTTOM_RIGHT:
            return external_bl_b
        _:
            Sc.logger.error("CellCorners.get_vd_external_corner_type")
            return SubtileCorner.UNKNOWN
