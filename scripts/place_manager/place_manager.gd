extends Node

# container for place data
var places = {}

# initialize
func _ready() -> void:
	pass

# get data from name
func get_data(name:String):
	if places.has(name):
		return places[name]
