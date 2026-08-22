extends Control
## いいねボタン押下時にハートが画面下から浮かび上がる演出を出すレイヤー

const HEART_COLORS := [
	Color(1.0, 0.3, 0.4),
	Color(1.0, 0.55, 0.65),
	Color(1.0, 0.75, 0.8),
]


func spawn_heart() -> void:
	var heart := Label.new()
	heart.text = "❤"
	heart.add_theme_font_size_override("font_size", randi_range(28, 44))
	heart.add_theme_color_override("font_color", HEART_COLORS[randi() % HEART_COLORS.size()])
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heart)

	var start_x := randf_range(size.x * 0.55, size.x * 0.9)
	var start_y := size.y - 40.0
	heart.position = Vector2(start_x, start_y)

	var rise := randf_range(180.0, 260.0)
	var drift := randf_range(-40.0, 40.0)

	var tween := create_tween()
	tween.tween_property(heart, "position:y", start_y - rise, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(heart, "position:x", start_x + drift, 1.4).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(heart, "modulate:a", 0.0, 1.0).set_delay(0.6)
	tween.chain().tween_callback(heart.queue_free)
