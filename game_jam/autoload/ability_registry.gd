extends Node
## Maps ability ids to AbilityData + handler and runs spoken words.
## Cooldowns live here so any UI can read them.

const ABILITY_PATHS: PackedStringArray = [
	"res://data/abilities/open.tres",
	"res://data/abilities/push.tres",
	"res://data/abilities/remember.tres",
	"res://data/abilities/hush.tres",
	"res://data/abilities/wait.tres",
	"res://data/abilities/help.tres",
	"res://data/abilities/hide.tres",
]

var _abilities: Dictionary = {}
var _handlers: Dictionary = {}
var _cooldowns: Dictionary = {}


func _ready() -> void:
	for path in ABILITY_PATHS:
		register(load(path) as AbilityData)
	EventBus.game_reset.connect(reset_cooldowns)


func reset_cooldowns() -> void:
	_cooldowns.clear()


func register(ability: AbilityData) -> void:
	if ability == null or ability.handler == null:
		push_error("AbilityRegistry: ability missing data or handler")
		return
	var handler: AbilityHandler = ability.handler.new() as AbilityHandler
	handler.ability = ability
	_abilities[ability.id] = ability
	_handlers[ability.id] = handler


func get_ability(ability_id: StringName) -> AbilityData:
	return _abilities.get(ability_id) as AbilityData


func cooldown_left(ability_id: StringName) -> float:
	return _cooldowns.get(ability_id, 0.0)


## 1.0 right after use, 0.0 when ready.
func cooldown_ratio(ability_id: StringName) -> float:
	var ability: AbilityData = get_ability(ability_id)
	if ability == null or ability.cooldown <= 0.0:
		return 0.0
	return cooldown_left(ability_id) / ability.cooldown


func _process(delta: float) -> void:
	for ability_id in _cooldowns.keys():
		_cooldowns[ability_id] = maxf(0.0, _cooldowns[ability_id] - delta)
		if _cooldowns[ability_id] == 0.0:
			_cooldowns.erase(ability_id)


## Speaks `bubble` at `target` (null = into the room). A wrong word never
## breaks anything: the target shudders and the player shows "?".
func speak(bubble: BubbleData, target: Interactable) -> bool:
	var ability: AbilityData = get_ability(bubble.ability_id)
	var ok: bool = false
	if ability != null and cooldown_left(ability.id) <= 0.0:
		var handler: AbilityHandler = _handlers[ability.id]
		match ability.target_type:
			AbilityData.TargetType.INTERACTABLE:
				ok = target != null and target.accepts(ability.id) and handler.execute(bubble, target, get_tree())
			AbilityData.TargetType.ROOM:
				ok = handler.execute(bubble, null, get_tree())

	var target_id: StringName = target.data.id if target != null else &""
	if ok:
		if ability.cooldown > 0.0:
			_cooldowns[ability.id] = ability.cooldown
		EventBus.ability_used.emit(bubble, target_id)
		if bubble.consumable:
			GameState.remove_bubble(bubble)
	else:
		if target != null:
			target.react_wrong()
		EventBus.ability_failed.emit(bubble, target_id)
	return ok
