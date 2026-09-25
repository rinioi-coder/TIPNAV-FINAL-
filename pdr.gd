extends Node

@export var label:Label

func _ready():
	if OS.has_feature("web"):
		_inject_accelerometer_js()

func _inject_accelerometer_js():
	var js_code = """
	window.accelerometerData = { x: 0, y: 0, z: 0 };
	window.isAccelActive = false;

	window.requestAccelerometerPermission = async function() {
		if (typeof DeviceMotionEvent !== 'undefined' && typeof DeviceMotionEvent.requestPermission === 'function') {
			try {
				const response = await DeviceMotionEvent.requestPermission();
				if (response === 'granted') {
					window.startDeviceMotion();
					return true;
				}
				return false;
			} catch (error) {
				console.error('Permission error:', error);
				return false;
			}
		} else if ('Accelerometer' in window) {
			try {
				const acl = new Accelerometer({ frequency: 60 });
				acl.addEventListener('reading', () => {
					window.accelerometerData.x = acl.x || 0;
					window.accelerometerData.y = acl.y || 0;
					window.accelerometerData.z = acl.z || 0;
				});
				acl.start();
				window.isAccelActive = true;
				return true;
			} catch (error) {
				window.startDeviceMotion();
				return true;
			}
		} else {
			window.startDeviceMotion();
			return true;
		}
	};

	window.startDeviceMotion = function() {
		window.addEventListener('devicemotion', (event) => {
			if (event.accelerationIncludingGravity) {
				window.accelerometerData.x = event.accelerationIncludingGravity.x || 0;
				window.accelerometerData.y = event.accelerationIncludingGravity.y || 0;
				window.accelerometerData.z = event.accelerationIncludingGravity.z || 0;
			}
		});
		window.isAccelActive = true;
	};
	"""
	JavaScriptBridge.eval(js_code)

# Connect this to your UI Button signal (e.g., pressed)
func _on_enable_sensors_button_pressed():
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.requestAccelerometerPermission();")

func _process(_delta):
	if not label: return
	
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		if window and window.accelerometerData:
			var js_data = window.accelerometerData
			var x = float(js_data.x)
			var y = float(js_data.y)
			var z = float(js_data.z)
			var accel_vector = Vector3(x, y, z)
			
			label.text = str(accel_vector)
			# Print to browser console and Godot debug output
			print("Accel: ", accel_vector)
