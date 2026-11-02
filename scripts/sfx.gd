class_name Sfx
extends Node
## Efectos de sonido (WAV en assets/sonidos/). Si falta un archivo, ese sonido simplemente no suena.

const NAMES := ["dados", "espadas", "barajar", "robar", "descartar", "victoria", "derrota", "aviso", "giratoria"]
var enabled := true
var _players := {}

func _ready() -> void:
	for n in NAMES:
		var st := _load(n)
		if st == null:
			continue
		var p := AudioStreamPlayer.new()
		p.stream = st
		add_child(p)
		_players[n] = p

static func _load(name: String) -> AudioStream:
	var path := "res://assets/sonidos/%s.wav" % name
	if ResourceLoader.exists(path):
		var r = load(path)
		if r is AudioStream:
			return r
	var bytes := FileAccess.get_file_as_bytes(path)       # WAV simple (16 bits, mono, 22050 Hz)
	if bytes.size() <= 44:
		return null
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = 22050
	st.stereo = false
	st.data = bytes.slice(44)
	return st

func play(name: String) -> void:
	if enabled and _players.has(name):
		_players[name].play()
