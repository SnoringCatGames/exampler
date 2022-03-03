class_name CornerDirection


enum {
    UNKNOWN,
    
    TOP_LEFT,
    TOP_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_RIGHT,
    
    EXTERNAL_TL_T,
    EXTERNAL_TL_L,
    EXTERNAL_TR_T,
    EXTERNAL_TR_R,
    EXTERNAL_BL_B,
    EXTERNAL_BL_L,
    EXTERNAL_BR_B,
    EXTERNAL_BR_R,
    
    EXTERNAL_TL_T2,
    EXTERNAL_TL_L2,
    EXTERNAL_TR_T2,
    EXTERNAL_TR_R2,
    EXTERNAL_BL_B2,
    EXTERNAL_BL_L2,
    EXTERNAL_BR_B2,
    EXTERNAL_BR_R2,
    
    EXTERNAL_TL_TD,
    EXTERNAL_TL_LD,
    EXTERNAL_TR_TD,
    EXTERNAL_TR_RD,
    EXTERNAL_BL_BD,
    EXTERNAL_BL_LD,
    EXTERNAL_BR_BD,
    EXTERNAL_BR_RD,
}

const OUTBOUND_CORNERS := [
    TOP_LEFT,
    TOP_RIGHT,
    BOTTOM_LEFT,
    BOTTOM_RIGHT,
]

const EXTERNAL_CORNERS := [
    EXTERNAL_TL_T,
    EXTERNAL_TL_L,
    EXTERNAL_TR_T,
    EXTERNAL_TR_R,
    EXTERNAL_BL_B,
    EXTERNAL_BL_L,
    EXTERNAL_BR_B,
    EXTERNAL_BR_R,
    
    EXTERNAL_TL_T2,
    EXTERNAL_TL_L2,
    EXTERNAL_TR_T2,
    EXTERNAL_TR_R2,
    EXTERNAL_BL_B2,
    EXTERNAL_BL_L2,
    EXTERNAL_BR_B2,
    EXTERNAL_BR_R2,
    
    EXTERNAL_TL_TD,
    EXTERNAL_TL_LD,
    EXTERNAL_TR_TD,
    EXTERNAL_TR_RD,
    EXTERNAL_BL_BD,
    EXTERNAL_BL_LD,
    EXTERNAL_BR_BD,
    EXTERNAL_BR_RD,
]

static func get_string(type: int) -> String:
    match type:
        UNKNOWN:
            return "UNKNOWN"
        TOP_LEFT:
            return "TOP_LEFT"
        TOP_RIGHT:
            return "TOP_RIGHT"
        BOTTOM_LEFT:
            return "BOTTOM_LEFT"
        BOTTOM_RIGHT:
            return "BOTTOM_RIGHT"
        EXTERNAL_TL_T:
            return "EXTERNAL_TL_T"
        EXTERNAL_TL_L:
            return "EXTERNAL_TL_L"
        EXTERNAL_TR_T:
            return "EXTERNAL_TR_T"
        EXTERNAL_TR_R:
            return "EXTERNAL_TR_R"
        EXTERNAL_BL_B:
            return "EXTERNAL_BL_B"
        EXTERNAL_BL_L:
            return "EXTERNAL_BL_L"
        EXTERNAL_BR_B:
            return "EXTERNAL_BR_B"
        EXTERNAL_BR_R:
            return "EXTERNAL_BR_R"
        EXTERNAL_TL_T2:
            return "EXTERNAL_TL_T2"
        EXTERNAL_TL_L2:
            return "EXTERNAL_TL_L2"
        EXTERNAL_TR_T2:
            return "EXTERNAL_TR_T2"
        EXTERNAL_TR_R2:
            return "EXTERNAL_TR_R2"
        EXTERNAL_BL_B2:
            return "EXTERNAL_BL_B2"
        EXTERNAL_BL_L2:
            return "EXTERNAL_BL_L2"
        EXTERNAL_BR_B2:
            return "EXTERNAL_BR_B2"
        EXTERNAL_BR_R2:
            return "EXTERNAL_BR_R2"
        EXTERNAL_TL_TD:
            return "EXTERNAL_TL_TD"
        EXTERNAL_TL_LD:
            return "EXTERNAL_TL_LD"
        EXTERNAL_TR_TD:
            return "EXTERNAL_TR_TD"
        EXTERNAL_TR_RD:
            return "EXTERNAL_TR_RD"
        EXTERNAL_BL_BD:
            return "EXTERNAL_BL_BD"
        EXTERNAL_BL_LD:
            return "EXTERNAL_BL_LD"
        EXTERNAL_BR_BD:
            return "EXTERNAL_BR_BD"
        EXTERNAL_BR_RD:
            return "EXTERNAL_BR_RD"
        _:
            Sc.logger.error("CornerDirection.get_string")
            return "??"


static func get_is_top(type: int) -> bool:
    match type:
        UNKNOWN:
            return false
        TOP_LEFT, \
        TOP_RIGHT:
            return true
        BOTTOM_LEFT, \
        BOTTOM_RIGHT:
            return false
        EXTERNAL_TL_L, \
        EXTERNAL_TR_R, \
        EXTERNAL_BL_B, \
        EXTERNAL_BR_B:
            return true
        EXTERNAL_TL_T, \
        EXTERNAL_TR_T, \
        EXTERNAL_BL_L, \
        EXTERNAL_BR_R:
            return false
        EXTERNAL_TL_T2, \
        EXTERNAL_TR_T2, \
        EXTERNAL_TL_L2, \
        EXTERNAL_TR_R2:
            return true
        EXTERNAL_BL_L2, \
        EXTERNAL_BR_B2, \
        EXTERNAL_BR_R2, \
        EXTERNAL_BL_B2:
            return false
        EXTERNAL_TL_TD, \
        EXTERNAL_TL_LD, \
        EXTERNAL_TR_TD, \
        EXTERNAL_TR_RD:
            return false
        EXTERNAL_BL_BD, \
        EXTERNAL_BL_LD, \
        EXTERNAL_BR_BD, \
        EXTERNAL_BR_RD:
            return true
        _:
            Sc.logger.error("CornerDirection.get_is_top")
            return false


static func get_is_left(type: int) -> bool:
    match type:
        UNKNOWN:
            return false
        TOP_LEFT, \
        BOTTOM_LEFT:
            return true
        TOP_RIGHT, \
        BOTTOM_RIGHT:
            return false
        EXTERNAL_TL_T, \
        EXTERNAL_TR_R, \
        EXTERNAL_BL_B, \
        EXTERNAL_BR_R:
            return true
        EXTERNAL_TL_L, \
        EXTERNAL_TR_T, \
        EXTERNAL_BL_L, \
        EXTERNAL_BR_B:
            return false
        EXTERNAL_TL_T2, \
        EXTERNAL_TL_L2, \
        EXTERNAL_BL_B2, \
        EXTERNAL_BL_L2:
            return true
        EXTERNAL_TR_T2, \
        EXTERNAL_TR_R2, \
        EXTERNAL_BR_B2, \
        EXTERNAL_BR_R2:
            return false
        EXTERNAL_TL_TD, \
        EXTERNAL_TL_LD, \
        EXTERNAL_BL_BD, \
        EXTERNAL_BL_LD:
            return false
        EXTERNAL_TR_TD, \
        EXTERNAL_TR_RD, \
        EXTERNAL_BR_BD, \
        EXTERNAL_BR_RD:
            return true
        _:
            Sc.logger.error("CornerDirection.get_is_left")
            return false


static func get_is_outbound(type: int) -> bool:
    match type:
        UNKNOWN:
            return false
        TOP_LEFT, \
        BOTTOM_LEFT, \
        TOP_RIGHT, \
        BOTTOM_RIGHT:
            return true
        EXTERNAL_TL_T, \
        EXTERNAL_TL_L, \
        EXTERNAL_TR_T, \
        EXTERNAL_TR_R, \
        EXTERNAL_BL_B, \
        EXTERNAL_BL_L, \
        EXTERNAL_BR_B, \
        EXTERNAL_BR_R:
            return false
        EXTERNAL_TL_T2, \
        EXTERNAL_TL_L2, \
        EXTERNAL_TR_T2, \
        EXTERNAL_TR_R2, \
        EXTERNAL_BL_B2, \
        EXTERNAL_BL_L2, \
        EXTERNAL_BR_B2, \
        EXTERNAL_BR_R2:
            return false
        EXTERNAL_TL_TD, \
        EXTERNAL_TL_LD, \
        EXTERNAL_TR_TD, \
        EXTERNAL_TR_RD, \
        EXTERNAL_BL_BD, \
        EXTERNAL_BL_LD, \
        EXTERNAL_BR_BD, \
        EXTERNAL_BR_RD:
            return false
        _:
            Sc.logger.error("CornerDirection.get_is_outbound")
            return false


static func get_outbound_from_inbound(external_corner: int) -> int:
    match external_corner:
        EXTERNAL_TL_T, \
        EXTERNAL_TL_L:
            return TOP_LEFT
        EXTERNAL_TR_T, \
        EXTERNAL_TR_R:
            return TOP_RIGHT
        EXTERNAL_BL_B, \
        EXTERNAL_BL_L:
            return BOTTOM_LEFT
        EXTERNAL_BR_B, \
        EXTERNAL_BR_R:
            return BOTTOM_RIGHT
        EXTERNAL_TL_T2, \
        EXTERNAL_TL_L2:
            return TOP_LEFT
        EXTERNAL_TR_T2, \
        EXTERNAL_TR_R2:
            return TOP_RIGHT
        EXTERNAL_BL_B2, \
        EXTERNAL_BL_L2:
            return BOTTOM_LEFT
        EXTERNAL_BR_B2, \
        EXTERNAL_BR_R2:
            return BOTTOM_RIGHT
        EXTERNAL_TL_TD, \
        EXTERNAL_TL_LD:
            return TOP_LEFT
        EXTERNAL_TR_TD, \
        EXTERNAL_TR_RD:
            return TOP_RIGHT
        EXTERNAL_BL_BD, \
        EXTERNAL_BL_LD:
            return BOTTOM_LEFT
        EXTERNAL_BR_BD, \
        EXTERNAL_BR_RD:
            return BOTTOM_RIGHT
        UNKNOWN, \
        TOP_LEFT, \
        BOTTOM_LEFT, \
        TOP_RIGHT, \
        BOTTOM_RIGHT, \
        _:
            Sc.logger.error("CornerDirection.get_outbound_from_inbound")
            return UNKNOWN


static func get_horizontal_flip(corner_direction: int) -> int:
    match corner_direction:
        EXTERNAL_TL_T:
            return EXTERNAL_TR_T
        EXTERNAL_TL_L:
            return EXTERNAL_TR_R
        EXTERNAL_TR_T:
            return EXTERNAL_TL_T
        EXTERNAL_TR_R:
            return EXTERNAL_TL_L
        EXTERNAL_BL_B:
            return EXTERNAL_BR_B
        EXTERNAL_BL_L:
            return EXTERNAL_BR_R
        EXTERNAL_BR_B:
            return EXTERNAL_BL_B
        EXTERNAL_BR_R:
            return EXTERNAL_BL_L
        EXTERNAL_TL_T2:
            return EXTERNAL_TR_T2
        EXTERNAL_TL_L2:
            return EXTERNAL_TR_R2
        EXTERNAL_TR_T2:
            return EXTERNAL_TL_T2
        EXTERNAL_TR_R2:
            return EXTERNAL_TL_L2
        EXTERNAL_BL_B2:
            return EXTERNAL_BR_B2
        EXTERNAL_BL_L2:
            return EXTERNAL_BR_R2
        EXTERNAL_BR_B2:
            return EXTERNAL_BL_B2
        EXTERNAL_BR_R2:
            return EXTERNAL_BL_L2
        EXTERNAL_TL_TD:
            return EXTERNAL_TR_TD
        EXTERNAL_TL_LD:
            return EXTERNAL_TR_RD
        EXTERNAL_TR_TD:
            return EXTERNAL_TL_TD
        EXTERNAL_TR_RD:
            return EXTERNAL_TL_LD
        EXTERNAL_BL_BD:
            return EXTERNAL_BR_BD
        EXTERNAL_BL_LD:
            return EXTERNAL_BR_RD
        EXTERNAL_BR_BD:
            return EXTERNAL_BL_BD
        EXTERNAL_BR_RD:
            return EXTERNAL_BL_LD
        TOP_LEFT:
            return TOP_RIGHT
        BOTTOM_LEFT:
            return BOTTOM_RIGHT
        TOP_RIGHT:
            return TOP_LEFT
        BOTTOM_RIGHT:
            return BOTTOM_LEFT
        UNKNOWN:
            return UNKNOWN
        _:
            Sc.logger.error("CornerDirection.get_horizontal_flip")
            return UNKNOWN


static func get_vertical_flip(corner_direction: int) -> int:
    match corner_direction:
        EXTERNAL_TL_T:
            return EXTERNAL_BL_B
        EXTERNAL_TL_L:
            return EXTERNAL_BL_L
        EXTERNAL_TR_T:
            return EXTERNAL_BR_B
        EXTERNAL_TR_R:
            return EXTERNAL_BR_R
        EXTERNAL_BL_B:
            return EXTERNAL_TL_T
        EXTERNAL_BL_L:
            return EXTERNAL_TL_L
        EXTERNAL_BR_B:
            return EXTERNAL_TR_T
        EXTERNAL_BR_R:
            return EXTERNAL_TR_R
        EXTERNAL_TL_T2:
            return EXTERNAL_BL_B2
        EXTERNAL_TL_L2:
            return EXTERNAL_BL_L2
        EXTERNAL_TR_T2:
            return EXTERNAL_BR_B2
        EXTERNAL_TR_R2:
            return EXTERNAL_BR_R2
        EXTERNAL_BL_B2:
            return EXTERNAL_TL_T2
        EXTERNAL_BL_L2:
            return EXTERNAL_TL_L2
        EXTERNAL_BR_B2:
            return EXTERNAL_TR_T2
        EXTERNAL_BR_R2:
            return EXTERNAL_TR_R2
        EXTERNAL_TL_TD:
            return EXTERNAL_BL_BD
        EXTERNAL_TL_LD:
            return EXTERNAL_BL_LD
        EXTERNAL_TR_TD:
            return EXTERNAL_BR_BD
        EXTERNAL_TR_RD:
            return EXTERNAL_BR_RD
        EXTERNAL_BL_BD:
            return EXTERNAL_TL_TD
        EXTERNAL_BL_LD:
            return EXTERNAL_TL_LD
        EXTERNAL_BR_BD:
            return EXTERNAL_TR_TD
        EXTERNAL_BR_RD:
            return EXTERNAL_TR_RD
        TOP_LEFT:
            return BOTTOM_LEFT
        BOTTOM_LEFT:
            return TOP_LEFT
        TOP_RIGHT:
            return BOTTOM_RIGHT
        BOTTOM_RIGHT:
            return TOP_RIGHT
        UNKNOWN:
            return UNKNOWN
        _:
            Sc.logger.error("CornerDirection.get_vertical_flip")
            return UNKNOWN
