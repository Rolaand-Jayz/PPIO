class_name PortraitChip
extends Control
## Party portrait proxy chip — drawn deterministically (no image assets).
## Distinct silhouette shape per toy + initial letter, with active/acted/down
## states that are distinguishable by shape and brightness, not color alone.

var unit_id := ""
var active := false
var act_state := "ready"  # ready | acted | down

const COLORS := {
	"jayze": Color(0.89, 0.65, 0.23),
	"kip": Color(0.16, 0.73, 0.78),
	"rallo": Color(0.86, 0.38, 0.32),
	"crusher": Color(0.53, 0.41, 0.73),
}

func _draw() -> void:
	var base: Color = COLORS.get(unit_id, Color.GRAY)
	var r := Rect2(Vector2.ZERO, size)
	var dim := 0.45 if act_state == "acted" else (0.25 if act_state == "down" else 1.0)
	var fill := base * dim
	fill.a = 1.0
	draw_rect(r, fill, true)
	var border := Color(1, 0.92, 0.55) if active else Color(0, 0, 0, 0.4)
	draw_rect(r, border, false, 3.0 if active else 2.0)
	# silhouette glyphs (shape-coded roles)
	var c := Vector2(size.x * 0.5, size.y * 0.58)
	var fg := Color(0.08, 0.09, 0.12, 0.85)
	match unit_id:
		"jayze":  # sword: triangle up
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -11), c + Vector2(5, 4), c + Vector2(-5, 4)]), fg)
			draw_rect(Rect2(c + Vector2(-6, 4), Vector2(12, 3)), fg)
		"kip":  # car: body + wheels
			draw_rect(Rect2(c + Vector2(-11, -4), Vector2(22, 8)), fg)
			draw_circle(c + Vector2(-6, 5), 3.5, fg)
			draw_circle(c + Vector2(6, 5), 3.5, fg)
		"rallo":  # wings: two arcs
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), c + Vector2(-12, 4), c + Vector2(-2, 3)]), fg)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -8), c + Vector2(12, 4), c + Vector2(2, 3)]), fg)
		"crusher":  # shield: heavy cross plate
			draw_rect(Rect2(c + Vector2(-8, -8), Vector2(16, 16)), fg)
			draw_rect(Rect2(c + Vector2(-2, -8), Vector2(4, 16)), fill)
			draw_rect(Rect2(c + Vector2(-8, -2), Vector2(16, 4)), fill)
	var initial := unit_id.left(1).to_upper()
	var font := get_theme_default_font()
	if font != null:
		draw_string(font, Vector2(4, size.y - 4), initial, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.9))
