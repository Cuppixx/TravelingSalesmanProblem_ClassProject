class_name Vertex extends Control

@onready var label:Label = $TextureButton/Label

var index:int = INF
var hand_solving:bool = false

func _ready() -> void:
	$TextureButton.tooltip_text = str(position)
	label.text = str(index)
	SignalEventBus.hand_solving.connect(func() -> void:
		if hand_solving == false: hand_solving = true
		else: hand_solving = false
	)

func _on_texture_button_pressed() -> void:
	if hand_solving == true: SignalEventBus.emit_signal("hs_added_vertex",index)
