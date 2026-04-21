extends TextureRect


# Called when the node enters the scene tree for the first time.

func _on_worldMapRecived(image: Image):
	texture = ImageTexture.create_from_image(image)
	
	pass
	
