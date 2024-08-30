extends Node2D

@onready var tilemap: TileMapLayer = $"../tilemap"

signal update_label

static var GOAL_STATE: Vector2i = Vector2i(4,1)

var state_tile_vecs: Array[Vector2i]
var V: Dictionary = {}
var pi: Dictionary = {}

func _ready() -> void:
	var pi_default = {
		Vector2i.UP:	.25,
		Vector2i.DOWN:	.25,
		Vector2i.RIGHT:	.25,
		Vector2i.LEFT:	.25,
	}
	# fill in all the values for V and pi
	for cell_vec: Vector2i in tilemap.get_used_cells():
		var cell_data: TileData = tilemap.get_cell_tile_data(cell_vec)
		if cell_data.get_custom_data('moveable'):
			V[cell_vec] = .0
			pi[cell_vec] = pi_default
			state_tile_vecs.append(cell_vec)
	
	state_tile_vecs.sort()
	
	# eval_onestep()
	policy_eval()
	emit_signal('update_label')
	
	print('AGENT READY')

func eval_onestep(gamma: float = .9) -> Dictionary:
	for state_tile_vec: Vector2i in state_tile_vecs:
		var state_tile_data: TileData = tilemap.get_cell_tile_data(state_tile_vec)
		
		if state_tile_vec == GOAL_STATE:
			V[state_tile_vec] = .0
			continue
		
		var action_probs: Dictionary = pi[state_tile_vec]
		var new_V = .0
		
		for action: Vector2i in action_probs:
			var next_state_tile_vec: Vector2i = state_tile_vec + action
			var next_state_tile_data = tilemap.get_cell_tile_data(next_state_tile_vec)
			
			var r: float
			if next_state_tile_data.get_custom_data('moveable'):
				r = next_state_tile_data.get_custom_data('reward')
			else:  # wall or immovable
				r = state_tile_data.get_custom_data('reward')
				next_state_tile_vec = state_tile_vec
			
			var action_prob: float = action_probs[action]
			# 당분간은 '다음 상태'만으로 보상값을 결정. 책에서 'GridWorld.reward()' 바꾼다면 이 파트 바꿔야함
			new_V += action_prob * (r + gamma * V[next_state_tile_vec])
		
		V[state_tile_vec] = new_V
	
	return V

func policy_eval(gamma: float = .9, thresh: float = .001) -> Dictionary:
	var count = 1
	while true:
		var old_V: Dictionary = V.duplicate(true)
		V = eval_onestep(gamma)
		
		var delta: float = .0
		for state in V:
			var t: float = abs(V[state] - old_V[state])
			if delta < t:
				delta = t
			
		if delta < thresh:
			break
		
		count += 1
	
	return V

################################################################################

var movements_kb = {
	'ui_up': Vector2i.UP,
	'ui_down': Vector2i.DOWN,
	'ui_right': Vector2i.RIGHT,
	'ui_left': Vector2i.LEFT,
}

func _unhandled_input(event: InputEvent) -> void:
	for movement: StringName in movements_kb.keys():
		if event.is_action_pressed(movement):
			move(movement)

func move(movement: StringName) -> void:
	# coords relative to the tilemap!
	var curr_tile: Vector2i = tilemap.local_to_map(global_position)
	var next_tile: Vector2i = curr_tile + movements_kb[movement]
	# check if moveable
	if state_tile_vecs.has(next_tile):
		global_position = tilemap.map_to_local(next_tile)
