class_name ResultJudge
extends RefCounted
## 削除ジャンル比率 vs 生存ジャンル比率からリザルトを判定する純粋ロジック。
## UI(result_overlay.gd)からもテスト(tests/test_result_judge.gd)からも
## 同じロジックを呼べるよう、シーンツリーに依存しない形にしてある。

const PRIORITY: Array[StringName] = [&"anti", &"fan", &"tease", &"neutral"]
const EPS := 1e-6

const RESULT_TABLE := {
	"no_action": {"title": "コメント無抵抗配信者",
		"description": "1つもコメントを消さなかった、驚異のスルースキル。\n良くも悪くも、何が来ても動じないメンタルの持ち主。"},
	"delete_all": {"title": "全消し系配信者",
		"description": "流れてきたコメントを一つ残らず削除した、まさかの完全排除タイプ。\n画面の平和は守ったけど、コメント欄の存在意義は…?"},
	"balanced": {"title": "バランス系配信者",
		"description": "消したコメントも残したコメントも、ジャンルの偏りなし。\nどんなコメントにもフラットに向き合う、公平な配信スタイル。"},

	[&"fan", &"tease"]:    {"title": "照れ隠し系配信者",
		"description": "褒められるとつい消してしまうのに、いじりコメントは平然と受け流す。\n打たれ強いのに褒め言葉には弱いタイプ。"},
	[&"fan", &"anti"]:     {"title": "卑屈系配信者",
		"description": "応援コメントは恥ずかしくてつい消しちゃうのに、辛口コメントはなぜかスルー。\nポジティブに弱く、ネガティブに強いメンタル。"},
	[&"fan", &"neutral"]:  {"title": "感情を出したくない系配信者",
		"description": "応援コメントには反応して消してしまうのに、当たり障りのないコメントには無関心。\n感情の起伏を見せたくないのかも。"},

	[&"tease", &"fan"]:     {"title": "いじりを許さない完璧主義配信者",
		"description": "からかい・いじりコメントは即削除、応援コメントは画面に残して大切にする。\nプライドが高く、弄られるのが大の苦手。"},
	[&"tease", &"anti"]:    {"title": "ノリツッコミ拒否系配信者",
		"description": "笑いのいじりコメントには過敏に反応して消すのに、本気の批判コメントは意外と読み流す。\n冗談に弱く、本音には強い。"},
	[&"tease", &"neutral"]: {"title": "いじり撲滅系配信者",
		"description": "いじりコメントを見つけたらすぐさま削除。\n当たり障りのないコメントには一切手を出さない、徹底したこだわり。"},

	[&"anti", &"fan"]:     {"title": "アンチを狩り、ファンを守る配信者",
		"description": "批判コメントは容赦なく削除、応援コメントは画面に残して大切にする。\nファン想いのメンタル最強配信者。"},
	[&"anti", &"tease"]:   {"title": "いじりには寛容、アンチには容赦なし配信者",
		"description": "ちょっとしたいじりコメントは笑って流すけど、本気の批判コメントは見つけ次第削除。\nノリは良いのに芯はブレない。"},
	[&"anti", &"neutral"]: {"title": "健全な運営配信者",
		"description": "批判コメントはきっちり削除、当たり障りのないコメントはそのまま流す。\nバランス感覚に優れた模範的チャンネル運営。"},

	[&"neutral", &"fan"]:   {"title": "とにかくクリックしたい配信者",
		"description": "特に意味のないコメントまでついクリックしてしまうタイプ。\nでも応援コメントだけはちゃんと画面に残しておく優しさも。"},
	[&"neutral", &"tease"]: {"title": "暇つぶし系配信者",
		"description": "当たり障りのないコメントを手癖でどんどん消していくのに、いじりコメントには反応せず放置。\n何を狙っているのか読めないタイプ。"},
	[&"neutral", &"anti"]:  {"title": "危機管理ゆるめ配信者",
		"description": "当たり障りのないコメントは次々消していくのに、批判コメントはなぜか見逃しがち。\n肝心なところが甘いタイプ。"},
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
		return RESULT_TABLE["no_action"]
	if total_survived == 0:
		return RESULT_TABLE["delete_all"]

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
		return RESULT_TABLE["balanced"]
	return RESULT_TABLE.get([targeted, protected_g], RESULT_TABLE["balanced"])
