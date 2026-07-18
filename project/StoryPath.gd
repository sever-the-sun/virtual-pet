class_name StoryPath extends Resource

var name: String
var description_array: Array[String]

enum ACTIONS {
	MEOW,
	HISS,
	NO_MOVE,
	TIMEOUT,
	BOTHER,
	EMPTY,
	MANUAL
}

var action_array: Array[ACTIONS]

var path_array: Array[String]
var alt_path_array: Array[String]
var alt_trigger_array: Array[String]

var flag_array: Array[String]

var line: int = 0

static func parse_paths(paths_raw: String) -> Array[StoryPath]:
	var paths_raw_array := paths_raw.split("\n---\n", false)
	var story_path_array: Array[StoryPath]
	for i in paths_raw_array:
		story_path_array.append(StoryPath.new(i))
	return story_path_array

func _init(params: String):
	var name_end: int = params.find(">")
	name = params.substr(1, name_end - 1)
	var paths_start: int = params.find("[")
	description_array.assign(params.substr(name_end + 2, paths_start - name_end - 3).split("\n\n"))
	
	var path_raw_array := params.substr(paths_start).split("\n")
	for i in path_raw_array.size():
		if path_raw_array[i]:
			if path_raw_array[i][0] == '=': # is a flag instead
				flag_array.append(path_raw_array[i].substr(1))
			else:
				var action_end: int = path_raw_array[i].find("]")
				match path_raw_array[i].substr(1, action_end - 1):
					"MEOW":
						action_array.append(ACTIONS.MEOW)
					"HISS":
						action_array.append(ACTIONS.HISS)
					"NO_MOVE":
						action_array.append(ACTIONS.NO_MOVE)
					"TIMEOUT":
						action_array.append(ACTIONS.TIMEOUT)
					"BOTHER":
						action_array.append(ACTIONS.BOTHER)
					"EMPTY":
						action_array.append(ACTIONS.EMPTY)
					"":
						action_array.append(ACTIONS.EMPTY)
					"MANUAL":
						action_array.append(ACTIONS.MANUAL)
				var rest_of_string := path_raw_array[i].substr(action_end + 5)
				if rest_of_string.find("?") != -1: # is a ternary operator
					var split := rest_of_string.split(" ? ")
					alt_trigger_array.append(split[0])
					alt_path_array.append(split[1].split(" : ")[0])
					path_array.append(split[1].split(" : ")[1])
				else:
					path_array.append(rest_of_string)
					alt_path_array.append("")
					alt_trigger_array.append("")

func get_next_line() -> String:
	if line >= description_array.size():
		return ""
	else:
		line += 1
		return description_array[line - 1]

func parse_input(input: ACTIONS, flags: Dictionary = {}) -> String:
	#print(action_array)
	for i in action_array.size():
		if action_array[i] == input:
			if flags.has(alt_trigger_array[i]) and flags[alt_trigger_array[i]]:
				return alt_path_array[i]
			else:
				return path_array[i]
	return ""
