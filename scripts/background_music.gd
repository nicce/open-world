extends AudioStreamPlayer

var home_area_audio_sound = preload("res://music/home.wav")
var dark_woodlands_audio_sound = preload("res://music/dark_woodslands.wav")
var audio_playing: String = ""

var audio_dict: Dictionary = {
	"home": home_area_audio_sound,
	"dark_woodlands": dark_woodlands_audio_sound
}

func play_audio(audio_key):
	if !is_audio_playing(audio_key):
		var stream = audio_dict[audio_key]
		set_stream(stream)
		play()
		audio_playing = audio_key
	
func is_audio_playing(audio_key) -> bool:
	return audio_playing == audio_key

