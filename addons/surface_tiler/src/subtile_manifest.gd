tool
class_name SubtileManifest
extends Node


# TODO: Add support for:
# - !forces_convex_collision_shapes
# - Multiple autotiling 90/45/27-tile-collections.
# - One-way collisions
# - Configuring z-index


# FIXME: LEFT OFF HERE: --------------------------------
var ACCEPTABLE_MATCH_PRIORITY_THRESHOLD := 500.0

# NOTE: These values should be between 0 and 1, exclusive.
var SUBTILE_DEPTH_TO_UNMATCHED_CORNER_WEIGHT_MULTIPLIER := {
    # NOTE: We need UNKNOWNs to match with high weight, so that a mapping
    #       without inbound corners will rank higher than a mapping with the
    #       wrong inbound corners.
    SubtileDepth.UNKNOWN: {
        SubtileDepth.UNKNOWN: 0.9,
        SubtileDepth.EXTERIOR: 0.9,
        SubtileDepth.EXT_INT: 0.9,
        SubtileDepth.INT_EXT: 0.9,
        SubtileDepth.FULLY_INTERIOR: 0.9,
    },
    SubtileDepth.EXTERIOR: {
        SubtileDepth.UNKNOWN: 0.9,
        SubtileDepth.EXTERIOR: 0.8,
        SubtileDepth.EXT_INT: 0.5,
        SubtileDepth.INT_EXT: 0.2,
        SubtileDepth.FULLY_INTERIOR: 0.12,
    },
    SubtileDepth.EXT_INT: {
        SubtileDepth.UNKNOWN: 0.9,
        SubtileDepth.EXTERIOR: 0.5,
        SubtileDepth.EXT_INT: 0.7,
        SubtileDepth.INT_EXT: 0.3,
        SubtileDepth.FULLY_INTERIOR: 0.16,
    },
    SubtileDepth.INT_EXT: {
        SubtileDepth.UNKNOWN: 0.9,
        SubtileDepth.EXTERIOR: 0.2,
        SubtileDepth.EXT_INT: 0.3,
        SubtileDepth.INT_EXT: 0.4,
        SubtileDepth.FULLY_INTERIOR: 0.25,
    },
    SubtileDepth.FULLY_INTERIOR: {
        SubtileDepth.UNKNOWN: 0.9,
        SubtileDepth.EXTERIOR: 0.12,
        SubtileDepth.EXT_INT: 0.16,
        SubtileDepth.INT_EXT: 0.25,
        SubtileDepth.FULLY_INTERIOR: 0.3,
    },
}

###

# Dictionary<int, String>
var SUBTILE_CORNER_TYPE_VALUE_TO_KEY: Dictionary

var outer_autotile_name: String
var inner_autotile_name := "__INNER_TILE__"
var forces_convex_collision_shapes: bool

# -   If true, the autotiling logic will try to find the best match given which
#     subtiles are available.
#     -   The tile-set author can then omit many of the possible subtile angle
#         combinations.
#     -   This may impact performance if many tiles are updated frequently at
#         run time.
# -   If false, the autotiling logic will assume all possible subtile angle
#         combinations are defined.
#     -   The tile-set author then needs to draw many more subtile angle
#         combinations.
#     -   Only exact quadrant corner-type matches will be used.
#     -   If an exact match isn't defined, then the error-indicator quadrant
#         will be used.
#     -   The level author can then see the error-indicator and change their
#         level topography to instead use whichever subtiles are available.
var allows_fallback_corner_matches: bool

# -   If false, then custom corner-match autotiling behavior will not happen at
#     runtime, and will only happen when editing within the scene editor.
var supports_runtime_autotiling: bool

var corner_type_annotation_key_path: String

var implicit_quadrant_connection_color: Color

var tileset_annotations_parser: TilesetAnnotationsParser
var subtile_target_corner_calculator: SubtileTargetCornerCalculator
var shape_calculator: CornerMatchTilesetShapeCalculator
var initializer: CornerMatchTilesetInitializer

# Array<{
#   tile_set: CornerMatchTileset,
#   tile_set_quadrants_path: String,
#   tile_set_corner_type_annotations_path: String,
#   quadrant_size: int,
#   subtile_collision_margin: float,
#   are_45_degree_subtiles_used: bool,
#   are_27_degree_subtiles_used: bool,
# }>
var tile_set_configs: Array

###


func register_manifest(manifest: Dictionary) -> void:
    self.outer_autotile_name = manifest.outer_autotile_name
    if manifest.has("inner_autotile_name"):
        self.inner_autotile_name = manifest.inner_autotile_name
    self.forces_convex_collision_shapes = \
            manifest.forces_convex_collision_shapes
    self.allows_fallback_corner_matches = \
            manifest.allows_fallback_corner_matches
    self.supports_runtime_autotiling = manifest.supports_runtime_autotiling
    
    self.corner_type_annotation_key_path = \
            manifest.corner_type_annotation_key_path
    self.implicit_quadrant_connection_color = \
            manifest.implicit_quadrant_connection_color
    
    _parse_subtile_corner_key_values()
    
    if !supports_runtime_autotiling and \
            Engine.editor_hint:
        return
    
    if manifest.has("tileset_annotations_parser_class"):
        self.tileset_annotations_parser = manifest.tileset_annotations_parser_class.new()
        assert(self.tileset_annotations_parser is TilesetAnnotationsParser)
    else:
        self.tileset_annotations_parser = TilesetAnnotationsParser.new()
    self.add_child(tileset_annotations_parser)
    
    if manifest.has("subtile_target_corner_calculator_class"):
        self.subtile_target_corner_calculator = \
                manifest.subtile_target_corner_calculator_class.new()
        assert(self.subtile_target_corner_calculator is \
                SubtileTargetCornerCalculator)
    else:
        self.subtile_target_corner_calculator = \
                SubtileTargetCornerCalculator.new()
    self.add_child(subtile_target_corner_calculator)
    
    if manifest.has("shape_calculator_class"):
        self.shape_calculator = manifest.shape_calculator_class.new()
        assert(self.shape_calculator is CornerMatchTilesetShapeCalculator)
    else:
        self.shape_calculator = CornerMatchTilesetShapeCalculator.new()
    self.add_child(shape_calculator)
    
    if manifest.has("initializer_class"):
        self.initializer = manifest.initializer_class.new()
        assert(self.initializer is CornerMatchTilesetInitializer)
    else:
        self.initializer = CornerMatchTilesetInitializer.new()
    self.add_child(initializer)
    
    assert(manifest.tile_sets is Array)
    self.tile_set_configs = manifest.tile_sets
    for tile_set_config in manifest.tile_sets:
        assert(tile_set_config.tile_set is CornerMatchTileset)
        assert(tile_set_config.tile_set_quadrants_path is String)
        assert(tile_set_config.tile_set_corner_type_annotations_path is String)
        assert(tile_set_config.quadrant_size is int)
        assert(tile_set_config.subtile_collision_margin is float or \
                tile_set_config.subtile_collision_margin is int)
        assert(tile_set_config.are_45_degree_subtiles_used is bool)
        assert(tile_set_config.are_27_degree_subtiles_used is bool)
    
    _validate_subtile_corner_to_depth()
    _validate_subtile_depth_to_unmatched_corner_weight_multiplier()
    _parse_fallback_corner_types()
    
    for tile_set_config in tile_set_configs:
        initializer.initialize_tileset(tile_set_config)


func get_subtile_corner_string(type: int) -> String:
    return SUBTILE_CORNER_TYPE_VALUE_TO_KEY[type]


# This hacky function exists for a couple reasons:
# -   We need to be able to use the anonymous enum syntax for these
#     SubtileCorner values, so that tile-set authors don't need to include so
#     many extra characters for the enum prefix in their GDScript
#     configurations.
# -   We need to be able to print the key for a given enum value, so that a
#     human can debug what's going on.
# -   We need to be able to iterate over all possible enum values.
# -   GDScript's type system doesn't allow referencing the name of a class from
#     within that class.
func _parse_subtile_corner_key_values() -> void:
    if !Engine.editor_hint and \
            !supports_runtime_autotiling:
        return
    
    var constants := SubtileCorner.get_script_constant_map()
    for key in constants:
        SUBTILE_CORNER_TYPE_VALUE_TO_KEY[constants[key]] = key


func _validate_subtile_corner_to_depth() -> void:
    assert(SUBTILE_CORNER_TYPE_VALUE_TO_KEY.size() == \
            SubtileCornerToDepth.CORNERS_TO_DEPTHS.size())
    for corner_type in SUBTILE_CORNER_TYPE_VALUE_TO_KEY:
        assert(SubtileCornerToDepth.CORNERS_TO_DEPTHS.has(corner_type))
        assert(SubtileCornerToDepth.CORNERS_TO_DEPTHS[corner_type] is int)


func _validate_subtile_depth_to_unmatched_corner_weight_multiplier() -> void:
    for weight_multipliers in \
            SUBTILE_DEPTH_TO_UNMATCHED_CORNER_WEIGHT_MULTIPLIER.values():
        for weight_multiplier in weight_multipliers.values():
            assert(weight_multiplier > 0.0 and weight_multiplier < 1.0)


func _parse_fallback_corner_types() -> void:
    _validate_fallback_subtile_corners()
    _populate_abridged_fallback_multipliers()
    _record_reverse_fallbacks()
    _record_transitive_fallbacks()
    _validate_connection_weight_multipliers()
    _populate_connection_weight_multipliers_with_fallbacks()
#    _print_fallbacks()


func _validate_connection_weight_multipliers() -> void:
    for value in CornerConnectionWeightMultipliers.MULTIPLIERS.values():
        assert(value is float or value is Dictionary)
        if value is Dictionary:
            assert(value.has("top") and value.top is float)
            assert(value.has("bottom") and value.bottom is float)
            assert(value.has("side") and value.side is float)


func _populate_connection_weight_multipliers_with_fallbacks() -> void:
    for corner_type in FallbackSubtileCorners.FALLBACKS:
        if CornerConnectionWeightMultipliers.MULTIPLIERS.has(corner_type):
            # Don't modify preexisting multipliers.
            continue
        
        var max_bottom := -INF
        var max_top := -INF
        var max_sides := -INF
        
        for fallback_type in FallbackSubtileCorners.FALLBACKS[corner_type]:
            if CornerConnectionWeightMultipliers.MULTIPLIERS.has(corner_type):
                var value = CornerConnectionWeightMultipliers \
                        .MULTIPLIERS[corner_type]
                if value is Dictionary:
                    max_top = max(max_top, value.top)
                    max_bottom = max(max_bottom, value.bottom)
                    max_sides = max(max_sides, value.side)
                else:
                    max_top = max(max_top, value)
                    max_bottom = max(max_bottom, value)
                    max_sides = max(max_sides, value)
        
        if max_top > 0 and max_bottom > 0 and max_sides > 0:
            if max_top == max_bottom and max_top == max_sides:
                CornerConnectionWeightMultipliers.MULTIPLIERS[corner_type] = \
                        max_top
            else:
                CornerConnectionWeightMultipliers.MULTIPLIERS[corner_type] = {
                    top = max_top,
                    bottom = max_bottom,
                    sides = max_sides,
                }


func _validate_fallback_subtile_corners() -> void:
    # Validate FallbackSubtileCorners.
    assert(SUBTILE_CORNER_TYPE_VALUE_TO_KEY.size() == \
            FallbackSubtileCorners.FALLBACKS.size())
    for corner_type in SUBTILE_CORNER_TYPE_VALUE_TO_KEY:
        assert(FallbackSubtileCorners.FALLBACKS.has(corner_type))
        assert(FallbackSubtileCorners.FALLBACKS[corner_type] is Dictionary)
        for fallback_type in FallbackSubtileCorners.FALLBACKS[corner_type]:
            var fallback_multipliers: Array = \
                    FallbackSubtileCorners.FALLBACKS[corner_type][fallback_type]
            assert(fallback_multipliers is Array)
            assert(fallback_multipliers.size() == 2 or \
                    fallback_multipliers.size() == 4)
            for multiplier in fallback_multipliers:
                assert(multiplier is float)
                assert(multiplier >= 0.0 and multiplier <= 1.0)


func _populate_abridged_fallback_multipliers() -> void:
    for corner_type in FallbackSubtileCorners.FALLBACKS:
        for fallback_type in FallbackSubtileCorners.FALLBACKS[corner_type]:
            var fallback_multipliers: Array = \
                    FallbackSubtileCorners.FALLBACKS[corner_type][fallback_type]
            if fallback_multipliers.size() == 2:
                fallback_multipliers.resize(4)
                fallback_multipliers[2] = fallback_multipliers[1]
                fallback_multipliers[3] = fallback_multipliers[0]


func _record_reverse_fallbacks() -> void:
    for corner_type in FallbackSubtileCorners.FALLBACKS:
        var forward_map: Dictionary = \
                FallbackSubtileCorners.FALLBACKS[corner_type]
        for fallback_type in forward_map:
            var reverse_map: Dictionary = \
                    FallbackSubtileCorners.FALLBACKS[fallback_type]
            if !reverse_map.has(corner_type):
                reverse_map[corner_type] = forward_map[fallback_type]
            var forward_multipliers: Array = forward_map[fallback_type]
            var reverse_multipliers: Array = reverse_map[corner_type]
            for i in 4:
                assert(forward_multipliers[i] == reverse_multipliers[i],
                        ("FallbackSubtileCorners: Two corner-types are " +
                        "mapped to each other with different multipliers: " +
                        "forward_type=%s, " +
                        "reverse_type=%s, " +
                        "index=%s, " +
                        "forward_multiplier=%s, " +
                        "reverse_multiplier=%s") % [
                            get_subtile_corner_string(corner_type),
                            get_subtile_corner_string(fallback_type),
                            i,
                            forward_multipliers[i],
                            reverse_multipliers[i],
                        ])


func _record_transitive_fallbacks() -> void:
    var exclusion_set := {}
    for corner_type in FallbackSubtileCorners.FALLBACKS:
        exclusion_set[corner_type] = true
        for fallback_type in FallbackSubtileCorners.FALLBACKS[corner_type]:
            var multipliers: Array = \
                    FallbackSubtileCorners.FALLBACKS[corner_type][fallback_type]
            _record_transitive_fallbacks_recursively(
                    fallback_type,
                    corner_type,
                    multipliers[0],
                    multipliers[1],
                    multipliers[2],
                    multipliers[3],
                    exclusion_set)
        exclusion_set[corner_type] = false


func _record_transitive_fallbacks_recursively(
        corner_type: int,
        transitive_basis_type: int,
        h_internal_multiplier: float,
        v_internal_multiplier: float,
        h_external_multiplier: float,
        v_external_multiplier: float,
        exclusion_set: Dictionary) -> void:
    var transitive_basis_map: Dictionary = \
            FallbackSubtileCorners.FALLBACKS[transitive_basis_type]
    var current_map: Dictionary = FallbackSubtileCorners.FALLBACKS[corner_type]
    
    # Create a new transitive mapping, if it didn't exist already.
    if !transitive_basis_map.has(corner_type):
        transitive_basis_map[corner_type] = [
            h_internal_multiplier,
            v_internal_multiplier,
            h_external_multiplier,
            v_external_multiplier,
        ]
    else:
        # Update the multipliers for the transitive mapping to be the max of the
        # previously-recorded and current-transitive values.
        var multipliers: Array = transitive_basis_map[corner_type]
        h_internal_multiplier = max(multipliers[0], h_internal_multiplier)
        v_internal_multiplier = max(multipliers[1], v_internal_multiplier)
        h_external_multiplier = max(multipliers[2], h_external_multiplier)
        v_external_multiplier = max(multipliers[3], v_external_multiplier)
        multipliers[0] = h_internal_multiplier
        multipliers[1] = v_internal_multiplier
        multipliers[2] = h_external_multiplier
        multipliers[3] = v_external_multiplier
    
    assert(!exclusion_set.has(corner_type) or !exclusion_set[corner_type])
    
    exclusion_set[corner_type] = true
    
    for fallback_type in current_map:
        if exclusion_set.has(fallback_type) and \
                exclusion_set[fallback_type]:
            # We're already considering this type in the current transitive
            # chain.
            continue
        
        # Calculate the transitive multipliers.
        var fallback_multipliers: Array = current_map[fallback_type]
        var transitive_h_internal_multiplier := min(
                h_internal_multiplier,
                fallback_multipliers[0])
        var transitive_v_internal_multiplier := min(
                v_internal_multiplier,
                fallback_multipliers[1])
        var transitive_h_external_multiplier := min(
                h_external_multiplier,
                fallback_multipliers[2])
        var transitive_v_external_multiplier := min(
                v_external_multiplier,
                fallback_multipliers[3])
        
        if transitive_h_internal_multiplier <= 0.0 and \
                transitive_v_internal_multiplier <= 0.0 and \
                transitive_h_external_multiplier <= 0.0 and \
                transitive_v_external_multiplier <= 0.0:
            # There is no transitive fallback weight to propagate.
            continue
        
        if transitive_basis_map.has(fallback_type):
            var preexisting_multipliers: Array = \
                    transitive_basis_map[fallback_type]
            if preexisting_multipliers[0] >= \
                        transitive_h_internal_multiplier and \
                    preexisting_multipliers[1] >= \
                        transitive_v_internal_multiplier and \
                    preexisting_multipliers[2] >= \
                        transitive_h_external_multiplier and \
                    preexisting_multipliers[3] >= \
                        transitive_v_external_multiplier:
                # This transitive fallback is already mapped with at least the
                # same weights.
                continue
        
        _record_transitive_fallbacks_recursively(
                fallback_type,
                transitive_basis_type,
                transitive_h_internal_multiplier,
                transitive_v_internal_multiplier,
                transitive_h_external_multiplier,
                transitive_v_external_multiplier,
                exclusion_set)
    
    exclusion_set[corner_type] = false


func _print_fallbacks() -> void:
    print("")
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    print(">>> FALLBACKS                >>>")
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    for corner_type in Sc.utils.cascade_sort(
            FallbackSubtileCorners.FALLBACKS.keys()):
        print("%s:" % get_subtile_corner_string(corner_type))
        for fallback_type in Sc.utils.cascade_sort(
                FallbackSubtileCorners.FALLBACKS[corner_type].keys()):
            var multipliers: Array = \
                    FallbackSubtileCorners.FALLBACKS[corner_type][fallback_type]
            print("    %s [h_opp=%s, v_opp=%s, h_inbound=%s, v_inbound=%s]" % [
                Sc.utils.pad_string(
                        get_subtile_corner_string(fallback_type) + ":",
                        56,
                        true,
                        true),
                str(multipliers[0]),
                str(multipliers[1]),
                str(multipliers[2]),
                str(multipliers[3]),
            ])
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    print("")
