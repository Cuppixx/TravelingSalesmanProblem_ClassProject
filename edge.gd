class_name Edge extends Line2D

@onready var label:Label = $Label
var edge:Vector2 = Vector2.INF


func _ready() -> void:
	label.text = " "+label.text+" "

	SignalEventBus.toggle_edgeweight_visibility.connect(func() -> void:
		if label.visible: label.visible = false
		else: label.visible = true
	)

	SignalEventBus.toggle_none_tour_edges.connect(func() -> void:
		if visible and default_color != Color.FOREST_GREEN: visible = false
		else: visible = true
	)
