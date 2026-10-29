class_name PetState
extends RefCounted
## Integral Buddy companion: needs, wallet, inventory, growth and study stats.

signal changed
signal grew(stage_index: int)

const STAGES := [
	{"name": "Sprout", "xp": 0, "art": "stage1"},
	{"name": "Explorer", "xp": 150, "art": "stage2"},
	{"name": "Scholar", "xp": 400, "art": "stage3"},
]
const GROW_NEED_THRESHOLD := 40.0
const FULLNESS_DECAY_SECONDS := 20.0
const JOY_DECAY_SECONDS := 26.0

const ITEMS := {
	"apple": {"name": "Crunchy Apple", "kind": "food", "price": 6, "fullness": 18, "joy": 0, "xp": 2, "icon": "res://assets/art/items/apple.png"},
	"muffin": {"name": "Berry Muffin", "kind": "food", "price": 14, "fullness": 35, "joy": 4, "xp": 3, "icon": "res://assets/art/items/muffin.png"},
	"pie": {"name": "Golden Berry Pie", "kind": "food", "price": 26, "fullness": 60, "joy": 10, "xp": 5, "icon": "res://assets/art/items/pie.png"},
	"ball": {"name": "Bouncy Ball", "kind": "toy", "price": 8, "fullness": 0, "joy": 18, "xp": 2, "icon": "res://assets/art/items/ball.png"},
	"yarn": {"name": "Yarn Ball", "kind": "toy", "price": 16, "fullness": -2, "joy": 35, "xp": 3, "icon": "res://assets/art/items/yarn.png"},
	"kite": {"name": "Star Kite", "kind": "toy", "price": 30, "fullness": -4, "joy": 60, "xp": 5, "icon": "res://assets/art/items/kite.png"},
}
const ITEM_ORDER := ["apple", "muffin", "pie", "ball", "yarn", "kite"]

var pet_name := "Inty"
var fullness := 70.0
var joy := 70.0
var xp := 0
var coins := 20
var stage := 0
var inventory := {"apple": 1, "muffin": 0, "pie": 0, "ball": 1, "yarn": 0, "kite": 0}
var solved := {}
var attempts := 0
var streak := 0
var best_streak := 0
var best_catch := 0
var best_pour := 0
var last_seen := 0
var tutorial_done := false
var _fullness_clock := 0.0
var _joy_clock := 0.0


static func create(name: String) -> PetState:
	var state := PetState.new()
	state.pet_name = sanitize_name(name)
	state.last_seen = int(Time.get_unix_time_from_system())
	return state


static func sanitize_name(value: String) -> String:
	var clean := value.replace("\n", " ").replace("\r", " ").strip_edges()
	if clean.is_empty():
		clean = "Inty"
	return clean.left(14)


func to_dict() -> Dictionary:
	return {
		"name": pet_name, "fullness": snappedf(fullness, 0.1), "joy": snappedf(joy, 0.1), "xp": xp, "coins": coins,
		"stage": stage, "inventory": inventory.duplicate(), "solved": solved.duplicate(), "attempts": attempts,
		"streak": streak, "best_streak": best_streak, "best_catch": best_catch, "best_pour": best_pour,
		"last_seen": int(Time.get_unix_time_from_system()), "tutorial_done": tutorial_done,
	}


static func from_dict(data: Dictionary) -> PetState:
	var state := PetState.new()
	state.pet_name = sanitize_name(str(data.get("name", "Inty")))
	state.fullness = clampf(float(data.get("fullness", 70.0)), 0.0, 100.0)
	state.joy = clampf(float(data.get("joy", 70.0)), 0.0, 100.0)
	state.xp = maxi(0, int(data.get("xp", 0)))
	state.coins = clampi(int(data.get("coins", 20)), 0, 999999)
	state.stage = clampi(int(data.get("stage", 0)), 0, STAGES.size() - 1)
	var inv: Variant = data.get("inventory", {})
	if inv is Dictionary:
		for id: String in ITEM_ORDER:
			state.inventory[id] = clampi(int((inv as Dictionary).get(id, 0)), 0, 99)
	var solved_data: Variant = data.get("solved", {})
	if solved_data is Dictionary:
		for key: Variant in solved_data:
			state.solved[str(key)] = maxi(0, int(solved_data[key]))
	state.attempts = maxi(0, int(data.get("attempts", 0)))
	state.streak = maxi(0, int(data.get("streak", 0)))
	state.best_streak = maxi(0, int(data.get("best_streak", 0)))
	state.best_catch = maxi(0, int(data.get("best_catch", 0)))
	state.best_pour = maxi(0, int(data.get("best_pour", 0)))
	state.last_seen = maxi(0, int(data.get("last_seen", 0)))
	state.tutorial_done = bool(data.get("tutorial_done", false))
	return state


## Gentle decay while you were away: capped so the pet is never neglected into despair.
func apply_offline(now_unix: int) -> Dictionary:
	if last_seen <= 0:
		last_seen = now_unix
		return {"minutes": 0}
	var elapsed := clampi(now_unix - last_seen, 0, 8 * 3600)
	last_seen = now_unix
	var lost_full := minf(elapsed / 240.0, 40.0)
	var lost_joy := minf(elapsed / 300.0, 40.0)
	fullness = maxf(minf(fullness, 10.0), fullness - lost_full)
	joy = maxf(minf(joy, 10.0), joy - lost_joy)
	changed.emit()
	return {"minutes": elapsed / 60}


func tick(delta: float) -> void:
	_fullness_clock += delta
	_joy_clock += delta
	var dirty := false
	while _fullness_clock >= FULLNESS_DECAY_SECONDS:
		_fullness_clock -= FULLNESS_DECAY_SECONDS
		fullness = maxf(0.0, fullness - 1.0)
		dirty = true
	while _joy_clock >= JOY_DECAY_SECONDS:
		_joy_clock -= JOY_DECAY_SECONDS
		joy = maxf(0.0, joy - 1.0)
		dirty = true
	if dirty:
		changed.emit()


func stage_info() -> Dictionary:
	return STAGES[stage]


func art_key() -> String:
	return str(STAGES[stage].art)


func is_final_stage() -> bool:
	return stage >= STAGES.size() - 1


## 0..1 progress toward the next stage (1.0 at the final stage).
func stage_progress() -> float:
	if is_final_stage():
		return 1.0
	var lo := int(STAGES[stage].xp)
	var hi := int(STAGES[stage + 1].xp)
	return clampf(float(xp - lo) / float(hi - lo), 0.0, 1.0)


func next_stage_xp() -> int:
	return int(STAGES[stage].xp) if is_final_stage() else int(STAGES[stage + 1].xp)


func is_ready_but_needs_care() -> bool:
	return not is_final_stage() and xp >= next_stage_xp() and not _needs_met()


func _needs_met() -> bool:
	return fullness >= GROW_NEED_THRESHOLD and joy >= GROW_NEED_THRESHOLD


func mood() -> String:
	if fullness < 30.0 and joy < 30.0:
		return "sad"
	if fullness < 30.0:
		return "hungry"
	if joy < 30.0:
		return "bored"
	if fullness >= 70.0 and joy >= 70.0:
		return "delighted"
	return "content"


func looks_happy() -> bool:
	return mood() in ["content", "delighted"]


func add_coins(amount: int) -> void:
	coins = clampi(coins + amount, 0, 999999)
	changed.emit()


func add_joy(amount: float) -> void:
	joy = clampf(joy + amount, 0.0, 100.0)
	changed.emit()
	try_grow()


func add_fullness(amount: float) -> void:
	fullness = clampf(fullness + amount, 0.0, 100.0)
	changed.emit()
	try_grow()


func gain_xp(amount: int) -> bool:
	xp = maxi(0, xp + amount)
	changed.emit()
	return try_grow()


func try_grow() -> bool:
	if is_final_stage() or xp < next_stage_xp() or not _needs_met():
		return false
	stage += 1
	changed.emit()
	grew.emit(stage)
	return true


func can_buy(id: String) -> bool:
	return ITEMS.has(id) and coins >= int(ITEMS[id].price)


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	coins -= int(ITEMS[id].price)
	inventory[id] = mini(int(inventory.get(id, 0)) + 1, 99)
	changed.emit()
	return true


func item_count(id: String) -> int:
	return int(inventory.get(id, 0))


## Returns {} if unavailable, else the applied item definition.
func use_item(id: String) -> Dictionary:
	if item_count(id) <= 0 or not ITEMS.has(id):
		return {}
	var item: Dictionary = ITEMS[id]
	inventory[id] = item_count(id) - 1
	fullness = clampf(fullness + float(item.fullness), 0.0, 100.0)
	joy = clampf(joy + float(item.joy), 0.0, 100.0)
	xp += int(item.xp)
	changed.emit()
	try_grow()
	return item


func record_attempt(topic_id: String, correct: bool) -> void:
	attempts += 1
	if correct:
		solved[topic_id] = int(solved.get(topic_id, 0)) + 1
		streak += 1
		best_streak = maxi(best_streak, streak)
	else:
		streak = 0
	changed.emit()


func total_solved() -> int:
	var total := 0
	for value: Variant in solved.values():
		total += int(value)
	return total


func speech() -> String:
	if is_ready_but_needs_care():
		return "I feel ready to grow… but I need a snack and some play first!"
	match mood():
		"sad":
			return "I'm hungry and a bit lonely… could we study for a treat?"
		"hungry":
			return "My tummy is rumbling! Solve a challenge to earn a snack?"
		"bored":
			return "Let's play a mini-game or bring out a toy!"
		"delighted":
			return "I'm so happy! Ready for a harder integral?"
	return "Hi! Every integral you solve helps me grow."
