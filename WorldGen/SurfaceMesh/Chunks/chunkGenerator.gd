@tool
class_name SurfaceChunk
extends MeshInstance3D


#@export var chunk_size: Dictionary = {"height": 512, "width": 512, "upwards": 512}
#@export var noisemap: NoiseTexture2D
#@export var texture: Texture2D
#
#@export_tool_button("Generate Mesh", "Callable") var generate_tool_button = generateChunk

var chunk_noisemap: NoiseTexture2D
var chunk_material: StandardMaterial3D
var chunk_size: Dictionary
var chunk_skylimit: int

#func _ready() -> void:
	#generateChunk()
	#




func get_noise_height(cords: Vector2i):
	var data: float = chunk_noisemap.noise.get_noise_2dv(cords) * chunk_skylimit
	
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

	for height in chunk_size.height:
		for width in chunk_size.width:
			verts.append(Vector3(width, get_noise_height(Vector2i(width, height)), height))
	pass


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
	var curr_triangle: int = 0
	for curr_height in chunk_size.height: # X = Vertical, is Z in Vector
		for curr_width in chunk_size.width: # Y = Horizontal, is Z in Vector
			var edge1 = curr_triangle
			var edge2 = curr_triangle + 1
			var edge3 = curr_triangle + chunk_size.width
			
			var edge4 = edge2
			var edge5 = edge4 + chunk_size.width
			var edge6 = edge3
			
			curr_triangle +=1
			if curr_width == chunk_size.width -1:
				continue
			
			
			if false: #enable for debug text about edging. 
				print_debug("Current Tirangle: %s" % curr_triangle)
				print_debug("chunk_size.width: %s" % chunk_size.width)
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

func generateChunk(Noisemap: NoiseTexture2D, c_material: StandardMaterial3D, skylimit: int, Chunk_size: Dictionary):
	
	chunk_noisemap = Noisemap
	chunk_material = c_material
	chunk_size     = Chunk_size
	chunk_skylimit = skylimit	
	
	# Generate surface Mesh
	mesh = ArrayMesh.new()

	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var edges = PackedInt32Array()


	verts = gen_verts()
	#verts = PackedVector3Array([
	 	#Vector3(0, 0, 0), #0
	 	#Vector3(0, 0, 1), #1
	 	#Vector3(1, 0, 0), #2
	 	#Vector3(1, 0, 1), #3
	 	#Vector3(2, 0, 0), #4
	 	#Vector3(2, 0, 1), #5
	 #])
	
	uvs = gen_uvs(verts)
	# uvs = PackedVector2Array([
	# 		Vector2(0, 0),
	# 		Vector2(1, 0),
	# 		Vector2(0, 1),
	# 		Vector2(1, 1),
	# 		Vector2(0.5, 0.5),
	# 		Vector2(1, 0.5),
	# 	])

	normals = gen_normals(uvs)
	# normals = PackedVector3Array([
	# 		Vector3.UP,
	# 		Vector3.UP,
	# 		Vector3.UP,
	# 		Vector3.UP,
	# 		Vector3.UP,
	# 		Vector3.UP,
	# 	])


	edges = gen_edges()
	#indices = PackedInt32Array([
			#0, 2, 1,
			#2, 3, 1,
			#2, 4, 3,
			#4, 5, 3,
		#])

	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = edges
	

	#print_debug("Vertex amount: %s" %verts.size())
	#print_debug("Edges amount: %s" %edges.size())
	
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	set_surface_override_material(0, chunk_material)

	pass # Replace with function body.
