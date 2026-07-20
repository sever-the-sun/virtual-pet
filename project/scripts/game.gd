extends Node2D

@onready var player: CharacterBody2D = $player


var story_path_array: Array[StoryPath]
var current_path: StoryPath

var flag_dict: Dictionary[String, bool] = {
}

var accepting_next_line: bool = false

var next_event: StoryPath.ACTIONS = StoryPath.ACTIONS.EMPTY

@onready var window: Window = get_window()
@onready var sub_window: Window = $sub_window

@onready var dialogue_label: RichTextLabel = $sub_window/dialogue
@onready var text_pass: Timer = $text_pass
@onready var line_pass: Timer = $line_pass
@onready var nothing_timer: Timer = $nothing_timer

@onready var user_bg: Sprite2D = $sub_window/Node2D/user_bg
@onready var user: AnimatedSprite2D = $sub_window/Node2D/user

var output_text_to_terminal: bool = false

var pet_name: String = ""
var good_ending: bool = false


const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1600,900),
	Vector2i(1280,720),
	Vector2i(1024,576),
	Vector2i(800,450),
	Vector2i(480, 270)
]

func _ready() -> void:
	# parse text
	var file = FileAccess.open("res://path-raw.txt", FileAccess.READ)
	story_path_array = StoryPath.parse_paths(file.get_as_text())
	current_path = story_path_array[0]
	
	# window
	#window.size_changed.connect(_on_window_size_changed)
	window.focus_entered.connect(_on_window_focus_entered)
	window.focus_exited.connect(_on_window_focus_exited)
	_on_window_size_changed()
	window.always_on_top = true

func _process(delta: float) -> void:
	sub_window.position = window.position - Vector2i(Vector2(200,200) * (window.size.x / 1280.0))
	
	if $AnimationPlayer.is_playing() && $cursor.position.distance_squared_to(player.position) > 160^2:
		unpet()
	
func _on_window_size_changed() -> void:
	
	sub_window.size = window.size + Vector2i(Vector2(400,600) * (window.size.x / 1280.0))
	$sub_window/Node2D.scale = Vector2.ONE * (window.size.x / 1280.0)
	#dialogue_label.scale = Vector2.ONE * (window.size.x / 1280.0)
	dialogue_label[&"theme_override_font_sizes/normal_font_size"] = int(roundf(48 * window.size.x / 1280.0))
	#print(48 * int(window.size.x / 1280.0))
	
	#print(int(window.size.x / 1280.0))
func _on_window_focus_entered() -> void:
	pass
	#sub_window.show()

func _on_window_focus_exited() -> void:
	pass
	#sub_window.hide()

func _on_option_button_item_selected(index: int) -> void:
	window.size = RESOLUTIONS[index]
	await get_tree().create_timer(0.05).timeout
	_on_window_size_changed()
#func _input(event: InputEvent) -> void:
	#
	#if accepting_next_line:
		#if Input.is_action_just_pressed(&"meow"):
			#get_next_path(StoryPath.ACTIONS.MEOW)
		#if Input.is_action_just_pressed(&"hiss"):
			#get_next_path(StoryPath.ACTIONS.HISS)

func meow() -> void:
	if accepting_next_line:
		get_next_path(StoryPath.ACTIONS.MEOW)
	else:
		pass
func hiss() -> void:
	if accepting_next_line:
		get_next_path(StoryPath.ACTIONS.HISS)
	else:
		pass

func pet() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property($cursor, ^"position", player.position + Vector2(0,-randf_range(64,128)).rotated(randf_range(-0.5, 0.5)), 0.2)
	tween.tween_property($cursor, ^"rotation", 0, 0.1)
	tween.tween_property($cursor, ^"position", player.position + Vector2(randf_range(-10, 10), randf_range(-10, 10)), 0.1)
	tween.play()
	await get_tree().create_timer(0.4).timeout
	$cursor/mouse.play(&"pet")
	$AnimationPlayer.play(&"pet")
	await get_tree().create_timer(3).timeout
	unpet()

func unpet() -> void:
	$AnimationPlayer.stop()
	$cursor/mouse.play(&"default")
	##TODO: make this so the mouse is a normal cursor

func update_flags_before_dialogue(flag_array: Array[String]) -> void:
	for flag in flag_array:
		match flag:
			"anim-focus":
				user.play(&"focus")
			"anim-head-tilt":
				user.play(&"head-tilt")
			"anim-look-closer":
				user.play(&"look-closer")
			"anim-look-reasonable":
				user.play(&"look-reasonable")
			"anim-turn-away":
				user.play(&"turn-away")
			"anim-wake-up":
				user.play(&"wake-up-a")
			"anim-head-tilt-reverse-conditional":
				if user.animation == &"head-tilt":
					user.play_backwards(&"head-tilt")
			"anim-turn-away-reverse-conditional":
				if user.animation == &"turn-away":
					user.play_backwards(&"turn-away")
			"bother1":
				$Area2D/CollisionShape2D.set_deferred(&"disabled", false)

func update_flags_after_dialogue(flag_array: Array[String]) -> void:
	
	for flag in flag_array:
		match flag:
			"pet":
				pet()
			"day1-end":
				new_day(2)
			"day2-end":
				new_day(3)
			"day3-end":
				new_day(4)
			"named-meow":
				name = "Maddy"
			"named-hiss":
				name = "Flora"
			"named-no-move":
				name = "Lily"
			"named-timeout":
				name = "Eva"
			"good_ending":
				good_ending = true
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
	nothing_timer.start()
	player.has_not_moved = true
	if current_path.action_array.is_empty():
		pass
		#print("okay we've reached an end???")
	elif current_path.action_array[0] == StoryPath.ACTIONS.EMPTY:
		get_next_path(StoryPath.ACTIONS.EMPTY)
	elif next_event == StoryPath.ACTIONS.BOTHER:
		next_event = StoryPath.ACTIONS.EMPTY
		get_next_path(StoryPath.ACTIONS.BOTHER)
func _on_nothing_timer_timeout() -> void:
	if accepting_next_line:
		if player.has_not_moved:
			get_next_path(StoryPath.ACTIONS.NO_MOVE)
		else:
			get_next_path(StoryPath.ACTIONS.TIMEOUT)

func render_line(text: String) -> void:
	dialogue_label.text = text.format({"name":name})
	if output_text_to_terminal:
		print(dialogue_label.text)
	dialogue_label.visible_characters = 0
	while dialogue_label.visible_characters < dialogue_label.get_total_character_count():
		dialogue_label.visible_characters += 1
		# longer pause if it's {.}
		if dialogue_label.text[dialogue_label.visible_characters - 1] == '.':
			text_pass.wait_time = 0.5
		else:
			text_pass.wait_time = 0.05
		#text_pass.wait_time *= 0.1
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

func _on_area_2d_body_entered(body: Node2D) -> void:
	if accepting_next_line:
		$Area2D/CollisionShape2D.set_deferred(&"disabled", true)
		get_next_path(StoryPath.ACTIONS.BOTHER)
	else:
		$Area2D/CollisionShape2D.set_deferred(&"disabled", true)
		next_event = StoryPath.ACTIONS.BOTHER

func new_day(day: int) -> void:
	match day:
		1:
			$day_anims.play(&"day1")
			await $day_anims.animation_finished
			next_path()
		2:
			await get_tree().create_timer(1).timeout
			$day_anims.play(&"turnoff")
			
			await get_tree().create_timer(1).timeout
			player.position.y = 696
			$cursor.position = Vector2(598.0, 275.0)
			$open_text.show()
			$open_text/CollisionShape2D.set_deferred(&"disabled",false)
			await $day_anims.animation_finished
			await get_tree().create_timer(1).timeout
			get_next_path(StoryPath.ACTIONS.MANUAL)
		3:
			$day_anims.play(&"turnoff")
			await get_tree().create_timer(1).timeout
			$open_text.hide()
			$open_text/CollisionShape2D.set_deferred(&"disabled",true)
			user_bg.hide()
			$sub_window/Node2D/lazy_chair.show()
			await $day_anims.animation_finished
			user.play(&"wake-up-a")
			await user.animation_finished
			user_bg.show()
			$sub_window/Node2D/lazy_chair.hide()
			user.play(&"wake-up-b")
			await user.animation_finished
			get_next_path(StoryPath.ACTIONS.MANUAL)
		4:
			await get_tree().create_timer(1).timeout
			$day_anims.play(&"turnoff_day4")
			
			#await get_tree().create_timer(1).timeout
			await $day_anims.animation_finished
			$walls/CollisionShape2D2.call_deferred(&"set_disabled",true)
			$ending/CollisionShape2D.call_deferred(&"set_disabled",false)
			#user.play(&"hug")


func _on_options_toggled(toggled_on: bool) -> void:
	$title/options_rect.visible = toggled_on
	if toggled_on:
		$title/credits.button_pressed = false
		_on_credits_toggled(false)


func _on_credits_toggled(toggled_on: bool) -> void:
	$title/credits_rect.visible = toggled_on
	if toggled_on:
		$title/options.button_pressed = false
		_on_options_toggled(false)


func _on_begin_pressed() -> void:
	$title.hide()
	new_day(1)


func _on_check_box_toggled(toggled_on: bool) -> void:
	output_text_to_terminal = toggled_on


func _on_ending_body_entered(body: Node2D) -> void:
	player.cutscene_no_move = true
	await get_tree().create_timer(1).timeout
	if good_ending:
		user.play(&"hug")
	else:
		user.play(&"turnoff")
		await user.animation_finished
		$day_anims.play(&"bad_end")
		#$sfx.play()
		#$pure_black_fg.show()
		#$pure_black_fg.modulate = Color.BLACK
