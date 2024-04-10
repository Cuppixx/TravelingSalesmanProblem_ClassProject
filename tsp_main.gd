class_name TravelingSalesmanProblemMain extends Node

# Resources
const VERTEX:Resource = preload("res://vertex.tscn")
const EDGE:Resource = preload("res://edge.tscn")

# References
@onready var left_graph:Control = $Control/HSplitContainer/HSplitContainer/LeftPanel/Graph
@onready var right_graph:Control = $Control/HSplitContainer/HSplitContainer/RightPanel/Graph

@onready var graph_selection_spinbox:SpinBox = $Control/HSplitContainer/UI/MarginContainer/VBoxContainer/SpinBoxGraph
@onready var graph_size_spinbox:SpinBox = $Control/HSplitContainer/UI/MarginContainer/VBoxContainer/SpinBoxSize
@onready var graph_seed_spinbox:SpinBox = $Control/HSplitContainer/UI/MarginContainer/VBoxContainer/SpinBoxSeed

var panel_size:Vector2
const panel_margin:Vector2 = Vector2(10,10)
@export var vertex_spacing:int = 150
var rng:RandomNumberGenerator = RandomNumberGenerator.new()

@export var current_graph:Control = right_graph
@export var custom_seed:int = 18
@export var graph_size:int = 5

var edge_weight_matrix = []

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
	graph_size_spinbox.value = graph_size
	graph_seed_spinbox.value = custom_seed

func _create_graph() -> void:
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
		var vertex_index:Label = vertex_instance.get_child(0).get_child(0)
		vertex_index.text = str(index)
		index += 1
		current_graph.add_child(vertex_instance)

	# Build EdgeWeightMatrix
	for i in range(graph_size):
		edge_weight_matrix.append([])
		for j in range(graph_size):
			edge_weight_matrix[i].append(0)

	# Fill EdgeWeightMatrix
	for i in range(graph_size):
		for j in range(graph_size):
			# Vertex position for edge origin, parent of the edge node
			var vertex_origin_pos:Vector2 = current_graph.get_child(i).position
			# Vertex position for edge destination,
			# pos targeted by the edge
			var vertex_destin_pos:Vector2 = current_graph.get_child(j).position

			var edge_weight = snappedf((vertex_origin_pos.distance_to(vertex_destin_pos))/10,0.01)
			print("From ",vertex_origin_pos," to ",vertex_destin_pos," are ",edge_weight)
			edge_weight_matrix[i][j] = edge_weight

	# Creating visual edges
	for i in range(graph_size):
		for j in range(i + 1, graph_size):
			var edge_instance = EDGE.instantiate()
			edge_instance.add_point(current_graph.get_child(i).position + Vector2.ONE * 50)
			edge_instance.add_point(current_graph.get_child(j).position + Vector2.ONE * 50)

			var edge_label:Label = edge_instance.get_child(0)
			edge_label.position = Vector2((current_graph.get_child(i).position.x + current_graph.get_child(j).position.x + 100)/2,(current_graph.get_child(i).position.y + current_graph.get_child(j).position.y + 100)/2)

			edge_label.text = str(edge_weight_matrix[i][j])
			edge_label.position.x -= edge_label.text.length() * 2
			current_graph.add_child(edge_instance)












#var routes:Array = []
func _solve_tsp_brute_force() -> Array:
	for i in range(len(edge_weight_matrix)):
		for j in range(len(edge_weight_matrix[i])):
			print("From: "+str(i)+" to: "+str(j)+" weight of: "+str(edge_weight_matrix[i][j]))
		print()
	print(edge_weight_matrix,"\n")
	return []
	#for i in range(factorial(len(edge_weight_matrix))):
		#routes.append([])
		#for j in range(len(edge_weight_matrix)-1):
			#routes[i].append(0)
#
	#for i in range(len(edge_weight_matrix)-1): routes[0][i] = i+1
#
	#_permute()
	#return routes
#
#func _permute() -> void:
	#var first_route = routes[0]
	#var permuted_route = first_route.duplicate()
	#_permuteRecursive(first_route, permuted_route, 0)
#
#func _permuteRecursive(original_route, permuted_route, start_index):
	#if start_index == len(original_route) - 1:
		#routes.append(permuted_route.duplicate())
		#return
#
	#for i in range(start_index, len(original_route)):
		#var temp
		#if i != start_index:
			## Swap elements
			#temp = permuted_route[start_index]
			#permuted_route[start_index] = permuted_route[i]
			#permuted_route[i] = temp
#
		#_permuteRecursive(original_route, permuted_route, start_index + 1)
#
		#if i != start_index:
			## Restore elements
			#temp = permuted_route[start_index]
			#permuted_route[start_index] = permuted_route[i]
			#permuted_route[i] = temp
#
#func factorial(n):
	#n -= 1
	#var holdvalue = 0
	#var boolis = true
	#if n == 0 or n == 1:
		#holdvalue = 1
	#else:
		#while n > 0:
			#if boolis:
				#boolis = false
				#holdvalue = n
			#else:
				#holdvalue = holdvalue * n
			#n = n-1
	#print("Routes num: ",holdvalue / 2,"\n")
	#return holdvalue / 2



func _solve_tsp_nearest_neighbor() -> Array: return _recursive_nearest_neighbor([],[],0,0)

func _recursive_nearest_neighbor(vertex_visited:Array,route:Array,start_vertex:int,current_vertex:int) -> Array:
	# Mark current vertex as visited
	vertex_visited.append(current_vertex)
	print("Visited ",vertex_visited)
	# Add current vertex to route
	route.append(current_vertex)
	print("Route ",route)
	# Get edge weight array from cuurent vertex to other vertices
	var current_edge_array:Array = edge_weight_matrix[current_vertex].duplicate()
	print("Current Edgeweights ",current_edge_array)
	# Make all edge weight based on vertices visited INF
	for visited_vertex in vertex_visited: current_edge_array[visited_vertex] = INF
	print("Current Edgeweights ",current_edge_array)
	# get nn from verticies
	if current_edge_array.min() < INF:
		var nearest_neightbor:float = current_edge_array.min()
		var next_vertex:int = current_edge_array.find(nearest_neightbor)
		print("Found available vertex / edge to travel to:", next_vertex)
		if not vertex_visited.has(next_vertex):
			_recursive_nearest_neighbor(vertex_visited,route,start_vertex,next_vertex)
	else: route.append(start_vertex)

	return route

# GUI Signals
func _on_btn_create_graph_pressed() -> void: _create_graph()

func _on_spin_box_graph_changed(value: float) -> void:
	match int(value):
		0: current_graph = left_graph
		1: current_graph = right_graph

func _on_spin_box_size_changed(value: float) -> void: graph_size = int(value)
func _on_spin_box_seed_changed(value: float) -> void: custom_seed = int(value)

func _on_btn_brute_force_pressed() -> void: print(_solve_tsp_brute_force())
func _on_btn_nearest_neighbor_pressed() -> void: print(_solve_tsp_nearest_neighbor())
