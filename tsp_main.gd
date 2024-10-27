class_name TravelingSalesmanProblemMain extends Node

#region @onready vars
@onready var left_graph:Control = $Control/HSplitContainer/HSplitContainer/LeftPanel/Graph
@onready var right_graph:Control = $Control/HSplitContainer/HSplitContainer/RightPanel/Graph

@onready var graph_selection_spinbox:SpinBox = $Control/HSplitContainer/UI/MarginContainer/VBoxContainer/SpinBoxGraph
@onready var graph_size_spinbox:SpinBox = $Control/HSplitContainer/UI/MarginContainer/VBoxContainer/SpinBoxSize
@onready var graph_seed_spinbox:SpinBox = $Control/HSplitContainer/UI/MarginContainer/VBoxContainer/SpinBoxSeed
#endregion

const VERTEX:Resource = preload("res://vertex.tscn")
const EDGE:Resource = preload("res://edge.tscn")

const panel_margin:Vector2 = Vector2(10,10)

@export_group("Graph Settings")
@export var vertex_spacing:int = 150

@export var current_graph:Control = right_graph
@export var custom_seed:int = 18
@export var graph_size:int = 5

var panel_size:Vector2 # Panel size gets calculated, dont set
var rng:RandomNumberGenerator = RandomNumberGenerator.new()
var edge_weight_matrix = []
var new_graph:bool = false


func _ready() -> void:
	panel_size = DisplayServer.window_get_size()
	panel_size.x /= 2
	var vertex_instance:Vertex = VERTEX.instantiate()
	var vertex_size:Vector2 = vertex_instance.get_child(0).size + panel_margin
	panel_size -= vertex_size

	rng.randomize()
	_load_default_config()

	vertex_instance.queue_free()


# Load default config from code to ui elements
func _load_default_config() -> void:
	if current_graph == left_graph: graph_selection_spinbox.value = 0
	else: graph_selection_spinbox.value = 1
	graph_size_spinbox.value = graph_size; graph_seed_spinbox.value = custom_seed


func _create_graph() -> void:
	new_graph = true
	rng.randomize()
	rng.set_seed(custom_seed)

	# Clear existing vertices
	for vertex in current_graph.get_children(true):
		vertex.free()

	var index:int = 0
	var generated_positions = []
	for x in graph_size:
		var valid_position:bool = false
		var new_position:Vector2 = Vector2.ZERO

		while not valid_position:
			valid_position = true
			new_position = Vector2(rng.randi_range(0,int(panel_size.x)), rng.randi_range(0,int(panel_size.y)))
			# Check distance from other vertices
			for existing_position in generated_positions:
				if new_position.distance_to(existing_position) < vertex_spacing:
					valid_position = false
					break

		# Add the new position to the list of generated positions
		generated_positions.append(new_position)

		# Create vertex instance and add to the graph
		var vertex_instance:Vertex = VERTEX.instantiate()
		vertex_instance.position = new_position
		vertex_instance.index = index
		index += 1
		current_graph.add_child(vertex_instance)

	# Build EdgeWeightMatrix
	edge_weight_matrix = []
	for i in range(graph_size):
		edge_weight_matrix.append([])
		for j in range(graph_size): edge_weight_matrix[i].append(0)

	# Fill EdgeWeightMatrix
	for i in range(graph_size):
		for j in range(graph_size):
			# Vertex position for edge origin, parent of the edge node
			var vertex_origin_pos:Vector2 = current_graph.get_child(i).position
			# Vertex position for edge destination,
			# pos targeted by the edge
			var vertex_destin_pos:Vector2 = current_graph.get_child(j).position

			var edge_weight = snappedf((vertex_origin_pos.distance_to(vertex_destin_pos))/10,0.01)
			edge_weight_matrix[i][j] = edge_weight

	# Creating visual edges
	for i in range(graph_size):
		for j in range(i + 1, graph_size):
			var edge_instance = EDGE.instantiate()
			edge_instance.add_point(current_graph.get_child(i).position + Vector2.ONE * 50)
			edge_instance.add_point(current_graph.get_child(j).position + Vector2.ONE * 50)
			edge_instance.edge = Vector2(i,j)

			var edge_label:Label = edge_instance.get_child(0)
			edge_label.position = Vector2((current_graph.get_child(i).position.x + current_graph.get_child(j).position.x + 100)/2,(current_graph.get_child(i).position.y + current_graph.get_child(j).position.y + 100)/2)

			edge_label.text = str(edge_weight_matrix[i][j])
			edge_label.position.x -= edge_label.text.length() * 2
			current_graph.add_child(edge_instance)


func _color_edge(edge:Vector2) -> void:
	var length_label = current_graph.get_parent().get_node("Label2")

	if length_label.text == "" or new_graph == true:
		new_graph = false; length_label.text = "0"

	if not edge.x == INF or not edge.y == INF:
		length_label.text = str(float(length_label.text) + edge_weight_matrix[edge.x][edge.y])

	for child in current_graph.get_children():
		if child is Edge:
			var inverse_edge:Vector2 = Vector2(edge.y,edge.x)
			if child.edge == edge or child.edge == inverse_edge:
				child.default_color = Color.FOREST_GREEN
				child.get_child(0).get_child(0).color = Color.FOREST_GREEN


var start_index:int
func _solve_tsp_manual() -> void:
	var tour:Array = []
	start_index = 0

	SignalEventBus.hs_added_vertex.connect(func(vertex_idx:int) -> void:
		if tour.is_empty(): start_index = vertex_idx
		else: start_index = tour.front()

		if not tour.has(vertex_idx): tour.append(vertex_idx)
		else: if tour.has(vertex_idx) and vertex_idx == start_index: tour.append(vertex_idx)

		if len(tour) > 1:
			_color_edge(Vector2(tour[len(tour)-2],tour[len(tour)-1]))
	)


#region Algorithm Function
func _recursive_brute_force_naive() -> Array:
	var arr = []
	for i in range(graph_size):
		arr.append(i)

	var permuations_arr = permutations(arr)
	for i in range(len(permuations_arr)):
		permuations_arr[i].append(permuations_arr[i].front())

	var final_sum = INF
	var current_i
	for i in range(len(permuations_arr)):
		var sum = 0
		for j in range(len(permuations_arr[i])):
			if j != permuations_arr[i].size()-1:
				var edge_weight_value = edge_weight_matrix[permuations_arr[i][j]][permuations_arr[i][j+1]]
				sum += edge_weight_value

		if sum < final_sum: final_sum = sum; current_i = i

	for j in range(len(permuations_arr[current_i])):
		if j != permuations_arr[current_i].size()-1:
			_color_edge(Vector2(permuations_arr[current_i][j],permuations_arr[current_i][j+1]))

	return [permuations_arr[current_i]]


func permutations(array,permuations_array = [],start=0):
	var n = array.size()

	if start == n - 1:
		permuations_array.append(array.duplicate())
	else:
		for i in range(start, n):
			# Swap elements at indices start and i
			var temp
			temp = array[start]
			array[start] = array[i]
			array[i] = temp

			# Recursively generate permutations for the rest of the array
			permutations(array,permuations_array,start + 1)

			# Swap back elements to backtrack
			temp = array[start]
			array[start] = array[i]
			array[i] = temp

	if permuations_array.size() == factorial(array.size()):
		return permuations_array


func factorial(n):
	var holdvalue = 0
	var boolis = true
	if n == 0 or n == 1:
		holdvalue = 1
	else:
		while n > 0:
			if boolis:
				boolis = false
				holdvalue = n
			else:
				holdvalue = holdvalue * n
			n = n-1
	return holdvalue


func _recursive_nearest_neighbor(vertex_visited:Array,tour:Array,start_vertex:int,current_vertex:int) -> Array:
	# Mark current vertex as visited and Add current vertex to tour
	vertex_visited.append(current_vertex)
	tour.append(current_vertex)

	if len(tour) > 1: _color_edge(Vector2(tour[len(tour)-2],tour[len(tour)-1]))

	# Get edgeweight array from current vertex to other vertices and make all edge weight based on vertices visited INF
	var current_edgeweight_array:Array = edge_weight_matrix[current_vertex].duplicate()
	for visited_vertex in vertex_visited: current_edgeweight_array[visited_vertex] = INF

	# Get 'nn' from verticies
	if current_edgeweight_array.min() < INF:
		var nearest_neightbor:float = current_edgeweight_array.min()
		var next_vertex:int = current_edgeweight_array.find(nearest_neightbor)

		if not vertex_visited.has(next_vertex):
			_recursive_nearest_neighbor(vertex_visited,tour,start_vertex,next_vertex)

	else:
		tour.append(start_vertex)
		if len(tour) > 1: _color_edge(Vector2(tour[len(tour)-2],tour[len(tour)-1]))

	return tour


func _recursive_greedy_heuristic_variation(edge_matrix:Array,vertex_visited1:Array,vertex_visited2:Array,tour:Array) -> Array:
	var minimum_edge:float = INF
	var minimum_edge_pair:Vector2 = Vector2.INF

	var valid_edge_found:bool = false
	for i in range(len(edge_matrix)):
		if not vertex_visited2.has(float(i)):
			for j in range(len(edge_matrix)):
				if not vertex_visited2.has(float(j)):
					if i != j:
						if edge_matrix[i][j] < minimum_edge:
							var tour_copy:Array = tour.duplicate()
							tour_copy.append(Vector2(i,j))
							if _creates_invalid_cycle(tour_copy) == false:
								minimum_edge = edge_matrix[i][j]
								minimum_edge_pair = Vector2(i,j)
								valid_edge_found = true

	if valid_edge_found:
		_color_edge(minimum_edge_pair)
		edge_matrix[minimum_edge_pair.x][minimum_edge_pair.y] = INF
		edge_matrix[minimum_edge_pair.y][minimum_edge_pair.x] = INF
		tour.append(minimum_edge_pair)

		if not vertex_visited1.has(minimum_edge_pair.x):
			vertex_visited1.append(minimum_edge_pair.x)
		elif not vertex_visited2.has(minimum_edge_pair.x): vertex_visited2.append(minimum_edge_pair.x)

		if not vertex_visited1.has(minimum_edge_pair.y):
			vertex_visited1.append(minimum_edge_pair.y)
		elif not vertex_visited2.has(minimum_edge_pair.y): vertex_visited2.append(minimum_edge_pair.y)

		for i in range(len(edge_matrix)):
				for j in range(len(edge_matrix)):
					if edge_matrix[i][j] != INF and i != j:
						_recursive_greedy_heuristic_variation(edge_matrix,vertex_visited1,vertex_visited2,tour)

	return tour


func _creates_invalid_cycle(tour:Array) -> bool:
	if len(tour) == len(edge_weight_matrix) or len(tour) < 3: return false

	if len(tour) < len(edge_weight_matrix):
		for i in len(tour):
			var tour_copy:Array = tour.duplicate()
			var vertices:Array = []
			vertices.append(tour_copy[i].x)
			vertices.append(tour_copy[i].y)
			tour_copy.pop_at(i)

			while not tour_copy.is_empty():
				var edge_to_pop:Vector2 = Vector2.INF
				var connections:int = 0

				for edge in tour_copy:
					if edge.x == vertices.back() or edge.y == vertices.back():

						if not vertices.has(edge.x): vertices.append(edge.x)
						else: connections += 1

						if not vertices.has(edge.y): vertices.append(edge.y)
						else: connections += 1

						if connections == 2: return true
						edge_to_pop = edge

					connections = 0
				tour_copy.pop_at(tour_copy.find(edge_to_pop))

	return false


func build_mst(vertices_visited:Array,vertices_unvisited:Array,current_vertex:int = 0,tour:Array = []) -> Array:
	vertices_visited.append(current_vertex)
	tour.append(current_vertex)
	vertices_unvisited.pop_at(vertices_unvisited.find(current_vertex))

	var smallest_edge = INF
	var next_vertex   = INF
	var _i            = INF

	for i in vertices_visited:
		for j in vertices_unvisited:
			if edge_weight_matrix[i][j] < smallest_edge:
				smallest_edge = edge_weight_matrix[i][j]
				next_vertex = j
				_i = i

	_color_edge(Vector2(_i,next_vertex))

	if not vertices_unvisited.is_empty(): build_mst(vertices_visited,vertices_unvisited,next_vertex,tour)
	else: return tour

	return tour


#func _reverse_2opt_tour(vertex1:int,vertex2:int,tour:Array) -> Array:
	#var vertex1_idx:int = INF
	#var vertex2_idx:int = INF
	#vertex1_idx = tour.find(vertex1)
	#vertex2_idx = tour.find(vertex2)
#
	#var tour_1:Array = tour.duplicate().slice(0,vertex1_idx)
	#var tour_2:Array = tour.duplicate().slice(vertex2_idx+1,tour.size())
#
	#tour = tour.slice(vertex1_idx,vertex2_idx+1)
	#tour.reverse()
#
	#return tour
#endregion


#region GUI Signals
func _on_btn_create_graph_pressed() -> void: _create_graph()


func _on_spin_box_graph_changed(value: float) -> void:
	match int(value):
		0: current_graph =  left_graph
		1: current_graph = right_graph


func _on_spin_box_size_changed(value: float) -> void:
	graph_size = int(value)


func _on_spin_box_seed_changed(value: float) -> void:
	custom_seed = int(value)


func _on_visibility_edgeweight_pressed() -> void: SignalEventBus.emit_signal("toggle_edgeweight_visibility")


func _on_visibility_edge_pressed() -> void: SignalEventBus.emit_signal("toggle_none_tour_edges")


func _on_btn_hand_solving_pressed() -> void:
	SignalEventBus.emit_signal("hand_solving")
	_solve_tsp_manual()


func _on_btn_brute_force_pressed() -> void: print(_recursive_brute_force_naive())


func _on_btn_nearest_neighbor_pressed() -> void: print(_recursive_nearest_neighbor([],[],0,0))


func _on_btn_greedy_heuristic_variation_pressed() -> void:
	print(_recursive_greedy_heuristic_variation(edge_weight_matrix.duplicate(),[],[],[]))


func _on_btn_minimum_spanning_tree_pressed():
	var tour:Array = []
	for i in range(graph_size): tour.append(i)
	print(build_mst([],tour))


func _on_btn_local_search_2_opt_pressed():
	print("WIP...")
	#var tour:Array = [3,4,1,0,2,5,7,6]
	#if debug_print: print("Before: ",tour)
	#for i in range(1,len(tour)):
		#var reversed_tour = _reverse_2opt_tour(i,tour.size()-1,tour)
		#var sum:int = 0
		#for j in range(len(reversed_tour)):
			#if j < reversed_tour.size(): sum += edge_weight_matrix[j][j+1]


func _on_button_pressed() -> void:
	var r = float($Control/HSplitContainer/HSplitContainer/RightPanel/Label2.text)
	var l =  float($Control/HSplitContainer/HSplitContainer/LeftPanel/Label2.text)

	$Control/HSplitContainer/UI/MarginContainer/VBoxContainer/Label2.text = "Lower Bound: " + str(r / l)
#endregion
