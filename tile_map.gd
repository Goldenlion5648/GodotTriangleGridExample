extends TileMap

@export var triangle_size = 2
@export var should_highlight_adjacents = true

var old_clicked_triangle = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	queue_redraw()


func triangle_offsets(start: Vector2i, size=2):
	var start_x = start.x
	var start_y = start.y
	return [
		Vector2i(start_x + size, start_y),
		Vector2i(start_x + size, start_y + size),
		Vector2i(start_x, start_y + size),
		Vector2i(start_x - size, start_y),
		Vector2i(start_x - size, start_y - size),
		Vector2i(start_x, start_y - size),
	]
	
func get_wrapped_triangle_offsets(pos:Vector2i, triangle_size):
	var current_triangle_offsets = triangle_offsets(pos, triangle_size)
	current_triangle_offsets.append(current_triangle_offsets[0])
	return current_triangle_offsets

func is_triangle_in_bounds(points) -> bool:
	if points.any(func(point:Vector2i): return point.x > point.y):
		return false
	if not points.all(func(point:Vector2i): 
					return point.x >= 0 and point.y >= 0
	):
		return false
	return true
	
func shares_two_corners(original_triangle, other_triangle):
	var original_triangle_as_array = []
	for point in original_triangle:
		original_triangle_as_array.append(point)
	var shared = original_triangle_as_array.filter(func(point):
					return point in other_triangle
	)
	return shared.size() >= 2 
	

func _draw() -> void:
	var end_coord = 8
	var colors_to_alternate = [
		Color(0.2773, 0.5469, 0.7461),
		Color(0.4157, 0.1961, 0.7765)
	]
	var small_triangle_border_width = 7
	var whole_board_border_width = 20
	var color_pos = 0
	var current_clicked_triangle = null
	var all_points_used = []
	for y in range(0, end_coord, triangle_size):
		for x in range(0, end_coord, triangle_size):
			var current = Vector2i(x, y)
			var current_triangle_offsets = get_wrapped_triangle_offsets(current,triangle_size)
			for i in range(len(current_triangle_offsets) - 1):
				var point1 =current_triangle_offsets[i]
				var point2 =current_triangle_offsets[i + 1]
				var current_points = [current, point1, point2]
				color_pos = (color_pos + 1) % len(colors_to_alternate)
				if not is_triangle_in_bounds(current_points):
					continue
				current_points = current_points.map(map_to_local)
				all_points_used.append_array(current_points)
				var mouse_pos = to_local(get_global_mouse_position())
				var current_polygon = PackedVector2Array(current_points)
				
				var current_tile_color = colors_to_alternate[color_pos]
				
				if Input.is_action_pressed("tile_pressed"):
					if should_highlight_adjacents and old_clicked_triangle != null and\
								shares_two_corners(old_clicked_triangle, current_polygon):
						current_tile_color = Color.DIM_GRAY
					if Geometry2D.is_point_in_polygon(mouse_pos, current_polygon):
						current_tile_color = Color.BLACK
						current_clicked_triangle = current_polygon.duplicate()
					
				
				draw_colored_polygon(current_polygon, current_tile_color)
				draw_polyline(current_polygon + PackedVector2Array([current_polygon[0]]), 
								Color.BLACK, small_triangle_border_width)
	
	old_clicked_triangle = current_clicked_triangle
	var extremes = get_corners(all_points_used)
	draw_polyline(extremes, 
					Color.BLACK, whole_board_border_width)

func get_corners(all_points_used):
	all_points_used.sort_custom(func(a, b): return a.x < b.x)
	var extreme1 = all_points_used[0]
	var extreme2 = all_points_used[-1]
	all_points_used.sort_custom(func(a, b): return a.y < b.y)
	var extreme3 = all_points_used[-1]
	
	var extremes = PackedVector2Array([extreme1, extreme2,
	extreme3, extreme1])
	return extremes
	
	
