# helper script for moving the capsule
extends MeshInstance3D

var move_weight:float = 1
var target_pos:Vector3 = Vector3.ZERO

# connect events
func _ready() -> void:
	PedestrianDeadReckoning.step_occured.connect(step_occured)

# update target position
func step_occured(step:Dictionary):
	var added_pos = Vector3(step.length*cos(deg_to_rad(step.heading)),0,step.length*sin(deg_to_rad(step.heading)))
	target_pos = target_pos + added_pos

# lerp to target position
func _process(delta: float) -> void:
	position = lerp(position,target_pos,move_weight)
