extends Node2D

var story_path_array: Array[StoryPath]
var current_path: StoryPath

var flag_dict: Dictionary[String, bool] = {
}

var accepting_next_line: bool = false

@onready var window: Window = get_window()
@onready var sub_window: Window = $sub_window

@onready var dialogue_label: RichTextLabel = $sub_window/dialogue
@onready var text_pass: Timer = $text_pass
@onready var line_pass: Timer = $line_pass


const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1600,900),
	Vector2i(1280,720),
	Vector2i(800,450)
]

func _ready() -> void:
	# parse text
	var file = FileAccess.open("res://path-raw.txt", FileAccess.READ)
	story_path_array = StoryPath.parse_paths(file.get_as_text())
	current_path = story_path_array[0]
	
	next_path()
	
	# window
	window.size_changed.connect(_on_window_size_changed)
	window.focus_entered.connect(_on_window_focus_entered)
	window.focus_exited.connect(_on_window_focus_exited)
	_on_window_size_changed()
	window.always_on_top = true

func _process(delta: float) -> void:
	sub_window.position = window.position - Vector2i(Vector2(200,200) * (window.size.x / 1280.0))
	
func _on_window_size_changed() -> void:
	sub_window.size = window.size + Vector2i(Vector2(400,600) * (window.size.x / 1280.0))

func _on_window_focus_entered() -> void:
	pass
	#sub_window.show()

func _on_window_focus_exited() -> void:
	pass
	#sub_window.hide()

func _on_option_button_item_selected(index: int) -> void:
	window.size = RESOLUTIONS[index]

func _input(event: InputEvent) -> void:
	if accepting_next_line:
		if Input.is_action_just_pressed(&"meow"):
			get_next_path(StoryPath.ACTIONS.MEOW)
		if Input.is_action_just_pressed(&"hiss"):
			get_next_path(StoryPath.ACTIONS.HISS)

func update_flags_before_dialogue(flag_array: Array[String]) -> void:
	pass

func update_flags_after_dialogue(flag_array: Array[String]) -> void:
	pass

func next_path() -> void:
	accepting_next_line = false
	current_path.line = 0
	update_flags_before_dialogue(current_path.flag_array)
	var next_line: String# = current_path.get_next_line()
	
	while true:
		next_line = current_path.get_next_line()
		if !next_line:
			break
		await render_line(next_line)
		line_pass.start()
		await line_pass.timeout
	#
	#if next_line:
		#render_line(next_line)
		update_flags_after_dialogue(current_path.flag_array)
	accepting_next_line = true

func render_line(text: String) -> void:
	dialogue_label.text = text
	dialogue_label.visible_characters = 0
	while dialogue_label.visible_characters < dialogue_label.get_total_character_count():
		dialogue_label.visible_characters += 1
		# longer pause if it's {.}
		if dialogue_label.text[dialogue_label.visible_characters - 1] == '.':
			text_pass.wait_time = 0.5
		else:
			text_pass.wait_time = 0.05
		text_pass.start()
		await text_pass.timeout

func get_next_path(action: StoryPath.ACTIONS):
	var dest: String = current_path.parse_input(action, flag_dict)
	if !dest:
		return
	
	for i in story_path_array:
		if i.name == dest:
			current_path = i
			next_path()
			return
	assert(false, "we haven't found a match for destination, this should not happen")
