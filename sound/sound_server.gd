class_name SoundServer extends Node

var sounds : Dictionary[String, AudioStreamOggVorbis] = {}
var speakers : Dictionary[String, AudioStreamPlayer] = {};
var sfx_volume : float = 0.0;
var sounds_played_this_frame : Dictionary = {};

func _ready():
	sounds["uiinteract"] = preload("res://sound/sfx/uiinteract.ogg");
	sounds["nuhuh"] = preload("res://sound/sfx/nuhuh.ogg");
	
	sounds["savestate"] = preload("res://sound/sfx/savestate.ogg");
	sounds["loadstate"] = preload("res://sound/sfx/loadstate.ogg");
	sounds["erased"] = preload("res://sound/sfx/erased.ogg");
	# ^ todo ^
	sounds["undo"] = preload("res://sound/sfx/undo.ogg");
	sounds["redo"] = preload("res://sound/sfx/redo.ogg");
	sounds["restart"] = preload("res://sound/sfx/restart.ogg");
	
	sounds["movecycle"] = preload("res://sound/sfx/movecycle.ogg");
	
	sounds["potionhp"] = preload("res://sound/sfx/potionhp.ogg");
	sounds["potionfire"] = preload("res://sound/sfx/potionfire.ogg");
	sounds["potionsteam"] = preload("res://sound/sfx/potionsteam.ogg");
	sounds["potionwater"] = preload("res://sound/sfx/potionwater.ogg");
	sounds["keypickup"] = preload("res://sound/sfx/keypickup.ogg");
	sounds["genericpickup"] = preload("res://sound/sfx/genericpickup.ogg");
	sounds["mysteriouspickup"] = preload("res://sound/sfx/mysteriouspickup.ogg");
	
	sounds["killfire"] = preload("res://sound/sfx/killfire.ogg");
	sounds["killsteam"] = preload("res://sound/sfx/killsteam.ogg");
	sounds["killwater"] = preload("res://sound/sfx/killwater.ogg");
	
	sounds["destroywall"] = preload("res://sound/sfx/destroywall.ogg");
	sounds["openlock"] = preload("res://sound/sfx/openlock.ogg");
	sounds["useitem"] = preload("res://sound/sfx/useitem.ogg");
	# v todo v
	sounds["victory"] = preload("res://sound/sfx/victory.ogg");
	
	for sound in sounds:
		var speaker = AudioStreamPlayer.new();
		add_child(speaker)
		speakers[sound] = speaker;
		speaker.stream = sounds[sound]
		speaker.max_polyphony = 4

func _process(_dt):
	sounds_played_this_frame = {}

func play(sound: String) -> void:
	if (sfx_volume <= -30.0):
		return;
	if (sounds_played_this_frame.has(sound)):
		return;
	if sound not in speakers:
		return
	
	var speaker := speakers[sound]
	sounds_played_this_frame[sound] = true;
	speaker.play();
