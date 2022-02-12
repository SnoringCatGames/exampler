class_name SubtileManifest
extends Node


# TODO: Add support for:
# - !forces_convex_collision_shapes
# - Multiple autotiling 90/45/27-tile-collections.
# - One-way collisions
# - Configuring z-index


# NOTE:
# -   This mapping enables us to match one corner type with another.
# -   Defining a value as negative will configure it as a valid match, but with
#     a lower-priority than a positive value.
# -   This maps from an expected target corner type to what is actually
#     configured in the given tile-set.
# FIXME: LEFT OFF HERE: -----------------------------------------
# - Is there a simpler way to allow the tile-set author to configure which
#   slopes are allowed to transition into which others?
const _FALLBACK_CORNER_TYPE_MATCHES := {
    # FIXME: LEFT OFF HERE: ------------------
    # FIXME: LEFT OFF HERE: ------------------
    # FIXME: LEFT OFF HERE: ------------------
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
}

# FIXME: LEFT OFF HERE: --------------------------------
var ACCEPTABLE_MATCH_PRIORITY_THRESHOLD := 2.0

###

# Dictionary<int, String>
var SUBTILE_CORNER_TYPE_VALUE_TO_KEY: Dictionary

var autotile_name_prefix: String
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
var allows_partial_matches: bool

# -   If false, then custom corner-match autotiling behavior will not happen at
#     runtime, and will only happen when editing within the scene editor.
var supports_runtime_autotiling: bool

var corner_type_annotation_key_path: String

var tile_set_image_parser: TileSetImageParser
var subtile_target_corner_calculator: SubtileTargetCornerCalculator
var shape_calculator: CornerMatchTilesetShapeCalculator
var initializer: CornerMatchTilesetInitializer

# Dictionary<SubtileCorner, Dictionary<SubtileCorner, bool>>
var fallback_corner_type_matches := {}

# Dictionary<int, int>
var corner_types_to_swap_for_bottom_quadrants: Dictionary

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
    self.autotile_name_prefix = manifest.autotile_name_prefix
    self.forces_convex_collision_shapes = \
            manifest.forces_convex_collision_shapes
    self.allows_partial_matches = manifest.allows_partial_matches
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
    
    _parse_corner_types_to_swap_for_bottom_quadrants(manifest)
    
    _parse_fallback_corner_type_matches()
    
    for tile_set_config in tile_set_configs:
        initializer.initialize_tileset(tile_set_config)


func _parse_corner_types_to_swap_for_bottom_quadrants(
        manifest: Dictionary) -> void:
    self.corner_types_to_swap_for_bottom_quadrants = {}
    for corner_type_pair in manifest.corner_types_to_swap_for_bottom_quadrants:
        assert(corner_type_pair is Array and \
                corner_type_pair.size() == 2 and \
                corner_type_pair[0] is int and \
                corner_type_pair[1] is int)
        self.corner_types_to_swap_for_bottom_quadrants[corner_type_pair[0]] = \
                corner_type_pair[1]
        self.corner_types_to_swap_for_bottom_quadrants[corner_type_pair[1]] = \
                corner_type_pair[0]


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


func _parse_fallback_corner_type_matches() -> void:
    # If the additional matching type map is a const and has already been
    # parsed, then skip it.
    if fallback_corner_type_matches.empty():
        # Check that the corner-type enum values match the
        # corner-type-to-matching-types map.
        assert(Su.subtile_manifest.SUBTILE_CORNER_TYPE_VALUE_TO_KEY.size() == \
                _FALLBACK_CORNER_TYPE_MATCHES.size())
        for corner_type in Su.subtile_manifest.SUBTILE_CORNER_TYPE_VALUE_TO_KEY:
            assert(_FALLBACK_CORNER_TYPE_MATCHES.has(corner_type))
            assert(_FALLBACK_CORNER_TYPE_MATCHES[corner_type] is Array)
        
        # Convert additional-matching arrays into sets.
        for corner_type in _FALLBACK_CORNER_TYPE_MATCHES:
            var list: Array = _FALLBACK_CORNER_TYPE_MATCHES[corner_type]
            var set := {}
            for matching_type in list:
                set[matching_type] = true
            fallback_corner_type_matches[corner_type] = set
