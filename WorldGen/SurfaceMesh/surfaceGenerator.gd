@tool
extends Node3D

@export_tool_button("Generate Surface", "Callable") var generate_tool_button = generateSurface
@export_tool_button("Delete Mesh", "Callable") var delete_mesh_tool_button = delete_mesh


@export_group("Size")
## The size of the world. Units are in number of chunks in each direction
@export var surface_size: Dictionary = {"height": 16, "width": 16}
## Size of chunk. Amount is in "Triangles in a row". Currently thinking in meters works. 
@export var chunk_size: Dictionary = {"height": 32, "width": 32}
## The height of the map. The noisemap is normalized, so the highest point will always be this tall
@export var sky_limit: int = 512


@export_group("Optimization")
@export_subgroup("Surface generation")
@export var thread_number: int = 10
@export_subgroup("Level of detail")
@export var enableLOD: bool = true: 
	get:
		return enableLOD
	set(value): 
		enableLOD = value
		generateSurface()
		



@export_group("Noise and textures")
@export var noisemap: NoiseTexture2D
@export var texture: Texture2D

### Game objects, such as the player
#@export_group("Game objects")
#@export var curr_cam: Node3D


#var curr_cam: Vector3 


signal worldMapGenerated(image: Image)



#var chunkRegistry: Vector2i = Vector

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Stop generating terrain when starting editor
	if Engine.is_editor_hint():
		return 
	else: 
		generateSurface()
	pass # Replace with function body.

func delete_mesh():
	for child in get_children():
		child.free()
	pass

## Creates the noise (Woop!  Woop!) for the whole world. 
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

func _generateWorldMap() -> Image:
	var n = noisemap.noise.get_image(chunk_size.width*surface_size.width, chunk_size.width*surface_size.width)
	worldMapGenerated.emit(n)
	return n

	
func _create_new_chunk(curr_size: Vector2i, distance_to_player: Vector3):
	var curr_height = curr_size.x
	var curr_width  = curr_size.y
	#var chunk_location = _calculate_chunk_position(Vector2i(curr_width, curr_height))
	var chunk = SurfaceChunk.new()
	var chunkID = Vector2i(curr_height, curr_width)
	chunk.name = str(chunkID)
	
	
	#Calculate position of chunk. Use this to get seamles transition to other chunks
	var chunk_position = Vector3((chunk_size.width) * curr_width,0,(chunk_size.height) * curr_height)
	
	# Spawn and Move Chunk into place
	call_deferred("add_child", chunk)
	chunk.position += chunk_position
	
	
	# Get noise for current chunk
	var curr_noise = noisemap.duplicate(true)
	curr_noise.noise.set_offset(Vector3(chunk_position.x,chunk_position.z,0))
	
	# Generate chunk
	chunk.generateChunk(curr_noise, _get_material_texture(), sky_limit, chunk_size, distance_to_player, chunk_position)
			
	pass
	
func generateSurface():
	var camera_pos = get_viewport().get_camera_3d().position
	# First remove mesh, if already exists
	delete_mesh()
	## Generate noisemap for whole surface: 
	_generate_noise()
	
	_generateWorldMap()
	
	# Create surface with threaded work
	var dispatch_queue = DispatchQueue.new()
	var timeStart = Time.get_ticks_msec()
	dispatch_queue.create_concurrent(thread_number)
	
	var threads_number_of_jobs = 0
	var threads_used = 0
	for curr_height in surface_size.height:
		for curr_width in surface_size.width:
			dispatch_queue.dispatch(_create_new_chunk.bind(Vector2(curr_height, curr_width), camera_pos))
			
			## This is purely for performance checks: 
			threads_number_of_jobs = threads_number_of_jobs +1
			var t = dispatch_queue.get_thread_count()
			if t >= threads_used:
				threads_used= t
	
	
	await dispatch_queue.all_tasks_finished
	var time_used = func():
		var t = Time.get_ticks_msec() - timeStart
		return str("%s seconds (%s milliseconds)" % [t*0.001, t])

	print("Surface created! Creation time: %s generating a %sm by %sm surface. We used %s threads on %s jobs" % [time_used.call(), chunk_size.height * surface_size.height, chunk_size.width * surface_size.width, threads_used, threads_number_of_jobs])


func _on_button_pressed_generate_surface() -> void:
	print("Trying to generate surface.")
	generateSurface()
	pass 


func _on_noise_freq_slider_value_changed(value: float) -> void:
	noisemap.noise.set_frequency(value)
	generateSurface()
	pass 


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


func _on_skyheight_slider_value_changed(value: int) -> void:
	sky_limit = value
	generateSurface()
	pass # Replace with function body.


func _on_LODEnabler_changes() -> void:
	enableLOD = !enableLOD
