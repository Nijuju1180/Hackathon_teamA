class_name FlowingComment
extends Label
## 画面を右から左へ流れる1件のコメント。
## 生成・レーン割り当ては CommentLayer が行う。

signal exited(comment: FlowingComment)

## 種別。"fan" / "tease" / "anti" / "neutral"。ゲーム側の判定に使う。
var comment_type: StringName = &"neutral"
## 秒あたりの移動px。長さによらず横断時間が一定になるよう CommentLayer が決める。
var speed: float = 0.0


func _process(delta: float) -> void:
	position.x -= speed * delta
	if position.x + size.x < 0.0:
		exited.emit(self)
		queue_free()
