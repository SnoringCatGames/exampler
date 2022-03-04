tool
class_name CornerMatchTileset
extends TileSet


# Dictionary<
#   CornerDirection,
#   Dictionary<
#     SubtileCorner, # Self-corner
#     (Vector2|Dictionary<
#       SubtileCorner, # H-internal-corner
#       (Vector2|Dictionary<
#         SubtileCorner, # V-internal-corner
#         (Vector2|Dictionary<
#           SubtileCorner, # H-external-corner
#           (Vector2|Dictionary<
#             SubtileCorner, # V-external-corner
#             (Vector2|Dictionary<
#               SubtileCorner, # Diagonal-internal-corner
#               (Vector2|Dictionary<
#                 SubtileCorner, # H2-external-corner
#                 (Vector2|Dictionary<
#                   SubtileCorner, # V2-external-corner
#                   (Vector2|Dictionary<
#                     SubtileCorner, # HD-external-corner
#                     (Vector2|Dictionary<
#                       SubtileCorner, # VD-external-corner
#                       Vector2        # Quadrant coordinates
#                 >)>)>)>)>)>)>)>)>)>>
var subtile_corner_types: Dictionary

var are_45_degree_subtiles_used: bool
var are_27_degree_subtiles_used: bool

var inner_tile_id: int
var inner_tile_name: String

var error_quadrants: Array
var empty_quadrants: Array
var clear_quadrants := [Vector2.INF, Vector2.INF, Vector2.INF, Vector2.INF]

# Dictionary<int, int>
var _tile_id_to_angle_type := {}
# Dictionary<int, int>
var _angle_type_to_tile_id := {}


func _is_tile_bound(
        drawn_id: int,
        neighbor_id: int) -> bool:
    return _tile_id_to_angle_type.has(drawn_id) and \
            _tile_id_to_angle_type.has(neighbor_id)


func tile_get_angle_type(tile_id: int) -> int:
    if tile_id == TileMap.INVALID_CELL:
        return CellAngleType.EMPTY
    elif _tile_id_to_angle_type.has(tile_id):
        return _tile_id_to_angle_type[tile_id]
    else:
        # Non-corner-match-tiles are treated as 90-degree surfaces.
        return CellAngleType.A90


func get_is_a_corner_match_subtile(tile_id: int) -> bool:
    return _tile_id_to_angle_type.has(tile_id)


func get_outer_cell_size() -> Vector2:
    return autotile_get_size(_angle_type_to_tile_id[CellAngleType.A90])


func get_inner_cell_size() -> Vector2:
    return autotile_get_size(inner_tile_id)
