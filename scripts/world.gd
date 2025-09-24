extends Node2D

signal carve_requested(center: Vector2, radius: float)

const WORLD_WIDTH = 1500
const MIN_DEPTH = 200
const MAX_DEPTH = 650
const POINT_COUNT = 16
const BAKE_INTERVAL = 1
const EXTRA_FLOOR_SPACE = 625
const CHUNK_SIZE = 32

var floor_polygons: Dictionary = {}
var collision_poly_nodes: Dictionary = {}
var polygon2d_nodes: Dictionary = {}
var floor_bodies: Dictionary = {}

@export var game: Node2D
@export var player_scene: PackedScene
@export var camera: Camera2D

func _ready():
	randomize()
	generate_terrain()
	connect("carve_requested", _on_carve_requested)
	
	TurnManager.initialize(game, self, player_scene, camera)

func generate_terrain():
	# 1. Create terrain curve
	var curve = Curve2D.new()
	var prev_y: float = 0.0
	var jump_limit = 50.0

	for i in range(POINT_COUNT):
		var t = float(i) / float(POINT_COUNT - 1)
		var x = t * WORLD_WIDTH
		var target_y = MIN_DEPTH + randf() * (MAX_DEPTH - MIN_DEPTH)
		var y = lerp(float(prev_y), target_y, 0.5)

		# Höhenwerte auf ein Raster "snappen"
		var step = 8  # je größer, desto blockiger (z. B. 4 = fein, 16 = sehr grob)
		y = int(y / step) * step

		if abs(y - prev_y) > jump_limit:
			y = clamp(prev_y + sign(y - prev_y) * jump_limit, MIN_DEPTH, MAX_DEPTH)
		prev_y = y

		curve.add_point(Vector2(x, y), Vector2(-50, 0), Vector2(50, 0))

	curve.bake_interval = BAKE_INTERVAL
	var baked_points = curve.get_baked_points()

	# 2. Find the lowest point for floor extension
	var lowest_point_y = 0.0
	for p in baked_points:
		lowest_point_y = max(lowest_point_y, p.y)

	var floor_y = lowest_point_y + EXTRA_FLOOR_SPACE

	# 3. Create the full terrain polygon
	var terrain_polygon = PackedVector2Array()
	
	# Add all curve points
	for p in baked_points:
		terrain_polygon.append(p)
	
	# Add floor points to close the polygon
	terrain_polygon.append(Vector2(WORLD_WIDTH, floor_y))
	terrain_polygon.append(Vector2(0, floor_y))

	# 4. Create chunks as 64x64 squares
	var num_chunks_x = int(ceil(WORLD_WIDTH / CHUNK_SIZE))
	var num_chunks_y = int(ceil(floor_y / CHUNK_SIZE))

	for chunk_x in range(num_chunks_x):
		for chunk_y in range(num_chunks_y):
			var chunk_start_x = chunk_x * CHUNK_SIZE
			var chunk_start_y = chunk_y * CHUNK_SIZE
			var chunk_end_x = min(chunk_start_x + CHUNK_SIZE, WORLD_WIDTH)
			var chunk_end_y = min(chunk_start_y + CHUNK_SIZE, floor_y)
			
			var chunk_key = str(chunk_x) + "," + str(chunk_y)
			
			# Skip chunks above the terrain
			if chunk_start_y > floor_y:
				continue
			
			# Define chunk boundary
			var chunk_bound = PackedVector2Array([
				Vector2(chunk_start_x, chunk_start_y),
				Vector2(chunk_end_x, chunk_start_y),
				Vector2(chunk_end_x, chunk_end_y),
				Vector2(chunk_start_x, chunk_end_y)
			])
			
			# Clip the terrain with the chunk boundary to get the chunk's terrain
			var clipped = Geometry2D.intersect_polygons(terrain_polygon, chunk_bound)
			
			if clipped.size() > 0:
				# Convert to local coordinates
				var local_polygon = PackedVector2Array()
				for point in clipped[0]:
					local_polygon.append(point - Vector2(chunk_start_x, chunk_start_y))
				
				# Only create chunks with valid polygons
				if local_polygon.size() >= 3:
					# Store the chunk polygon
					floor_polygons[chunk_key] = local_polygon
					
					# Create static body
					var floor_body = StaticBody2D.new()
					floor_body.add_to_group("Terrain")
					floor_body.position = Vector2(chunk_start_x, chunk_start_y)
					add_child(floor_body)
					floor_bodies[chunk_key] = floor_body
					
					# Add collision polygon
					collision_poly_nodes[chunk_key] = CollisionPolygon2D.new()
					collision_poly_nodes[chunk_key].polygon = local_polygon
					floor_body.add_child(collision_poly_nodes[chunk_key])
					
					# Add visual polygon
					polygon2d_nodes[chunk_key] = Polygon2D.new()
					polygon2d_nodes[chunk_key].polygon = local_polygon
					polygon2d_nodes[chunk_key].color = Color(0.153, 0.573, 0.15, 1.0)
					floor_body.add_child(polygon2d_nodes[chunk_key])

func _on_carve_requested(center: Vector2, radius: float) -> void:
	# 1. Determine affected chunks
	var start_chunk_x = int(floor((center.x - radius) / CHUNK_SIZE))
	var end_chunk_x = int(ceil((center.x + radius) / CHUNK_SIZE))
	var start_chunk_y = int(floor((center.y - radius) / CHUNK_SIZE))
	var end_chunk_y = int(ceil((center.y + radius) / CHUNK_SIZE))
	
	# Ensure bounds
	start_chunk_x = max(0, start_chunk_x)
	start_chunk_y = max(0, start_chunk_y)
	
	# 2. Create the hole polygon in world coordinates
	var hole_polygon = create_circle_polygon(center, radius, 32)
	hole_polygon.reverse() # Reverse to ensure proper subtraction
	
	# 3. Iterate through affected chunks
	for chunk_x in range(start_chunk_x, end_chunk_x + 1):
		for chunk_y in range(start_chunk_y, end_chunk_y + 1):
			var chunk_key = str(chunk_x) + "," + str(chunk_y)
			
			if floor_polygons.has(chunk_key):
				# Get chunk local coordinates
				var chunk_position = floor_bodies[chunk_key].position
				
				# Transform the hole polygon to local coordinates
				var local_hole_polygon = PackedVector2Array()
				for point in hole_polygon:
					local_hole_polygon.append(point - chunk_position)
				
				# Get the chunk's polygon
				var chunk_polygon = floor_polygons[chunk_key]
				
				# Check if the hole might intersect the chunk
				var chunk_rect = Rect2(Vector2.ZERO, Vector2(CHUNK_SIZE, CHUNK_SIZE))
				var hole_center_local = center - chunk_position
				
				if chunk_rect.grow(radius).has_point(hole_center_local):
					# Try to clip the polygon
					var result = Geometry2D.clip_polygons(chunk_polygon, local_hole_polygon)
					
					if result.size() > 0:
						# Update the chunk polygon
						floor_polygons[chunk_key] = result[0]
						collision_poly_nodes[chunk_key].polygon = result[0]
						polygon2d_nodes[chunk_key].polygon = result[0]
					else:
						floor_bodies[chunk_key].queue_free()
						floor_bodies.erase(chunk_key)
						floor_polygons.erase(chunk_key)
						collision_poly_nodes.erase(chunk_key)
						polygon2d_nodes.erase(chunk_key)

func create_circle_polygon(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(segments):
		var angle = TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radius, sin(angle) * radius))
	return points
	
func find_player_spawnpoint(camera: Camera2D, player_index: int, player_count: int) -> Vector2:
	# Get camera information
	var camera_center = camera.global_position
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_width = viewport_size.x / camera.zoom.x
	var camera_height = viewport_size.y / camera.zoom.y
	
	# Calculate safe spawn area within camera view
	var spawn_min_x = camera_center.x - (camera_width / 2) + 100
	var spawn_max_x = camera_center.x + (camera_width / 2) - 100
	
	# Calculate position based on player index
	var x_position
	
	if player_count == 1:
		# Center single player
		x_position = camera_center.x
	elif player_count == 2:
		# Two players on opposite sides
		if player_index == 0:
			x_position = spawn_min_x + (camera_width * 0.25)  # 1/4 across
		else:
			x_position = spawn_min_x + (camera_width * 0.75)  # 3/4 across
	else:
		# Multiple players evenly distributed
		var segment_width = camera_width / (player_count + 1)
		x_position = spawn_min_x + segment_width * (player_index + 1)
	
	# Add slight randomness to prevent exact alignment
	x_position += randf_range(-20, 20)
	
	# Make sure we're within safe bounds
	x_position = clamp(x_position, spawn_min_x, spawn_max_x)
	
	# Use a different method to find safe spawn height
	# Cast a physics ray from well above the terrain to below it
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		Vector2(x_position, MIN_DEPTH - 200),  # Start well above terrain
		Vector2(x_position, MAX_DEPTH + 200)   # End well below terrain
	)
	query.collision_mask = 1  # Make sure this matches the terrain layer
	var result = space_state.intersect_ray(query)
	
	var spawn_y
	if result:
		# Found terrain, spawn safely above it
		spawn_y = result.position.y - 100  # 100 pixels above terrain
		print("Spawning player at ", x_position, ", ", spawn_y, " (terrain at ", result.position.y, ")")
	else:
		# Fallback method - use the curve points to estimate safe height
		var safe_y = find_safe_height_from_baked_points(x_position)
		spawn_y = safe_y
		print("Using fallback spawn height: ", spawn_y)
	
	return Vector2(x_position, spawn_y)

# Alternative method using baked points to determine a safe spawn height
func find_safe_height_from_baked_points(x_position: float) -> float:
	# Use a very conservative approach - find the highest point on the terrain
	# within a reasonable range of the requested x position
	
	# First gather all chunks that might be relevant
	var min_height = MIN_DEPTH  # Start with the minimum terrain depth
	var check_range = 100.0     # Check within this range of the target x
	
	var start_chunk_x = int(floor((x_position - check_range) / CHUNK_SIZE))
	var end_chunk_x = int(ceil((x_position + check_range) / CHUNK_SIZE))
	
	start_chunk_x = max(0, start_chunk_x)
	end_chunk_x = min(end_chunk_x, int(ceil(WORLD_WIDTH / CHUNK_SIZE)) - 1)
	
	# Find the minimum y value (highest point) in all relevant chunks
	for chunk_x in range(start_chunk_x, end_chunk_x + 1):
		for chunk_y in range(0, int(ceil(MAX_DEPTH / CHUNK_SIZE))):
			var chunk_key = str(chunk_x) + "," + str(chunk_y)
			
			if floor_polygons.has(chunk_key):
				var chunk_start_y = chunk_y * CHUNK_SIZE
				var poly = floor_polygons[chunk_key]
				
				# Find the minimum y value in this polygon
				for point in poly:
					var world_y = point.y + chunk_start_y
					min_height = min(min_height, world_y)
	
	# Return a height safely above the highest point
	return min_height - 100
