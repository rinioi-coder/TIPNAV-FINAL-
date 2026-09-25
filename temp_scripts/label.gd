extends Label

func _ready() -> void:
	Accelerometer.updated.connect(accelerometer_updated)

func accelerometer_updated(data:Vector3):
	text = str(data.length())
