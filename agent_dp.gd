extends AgentsTilemap

func _ready() -> void:
	bt_policy.connect('button_down', func(): run_agent(policy_iter))
	bt_value.connect('button_down', func(): run_agent(value_iter))
	reset_bt.connect('button_down', reset_vars)
	
	# fill in all the values for V and pi
	for cell_vec: Vector2i in tilemap.get_used_cells():
		var cell_data: TileData = tilemap.get_cell_tile_data(cell_vec)
		if cell_data.get_custom_data('moveable'):
			V[cell_vec] = .0
			pi[cell_vec] = pi_default
			state_tile_vecs.append(cell_vec)
	
	state_tile_vecs.sort()
	
	# eval_onestep()
	# policy_eval()
	# policy_iter()
	# emit_signal('update_label')
	
	print('AGENT READY')

func reset_vars():
	for cell_vec: Vector2i in tilemap.get_used_cells():
		var cell_data: TileData = tilemap.get_cell_tile_data(cell_vec)
		if cell_data.get_custom_data('moveable'):
			V[cell_vec] = .0
			pi[cell_vec] = pi_default
			state_tile_vecs.append(cell_vec)
	
	state_tile_vecs.sort()


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
	
	print('policy_eval count: ', count)
	return V

func argmax(dictionary: Dictionary) -> Variant:
	var max_key = null
	var max_value = -INF
	
	for key in dictionary.keys():
		var value = dictionary[key]
		if value > max_value:
			max_value = value
			max_key = key
	
	return max_key

func greedy_policy(gamma: float) -> Dictionary:
	var _pi: Dictionary = {}
	
	for state_tile_vec in state_tile_vecs:
		var action_values: Dictionary = {}
		
		for action: Vector2i in pi_default:
			var next_state_tile_vec: Vector2i = state_tile_vec + action
			var next_state_tile_data: TileData = tilemap.get_cell_tile_data(next_state_tile_vec)
			
			var r: float
			if next_state_tile_data.get_custom_data('moveable'):
				r = next_state_tile_data.get_custom_data('reward')
			else:  # wall or immovable
				r = next_state_tile_data.get_custom_data('reward')
				next_state_tile_vec = state_tile_vec
			
			var value: float = r + gamma * V[next_state_tile_vec]
			action_values[action] = value
		
		var max_action: Vector2i = argmax(action_values)
		var action_probs: Dictionary = {
			Vector2i.UP:	0,
			Vector2i.DOWN:	0,
			Vector2i.RIGHT:	0,
			Vector2i.LEFT:	0,
		}
		action_probs[max_action] = 1.0
		_pi[state_tile_vec] = action_probs
	
	return _pi

func policy_iter(gamma: float = .9, thresh: float = .001) -> Dictionary:
	var count: int = 1
	while true:
		V = policy_eval(gamma, thresh)
		var new_pi = greedy_policy(gamma)
		
		count += 1
		if new_pi == pi:
			break
		pi = new_pi
	
	print('policy_iter count: ', count)
	return pi

func value_iter_onestep(gamma: float = .9) -> Dictionary:
	for state in state_tile_vecs:
		if state == GOAL_STATE:
			V[state] = .0
			continue
		
		var action_probs: Dictionary = pi[state]
		
		var action_values = []
		for action: Vector2i in action_probs:
			var next_state: Vector2i = state + action
			var next_state_tile_data = tilemap.get_cell_tile_data(next_state)
			
			var r: float
			if next_state_tile_data.get_custom_data('moveable'):
				r = next_state_tile_data.get_custom_data('reward')
			else:  # wall or immovable
				r = tilemap.get_cell_tile_data(state).get_custom_data('reward')
				next_state = state
			
			var value: float = r + gamma * V[next_state]
			action_values.append(value)
		
		V[state] = action_values.max()
	
	return V

func value_iter(gamma: float = .9, thresh: float = .001) -> Dictionary:
	var counter: int = 1
	while true:
		var old_V: Dictionary = V.duplicate(true)
		V = value_iter_onestep(gamma)
		
		var delta = .0
		for state: Vector2i in V:
			var t = abs(V[state] - old_V[state])
			if delta < t:
				delta = t
			
		if delta < thresh:
			break
	
	return V

func run_agent(iter_func: Callable) -> void:
	print('running agent!')
	move_to(START_STATE)
	iter_func.call()
	emit_signal('update_label')
	
	var curr_tile: Vector2i = tilemap.local_to_map(global_position)
	
	while curr_tile != GOAL_STATE:
		await get_tree().create_timer(.25).timeout 
		var move_dir: Vector2i = argmax(pi[curr_tile])
		move(move_dir)
		curr_tile += move_dir
	
	print('done!')

################################################################################

func _unhandled_input(event: InputEvent) -> void:
	for movement: StringName in movements_kb.keys():
		if event.is_action_pressed(movement):
			move(movements_kb[movement])

func move(movement: Vector2i) -> void:
	# coords relative to the tilemap!
	var curr_tile: Vector2i = tilemap.local_to_map(global_position)
	var next_tile: Vector2i = curr_tile + movement
	# check if moveable
	if state_tile_vecs.has(next_tile):
		global_position = tilemap.map_to_local(next_tile)

func move_to(coords: Vector2i) -> void:
	# coords relative to the tilemap!
	var next_tile: Vector2i = coords
	# check if moveable
	if state_tile_vecs.has(next_tile):
		global_position = tilemap.map_to_local(next_tile)
