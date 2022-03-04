tool
class_name CornerConnectionWeightMultipliers
extends Reference
## -   This is needed for breaking ties when two quadrants have different
##     connections with equal weight.
## -   This depends on aspects of the tileset's art.
##     -   For example, floor art might extend far enough to impact the lower
##         neighbor art, but wall and ceiling art might not.
## -   If you know that your tileset has certain properties, like above, then
##     you might know that you can essentially ignore, or at least deprioritize,
##     some quadrant connections.
## -   Otherwise, you might need to change many quadrant connection annotations
##     from the original starting template, and also add many additional subtile
##     combinations to account for various adjacent corner-types.


const MULTIPLIERS := {
    SubtileCorner.EXT_90H: {
        top = 1.0,
        side = 0.5,
        bottom = 0.5,
    },
    SubtileCorner.EXT_45_H_SIDE: 0.9,
    # FIXME: LEFT OFF HERE: ----------------------- ...
}

static func get_multiplier(
        corner_type: int,
        side_label: String) -> float:
    if MULTIPLIERS.has(corner_type):
        if MULTIPLIERS[corner_type] is Dictionary:
            return MULTIPLIERS[corner_type][side_label]
        else:
            return MULTIPLIERS[corner_type]
    else:
        return 1.0
