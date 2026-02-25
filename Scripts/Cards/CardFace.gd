extends TextureRect

func _ready() -> void: #set the card face based on its metadata fields
	var card_color: String = get_parent().get_meta("Color")
	var card_value: String = get_parent().get_meta("Value")
	texture = GameMaster.sprite_map[card_color][card_value]


