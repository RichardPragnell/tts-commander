extends Control

const CommandProcessorScript = preload("res://scripts/command_processor.gd")
const ShipViewScript = preload("res://scripts/ship_view.gd")

var processor = CommandProcessorScript.new()
var rooms := {}
var crew := {}
var ship_state := {}
var log_lines: Array[String] = []

var ship_view: Control
var voice_label: Label
var router_label: Label
var thought_label: Label
var status_label: Label
var command_line: LineEdit
var log_text: RichTextLabel

func _ready() -> void:
	randomize()
	_boot_state()
	_build_ui()
	_append_log("POC booted. Type a command or run a GDD scenario.")
	_append_log("Try: GELADERA!, fire lasers at the asteroid, fix the engine bay leak, scan the anomaly.")
	_refresh_ui()

func _process(delta: float) -> void:
	for crew_id in crew.keys():
		var data: Dictionary = crew[crew_id]
		if float(data.get("progress", 1.0)) < 1.0:
			data["progress"] = minf(1.0, float(data["progress"]) + delta * 0.9)
			if float(data["progress"]) >= 1.0:
				data["room"] = data["target_room"]
			crew[crew_id] = data
	if ship_view:
		ship_view.set_state(rooms, crew, ship_state)

func _boot_state() -> void:
	rooms = {
		"bridge": {
			"display": "BRIDGE NODE",
			"status": "Player Input Deck",
			"danger": 0.05,
			"color": Color(0.10, 0.18, 0.22)
		},
		"tactical": {
			"display": "TACTICAL NODE",
			"status": "Weapons Hot",
			"danger": 0.18,
			"color": Color(0.16, 0.13, 0.20)
		},
		"engine": {
			"display": "ENGINE ROOM",
			"status": "Hull Leak Warning",
			"danger": 0.58,
			"color": Color(0.18, 0.12, 0.10)
		},
		"geladera": {
			"display": "GELADERA NODE",
			"status": "Emergency Rations",
			"danger": 0.02,
			"color": Color(0.11, 0.18, 0.15)
		}
	}

	crew = {
		"dog": {
			"name": "Dog Captain",
			"short_name": "DogCapt",
			"room": "bridge",
			"target_room": "bridge",
			"progress": 1.0,
			"slot": 0,
			"state": "Idle",
			"thought": "Listening for command tone.",
			"color": Color(0.25, 0.72, 1.0),
			"morale": 78,
			"panic": 8
		},
		"luffy": {
			"name": "Luffy Style",
			"short_name": "Luffy",
			"room": "tactical",
			"target_room": "tactical",
			"progress": 1.0,
			"slot": 1,
			"state": "Targeting",
			"thought": "Say blow up. I dare you.",
			"color": Color(1.0, 0.48, 0.18),
			"morale": 64,
			"panic": 20
		},
		"intern": {
			"name": "Paranoid Intern",
			"short_name": "Intern",
			"room": "engine",
			"target_room": "engine",
			"progress": 1.0,
			"slot": 2,
			"state": "Nervous",
			"thought": "The pipe is glowing again.",
			"color": Color(0.82, 0.95, 0.42),
			"morale": 46,
			"panic": 68
		}
	}

	ship_state = {
		"sector": "Alpha-9",
		"shields": 60,
		"hull": 72,
		"threat": 42,
		"morale": 55,
		"beer": 3,
		"last_latency": 0
	}

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	root.offset_left = 14
	root.offset_top = 14
	root.offset_right = -14
	root.offset_bottom = -14
	add_child(root)

	var title := Label.new()
	title.text = "LOOSE CANNONS POC - Real-Time Crew Command Router"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	root.add_child(status_label)

	ship_view = Control.new()
	ship_view.set_script(ShipViewScript)
	ship_view.custom_minimum_size = Vector2(960, 430)
	ship_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ship_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(ship_view)

	var lower := HBoxContainer.new()
	lower.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lower.add_theme_constant_override("separation", 10)
	root.add_child(lower)

	var controls := VBoxContainer.new()
	controls.custom_minimum_size = Vector2(460, 220)
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower.add_child(controls)

	voice_label = _make_info_label("LIVE VOICE TRANSCRIBER: waiting for text input")
	router_label = _make_info_label("ENGINE ROUTER LOG: idle")
	thought_label = _make_info_label("CREW INTERNAL DIALOG: stable enough")
	controls.add_child(voice_label)
	controls.add_child(router_label)
	controls.add_child(thought_label)

	command_line = LineEdit.new()
	command_line.placeholder_text = "Speak/type command transcript here, then press Enter"
	command_line.text_submitted.connect(_on_command_submitted)
	controls.add_child(command_line)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	controls.add_child(button_row)
	_add_scenario_button(button_row, "GELADERA!", "GELADERA!")
	_add_scenario_button(button_row, "Repair Leak", "Hey, do me a huge favor and wander down to the engine area to seal that glowing red pipe.")
	_add_scenario_button(button_row, "Fire Lasers", "Luffy, blow up that incoming space rock right now!")
	_add_scenario_button(button_row, "Scan", "Dog captain, check the sector for unknown life signs.")

	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.fit_content = false
	log_text.scroll_following = true
	log_text.custom_minimum_size = Vector2(440, 220)
	log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lower.add_child(log_text)

func _make_info_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(0, 34)
	return label

func _add_scenario_button(parent: Control, label: String, command: String) -> void:
	var button := Button.new()
	button.text = label
	button.tooltip_text = command
	button.pressed.connect(func() -> void:
		command_line.text = command
		_on_command_submitted(command)
	)
	parent.add_child(button)

func _on_command_submitted(text: String) -> void:
	if text.strip_edges() == "":
		return
	command_line.clear()
	_handle_command(text)

func _handle_command(text: String) -> void:
	var started_at := Time.get_ticks_msec()
	voice_label.text = "LIVE VOICE TRANSCRIBER: \"" + text + "\""
	var result: Dictionary = processor.parse_command(text, _processor_state())
	router_label.text = "ENGINE ROUTER LOG: " + result["tier"] + " -> Action: " + result["action"] + " | Target: " + result["target"].to_upper()

	if result["tier"].begins_with("Tier 2"):
		await get_tree().create_timer(0.28).timeout

	var latency := Time.get_ticks_msec() - started_at
	result["latency_ms"] = latency
	ship_state["last_latency"] = latency
	_execute_command(result)
	_refresh_ui()

func _processor_state() -> Dictionary:
	return {
		"rooms": rooms,
		"crew": crew,
		"ship": ship_state
	}

func _execute_command(result: Dictionary) -> void:
	var action := String(result["action"])
	var target := String(result["target"])
	var crew_id := String(result["crew_id"])
	var urgency := int(result["urgency"])
	var crew_member: Dictionary = crew[crew_id]
	crew_member["target_room"] = target
	crew_member["progress"] = 0.0 if crew_member["room"] != target else 1.0

	var roll := randi_range(1, 100)
	var morale := int(crew_member.get("morale", 50))
	var panic := int(crew_member.get("panic", 0))
	var score := roll + int(morale * 0.35) - int(panic * 0.25)

	match action:
		"GELADERA":
			_apply_geladera(result, crew_member)
		"ATTACK":
			_apply_attack(result, crew_member, score)
		"REPAIR":
			_apply_repair(result, crew_member, score, urgency)
		"SHIELD":
			_apply_shield(result, crew_member, score)
		"SCAN":
			_apply_scan(result, crew_member, score)
		_:
			crew_member["state"] = "Confused"
			crew_member["thought"] = "I heard words, not orders."
			_append_log("[MISS] Router could not map command: " + result["raw_text"])

	crew[crew_id] = crew_member
	_apply_passive_pressure()

func _apply_geladera(result: Dictionary, crew_member: Dictionary) -> void:
	ship_state["beer"] = max(0, int(ship_state["beer"]) - 1)
	ship_state["morale"] = mini(100, int(ship_state["morale"]) + 18)
	for id in crew.keys():
		var data: Dictionary = crew[id]
		data["panic"] = max(0, int(data.get("panic", 0)) - 34)
		data["morale"] = mini(100, int(data.get("morale", 50)) + 12)
		data["state"] = "Clumsy"
		data["thought"] = "Emergency rations deployed. Fine, I will help."
		crew[id] = data
	rooms["geladera"]["status"] = "Beer canisters dropped"
	rooms["geladera"]["danger"] = 0.0
	crew_member["state"] = "Broadcasting"
	crew_member["thought"] = "GELADERA protocol works every time."
	thought_label.text = "CREW INTERNAL DIALOG (Dog Captain): " + crew_member["thought"]
	_append_log("[FAST] GELADERA resolved in " + str(result["latency_ms"]) + "ms. Intern panic reset to responsive profile.")

func _apply_attack(result: Dictionary, crew_member: Dictionary, score: int) -> void:
	crew_member["state"] = "Reckless Fire"
	crew_member["thought"] = "He said blow up. Maximum wattage."
	var damage := 24 if score >= 55 else 10
	ship_state["threat"] = max(0, int(ship_state["threat"]) - damage)
	ship_state["shields"] = max(0, int(ship_state["shields"]) - 6)
	rooms["tactical"]["status"] = "Weapons Fired"
	rooms["tactical"]["danger"] = minf(1.0, float(rooms["tactical"]["danger"]) + (0.18 if score >= 55 else 0.34))
	thought_label.text = "CREW INTERNAL DIALOG (Luffy): " + crew_member["thought"]
	if score >= 55:
		_append_log("[HIT] Luffy reduced threat by " + str(damage) + ". BUT reckless sync-fire strained the grid.")
	else:
		ship_state["hull"] = max(0, int(ship_state["hull"]) - 8)
		_append_log("[CHAOS] Luffy fired everything. BECAUSE targeting was sloppy, THEREFORE hull took backlash damage.")

func _apply_repair(result: Dictionary, crew_member: Dictionary, score: int, urgency: int) -> void:
	if urgency >= 3 and int(crew_member.get("panic", 0)) > 45:
		crew_member["state"] = "Frozen"
		crew_member["panic"] = mini(100, int(crew_member.get("panic", 0)) + 10)
		crew_member["thought"] = "Too loud. Locking the room. That feels safer."
		rooms["engine"]["status"] = "Intern froze at breach"
		rooms["engine"]["danger"] = minf(1.0, float(rooms["engine"]["danger"]) + 0.12)
		_append_log("[PANIC] Intern froze. BUT the leak kept venting, THEREFORE engine danger increased.")
		thought_label.text = "CREW INTERNAL DIALOG (Intern): " + crew_member["thought"]
		return

	crew_member["state"] = "Repairing"
	crew_member["panic"] = max(0, int(crew_member.get("panic", 0)) - 8)
	if score >= 45:
		ship_state["hull"] = mini(100, int(ship_state["hull"]) + 14)
		rooms["engine"]["status"] = "Leak patched"
		rooms["engine"]["danger"] = maxf(0.0, float(rooms["engine"]["danger"]) - 0.28)
		crew_member["thought"] = "Patch applied. I only dropped one wrench."
		_append_log("[REPAIR] Engine leak patched in " + str(result["latency_ms"]) + "ms. Deep target mapped to ENGINE.")
	else:
		ship_state["hull"] = max(0, int(ship_state["hull"]) - 5)
		rooms["engine"]["danger"] = minf(1.0, float(rooms["engine"]["danger"]) + 0.10)
		crew_member["thought"] = "I patched the scary part. Maybe not the right part."
		_append_log("[FAIL] Repair attempt missed. BECAUSE the intern guessed wrong, THEREFORE hull dropped.")
	thought_label.text = "CREW INTERNAL DIALOG (Intern): " + crew_member["thought"]

func _apply_shield(result: Dictionary, crew_member: Dictionary, score: int) -> void:
	crew_member["state"] = "Commanding"
	if score >= 40:
		ship_state["shields"] = mini(100, int(ship_state["shields"]) + 18)
		rooms["bridge"]["status"] = "Shield routing stable"
		crew_member["thought"] = "Defensive posture. Sensible human."
		_append_log("[SHIELD] Shields reinforced to " + str(ship_state["shields"]) + "%.")
	else:
		rooms["bridge"]["danger"] = minf(1.0, float(rooms["bridge"]["danger"]) + 0.12)
		crew_member["thought"] = "I protected the loudest blinking light."
		_append_log("[MUTATION] Dog Captain protected the wrong console. Bridge danger increased.")
	thought_label.text = "CREW INTERNAL DIALOG (Dog Captain): " + crew_member["thought"]

func _apply_scan(result: Dictionary, crew_member: Dictionary, score: int) -> void:
	crew_member["state"] = "Scanning"
	if score >= 35:
		ship_state["threat"] = max(0, int(ship_state["threat"]) - 6)
		crew_member["thought"] = "Found the anomaly trail. It smells electrical."
		_append_log("[SCAN] Sector sweep identified a weak point. Threat forecast lowered.")
	else:
		crew_member["thought"] = "I chased motion on the bridge window."
		_append_log("[DOG LOGIC] Scan distracted by movement. No useful target data.")
	thought_label.text = "CREW INTERNAL DIALOG (Dog Captain): " + crew_member["thought"]

func _apply_passive_pressure() -> void:
	if int(ship_state["threat"]) > 0:
		ship_state["shields"] = max(0, int(ship_state["shields"]) - 1)
	if float(rooms["engine"]["danger"]) > 0.55:
		ship_state["hull"] = max(0, int(ship_state["hull"]) - 1)
	if int(ship_state["shields"]) <= 20:
		rooms["bridge"]["danger"] = minf(1.0, float(rooms["bridge"]["danger"]) + 0.03)
	if int(ship_state["hull"]) <= 0:
		_append_log("[LOSS] Hull integrity collapsed. Reset the scene to retry the POC run.")

func _refresh_ui() -> void:
	status_label.text = "DB~GALAXY Sector %s | Shields %d%% | Hull %d%% | Threat %d%% | Morale %d%% | Geladera %d | Last latency %dms" % [
		ship_state["sector"],
		ship_state["shields"],
		ship_state["hull"],
		ship_state["threat"],
		ship_state["morale"],
		ship_state["beer"],
		ship_state["last_latency"]
	]
	if ship_view:
		ship_view.set_state(rooms, crew, ship_state)
	if log_text:
		log_text.clear()
		for line in log_lines:
			log_text.append_text(line + "\n")

func _append_log(message: String) -> void:
	var stamp := Time.get_time_string_from_system()
	log_lines.append("[color=#9fb7c5]" + stamp + "[/color] " + message)
	if log_lines.size() > 10:
		log_lines.pop_front()
	if log_text:
		log_text.append_text(log_lines.back() + "\n")
