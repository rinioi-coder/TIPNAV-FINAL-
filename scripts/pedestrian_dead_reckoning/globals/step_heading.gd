# singleton for calculating step heading
extends Node

# calculate step heading
func calculate(step:Dictionary):
	return step.data[step.data.size() - 1].heading
