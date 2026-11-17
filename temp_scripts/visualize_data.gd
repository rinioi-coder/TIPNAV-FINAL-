# helper script to display step data to texts
extends Label

var count:int = 0

func _ready() -> void:
	PedestrianDeadReckoning.step_occured.connect(step_occured)

func step_occured(step):
	count += 1
	text = str("COUNT= ", count, " , LENGTH= ", step.length," , HEADING=", step.heading)
