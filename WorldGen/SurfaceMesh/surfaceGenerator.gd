@tool
extends Node3D


## The size of the world. Units are in number of chunks in each direction
@export var surface_size: Dictionary = {"height": 4, "width": 4}
## Size of chunk. Amount is in "Triangles in a row". Currently thinking in meters works. 
@export var chunk_size: Dictionary = {"height": 16, "width": 16}
## The height of the map. The noisemap is normalized, so the highest point will always be this tall
@export var sky_limit: int = 512

@export var noisemap: NoiseTexture2D
@export var texture: Texture2D



@export_tool_button("Generate Surface", "Callable") var generate_tool_button = generateSurface
@export_tool_button("Delete Mesh", "Callable") var delete_mesh_tool_button = delete_mesh

#var chunkRegistry: Vector2i = Vector

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#generateSurface()
	#pass # Replace with function body.

func delete_mesh():
	for child in get_children():
		child.free()
	pass

func _generate_noise():
	if noisemap == null:
		noisemap = NoiseTexture2D.new()
	
	noisemap.height = chunk_size.height
	noisemap.width = chunk_size.width
	
	if noisemap.noise == null:
		noisemap.noise = FastNoiseLite.new()

	return noisemap
	

func _get_material_texture():
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat
	

	
func generateSurface():
	# First remove mesh, if already exists
	delete_mesh()
	 #Generate noisemap: 
	_generate_noise()
	
	
	for curr_height in surface_size.height:
		for curr_width in surface_size.width:
			#var chunk_location = _calculate_chunk_position(Vector2i(curr_width, curr_height))
			var chunk = SurfaceChunk.new()
			var chunkID = Vector2i(curr_height, curr_width)
			chunk.name = str(chunkID)
			
			#Calculate position of chunk. Use this to get seamles transition to other chunks
			var chunk_position = Vector3((chunk_size.width -1) * curr_width,0,(chunk_size.height - 1) * curr_height)
			
			# Get noise for current chunk
			var curr_noise = noisemap
			curr_noise.noise.set_offset(Vector3(chunk_position.x,chunk_position.z,0))
			
			chunk.generateChunk(curr_noise, _get_material_texture(), sky_limit, chunk_size)
			
			add_child(chunk)
			
			# Move Chunk into place
			chunk.position += chunk_position
			#chunk.position += _calculate_chunk_position(chunk.transform.origin)
			
			pass
	pass


func _on_button_pressed_generate_surface() -> void:
	print("Trying to generate surface.")
	generateSurface()
	pass # Replace with function body.


func _on_noise_freq_slider_value_changed(value: float) -> void:
	noisemap.noise.set_frequency(value)
	generateSurface()
	pass # Replace with function body.


func _on_surface_size_slider_value_changed(value: float, dir: String) -> void:
	if dir == "height":
		surface_size.height = int(value)
	if dir == "width":
		surface_size.width = int(value)
	else: 
		surface_size.height = int(value)
		surface_size.width = int(value)
	generateSurface()
	pass # Replace with function body.


func _on_chunk_size_slider_value_changed(value: float, dir: String) -> void:
	if dir == "height":
		chunk_size.height = int(value)
	if dir == "width":
		chunk_size.width = int(value)
	else: 
		chunk_size.height = int(value)
		chunk_size.width = int(value)
	generateSurface()
	pass # Replace with function body.


func _on_skyheight_slider_value_changed(value: float) -> void:
	sky_limit = value
	generateSurface()
	pass # Replace with function body.
