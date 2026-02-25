extends AudioStreamPlayer

var current_track: String
var reverb: AudioEffectReverb
var lowpass_filter: AudioEffectLowPassFilter

const music_dic: Dictionary = {
	"Riding the Mood Swing" = preload("res://Assets/Audio/Music/Riding the Mood Swing.mp3"),
	"Sunset Juice" = preload("res://Assets/Audio/Music/Sunset Juice.mp3"),
	"The Halcyon Card Club" = preload("res://Assets/Audio/Music/The Halcyon Card Club.mp3"),
}

func _ready() -> void:
	reverb = AudioServer.get_bus_effect(1, 0)
	lowpass_filter = AudioServer.get_bus_effect(1, 1)
	current_track = random_track()
	stream = music_dic[current_track]
	play()

func _on_finished() -> void:
	current_track = random_track(true)
	stream = music_dic[current_track]
	play()

func random_track(avoid_current_track: bool = false) -> String:
	if avoid_current_track:
		var track_names = music_dic.keys()
		var random_track_name = track_names.pick_random()
		if random_track_name == current_track:
			return random_track(avoid_current_track)
		else:
			return random_track_name
	else:
		var track_names = music_dic.keys()
		var random_track_name = track_names.pick_random()
		return random_track_name

func set_reverb_wet(target_value: float, target_dry_value: float = reverb.dry, transition_time: float = 0) -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(reverb, "wet", target_value, transition_time)
	tween.tween_property(reverb, "dry", target_dry_value, transition_time)
	if target_value > 0.0:
		AudioServer.set_bus_volume_db(1, -10.0)
	else:
		AudioServer.set_bus_volume_db(1, -5.0)

func set_lowpass_freq(target_freq: float, transition_time: float = 0) -> void:
	var tween = create_tween().set_parallel()
	tween.tween_property(lowpass_filter, "cutoff_hz", target_freq, transition_time)
