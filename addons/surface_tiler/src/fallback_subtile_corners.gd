class_name FallbackSubtileCorners
extends Reference


# NOTE:
# -   This mapping enables us to match one corner type with another.
# -   Each mapping multiplier must be between 0 and 1.
# -   Reverse mappings are automatically added. DO NOT INCLUDE THEM HERE.
#     -   E.g., if A maps to B, then B should not map to A.
# FIXME: LEFT OFF HERE: -----------------------------------------
# - Should this be configurable by the tileset author?
# - Would there be a simpler way to allow the tile-set author to configure which
#   slopes are allowed to transition into which others?
const FALLBACKS := {
    SubtileCorner.UNKNOWN: [],
    SubtileCorner.ERROR: [],
    SubtileCorner.EMPTY: [],
    SubtileCorner.FULLY_INTERIOR: [],
    
    ### 90-degree.
    
    SubtileCorner.EXT_90H: [],
    SubtileCorner.EXT_90V: [],
    SubtileCorner.EXT_90_90_CONVEX: [
        [SubtileCorner.EMPTY, 1.0],
    ],
    SubtileCorner.EXT_90_90_CONCAVE: [],
    
    SubtileCorner.EXT_INT_90H: [],
    SubtileCorner.EXT_INT_90V: [],
    SubtileCorner.EXT_INT_90_90_CONVEX: [],
    SubtileCorner.EXT_INT_90_90_CONCAVE: [],
    
    SubtileCorner.INT_90H: [],
    SubtileCorner.INT_90V: [],
    SubtileCorner.INT_90_90_CONVEX: [],
    SubtileCorner.INT_90_90_CONCAVE: [],
    
    ### 45-degree.
    
    SubtileCorner.EXT_45_H_SIDE: [],
    SubtileCorner.EXT_45_V_SIDE: [],
    SubtileCorner.EXT_EXT_45_CLIPPED: [],
    
    SubtileCorner.EXT_INT_45_H_SIDE: [],
    SubtileCorner.EXT_INT_45_V_SIDE: [],
    SubtileCorner.EXT_INT_45_CLIPPED: [],
    
    SubtileCorner.INT_EXT_45_CLIPPED: [],
    
    SubtileCorner.INT_45_H_SIDE: [],
    SubtileCorner.INT_45_V_SIDE: [],
    SubtileCorner.INT_INT_45_CLIPPED: [],
    
    ### 90-to-45-degree.
    
    SubtileCorner.EXT_90H_45_CONVEX_ACUTE: [
        [SubtileCorner.EMPTY, 1.0],
    ],
    SubtileCorner.EXT_90V_45_CONVEX_ACUTE: [
        [SubtileCorner.EMPTY, 1.0],
    ],
    
    SubtileCorner.EXT_90H_45_CONVEX: [
        [SubtileCorner.EXT_90H, 0.6],
    ],
    SubtileCorner.EXT_90V_45_CONVEX: [
        [SubtileCorner.EXT_90V, 0.6],
    ],
    
    SubtileCorner.EXT_EXT_90H_45_CONCAVE: [
        [SubtileCorner.EXT_EXT_45_CLIPPED, 0.6],
        [SubtileCorner.EXT_90_90_CONCAVE, 0.3],
    ],
    SubtileCorner.EXT_EXT_90V_45_CONCAVE: [
        [SubtileCorner.EXT_EXT_45_CLIPPED, 0.6],
        [SubtileCorner.EXT_90_90_CONCAVE, 0.3],
    ],
    
    SubtileCorner.EXT_INT_90H_45_CONVEX: [
        [SubtileCorner.INT_45_H_SIDE, 0.6],
    ],
    SubtileCorner.EXT_INT_90V_45_CONVEX: [
        [SubtileCorner.INT_45_H_SIDE, 0.6],
    ],
    
    SubtileCorner.EXT_INT_90H_45_CONCAVE: [
        [SubtileCorner.EXT_INT_45_V_SIDE, 0.6],
    ],
    SubtileCorner.EXT_INT_90V_45_CONCAVE: [
        [SubtileCorner.EXT_INT_45_H_SIDE, 0.6],
    ],
    
    SubtileCorner.INT_EXT_90H_45_CONCAVE: [
        [SubtileCorner.INT_INT_45_CLIPPED, 0.6],
        [SubtileCorner.INT_EXT_90V_45_CONCAVE, 0.6],
        [SubtileCorner.EXT_INT_45_V_SIDE, 0.3],
        [SubtileCorner.EXT_INT_90H_45_CONCAVE, 0.3],
    ],
    SubtileCorner.INT_EXT_90V_45_CONCAVE: [
        [SubtileCorner.INT_INT_45_CLIPPED, 0.6],
        [SubtileCorner.INT_EXT_90H_45_CONCAVE, 0.6],
        [SubtileCorner.EXT_INT_45_H_SIDE, 0.3],
        [SubtileCorner.EXT_INT_90V_45_CONCAVE, 0.3],
    ],
    
    SubtileCorner.INT_INT_EXT_90H_45_CONCAVE: [
        [SubtileCorner.INT_90H, 0.6],
    ],
    SubtileCorner.INT_INT_EXT_90V_45_CONCAVE: [
        [SubtileCorner.INT_90V, 0.6],
    ],
    
    SubtileCorner.INT_INT_90H_45_CONCAVE: [
        [SubtileCorner.INT_45_H_SIDE, 0.6],
    ],
    SubtileCorner.INT_INT_90V_45_CONCAVE: [
        [SubtileCorner.INT_45_V_SIDE, 0.6],
    ],
    
    ### Complex 90-45-degree combinations.
    
    SubtileCorner.EXT_INT_45_FLOOR_45_CEILING: [],
    
    SubtileCorner.INT_45_FLOOR_45_CEILING: [],
    
    SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE: [],
    SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE: [],
    
    SubtileCorner.INT_90H_EXT_INT_45_CONVEX_ACUTE: [
        [SubtileCorner.EXT_INT_45_V_SIDE, 0.4],
    ],
    SubtileCorner.INT_90V_EXT_INT_45_CONVEX_ACUTE: [
        [SubtileCorner.EXT_INT_45_H_SIDE, 0.4],
    ],
    
    SubtileCorner.INT_90H_EXT_INT_90H_45_CONCAVE: [
        [SubtileCorner.EXT_INT_90H, 0.4],
        [SubtileCorner.EXT_INT_45_V_SIDE, 0.3],
    ],
    SubtileCorner.INT_90V_EXT_INT_90V_45_CONCAVE: [
        [SubtileCorner.EXT_INT_90V, 0.4],
        [SubtileCorner.EXT_INT_45_H_SIDE, 0.3],
    ],
    
    
    SubtileCorner.INT_90H_INT_EXT_45_CLIPPED: [
        [SubtileCorner.INT_EXT_45_CLIPPED, 0.4],
    ],
    SubtileCorner.INT_90V_INT_EXT_45_CLIPPED: [
        [SubtileCorner.INT_EXT_45_CLIPPED, 0.4],
    ],
    SubtileCorner.INT_90_90_CONVEX_INT_EXT_45_CLIPPED: [
        [SubtileCorner.INT_90_90_CONVEX, 0.45],
        [SubtileCorner.INT_EXT_45_CLIPPED, 0.35],
    ],
    
    SubtileCorner.INT_90H_INT_45_H_SIDE: [],
    SubtileCorner.INT_90V_INT_45_H_SIDE: [],
    SubtileCorner.INT_90_90_CONVEX_INT_45_H_SIDE: [],
    
    SubtileCorner.INT_90H_INT_45_V_SIDE: [],
    SubtileCorner.INT_90V_INT_45_V_SIDE: [],
    SubtileCorner.INT_90_90_CONVEX_INT_45_V_SIDE: [],
    
    SubtileCorner.INT_90H_INT_45_FLOOR_45_CEILING: [],
    SubtileCorner.INT_90V_INT_45_FLOOR_45_CEILING: [],
    SubtileCorner.INT_90_90_CONVEX_INT_45_FLOOR_45_CEILING: [],
    
    SubtileCorner.INT_INT_EXT_90H_45_CONCAVE_90V_45_CONCAVE: [
        [SubtileCorner.INT_90_90_CONVEX, 0.6],
    ],
    SubtileCorner.INT_90H_INT_INT_EXT_90V_45_CONCAVE: [
        [SubtileCorner.INT_INT_EXT_90H_45_CONCAVE_90V_45_CONCAVE, 0.7],
        [SubtileCorner.INT_90_90_CONVEX, 0.6],
    ],
    SubtileCorner.INT_90V_INT_INT_EXT_90H_45_CONCAVE: [
        [SubtileCorner.INT_INT_EXT_90H_45_CONCAVE_90V_45_CONCAVE, 0.7],
        [SubtileCorner.INT_90_90_CONVEX, 0.6],
        [SubtileCorner.INT_90H_INT_INT_EXT_90V_45_CONCAVE, 0.5],
    ],
    
    SubtileCorner.INT_INT_EXT_90H_45_CONCAVE_INT_45_H_SIDE: [],
    SubtileCorner.INT_INT_EXT_90V_45_CONCAVE_INT_45_V_SIDE: [],
    
    SubtileCorner.INT_INT_EXT_90H_45_CONCAVE_INT_45_V_SIDE: [],
    SubtileCorner.INT_INT_EXT_90V_45_CONCAVE_INT_45_H_SIDE: [],
    
    SubtileCorner.INT_INT_EXT_90H_45_CONCAVE_90V_45_CONCAVE_INT_45_H_SIDE: [],
    SubtileCorner.INT_INT_EXT_90H_45_CONCAVE_90V_45_CONCAVE_INT_45_V_SIDE: [],
    
    SubtileCorner.INT_INT_EXT_90H_45_CONCAVE_INT_45_FLOOR_45_CEILING: [],
    SubtileCorner.INT_INT_EXT_90V_45_CONCAVE_INT_45_FLOOR_45_CEILING: [],
    SubtileCorner.INT_INT_EXT_90H_45_CONCAVE_90V_45_CONCAVE_INT_45_FLOOR_45_CEILING: [],
    
    SubtileCorner.INT_INT_90H_45_CONCAVE_90V_45_CONCAVE: [
        [SubtileCorner.INT_45_FLOOR_45_CEILING, 0.6],
    ],
    SubtileCorner.INT_INT_90H_45_CONCAVE_INT_45_V_SIDE: [
        [SubtileCorner.INT_45_FLOOR_45_CEILING, 0.6],
        [SubtileCorner.INT_INT_90H_45_CONCAVE_90V_45_CONCAVE, 0.6],
    ],
    SubtileCorner.INT_INT_90V_45_CONCAVE_INT_45_H_SIDE: [
        [SubtileCorner.INT_45_FLOOR_45_CEILING, 0.6],
        [SubtileCorner.INT_INT_90H_45_CONCAVE_90V_45_CONCAVE, 0.6],
        [SubtileCorner.INT_INT_90H_45_CONCAVE_INT_45_V_SIDE, 0.6],
    ],
    
    SubtileCorner.INT_90H_INT_INT_90V_45_CONCAVE: [],
    SubtileCorner.INT_90V_INT_INT_90H_45_CONCAVE: [],
    
    SubtileCorner.INT_90H_INT_INT_90V_45_CONCAVE_INT_45_H_SIDE: [],
    SubtileCorner.INT_90V_INT_INT_90H_45_CONCAVE_INT_45_V_SIDE: [],
    
    SubtileCorner.INT_90_90_CONCAVE_INT_45_H_SIDE: [],
    SubtileCorner.INT_90_90_CONCAVE_INT_45_V_SIDE: [],
    SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR_45_CEILING: [],
    
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE: [],
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE: [],
    
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_90V_45_CONCAVE: [],
    
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_INT_45_V_SIDE: [],
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE_INT_45_H_SIDE: [],
    
    ### 27-degree.
    
    # FIXME: LEFT OFF HERE: ------------------
    
#    SubtileCorner.EXT_27_SHALLOW_CLIPPED: [],
#    SubtileCorner.EXT_27_STEEP_CLIPPED: [],
#
#    SubtileCorner.EXT_27_FLOOR_SHALLOW_CLOSE: [],
#    SubtileCorner.EXT_27_FLOOR_SHALLOW_FAR: [],
#    SubtileCorner.EXT_27_FLOOR_STEEP_CLOSE: [],
#    SubtileCorner.EXT_27_FLOOR_STEEP_FAR: [],
#
#    SubtileCorner.EXT_27_CEILING_SHALLOW_CLOSE: [],
#    SubtileCorner.EXT_27_CEILING_SHALLOW_FAR: [],
#    SubtileCorner.EXT_27_CEILING_STEEP_CLOSE: [],
#    SubtileCorner.EXT_27_CEILING_STEEP_FAR: [],
#
#
#    SubtileCorner.INT_27_INT_CORNER_SHALLOW: [],
#    SubtileCorner.INT_27_INT_CORNER_STEEP: [],
    
    
    ### 90-to-27-degree.
    
    # FIXME: LEFT OFF HERE: ------------------
    
    ### 45-to-27-degree.
    
    # FIXME: LEFT OFF HERE: ------------------
}
