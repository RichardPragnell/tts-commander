extends RefCounted

class_name CommandProcessor

const FAST_TARGET_MS := 150
const DEEP_TARGET_MS := 600

const ACTION_ATTACK := "ATTACK"
const ACTION_REPAIR := "REPAIR"
const ACTION_SHIELD := "SHIELD"
const ACTION_SCAN := "SCAN"
const ACTION_GELADERA := "GELADERA"
const ACTION_UNKNOWN := "UNKNOWN"

var fast_keywords := {
	ACTION_GELADERA: ["geladera", "beer", "cerveza", "fridge"],
	ACTION_ATTACK: ["fire", "shoot", "blast", "laser", "attack", "blow up"],
	ACTION_REPAIR: ["repair", "fix", "patch", "seal"],
	ACTION_SHIELD: ["shield", "defend", "protect"],
	ACTION_SCAN: ["scan", "analyze", "survey"]
}

func parse_command(raw_text: String, state: Dictionary) -> Dictionary:
	var started_at := Time.get_ticks_msec()
	var text := raw_text.strip_edges()
	var normalized := text.to_lower()
	var action := _match_fast_action(normalized)
	var is_fast := action != ACTION_UNKNOWN
	var target := _infer_target(normalized, action)
	var urgency := _infer_urgency(text, normalized)

	if not is_fast:
		action = _infer_deep_action(normalized)
		target = _infer_target(normalized, action)

	if target == "":
		target = _fallback_target_for_action(action)

	var crew_id := _crew_for_action(action, target)
	var budget := FAST_TARGET_MS if is_fast else DEEP_TARGET_MS

	return {
		"raw_text": text,
		"normalized": normalized,
		"action": action,
		"target": target,
		"urgency": urgency,
		"crew_id": crew_id,
		"tier": "Tier 1 Fast-Path" if is_fast else "Tier 2 Deep-Path",
		"budget_ms": budget,
		"parse_ms": Time.get_ticks_msec() - started_at,
		"ship_snapshot": state
	}

func _match_fast_action(text: String) -> String:
	for action in fast_keywords.keys():
		if _contains_any(text, fast_keywords[action]):
			return action
	return ACTION_UNKNOWN

func _infer_deep_action(text: String) -> String:
	if _contains_any(text, ["glowing red pipe", "leak", "hull", "engine area", "engine bay", "broken", "sparking"]):
		return ACTION_REPAIR
	if _contains_any(text, ["space rock", "asteroid", "incoming", "monster", "pirate", "enemy", "threat"]):
		return ACTION_ATTACK
	if _contains_any(text, ["safe", "cover", "barrier", "incoming fire"]):
		return ACTION_SHIELD
	if _contains_any(text, ["what is", "where is", "check", "look at", "inspect", "unknown", "anomaly"]):
		return ACTION_SCAN
	if _contains_any(text, ["calm", "panic", "drink", "cold one", "ration"]):
		return ACTION_GELADERA
	return ACTION_UNKNOWN

func _infer_target(text: String, action: String) -> String:
	if _contains_any(text, ["bridge", "captain", "command deck"]):
		return "bridge"
	if _contains_any(text, ["tactical", "weapon", "weapons", "turret", "laser", "enemy", "asteroid", "rock"]):
		return "tactical"
	if _contains_any(text, ["engine", "reactor", "hull", "leak", "pipe", "bay"]):
		return "engine"
	if _contains_any(text, ["geladera", "beer", "cerveza", "fridge", "ration"]):
		return "geladera"
	return _fallback_target_for_action(action)

func _fallback_target_for_action(action: String) -> String:
	match action:
		ACTION_ATTACK:
			return "tactical"
		ACTION_REPAIR:
			return "engine"
		ACTION_SHIELD:
			return "bridge"
		ACTION_SCAN:
			return "bridge"
		ACTION_GELADERA:
			return "geladera"
		_:
			return "bridge"

func _crew_for_action(action: String, target: String) -> String:
	match action:
		ACTION_ATTACK:
			return "luffy"
		ACTION_REPAIR:
			return "intern"
		ACTION_GELADERA:
			return "dog"
		ACTION_SCAN, ACTION_SHIELD:
			return "dog"
		_:
			match target:
				"tactical":
					return "luffy"
				"engine":
					return "intern"
				_:
					return "dog"

func _infer_urgency(raw_text: String, text: String) -> int:
	var urgency := 0
	if raw_text.contains("!"):
		urgency += 2
	if raw_text == raw_text.to_upper() and raw_text.length() > 3:
		urgency += 2
	if _contains_any(text, ["now", "hurry", "right now", "quick", "emergency", "critical", "please"]):
		urgency += 1
	return clampi(urgency, 0, 5)

func _contains_any(text: String, terms: Array) -> bool:
	for term in terms:
		if text.find(term) != -1:
			return true
	return false
