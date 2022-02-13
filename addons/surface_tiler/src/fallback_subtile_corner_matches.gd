class_name FallbackSubtileCornerMatches
extends Reference



# FIXME: LEFT OFF HERE: --------------- REMOVE: Old mapping.
#    SubtileCorner.EMPTY: [SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90H_TO_45_CONVEX_ACUTE, SubtileCorner.EXT_90V_TO_45_CONVEX_ACUTE],
#
#    SubtileCorner.EXT_90_90_CONVEX: [SubtileCorner.EMPTY],
#
#    SubtileCorner.EXT_CLIPPED_90_90: [-SubtileCorner.EXT_CLIPPED_45_45],
#
#    SubtileCorner.EXT_45_FLOOR_TO_90: [-SubtileCorner.EXT_45_FLOOR],
#    SubtileCorner.EXT_45_FLOOR_TO_45_CONVEX: [-SubtileCorner.EXT_45_FLOOR],
#    SubtileCorner.EXT_45_CEILING_TO_90: [-SubtileCorner.EXT_45_CEILING],
#    SubtileCorner.EXT_45_CEILING_TO_45_CONVEX: [-SubtileCorner.EXT_45_CEILING],
#
#
#    SubtileCorner.EXT_CLIPPED_27_SHALLOW: [-SubtileCorner.EXT_CLIPPED_45_45],
#    SubtileCorner.EXT_CLIPPED_27_STEEP: [-SubtileCorner.EXT_CLIPPED_45_45],
#    SubtileCorner.EXT_27_FLOOR_SHALLOW_CLOSE: [-SubtileCorner.EXT_90H],
#    SubtileCorner.EXT_27_FLOOR_STEEP_CLOSE: [-SubtileCorner.EXT_90V],
#
#
#    SubtileCorner.EXT_27_CEILING_SHALLOW_CLOSE: [-SubtileCorner.EXT_90H],
#    SubtileCorner.EXT_27_CEILING_STEEP_CLOSE: [-SubtileCorner.EXT_90V],
#
#
#    SubtileCorner.EXT_CLIPPED_90H_45: [-SubtileCorner.EXT_CLIPPED_45_45],
#    SubtileCorner.EXT_CLIPPED_90V_45: [-SubtileCorner.EXT_CLIPPED_45_45],
#    SubtileCorner.EXT_90H_TO_45_CONVEX: [-SubtileCorner.EXT_90H],
#    SubtileCorner.EXT_90V_TO_45_CONVEX: [-SubtileCorner.EXT_90V],
#    SubtileCorner.EXT_90H_TO_45_CONVEX_ACUTE: [SubtileCorner.EMPTY, SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90V_TO_45_CONVEX_ACUTE],
#    SubtileCorner.EXT_90V_TO_45_CONVEX_ACUTE: [SubtileCorner.EMPTY, SubtileCorner.EXT_90_90_CONVEX, SubtileCorner.EXT_90H_TO_45_CONVEX_ACUTE],






# NOTE:
# -   This mapping enables us to match one corner type with another.
# -   Defining a value as negative will configure it as a valid match, but with
#     a lower-priority than a positive value.
# -   This maps from an expected target corner type to what is actually
#     configured in the given tile-set.
# FIXME: LEFT OFF HERE: -----------------------------------------
# - Should this be configurable by the tileset author?
# - Would there be a simpler way to allow the tile-set author to configure which
#   slopes are allowed to transition into which others?
const FALLBACKS := {
    # FIXME: LEFT OFF HERE: ----------------------------------------
    # FIXME: LEFT OFF HERE: ----------------------------------------
    # FIXME: LEFT OFF HERE: ----------------------------------------
    # FIXME: LEFT OFF HERE: ----------------------------------------
    # FIXME: LEFT OFF HERE: ----------------------------------------
    # - Update fallback mappings.
    
    SubtileCorner.UNKNOWN: [],
    SubtileCorner.ERROR: [],
    SubtileCorner.EMPTY: [
        [SubtileCorner.EXT_90_90_CONVEX, 1.0],
        [SubtileCorner.EXT_90H_45_CONVEX_ACUTE, 1.0],
        [SubtileCorner.EXT_90V_45_CONVEX_ACUTE, 1.0],
    ],
    SubtileCorner.FULLY_INTERIOR: [],
    
    ### 90-degree.
    
    SubtileCorner.EXT_90H: [],
    SubtileCorner.EXT_90V: [],
    SubtileCorner.EXT_90_90_CONVEX: [],
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
    
    SubtileCorner.EXT_45_FLOOR: [],
    SubtileCorner.EXT_45_CEILING: [],
    SubtileCorner.EXT_EXT_45_CLIPPED: [],
    
    SubtileCorner.EXT_INT_45_FLOOR: [],
    SubtileCorner.EXT_INT_45_CEILING: [],
    SubtileCorner.EXT_INT_45_CLIPPED: [],
    
    SubtileCorner.INT_EXT_45_CLIPPED: [],
    
    SubtileCorner.INT_45_FLOOR: [],
    SubtileCorner.INT_45_CEILING: [],
    SubtileCorner.INT_INT_45_CLIPPED: [],
    
    ### 90-to-45-degree.
    
    SubtileCorner.EXT_90H_45_CONVEX_ACUTE: [],
    SubtileCorner.EXT_90V_45_CONVEX_ACUTE: [],
    
    SubtileCorner.EXT_90H_45_CONVEX: [],
    SubtileCorner.EXT_90V_45_CONVEX: [],
    
    SubtileCorner.EXT_90H_45_CONCAVE: [],
    SubtileCorner.EXT_90V_45_CONCAVE: [],
    
    SubtileCorner.EXT_INT_90H_45_CONVEX: [],
    SubtileCorner.EXT_INT_90V_45_CONVEX: [],
    
    SubtileCorner.EXT_INT_90H_45_CONCAVE: [],
    SubtileCorner.EXT_INT_90V_45_CONCAVE: [],
    
    SubtileCorner.INT_EXT_90H_45_CONCAVE: [],
    SubtileCorner.INT_EXT_90V_45_CONCAVE: [],
    
    SubtileCorner.INT_INT_90H_45_CONCAVE: [],
    SubtileCorner.INT_INT_90V_45_CONCAVE: [],
    
    ### Complex 90-45-degree combinations.
    
    SubtileCorner.EXT_INT_45_FLOOR_45_CEILING: [],
    
    SubtileCorner.INT_45_FLOOR_45_CEILING: [],
    
    SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE: [],
    SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE: [],
    
    SubtileCorner.INT_90H_EXT_INT_45_CONVEX_ACUTE: [],
    SubtileCorner.INT_90V_EXT_INT_45_CONVEX_ACUTE: [],
    
    SubtileCorner.INT_90H_EXT_INT_90H_45_CONCAVE: [],
    SubtileCorner.INT_90V_EXT_INT_90V_45_CONCAVE: [],
    
    
    SubtileCorner.INT_90H_INT_EXT_45_CLIPPED: [],
    SubtileCorner.INT_90V_INT_EXT_45_CLIPPED: [],
    SubtileCorner.INT_90_90_CONVEX_INT_EXT_45_CLIPPED: [],
    
    SubtileCorner.INT_INT_90H_45_CONCAVE_90V_45_CONCAVE: [],
    SubtileCorner.INT_INT_90H_45_CONCAVE_INT_45_CEILING: [],
    SubtileCorner.INT_INT_90V_45_CONCAVE_INT_45_FLOOR: [],
    
    SubtileCorner.INT_90H_INT_INT_90V_45_CONCAVE: [],
    SubtileCorner.INT_90V_INT_INT_90H_45_CONCAVE: [],
    
    SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR: [],
    SubtileCorner.INT_90_90_CONCAVE_INT_45_CEILING: [],
    SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR_45_CEILING: [],
    
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE: [],
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE: [],
    
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_90V_45_CONCAVE: [],
    
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_INT_45_CEILING: [],
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE_INT_45_FLOOR: [],
    
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
