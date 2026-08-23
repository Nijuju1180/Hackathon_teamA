class_name ResultJudge
extends RefCounted
## 削除ジャンル比率 vs 生存ジャンル比率からリザルトを判定する純粋ロジック。
## UI(result_overlay.gd)からもテスト(tests/test_result_judge.gd)からも
## 同じロジックを呼べるよう、シーンツリーに依存しない形にしてある。

const PRIORITY: Array[StringName] = [&"anti", &"fan", &"tease", &"neutral"]
const EPS := 1e-6

## 結果ごとの背景画像を個別指定しなかった場合のフォールバック。
## RESULT_TABLE の各エントリに "background" キーを足せば、その結果だけ差し替えられる。
const DEFAULT_BACKGROUND := "res://assets/nomalresult.PNG"

const RESULT_TABLE := {
	"no_action": {"title": "コメント無抵抗配信者",
		"description": "表現の自由が保たれた素晴らしい民主主義のチャンネル！
どんな言葉も飛び交うチャンネルはきっと自由で幸福でしょう、本当に？"},
	"delete_all": {"title": "全消し系配信者",
		"description": "画面の平和は守ったけど、コメント欄の存在意義は…?\n一人でゲームすれば？",
		"background": "res://assets/tako.PNG"},
	"balanced": {"title": "機械的配信者",
		"description": "どんなコメントにもフラットに向き合う、公平な配信スタイル。\nこれが真の平等でしょう"},

	[&"fan", &"tease"]:    {"title": "照れ隠し系配信者",
		"description": "褒められるとつい消してしまうのに、いじりコメントは平然と受け流す。\nふーん、可愛いじゃん"},
	[&"fan", &"anti"]:     {"title": "卑屈系配信者",
		"description": "応援コメントは恥ずかしくてつい消しちゃうのに、辛口コメントはなぜかスルー。\nこう聞くと可愛いけれど外から見たら普通にやばいのでやめた方がいいと思う。"},
	[&"fan", &"neutral"]:  {"title": "ま、別にあんたたちのことなんてどうでもいいんだけどね…",
		"description": "感情の起伏を見せたくないのかも。\nもー、恥ずかしがらなくていいって！"},

	[&"tease", &"fan"]:     {"title": "イジられ系配信者",
		"description": "からかい・いじりコメントは即削除、応援コメントは画面に残して大切にする。\nでもプライドが高くてイジられるのが苦手って一番イジられるタイプだと思いますよ。"},
	[&"tease", &"anti"]:    {"title": "冷笑系配信者?",
		"description": "イジり面白くないって…って思ってそうですよね（笑）",
		"background": "res://assets/glass.PNG"},
	[&"tease", &"neutral"]: {"title": "イジり撲滅委員会会長",
		"description": "いじりコメントを見つけたらすぐさま削除。\nイジりといじめは紙一重と言いますし、どんどん撲滅していきましょう。"},

	[&"anti", &"fan"]:     {"title": "厳格ハウスルール　独裁配信者",
		"description": "アンチコメントは全削除、あなたをハイパーヨイショ。\n気に入らないリスナーを追い出していった結果できるのはユートピアか、それとも電子上の地獄か？",
		"background": "res://assets/gennki.PNG"},
	[&"anti", &"tease"]:   {"title": "ゆるキャラ系配信者",
		"description": "イジりは笑って、批判は消す。\n過ごしやすそうなチャンネルだ…。",
		"background": "res://assets/mascot.PNG"},
	[&"anti", &"neutral"]: {"title": "正しい…",
		"description": "批判コメントはきっちり削除、当たり障りのないコメントはそのまま流す。\n正しい…"},

	[&"neutral", &"fan"]:   {"title": "コメントクリッカー",
		"description": "意味のないコメントをよく消す。\nコメントを消すことほど楽しいことはない。"},
	[&"neutral", &"tease"]: {"title": "自虐系コメディで売っています",
		"description": "当たり障りないコメントをぽちぽち。\nイジりコメントは残す。計算したイジりコメディ。",
		"background": "res://assets/zuko.PNG"},
	[&"neutral", &"anti"]:  {"title": "殺す気で来い",
		"description": "殺意を感じないコメントは一刀両断。\nリスナーなら本気を見せてみろ",
		"background": "res://assets/man.PNG"},
}


## deleted_counts/survived_counts (StringName->int) から判定結果({title, description})を返す。
## UI・シーンツリーに一切依存しない静的関数なので、インスタンス化不要でテストできる。
static func judge(deleted_counts: Dictionary, survived_counts: Dictionary) -> Dictionary:
	var total_deleted := 0
	for v in deleted_counts.values():
		total_deleted += v
	var total_survived := 0
	for v in survived_counts.values():
		total_survived += v

	if total_deleted == 0:
		return _resolve(RESULT_TABLE["no_action"])
	if total_survived == 0:
		return _resolve(RESULT_TABLE["delete_all"])

	var best_bias := -INF
	var worst_bias := INF
	var targeted: StringName = PRIORITY[0]
	var protected_g: StringName = PRIORITY[0]
	for g in PRIORITY:
		var d_ratio := float(deleted_counts.get(g, 0)) / float(total_deleted)
		var s_ratio := float(survived_counts.get(g, 0)) / float(total_survived)
		var bias := d_ratio - s_ratio
		if bias > best_bias + EPS:
			best_bias = bias
			targeted = g
		if bias < worst_bias - EPS:
			worst_bias = bias
			protected_g = g

	if targeted == protected_g:
		return _resolve(RESULT_TABLE["balanced"])
	return _resolve(RESULT_TABLE.get([targeted, protected_g], RESULT_TABLE["balanced"]))


## RESULT_TABLE の1エントリに、未指定なら DEFAULT_BACKGROUND を補って返す。
static func _resolve(entry: Dictionary) -> Dictionary:
	return {
		"title": entry.title,
		"description": entry.description,
		"background": entry.get("background", DEFAULT_BACKGROUND),
	}
