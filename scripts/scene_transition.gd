extends CanvasLayer
## 画面遷移のフェード演出。Autoload「SceneTransition」として常駐する。
## シーンを切り替えるときは get_tree().change_scene_to_file() を直接呼ばず、
## change_scene() / reload_scene() を使う。

## 片道(暗転 or 明転)にかける秒数
const FADE_SECONDS := 0.35

var _fade_rect: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	# ゲーム側がポーズしても遷移が止まらないようにする
	process_mode = Node.PROCESS_MODE_ALWAYS
	# HUDなど他のCanvasLayerより必ず手前に出す
	layer = 128

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	_fade_rect.visible = false
	add_child(_fade_rect)


func change_scene(path: String) -> void:
	await _transition(func() -> int: return get_tree().change_scene_to_file(path), path)


func reload_scene() -> void:
	await _transition(func() -> int: return get_tree().reload_current_scene(), "(現在のシーン)")


## 暗転 → swap(シーン入れ替え) → 明転 の共通処理。
## swap は Error コードを返す Callable。
func _transition(swap: Callable, target: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	await _fade_to(1.0)
	var err: int = swap.call()
	if err == OK:
		await _wait_for_scene_swap()
	else:
		# 切り替えに失敗したら暗転したままにせず、元の画面に戻して原因を残す
		push_error("SceneTransition: シーンの切り替えに失敗しました target=%s error=%d" % [target, err])
	await _fade_to(0.0)

	_is_transitioning = false


## change_scene_to_file / reload_current_scene は実際の入れ替えを次フレームに遅らせるため、
## 新しいシーンが立ち上がるまで待ってから明転する。
func _wait_for_scene_swap() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _fade_to(alpha: float) -> void:
	_fade_rect.visible = true
	# フェード中は下のUIを触らせない(連打で二重遷移させない)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", alpha, FADE_SECONDS)
	await tween.finished

	if is_zero_approx(alpha):
		_fade_rect.visible = false
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
