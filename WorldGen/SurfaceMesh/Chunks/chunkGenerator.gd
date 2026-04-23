@tool
class_name SurfaceChunk
extends Node3D


#@export var _chunk_size: Dictionary = {"height": 512, "width": 512, "upwards": 512}
#@export var noisemap: NoiseTexture2D
#@export var texture: Texture2D
#
#@export_tool_button("Generate Mesh", "Callable") var generate_tool_button = generateChunk


var chunk_mesh: MeshInstance3D
var _chunk_noisemap: NoiseTexture2D
var _chunk_material: StandardMaterial3D
var _chunk_size: Dictionary
var _chunk_skylimit: int
var _camera_pos: Vector3
var _chunk_position: Vector3
var _chunk_created: bool = false

## The amount to divide _chunk_size with. This is to control LOD levels. 
var _chunk_LOD_Level: float
var chunk_LOD_width: float
var chunk_LOD_height: float



var LOD_level: float = LOD_setting4_distance:
	get:
		return LOD_level
	set(value): 
		LOD_level = value
		if _chunk_created:
			_generate()
		
@export_subgroup("LOD setting 1")
@export var LOD_setting1_distance:  float = 20
## Percantage reduction
@export var LOD_setting1_reduction: float = 1

@export_subgroup("LOD setting 2")
@export var LOD_setting2_distance:  float = 50
## Percantage reduction
@export var LOD_setting2_reduction: float = 0.5

@export_subgroup("LOD setting 3")
@export var LOD_setting3_distance:  float = 100
## Percantage reduction
@export var LOD_setting3_reduction: float = 0.25

@export_subgroup("LOD setting 4")
@export var LOD_setting4_distance:  float = 200
## Percantage reduction
@export var LOD_setting4_reduction: float = 0.1


@export_group("Debug variables")
@export var distance_to_camera: float
@export var enable_LOD: bool = true

@export_subgroup("Performance (milliseconds)")
@export var _perf_timer_generate: = 0
@export var _perf_timer_verts: = 0
@export var _perf_timer_uvs: = 0
@export var _perf_timer_normals: = 0
@export var _perf_timer_edges: = 0



func get_noise_height(cords: Vector2i):
	var data: float = _chunk_noisemap.noise.get_noise_2dv(cords) * _chunk_skylimit
	
	# This is for debugging. Creates a flat map
	#var data: float = 0.0
	
	return data
	

func gen_verts() -> PackedVector3Array:

	# verts = PackedVector3Array([
	# Vector3(0, 0, 0), #0
	# Vector3(0, 0, 1), #1
	# Vector3(1, 0, 0), #2
	# Vector3(1, 0, 1), #3
	# Vector3(2, 0, 0), #4
	# Vector3(2, 0, 1), #5
	# ])

	var verts = PackedVector3Array()
	
	#var chunk_LOD_width  = _chunk_size.width  * _chunk_LOD_Level
	#var chunk_LOD_height = round(_chunk_size.height * _chunk_LOD_Level)
	
	var chunk_width_min  = 0
	var chunk_width_max  = _chunk_size.width
	
	var chunk_height_min  = 0
	var chunk_height_max  = _chunk_size.height

	
	for height in chunk_LOD_height:
		var height_step: float = float(height) / float(chunk_LOD_height - 1)
		var next_pos_height = chunk_height_min + height_step * (chunk_height_max - chunk_height_min)
		for width in chunk_LOD_width:
			var width_step: float = float(width) / float(chunk_LOD_width - 1)
			var next_pos_width = chunk_width_min + width_step * (chunk_width_max - chunk_width_min)
			verts.append(Vector3(next_pos_width, get_noise_height(Vector2i(next_pos_width, next_pos_height)), next_pos_height))
		pass
	pass

	#debug1 = debug1 + 1
	#if verts.is_empty():
		#pass
	return verts

func gen_uvs(verts) -> PackedVector2Array:
	# return PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1), ])

	var uvs = PackedVector2Array()

	# Finn bounds
	var min_v = verts[0]
	var max_v = verts[0]

	for v in verts:
		min_v = min_v.min(v)
		max_v = max_v.max(v)

	var size = max_v - min_v

	for v in verts:
		var uv = Vector2(
			(v.x - min_v.x) / size.x if size.x != 0 else 0.0,
			(v.z - min_v.z) / size.z if size.z != 0 else 0.0
		)
		uvs.append(uv)

	return uvs

func gen_normals(uvs: PackedVector2Array) -> PackedVector3Array:
	var normals: PackedVector3Array
	for i in uvs.size():
		normals.append(Vector3.UP)
	return normals

func gen_edges() -> PackedInt32Array:
	# indices = PackedInt32Array([
	# 	0, 2, 1,
	# 	2, 3, 1,
	# 	2, 4, 3,
	# 	4, 5, 3,
	# ])

	var edges = PackedInt32Array()

	# This generates triangles
	for curr_height in range(chunk_LOD_height - 1): # X = Vertical, is Z in Vector
		for curr_width in range(chunk_LOD_width - 1): # Y = Horizontal, is Z in Vector
			var curr_triangle = curr_height * chunk_LOD_width + curr_width
			var edge1 = curr_triangle
			var edge2 = curr_triangle + 1
			var edge3 = curr_triangle + chunk_LOD_width
			
			var edge4 = edge2
			var edge5 = edge4 + chunk_LOD_width
			var edge6 = edge3
			
			curr_triangle +=1
			if curr_width == chunk_LOD_width -1:
				continue
			
			
			if false: #enable for debug text about edging. 
				print_debug("Current Tirangle: %s" % curr_triangle)
				print_debug("_chunk_size.width: %s" % _chunk_size.width)
				print_debug("Height: %s" % curr_height)
				print_debug("Width: %s" % curr_width)
				print_debug("###")
				print_debug("Edge1:  %s" % edge1)
				print_debug("Edge2:  %s" % edge2)
				print_debug("Edge3:  %s" % edge3)
				print_debug("###")
				print_debug("Edge4:  %s" % edge4)
				print_debug("Edge5:  %s" % edge5)
				print_debug("Edge6:  %s" % edge6)
				print_debug()
			
			#######################################
			#  First edge
			#  ⬇️
			#  ____
			#  |  /
			#  | / ⬅️ Second Edge
			#  |/
			#  ⬆️ Thirt Edge
			#######################################
			# First triangle
			edges.append(edge1)
			edges.append(edge2)
			edges.append(edge3)
			
			# Second triangle
			edges.append(edge4)
			edges.append(edge5)
			edges.append(edge6)
			
			#######################################
			#  Third edge
			#  ⬇
			#    /|
			#   / |⬅️ First Edge
			#  /__|
			#  ⬆️ Second Edge
			#######################################
			
		pass
	return edges


func gen_collision():
	var curr_coll = CollisionShape3D.new()
	curr_coll.shape = chunk_mesh.mesh.create_trimesh_shape()
	
	var curr_staticBody = StaticBody3D.new()
	curr_staticBody.add_child(curr_coll)
	
	await call_deferred("add_child", curr_staticBody)
	pass


func _calculate_LOD(chunk_position: Vector3):
	if !enable_LOD:
		return 1.0
	return LOD_setting4_reduction
	#var curr_cam = get_viewport().get_camera_3d().position
	var curr_dist: float = chunk_position.distance_to(_camera_pos)
	distance_to_camera = curr_dist
	
	if curr_dist   >= LOD_setting4_distance:
		LOD_level = LOD_setting4_reduction	
		
	elif curr_dist   >= LOD_setting3_distance:
		LOD_level = LOD_setting3_reduction
	
	elif curr_dist >= LOD_setting2_distance:
		LOD_level = LOD_setting2_reduction
	
	elif curr_dist >= LOD_setting1_distance:
		LOD_level = LOD_setting1_reduction
	
	else: 
		LOD_level = 1 # Full quality
		pass
	
	if LOD_level == 0:
		# Only for Debugging. 
		pass
		
	return LOD_level

var debug1 = 0

func generateChunk(Noisemap: NoiseTexture2D, chunk_material: StandardMaterial3D, skylimit: int, chunk_size: Dictionary, camera_pos: Vector3, chunk_position: Vector3):
	
	_chunk_noisemap = Noisemap
	_chunk_material = chunk_material
	_chunk_size     = chunk_size
	_chunk_skylimit = skylimit		
	_chunk_position = chunk_position
	_camera_pos = camera_pos
	_chunk_LOD_Level = _calculate_LOD(_chunk_position)
	
	_generate()
	_chunk_created = true
	
func _generate():	
	var _perfTimer_generate_start = Time.get_ticks_msec()
	# Calculate new chunk size with applied LOD
	chunk_LOD_width  = round(_chunk_size.width  * _chunk_LOD_Level)
	chunk_LOD_height = round(_chunk_size.height * _chunk_LOD_Level)
	
	if chunk_LOD_width <= 2:
		chunk_LOD_width = 2
	if chunk_LOD_height <= 2:
		chunk_LOD_height = 2
	
	
	#print(_chunk_size)
	chunk_mesh = MeshInstance3D.new()
	# Generate surface Mesh
	chunk_mesh.mesh = ArrayMesh.new()

	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var _perfTimer_verts_start = Time.get_ticks_msec()
	var verts: PackedVector3Array = gen_verts()
	_perf_timer_verts = Time.get_ticks_msec() - _perfTimer_verts_start

	
	var _perfTimer_uvs_start = Time.get_ticks_msec()	
	var uvs: PackedVector2Array = gen_uvs(verts)
	_perf_timer_uvs = Time.get_ticks_msec() - _perfTimer_uvs_start
	
	
	var _perfTimer_normals_start = Time.get_ticks_msec()
	var normals: PackedVector3Array = gen_normals(uvs)
	_perf_timer_normals = Time.get_ticks_msec() - _perfTimer_normals_start
	
	
	var _perfTimer_edges_start = Time.get_ticks_msec()
	var edges: PackedInt32Array = gen_edges()
	_perf_timer_edges = Time.get_ticks_msec() - _perfTimer_edges_start
	
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = edges
	
	if edges.is_empty():
		pass
	
	chunk_mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	chunk_mesh.set_surface_override_material(0, _chunk_material)
	
	gen_collision()
	
	await call_deferred("add_child",(chunk_mesh))
	
	## Create a VisibleOnScreenNotifier3D, to check if the object is in the scene.
	var visibilityNotifier = VisibleOnScreenEnabler3D.new()
	visibilityNotifier.aabb = AABB(Vector3(0,0,0), Vector3(_chunk_size.height * 1.5 ,0, _chunk_size.width * 1.5))
	visibilityNotifier.screen_exited.connect(_invisible)
	visibilityNotifier.screen_entered.connect(_visible)
	
	await call_deferred("add_child",visibilityNotifier)
	_perf_timer_generate = Time.get_ticks_msec() - _perfTimer_generate_start
	pass # Replace with function body.



func _visible():
	#print("Visible! %s" % name)
	chunk_mesh.visible = true
	pass
	
func _invisible():
	#print("Not Visible! %s" % name)
	chunk_mesh.visible = false
	pass
