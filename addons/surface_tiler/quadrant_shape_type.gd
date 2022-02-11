class_name QuadrantShapeType


enum {
    EMPTY,
    FULL_SQUARE,
    CLIPPED_CORNER_90_90,
    CLIPPED_CORNER_45,
    MARGIN_TOP_90,
    MARGIN_SIDE_90,
    MARGIN_TOP_AND_SIDE_90,
    FLOOR_45_N,
    CEILING_45_N,
    EXT_90H_45_CONVEX_ACUTE,
    EXT_90V_45_CONVEX_ACUTE,
}

const VALUES := [
    EMPTY,
    FULL_SQUARE,
    CLIPPED_CORNER_90_90,
    CLIPPED_CORNER_45,
    MARGIN_TOP_90,
    MARGIN_SIDE_90,
    MARGIN_TOP_AND_SIDE_90,
    FLOOR_45_N,
    CEILING_45_N,
    EXT_90H_45_CONVEX_ACUTE,
    EXT_90V_45_CONVEX_ACUTE,
]


static func get_shape_type_for_corner_type(corner_type: int) -> int:
    match corner_type:
        SubtileCorner.UNKNOWN:
            return FULL_SQUARE
        SubtileCorner.EMPTY:
            return EMPTY
        SubtileCorner.FULLY_INTERIOR:
            return FULL_SQUARE
        SubtileCorner.ERROR:
            return FULL_SQUARE
        
        ### 90-degree.
        
        SubtileCorner.EXT_90H:
            return MARGIN_TOP_90
        SubtileCorner.EXT_90V:
            return MARGIN_SIDE_90
        SubtileCorner.EXT_90_90_CONVEX:
            return MARGIN_TOP_AND_SIDE_90
        SubtileCorner.EXT_90_90_CONCAVE:
            return CLIPPED_CORNER_90_90
        
        SubtileCorner.EXT_INT_90H, \
        SubtileCorner.EXT_INT_90V, \
        SubtileCorner.EXT_INT_90_90_CONVEX, \
        SubtileCorner.EXT_INT_90_90_CONCAVE, \
        SubtileCorner.INT_90H, \
        SubtileCorner.INT_90V, \
        SubtileCorner.INT_90_90_CONVEX, \
        SubtileCorner.INT_90_90_CONCAVE:
            return FULL_SQUARE
        
        ### 45-degree.
        
        SubtileCorner.EXT_45_FLOOR:
            return FLOOR_45_N
        SubtileCorner.EXT_45_CEILING:
            return CEILING_45_N
        SubtileCorner.EXT_EXT_45_CLIPPED:
            return CLIPPED_CORNER_45
        
        SubtileCorner.EXT_INT_45_FLOOR, \
        SubtileCorner.EXT_INT_45_CEILING, \
        SubtileCorner.EXT_INT_45_CLIPPED, \
        SubtileCorner.INT_EXT_45_CLIPPED, \
        SubtileCorner.INT_45_FLOOR, \
        SubtileCorner.INT_45_CEILING, \
        SubtileCorner.INT_INT_45_CLIPPED:
            return FULL_SQUARE
        
        ### 90-to-45-degree.
        
        SubtileCorner.EXT_90H_45_CONVEX_ACUTE:
            return EXT_90H_45_CONVEX_ACUTE
        SubtileCorner.EXT_90V_45_CONVEX_ACUTE:
            return EXT_90V_45_CONVEX_ACUTE
        
        SubtileCorner.EXT_90H_45_CONVEX:
            return MARGIN_TOP_90
        SubtileCorner.EXT_90V_45_CONVEX:
            return MARGIN_SIDE_90
        
        SubtileCorner.EXT_90H_45_CONCAVE:
            return CLIPPED_CORNER_45
        SubtileCorner.EXT_90V_45_CONCAVE:
            return CLIPPED_CORNER_45
        
        SubtileCorner.EXT_INT_90H_45_CONVEX, \
        SubtileCorner.EXT_INT_90V_45_CONVEX, \
        SubtileCorner.EXT_INT_90H_45_CONCAVE, \
        SubtileCorner.EXT_INT_90V_45_CONCAVE, \
        SubtileCorner.INT_EXT_90H_45_CONCAVE, \
        SubtileCorner.INT_EXT_90V_45_CONCAVE, \
        SubtileCorner.INT_INT_90H_45_CONCAVE, \
        SubtileCorner.INT_INT_90V_45_CONCAVE:
            return FULL_SQUARE
        
        ### Complex 90-45-degree combinations.
        
        SubtileCorner.EXT_INT_45_FLOOR_45_CEILING, \
        SubtileCorner.INT_45_FLOOR_45_CEILING, \
        SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE, \
        SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE, \
        SubtileCorner.INT_90H_EXT_INT_45_CONVEX_ACUTE, \
        SubtileCorner.INT_90V_EXT_INT_45_CONVEX_ACUTE, \
        SubtileCorner.INT_90H_EXT_INT_90H_45_CONCAVE, \
        SubtileCorner.INT_90V_EXT_INT_90V_45_CONCAVE, \
        SubtileCorner.INT_90H_INT_EXT_45_CLIPPED, \
        SubtileCorner.INT_90V_INT_EXT_45_CLIPPED, \
        SubtileCorner.INT_90_90_CONVEX_INT_EXT_45_CLIPPED, \
        SubtileCorner.INT_INT_90H_45_CONCAVE_90V_45_CONCAVE, \
        SubtileCorner.INT_INT_90H_45_CONCAVE_INT_45_CEILING, \
        SubtileCorner.INT_INT_90V_45_CONCAVE_INT_45_FLOOR, \
        SubtileCorner.INT_90H_INT_INT_90V_45_CONCAVE, \
        SubtileCorner.INT_90V_INT_INT_90H_45_CONCAVE, \
        SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR, \
        SubtileCorner.INT_90_90_CONCAVE_INT_45_CEILING, \
        SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR_45_CEILING, \
        SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE, \
        SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE, \
        SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_90V_45_CONCAVE, \
        SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_INT_45_CEILING, \
        SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE_INT_45_FLOOR:
            return FULL_SQUARE
        
        # FIXME: LEFT OFF HERE: -------- A27
        
        _:
            # FIXME: LEFT OFF HERE: ---------------------
            # - Translate int to String after moving the translator to manifest.
            Sc.logger.error(
                    "QuadrantShapeType.get_shape_type_for_corner_type: %s" % \
                    corner_type)
            return FULL_SQUARE
