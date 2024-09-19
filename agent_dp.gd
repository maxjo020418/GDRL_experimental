extends AgentsTilemap

# Dynamic Programming based RL agent model

func _ready() -> void:
	super._ready()
	
	var bt: Button = buttons['BTDP']
	var step_bt: Button = buttons['one_step']
	bt.connect('button_down', run_agent)
	step_bt.connect('button_down', run_agent_onestep)
	
	print('AGENT_DP READY')


func run_agent():
	var gamma = .9
	value_iter(gamma)
	update_label.emit(V)

func run_agent_onestep():
	var gamma = .9
	value_iter_onestep(gamma)
	update_label.emit(V)

####################################################
# NOTE: All funcitons below are in-place functions!
####################################################

func value_iter(gamma, thresh=.001):
	while true:
		var old_V: Dictionary = V.duplicate(true)
		value_iter_onestep(gamma)
		
		var delta = 0.0
		for state: Vector2i in V:
			var t: float = abs(V[state] - old_V[state])
			if delta < t:
				delta = t
		
		if delta < thresh:
			break


func value_iter_onestep(gamma) -> void:
	for state: Vector2i in map.tile_data:
		if not map.is_moveable(state):
			continue
		
		if state == map.GOAL_STATE:
			V[state] = 0
			continue
		
		var action_values: Array[float] = []
		for action: Vector2i in movements_default:
			# var next_state: Vector2i = state + action
			var r: float = map.get_next_reward(state, action)
			var value: float = r + gamma * V[state + action]
			action_values.append(value)
		
		V[state] = action_values.max()
