# singleton for accessing magnetometer data and the compass heading
extends Node

# Degrees added to the heading. Calibrate once against a real compass app
# (you saw about 180 on Firefox when flat). Leave at 0.0 if it already matches.
const HEADING_OFFSET: float = -0.0

# How quickly heading_smooth follows heading (0..1, higher = faster, less smooth)
const SMOOTHING: float = 0.15

# Print a debug line once per second
const DEBUG_LOG: bool = false

# flags
var is_initialized: bool = false
var is_active: bool = false

# raw data from JS
var status: String = "uninitialized"
var data_timestamp: float = 0.0
var data: Vector3 = Vector3.ZERO   # magnetic north, in the phone's frame
var up: Vector3 = Vector3.UP       # "up", in the phone's frame

# heading, degrees clockwise from magnetic north (0..360)
var heading: float = 0.0           # raw
var heading_smooth: float = 0.0    # low-pass filtered
var has_heading: bool = false

var _window: JavaScriptObject
var _log_timer: float = 0.0
var _smooth_rad: float = 0.0

func _ready():
	print("[Magnetometer.gd] HEADING_OFFSET = ", HEADING_OFFSET)
	
	if OS.has_feature("web"):
		_window = JavaScriptBridge.get_interface("window")
		# Attempt initial JS check (works on Android; iOS needs a gesture)
		JavaScriptBridge.eval("if (window.initMagnetometer) { window.initMagnetometer(); }")

func _unhandled_input(event: InputEvent):
	# Required for iOS Safari: call init on a user gesture
	if is_active or not OS.has_feature("web"):
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			is_initialized = true
			JavaScriptBridge.eval("if (window.initMagnetometer) { window.initMagnetometer(); }")

func _process(delta: float):
	if not OS.has_feature("web") or _window == null:
		return

	status = str(_window.magStatus)
	is_active = status.begins_with("active")

	if is_active:
		var mag = _window.magnetometerData
		if mag:
			data = Vector3(float(mag.x), float(mag.y), float(mag.z))
			data_timestamp = float(mag.timestamp)

		var u = _window.magUp
		if u:
			up = Vector3(float(u.x), float(u.y), float(u.z))

		_update_heading()

	if DEBUG_LOG:
		_log_timer += delta
		if _log_timer >= 1.0:
			_log_timer = 0.0
			print(status, " | heading=", snapped(heading, 0.1), " smooth=", snapped(heading_smooth, 0.1))

# Computes the heading from data (north) and up, for any phone orientation.
# The phone's "pointing direction" is the top edge when the phone is flat, and the
# back of the phone (camera direction) when it is upright or in landscape.
# Returns NAN if there is no valid data.
func compute_heading() -> float:
	if data.length() < 0.1 or up.length() < 0.1:
		return NAN

	var n := data.normalized()
	var u := up.normalized()
	var east := n.cross(u)

	# Horizontal part of each candidate pointing direction
	var f_top := Vector3(0, 1, 0)
	var f_back := Vector3(0, 0, -1)
	var h_top := f_top - u * f_top.dot(u)
	var h_back := f_back - u * f_back.dot(u)

	# Use whichever is more horizontal right now
	var f := h_back if h_back.length() > h_top.length() else h_top
	
	var deg := rad_to_deg(atan2(east.dot(f), n.dot(f)))
	return fposmod(deg + HEADING_OFFSET, 360.0)

func _update_heading() -> void:
	var h := compute_heading()
	if is_nan(h):
		return
	heading = h
	
	var target := deg_to_rad(h)
	if not has_heading:
		_smooth_rad = target
		has_heading = true
	else:
		# lerp_angle takes the short way around, so 359 -> 1 does not swing through 180
		_smooth_rad = lerp_angle(_smooth_rad, target, SMOOTHING)
	heading_smooth = fposmod(rad_to_deg(_smooth_rad), 360.0)
