# singleton for handling pdr
extends Node

func _ready() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
		window.godotAccel = {x: 0, y: 0, z: 0};
		
		window.addEventListener("devicemotion", function(event) {
			if (event.acceleration) {
				window.godotAccel.x = event.acceleration.x || 0;
				window.godotAccel.y = event.acceleration.y || 0;
				window.godotAccel.z = event.acceleration.z || 0;
			}
			})
		""")

func _process(delta: float) -> void:
	if OS.has_feature("web"):
		var data = JavaScriptBridge.eval("""
			JSON.stringify(window.godotAccel)
		""")
		
		var accel_data = JSON.parse_string(data)
		
		if accel_data:
			var accel = Vector3(accel_data.x,accel_data.y,accel_data.z)
			$Ui/Label.text = str(accel)
			print(accel)
