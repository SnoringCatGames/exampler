class_name SubtileCornerToDepth
extends Reference


const CORNERS_TO_DEPTHS := {
    SubtileCorner.UNKNOWN: SubtileDepth.UNKNOWN,
    
    SubtileCorner.ERROR: SubtileDepth.UNKNOWN,
    SubtileCorner.EMPTY: SubtileDepth.UNKNOWN,
    SubtileCorner.FULLY_INTERIOR: SubtileDepth.UNKNOWN,
    
    ### 90-degree.
    
    SubtileCorner.EXT_90H: SubtileDepth.EXTERIOR,
    SubtileCorner.EXT_90V: SubtileDepth.EXTERIOR,
    SubtileCorner.EXT_90_90_CONVEX: SubtileDepth.EXTERIOR,
    SubtileCorner.EXT_90_90_CONCAVE: SubtileDepth.EXTERIOR,
    
    SubtileCorner.EXT_INT_90H: SubtileDepth.MID,
    SubtileCorner.EXT_INT_90V: SubtileDepth.MID,
    SubtileCorner.EXT_INT_90_90_CONVEX: SubtileDepth.MID,
    SubtileCorner.EXT_INT_90_90_CONCAVE: SubtileDepth.MID,
    
    SubtileCorner.INT_90H: SubtileDepth.INTERIOR,
    SubtileCorner.INT_90V: SubtileDepth.INTERIOR,
    SubtileCorner.INT_90_90_CONVEX: SubtileDepth.INTERIOR,
    SubtileCorner.INT_90_90_CONCAVE: SubtileDepth.INTERIOR,
    
    ### 45-degree.
    
    SubtileCorner.EXT_45_FLOOR: SubtileDepth.EXTERIOR,
    SubtileCorner.EXT_45_CEILING: SubtileDepth.EXTERIOR,
    SubtileCorner.EXT_EXT_45_CLIPPED: SubtileDepth.EXTERIOR,
    
    SubtileCorner.EXT_INT_45_FLOOR: SubtileDepth.MID,
    SubtileCorner.EXT_INT_45_CEILING: SubtileDepth.MID,
    SubtileCorner.EXT_INT_45_CLIPPED: SubtileDepth.MID,
    
    SubtileCorner.INT_EXT_45_CLIPPED: SubtileDepth.MID,
    
    SubtileCorner.INT_45_FLOOR: SubtileDepth.INTERIOR,
    SubtileCorner.INT_45_CEILING: SubtileDepth.INTERIOR,
    SubtileCorner.INT_INT_45_CLIPPED: SubtileDepth.INTERIOR,
    
    ### 90-to-45-degree.
    
    SubtileCorner.EXT_90H_45_CONVEX_ACUTE: SubtileDepth.EXTERIOR,
    SubtileCorner.EXT_90V_45_CONVEX_ACUTE: SubtileDepth.EXTERIOR,
    
    SubtileCorner.EXT_90H_45_CONVEX: SubtileDepth.EXTERIOR,
    SubtileCorner.EXT_90V_45_CONVEX: SubtileDepth.EXTERIOR,
    
    SubtileCorner.EXT_90H_45_CONCAVE: SubtileDepth.EXTERIOR,
    SubtileCorner.EXT_90V_45_CONCAVE: SubtileDepth.EXTERIOR,
    
    SubtileCorner.EXT_INT_90H_45_CONVEX: SubtileDepth.MID,
    SubtileCorner.EXT_INT_90V_45_CONVEX: SubtileDepth.MID,
    
    SubtileCorner.EXT_INT_90H_45_CONCAVE: SubtileDepth.MID,
    SubtileCorner.EXT_INT_90V_45_CONCAVE: SubtileDepth.MID,
    
    SubtileCorner.INT_EXT_90H_45_CONCAVE: SubtileDepth.INTERIOR,
    SubtileCorner.INT_EXT_90V_45_CONCAVE: SubtileDepth.INTERIOR,
    
    SubtileCorner.INT_INT_90H_45_CONCAVE: SubtileDepth.INTERIOR,
    SubtileCorner.INT_INT_90V_45_CONCAVE: SubtileDepth.INTERIOR,
    
    ### Complex 90-45-degree combinations.
    
    SubtileCorner.EXT_INT_45_FLOOR_45_CEILING: SubtileDepth.MID,
    
    SubtileCorner.INT_45_FLOOR_45_CEILING: SubtileDepth.INTERIOR,
    
    SubtileCorner.EXT_INT_90H_45_CONVEX_ACUTE: SubtileDepth.MID,
    SubtileCorner.EXT_INT_90V_45_CONVEX_ACUTE: SubtileDepth.MID,
    
    SubtileCorner.INT_90H_EXT_INT_45_CONVEX_ACUTE: SubtileDepth.MID,
    SubtileCorner.INT_90V_EXT_INT_45_CONVEX_ACUTE: SubtileDepth.MID,
    
    SubtileCorner.INT_90H_EXT_INT_90H_45_CONCAVE: SubtileDepth.MID,
    SubtileCorner.INT_90V_EXT_INT_90V_45_CONCAVE: SubtileDepth.MID,
    
    
    SubtileCorner.INT_90H_INT_EXT_45_CLIPPED: SubtileDepth.MID,
    SubtileCorner.INT_90V_INT_EXT_45_CLIPPED: SubtileDepth.MID,
    SubtileCorner.INT_90_90_CONVEX_INT_EXT_45_CLIPPED: SubtileDepth.MID,
    
    SubtileCorner.INT_INT_90H_45_CONCAVE_90V_45_CONCAVE: SubtileDepth.INTERIOR,
    SubtileCorner.INT_INT_90H_45_CONCAVE_INT_45_CEILING: SubtileDepth.INTERIOR,
    SubtileCorner.INT_INT_90V_45_CONCAVE_INT_45_FLOOR: SubtileDepth.INTERIOR,
    
    SubtileCorner.INT_90H_INT_INT_90V_45_CONCAVE: SubtileDepth.MID,
    SubtileCorner.INT_90V_INT_INT_90H_45_CONCAVE: SubtileDepth.MID,
    
    SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR: SubtileDepth.MID,
    SubtileCorner.INT_90_90_CONCAVE_INT_45_CEILING: SubtileDepth.MID,
    SubtileCorner.INT_90_90_CONCAVE_INT_45_FLOOR_45_CEILING: SubtileDepth.MID,
    
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE: SubtileDepth.MID,
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE: SubtileDepth.MID,
    
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_90V_45_CONCAVE: SubtileDepth.MID,
    
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90H_45_CONCAVE_INT_45_CEILING: SubtileDepth.MID,
    SubtileCorner.INT_90_90_CONCAVE_INT_INT_90V_45_CONCAVE_INT_45_FLOOR: SubtileDepth.MID,
    
    ### 27-degree.
    
    # FIXME: LEFT OFF HERE: ------------------
    
#    SubtileCorner.EXT_27_SHALLOW_CLIPPED: SubtileDepth.,
#    SubtileCorner.EXT_27_STEEP_CLIPPED: SubtileDepth.,
#
#    SubtileCorner.EXT_27_FLOOR_SHALLOW_CLOSE: SubtileDepth.,
#    SubtileCorner.EXT_27_FLOOR_SHALLOW_FAR: SubtileDepth.,
#    SubtileCorner.EXT_27_FLOOR_STEEP_CLOSE: SubtileDepth.,
#    SubtileCorner.EXT_27_FLOOR_STEEP_FAR: SubtileDepth.,
#
#    SubtileCorner.EXT_27_CEILING_SHALLOW_CLOSE: SubtileDepth.,
#    SubtileCorner.EXT_27_CEILING_SHALLOW_FAR: SubtileDepth.,
#    SubtileCorner.EXT_27_CEILING_STEEP_CLOSE: SubtileDepth.,
#    SubtileCorner.EXT_27_CEILING_STEEP_FAR: SubtileDepth.,
#
#
#    SubtileCorner.INT_27_INT_CORNER_SHALLOW: SubtileDepth.,
#    SubtileCorner.INT_27_INT_CORNER_STEEP: SubtileDepth.,
    
    
    ### 90-to-27-degree.
    
    # FIXME: LEFT OFF HERE: ------------------
    
    ### 45-to-27-degree.
    
    # FIXME: LEFT OFF HERE: ------------------
}
