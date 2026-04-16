@tool
extends Node3D

@export var surface_size: Dictionary = {"height": 4, "width": 4}
@export var sky_limit: int = 512
@export var noisemap: NoiseTexture2D
@export var texture: Texture2D

@export var chunk_size: Dictionary = {"height": 4, "width": 4}


@export_tool_button("Generate Surface", "Callable") var generate_tool_button = generateSurface

#var chunkRegistry: Vector2i = Vector

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generateSurface()
	pass # Replace with function body.



func _generate_noise():
	if noisemap == null:
		noisemap = NoiseTexture2D.new()
	
	noisemap.height = chunk_size.height
	noisemap.width = chunk_size.width
	
	if noisemap.noise == null:
		noisemap.noise = FastNoiseLite.new()
	pass

func _get_material_texture():
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = texture
	return mat
	
func _calculate_chunk_position(cords: Vector3) -> Vector3:
	var chunk_location_width  = cords.x
	var chunk_location_height = cords.y
	
	var trans_width  = chunk_size.width  + chunk_location_width
	var trans_height = chunk_size.height + chunk_location_height
	
	var pos = cords
	
	pos.x = trans_width
	pos.y = trans_height
	
	return pos

	
func generateSurface():
	 #Generate noisemap: 
	_generate_noise()
	
	
	for curr_height in surface_size.height:
		for curr_width in surface_size.width:
			#var chunk_location = _calculate_chunk_position(Vector2i(curr_width, curr_height))
			var chunk = SurfaceChunk.new()
			chunk.generateChunk(noisemap, _get_material_texture(), sky_limit)
			# TODO Får ikke spawnet chunks. 
			# Move Chunk into place
			chunk.position += _calculate_chunk_position(chunk.transform.origin)
			
			add_child(chunk)
			pass
	pass
