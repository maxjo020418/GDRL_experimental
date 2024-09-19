extends AgentsTilemap

# Monte-Carlo based RL agent model

func _ready() -> void:
	super._ready()
	
	var bt: Button = buttons['BTMC']
	bt.connect('button_down', run_agent)
	
	print('AGENT_MC READY')


func run_agent():
	pass
