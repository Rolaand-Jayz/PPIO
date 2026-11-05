extends Node
## Audio manager (autoload: Audio). Event-driven playback on the project's
## bus layout (Master/Music/SFX/UI/Ambience). Deterministic gameplay code
## never depends on audio: sounds are fire-and-forget presentations of
## events that already happened in the rules.

const SFX_PATHS := {
	# UI cues
	"ui_move": "res://assets/audio/ui/ui_move.wav",
	"ui_confirm": "res://assets/audio/ui/ui_confirm.wav",
	"ui_cancel": "res://assets/audio/ui/ui_cancel.wav",
	"ui_deny": "res://assets/audio/ui/ui_deny.wav",
	"ui_open": "res://assets/audio/ui/ui_open.wav",
	"ui_close": "res://assets/audio/ui/ui_close.wav",
	"ui_target": "res://assets/audio/ui/ui_target.wav",
	"ui_party": "res://assets/audio/ui/ui_party.wav",
	"ui_pause": "res://assets/audio/ui/ui_pause.wav",
	# combat SFX
	"jayze_attack": "res://assets/audio/sfx/jayze_attack.wav",
	"jayze_ability": "res://assets/audio/sfx/jayze_ability.wav",
	"kip_shoot": "res://assets/audio/sfx/kip_shoot.wav",
	"kip_ram": "res://assets/audio/sfx/kip_ram.wav",
	"rallo_claw": "res://assets/audio/sfx/rallo_claw.wav",
	"rallo_ability": "res://assets/audio/sfx/rallo_ability.wav",
	"jonnie_attack": "res://assets/audio/sfx/jonnie_attack.wav",
	"jonnie_ability": "res://assets/audio/sfx/jonnie_ability.wav",
	"jonnie_brace": "res://assets/audio/sfx/jonnie_brace.wav",
	"impact_light": "res://assets/audio/sfx/impact_light.wav",
	"impact_heavy": "res://assets/audio/sfx/impact_heavy.wav",
	"guard_block": "res://assets/audio/sfx/guard_block.wav",
	"hit_react": "res://assets/audio/sfx/hit_react.wav",
	"evade": "res://assets/audio/sfx/evade.wav",
	"ko_down": "res://assets/audio/sfx/ko_down.wav",
	"telegraph_warn": "res://assets/audio/sfx/telegraph_warn.wav",
	"enemy_attack": "res://assets/audio/sfx/enemy_attack.wav",
	"projectile": "res://assets/audio/sfx/projectile.wav",
	"heal": "res://assets/audio/sfx/heal.wav",
	"stagger": "res://assets/audio/sfx/stagger.wav",
}

const MUSIC := {
	"combat": "res://assets/audio/music/combat_theme.ogg",
	"encounter": "res://assets/audio/music/encounter_start.ogg",
	"victory": "res://assets/audio/music/victory.ogg",
	"defeat": "res://assets/audio/music/defeat.ogg",
	"ambience": "res://assets/audio/music/ambience.ogg",
}

const POOL_SIZE := 10

var _streams := {}
var _music_streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_front: AudioStreamPlayer  # which slot is audible
var _ambience: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in SFX_PATHS:
		if ResourceLoader.exists(SFX_PATHS[key]):
			_streams[key] = load(SFX_PATHS[key])
	for key in MUSIC:
		if ResourceLoader.exists(MUSIC[key]):
			_music_streams[key] = load(MUSIC[key])
			if _music_streams[key] is AudioStreamOggVorbis:
				_music_streams[key].loop = key in ["combat", "ambience"]
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
		var p3 := AudioStreamPlayer3D.new()
		p3.bus = "SFX"
		p3.unit_size = 14.0
		p3.max_db = 0.0
		add_child(p3)
		_pool_3d.append(p3)
	_music_a = _make_music_player()
	_music_b = _make_music_player()
	_music_front = _music_a
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = "Ambience"
	add_child(_ambience)

func _make_music_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "Music"
	add_child(p)
	return p

## Fire-and-forget UI/non-positional cue. Guarded by stream existence so
## missing files can never break gameplay flow.
func ui(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	_play_2d(name, "UI", pitch, volume_db)

func sfx(name: String, pitch := 1.0, volume_db := 0.0) -> void:
	_play_2d(name, "SFX", pitch, volume_db)

func sfx_at(name: String, pos: Vector3, pitch := 1.0, volume_db := 0.0) -> void:
	if not _streams.has(name):
		return
	for p in _pool_3d:
		if not p.playing:
			p.stream = _streams[name]
			p.pitch_scale = pitch
			p.volume_db = volume_db
			p.global_position = pos
			p.play()
			return
	# pool exhausted: steal the first player rather than dropping the event
	_pool_3d[0].stream = _streams[name]
	_pool_3d[0].pitch_scale = pitch
	_pool_3d[0].volume_db = volume_db
	_pool_3d[0].global_position = pos
	_pool_3d[0].play()

func _play_2d(name: String, bus: String, pitch: float, volume_db: float) -> void:
	if not _streams.has(name):
		return
	for p in _pool:
		if not p.playing:
			p.bus = bus
			p.stream = _streams[name]
			p.pitch_scale = pitch
			p.volume_db = volume_db
			p.play()
			return
	_pool[0].stream = _streams[name]
	_pool[0].pitch_scale = pitch
	_pool[0].volume_db = volume_db
	_pool[0].play()

func play_music(key: String, fade := 0.8) -> void:
	if not _music_streams.has(key):
		return
	var back := _music_b if _music_front == _music_a else _music_a
	back.stream = _music_streams[key]
	back.volume_db = -40.0
	back.play()
	_music_front = back
	var fade_out := _music_b if back == _music_a else _music_a
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(back, "volume_db", 0.0, fade)
	if fade_out.playing:
		tw.tween_property(fade_out, "volume_db", -40.0, fade)
		tw.chain().tween_callback(fade_out.stop)

func stop_music(fade := 0.6) -> void:
	for p in [_music_a, _music_b]:
		if p.playing:
			var tw := create_tween()
			tw.tween_property(p, "volume_db", -40.0, fade)
			tw.tween_callback(p.stop)

func start_ambience() -> void:
	if _music_streams.has("ambience") and not _ambience.playing:
		_ambience.stream = _music_streams["ambience"]
		_ambience.volume_db = -6.0
		_ambience.play()

func stop_ambience() -> void:
	if _ambience.playing:
		_ambience.stop()
