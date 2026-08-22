class_name FlowingComment
extends Label
## 画面を右から左へ流れる1件のコメント。
## 生成・レーン割り当ては CommentLayer が行う。

signal exited(comment: FlowingComment)
## クリックされて途中で消されたときに発火する(画面外に流れ切っただけの場合は発火しない)
signal dismissed(comment: FlowingComment)

## 種別。"fan" / "tease" / "anti" / "neutral"。ゲーム側の判定に使う。
var comment_type: StringName = &"neutral"
## 秒あたりの移動px。長さによらず横断時間が一定になるよう CommentLayer が決める。
var speed: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	position.x -= speed * delta
	if position.x + size.x < 0.0:
		exited.emit(self)
		queue_free()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		dismissed.emit(self)
		exited.emit(self)
		queue_free()
