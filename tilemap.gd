extends TileMapLayer

@onready var agent: Node2D = $"../Agent"

func create_label() -> Label:
	var label: Label = Label.new()
	var ls: LabelSettings = LabelSettings.new()
	label.visible = true
	label.z_index = 100
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	ls.font_size = 10
	label.label_settings = ls
	
	return label

func _ready() -> void:
	agent.connect('update_label', update_label)
	
	for cell_vec: Vector2i in get_used_cells():
		var cell_data: TileData = get_cell_tile_data(cell_vec)
		if cell_data.get_custom_data('moveable'):
			var label: Label = create_label()
			label.text = str(cell_vec)
			label.set_meta('cell_vec', cell_vec)
			label.global_position = map_to_local(cell_vec)
			add_child(label)
	
	print('TILEMAP READY')

func update_label() -> void:
	for label: Label in get_children():
		var cell_vec: Vector2i = label.get_meta('cell_vec')
		label.text = str(round_to_dec(agent.V[cell_vec], 2), '\n', cell_vec)

func _process(delta: float) -> void:
	pass

func round_to_dec(num, digit):
		return round(num * pow(10.0, digit)) / pow(10.0, digit)
