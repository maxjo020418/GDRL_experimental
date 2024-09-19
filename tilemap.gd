extends TileMapLayer

@onready var agents: Array[Node] = %agents_tilemap.get_children()

# a dict of TileData, mapped by Vector2i/coords
# stores all the (custom)data for each tile
# if Vector2i/coord key is not in it, consider it out of bounds
var tile_data: Dictionary  # {Vector2i : TileData}

# needs seperate start/end state for starting and ending train/run process
static var GOAL_STATE: Vector2i = Vector2i(4, 1)
static var START_STATE: Vector2i = Vector2i(1, 1)

func _ready() -> void:
	var create_label = \
	func create_label() -> Label:
		var label: Label = Label.new()
		var ls: LabelSettings = LabelSettings.new()
		label.visible = true
		label.z_index = 100  # on top of everything
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		ls.font_size = 10
		label.label_settings = ls
		
		return label
	
	for cell_vec: Vector2i in get_used_cells():
		var cell_tile_data: TileData = get_cell_tile_data(cell_vec)
		tile_data[cell_vec] = cell_tile_data
		if cell_tile_data.get_custom_data('moveable'):
			# give labels and according metadata(cell_vec)
			var label: Label = create_label.call()
			label.set_meta('cell_vec', cell_vec)
			label.global_position = map_to_local(cell_vec)
			add_child(label)
	
	# connecting all the needed signals - for receiving
	for agent in agents:
		agent.connect('update_label', update_label)
		# other signals...
	
	print('TILEMAP READY')


func update_label(V: Dictionary) -> void:  # dict needs to be {Vector2i : val}
	var roundn = \
	func round_to_dec(num, digit):
		return round(num * pow(10.0, digit)) / pow(10.0, digit)
	for label: Node in get_children():
		var cell_vec: Vector2i = label.get_meta('cell_vec')
		label.text = str(cell_vec, '\n', roundn.call(V[cell_vec], 2))


func is_moveable(coords: Vector2i) -> bool:
	if coords in tile_data:
		return tile_data[coords].get_custom_data('moveable')
	else:
		push_error(str(coords), ' is out of bounds!')
		return false

func get_next_reward(current_coord: Vector2i, movement: Vector2i) -> float:
	var next_coord: Vector2i = current_coord + movement
	if next_coord in tile_data:
		if is_moveable(next_coord):
			return tile_data[next_coord].get_custom_data('reward')
		else:
			# print('Bouncing from obstacle! returning from ', next_coord)
			return tile_data[current_coord].get_custom_data('reward')
	else:
		push_error(str(next_coord), ' does not exist in the map!')
		return 0
