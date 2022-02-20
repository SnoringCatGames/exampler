tool
class_name SubtileManifest
extends Node


# TODO: Add support for:
# - !forces_convex_collision_shapes
# - Multiple autotiling 90/45/27-tile-collections.
# - One-way collisions
# - Configuring z-index


# FIXME: LEFT OFF HERE: --------------------------------
var ACCEPTABLE_MATCH_PRIORITY_THRESHOLD := 0.5

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
#     -   The tile-set author then needs to draw, and configure in GDScript,
#         many more subtile angle combinations.
#     -   Only exact matches will be used.
#     -   If an exact match isn't defined, then a single given fallback
#         error-indicator subtile will be used.
#     -   The level author can then see the error-indicator subtile and change
#         their level topography to instead use whichever subtiles are
#         available.
var allows_fallback_corner_matches: bool
var allows_non_fallback_corner_matches: bool

# -   If false, then custom corner-match autotiling behavior will not happen at
#     runtime, and will only happen when editing within the scene editor.
var supports_runtime_autotiling: bool

var corner_type_annotation_key_path: String

var tile_set_image_parser: TileSetImageParser
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
    self.allows_non_fallback_corner_matches = \
            manifest.allows_non_fallback_corner_matches
    self.supports_runtime_autotiling = manifest.supports_runtime_autotiling
    
    self.corner_type_annotation_key_path = \
            manifest.corner_type_annotation_key_path
    
    _parse_subtile_corner_key_values()
    
    if !supports_runtime_autotiling and \
            Engine.editor_hint:
        return
    
    if manifest.has("tile_set_image_parser_class"):
        self.tile_set_image_parser = manifest.tile_set_image_parser_class.new()
        assert(self.tile_set_image_parser is TileSetImageParser)
    else:
        self.tile_set_image_parser = TileSetImageParser.new()
    self.add_child(tile_set_image_parser)
    
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
    
    _parse_fallback_corner_types()
    
    for tile_set_config in tile_set_configs:
        initializer.initialize_tileset(tile_set_config)


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


func get_subtile_corner_string(type: int) -> String:
    return SUBTILE_CORNER_TYPE_VALUE_TO_KEY[type]


func _parse_fallback_corner_types() -> void:
    # Validate FallbackSubtileCorners.
    assert(SUBTILE_CORNER_TYPE_VALUE_TO_KEY.size() == \
            FallbackSubtileCorners.FALLBACKS.size())
    for corner_type in SUBTILE_CORNER_TYPE_VALUE_TO_KEY:
        assert(FallbackSubtileCorners.FALLBACKS.has(corner_type))
        assert(FallbackSubtileCorners.FALLBACKS[corner_type] is Array)
        for fallback in FallbackSubtileCorners.FALLBACKS[corner_type]:
            assert(fallback is Array)
            assert(fallback.size() == 3)
            assert(fallback[0] is int)
            assert(fallback[1] is float)
            assert(fallback[2] is bool)
            assert(fallback[1] > 0.0 and fallback[1] <= 1.0)
    
    # Validate SubtileCornerToDepth.
    assert(SUBTILE_CORNER_TYPE_VALUE_TO_KEY.size() == \
            SubtileCornerToDepth.CORNERS_TO_DEPTHS.size())
    for corner_type in SUBTILE_CORNER_TYPE_VALUE_TO_KEY:
        assert(SubtileCornerToDepth.CORNERS_TO_DEPTHS.has(corner_type))
        assert(SubtileCornerToDepth.CORNERS_TO_DEPTHS[corner_type] is int)
    
    # Validate SUBTILE_DEPTH_TO_UNMATCHED_CORNER_WEIGHT_MULTIPLIER.
    for weight_multipliers in \
            SUBTILE_DEPTH_TO_UNMATCHED_CORNER_WEIGHT_MULTIPLIER.values():
        for weight_multiplier in weight_multipliers.values():
            assert(weight_multiplier > 0.0 and weight_multiplier < 1.0)
    
    # Record reverse-mappings for FallbackSubtileCorners.
    for corner_type in FallbackSubtileCorners.FALLBACKS:
        for fallback in FallbackSubtileCorners.FALLBACKS[corner_type]:
            var fallback_corner_type: int = fallback[0]
            var is_reverse_mapping_present := false
            for fallback_fallback in \
                    FallbackSubtileCorners.FALLBACKS[fallback_corner_type]:
                if fallback_fallback[0] == corner_type:
                    is_reverse_mapping_present = true
            if !is_reverse_mapping_present:
                FallbackSubtileCorners.FALLBACKS[fallback_corner_type] \
                        .push_back([corner_type, fallback[1]])
    
    # FIXME: LEFT OFF HERE: -------------------
    # - Record transitive fallback mappings?
    # - Or should this only be traversed on demand?
