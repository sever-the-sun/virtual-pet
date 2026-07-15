extends Node2D
@onready var window: Window = get_window()
@onready var sub_window: Window = $sub_window

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1600,900),
	Vector2i(1280,720),
	Vector2i(800,450)
]

func _ready() -> void:
	window.size_changed.connect(_on_window_size_changed)
	#window.visibility_changed.connect(_on_window_visibility_changed)
	window.focus_entered.connect(_on_window_focus_entered)
	window.focus_exited.connect(_on_window_focus_exited)
	_on_window_size_changed()
	window.always_on_top = true
	
func _process(delta: float) -> void:
	sub_window.position = window.position - Vector2i(100,100)
	
func _on_window_size_changed() -> void:
	sub_window.size = window.size + Vector2i(200,200)

func _on_window_focus_entered() -> void:
	pass
	#sub_window.show()

func _on_window_focus_exited() -> void:
	pass
	#sub_window.hide()


func _on_option_button_item_selected(index: int) -> void:
	window.size = RESOLUTIONS[index]
