extends Node2D

func clear_discard_pile() -> void:
	for child in get_children():
		remove_child(child)

func update_discard_pile() -> void:
	var shown_card: Node2D = GameMaster.discard_pile[-1]
	shown_card.set_meta("HoverEffect", false)
	shown_card.set_meta("CanBePlayed", false) #make sure a played card can't be played again
	shown_card.set_card_back(false)
	shown_card.position = Vector2(0, 0)
	shown_card.rotate(randf_range(-0.2, 0.2)) 
	add_child(shown_card)
