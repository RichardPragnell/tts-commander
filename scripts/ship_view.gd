extends Control

class_name ShipView

var rooms := {}
var crew := {}
var ship_state := {}

var room_order := ["bridge", "tactical", "engine", "geladera"]

func set_state(next_rooms: Dictionary, next_crew: Dictionary, next_ship_state: Dictionary) -> void:
	rooms = next_rooms
	crew = next_crew
	ship_state = next_ship_state
	queue_redraw()

func _draw() -> void:
	var bg := Rect2(Vector2.ZERO, size)
	draw_rect(bg, Color(0.035, 0.045, 0.06), true)
	_draw_corridors()
	for room_id in room_order:
		_draw_room(room_id)
	for crew_id in crew.keys():
		_draw_crew(crew_id)

func _draw_corridors() -> void:
	var corridor_color := Color(0.27, 0.36, 0.42)
	var a := _room_rect("bridge").get_center()
	var b := _room_rect("tactical").get_center()
	var c := _room_rect("engine").get_center()
	var d := _room_rect("geladera").get_center()
	draw_line(a, b, corridor_color, 8.0, true)
	draw_line(a, c, corridor_color, 8.0, true)
	draw_line(b, d, corridor_color, 8.0, true)
	draw_line(c, d, corridor_color, 8.0, true)
	draw_line(Vector2(a.x, c.y), Vector2(b.x, c.y), Color(0.18, 0.24, 0.29), 4.0, true)

func _draw_room(room_id: String) -> void:
	var rect := _room_rect(room_id)
	var data: Dictionary = rooms.get(room_id, {})
	var danger := float(data.get("danger", 0.0))
	var base_color: Color = data.get("color", Color(0.11, 0.14, 0.18))
	var fill := base_color.lerp(Color(0.55, 0.08, 0.05), danger)
	var outline := Color(0.65, 0.74, 0.78).lerp(Color(1.0, 0.25, 0.13), danger)

	draw_rect(rect, fill, true)
	draw_rect(rect, outline, false, 3.0)

	var font := get_theme_default_font()
	var font_size := 18
	var label := String(data.get("display", room_id.to_upper()))
	var status := String(data.get("status", "Nominal"))
	var occupant := _occupants_for_room(room_id)

	draw_string(font, rect.position + Vector2(16, 30), label, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32, font_size, Color(0.92, 0.96, 0.98))
	draw_string(font, rect.position + Vector2(16, 58), status, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32, 14, Color(0.72, 0.82, 0.86))
	draw_string(font, rect.position + Vector2(16, rect.size.y - 18), occupant, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 32, 13, Color(0.86, 0.9, 0.78))

func _draw_crew(crew_id: String) -> void:
	var data: Dictionary = crew.get(crew_id, {})
	var pos := _crew_position(data)
	var color: Color = data.get("color", Color.WHITE)
	var state := String(data.get("state", "Idle"))
	var thought := String(data.get("thought", ""))
	var name := String(data.get("name", crew_id))
	var font := get_theme_default_font()

	draw_circle(pos, 18.0, color)
	draw_circle(pos, 19.0, Color(0.95, 0.98, 1.0), false, 2.0)
	draw_string(font, pos + Vector2(-34, 38), name, HORIZONTAL_ALIGNMENT_CENTER, 68, 12, Color(0.93, 0.96, 0.98))
	draw_string(font, pos + Vector2(-38, 53), state, HORIZONTAL_ALIGNMENT_CENTER, 76, 11, Color(0.72, 0.83, 0.88))

	if thought != "":
		var bubble_text := thought
		if bubble_text.length() > 54:
			bubble_text = bubble_text.substr(0, 51) + "..."
		var bubble := Rect2(pos + Vector2(-88, -64), Vector2(176, 34))
		draw_rect(bubble, Color(0.92, 0.95, 0.88), true)
		draw_rect(bubble, Color(0.24, 0.29, 0.24), false, 1.0)
		draw_string(font, bubble.position + Vector2(8, 22), bubble_text, HORIZONTAL_ALIGNMENT_LEFT, bubble.size.x - 16, 11, Color(0.08, 0.12, 0.1))

func _room_rect(room_id: String) -> Rect2:
	var margin := 34.0
	var room_w := maxf(210.0, size.x * 0.31)
	var room_h := maxf(124.0, size.y * 0.27)
	var top_y := 64.0
	var bottom_y := maxf(top_y + room_h + 56.0, size.y - room_h - margin)
	var right_x := size.x - room_w - margin
	match room_id:
		"bridge":
			return Rect2(Vector2(margin, top_y), Vector2(room_w, room_h))
		"tactical":
			return Rect2(Vector2(right_x, top_y), Vector2(room_w, room_h))
		"engine":
			return Rect2(Vector2(margin, bottom_y), Vector2(room_w, room_h))
		"geladera":
			return Rect2(Vector2(right_x, bottom_y), Vector2(room_w, room_h))
		_:
			return Rect2(Vector2(margin, top_y), Vector2(room_w, room_h))

func _crew_position(data: Dictionary) -> Vector2:
	var room_id := String(data.get("room", "bridge"))
	var target_id := String(data.get("target_room", room_id))
	var start := _room_rect(room_id).get_center()
	var target := _room_rect(target_id).get_center()
	var progress := float(data.get("progress", 1.0))
	var pos := start.lerp(target, progress)
	var slot := int(data.get("slot", 0))
	return pos + Vector2((slot - 1) * 34, 6)

func _occupants_for_room(room_id: String) -> String:
	var names: Array[String] = []
	for crew_id in crew.keys():
		var data: Dictionary = crew[crew_id]
		var current_room := String(data.get("target_room", data.get("room", "bridge")))
		if current_room == room_id:
			names.append(String(data.get("short_name", data.get("name", crew_id))))
	return "Occupants: " + (", ".join(names) if names.size() > 0 else "None")
