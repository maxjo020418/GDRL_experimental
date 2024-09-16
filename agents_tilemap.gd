extends Sprite2D
class_name AgentsTilemap

signal update_label

@onready var map: TileMapLayer = $TileMapEnv
@onready var _buttons: Array[Node] = $BTGroup.get_children()

var buttons: Dictionary  # {<StringName name of node>: Button}

# dicts are mapped as - { <Vector2i in tilemap space> : value }
# singleton style value used
var V: Dictionary	# Value function results
var pi: Dictionary	# pi - policy values

# all possible default movements in this env.
var pi_default = {
	Vector2i.UP:	.25,
	Vector2i.DOWN:	.25,
	Vector2i.RIGHT:	.25,
	Vector2i.LEFT:	.25,
}

func _ready() -> void:
	V = {}
	pi = pi_default
	
	for button: Button in _buttons:
		buttons[button.name] = button
	
	print('AgentsTilemap READY')

###############################################
# interface(?) stuff for the Agent classes
# following functions needs to be overidden
# if not overidden(implemented), will raise an error
###############################################

func foo():  # example in case of future use
	push_error('Interface `foo` was not implemented!')

#######################################
# functions for controlling the sprite
#######################################

# The 'move' functions below are purely for rendering purposes
# it does not put the calculations into account!

func move(movement: Vector2i) -> void:
	# coords relative to the tilemap!
	var curr_tile: Vector2i = map.local_to_map(global_position)
	var next_tile: Vector2i = curr_tile + movement
	
	# check if moveable
	if map.is_moveable(next_tile):
		global_position = map.map_to_local(next_tile)
	else:
		print('Bounced off wall')

func move_to(coords: Vector2i) -> void:
	# coords relative to the tilemap!
	var next_tile: Vector2i = coords
	
	# check if moveable
	if map.is_moveable(next_tile):
		global_position = map.map_to_local(next_tile)
	else:
		push_warning('Cannot move to ' + str(next_tile))

# manual movements enabled for debugging purposes...
func _unhandled_input(event: InputEvent) -> void:
	var movements_kb = {
		'ui_up': Vector2i.UP,
		'ui_down': Vector2i.DOWN,
		'ui_right': Vector2i.RIGHT,
		'ui_left': Vector2i.LEFT,
	}
	for movement: StringName in movements_kb.keys():
		if event.is_action_pressed(movement):
			move(movements_kb[movement])

# reset/clear all the variables
# resets the sprite to start location
func cleanup() -> void:
	_ready()  # resets variable -> NOTE: might have side effects in some cases
	move_to(map.START_STATE)
