# singleton for step detection adaptive parameter calculations
extends Node

# settings
var window_ratio:float = .2

# calculate new parameter values
# based on recent data
func update_parameters():
<<<<<<< Updated upstream
	if PedestrianDeadReckoning.steps_buffer.size() < PedestrianDeadReckoning.steps_buffer_size: return
=======
<<<<<<< Updated upstream
<<<<<<< Updated upstream
	if PedestrianDeadReckoning.steps_buffer.size() < PedestrianDeadReckoning.steps_buffer_size: return
=======
=======
>>>>>>> Stashed changes
	var steps:Array = PedestrianDeadReckoning.steps_buffer
	var count:int = steps.size()
	
	# wait until the steps buffer is full
	if count < PedestrianDeadReckoning.steps_buffer_size: return
<<<<<<< Updated upstream
=======
# +/- window around the measured averages (wider = more tolerant to pace changes)
var window_ratio:float = 1

# how much to trust the newly calculated values per update
# 0.0 = ignore new calculation, 1.0 = fully overwrite
var blend_weight:float = 0.2

# how much each update pulls a setting back toward its default
# (time constant is roughly 1 / default_pull updates, so ~100 steps at 0.01)
var default_pull:float = 0.01

# every adaptive setting stays within [default * low, default * high]
var bound_low_ratio:float = 0.5
var bound_high_ratio:float = 2.0

# sanity bounds for step duration (msec), so bad early data can't lock detection
var step_duration_floor:float = 250.0
var step_duration_ceiling:float = 2000.0

# if no step reaches update_parameters() for this long, snap back to defaults
var reset_timeout_msec:int = 5000
var _last_update_msec:int = 0
var _is_at_defaults:bool = true

func _process(_delta:float) -> void:
	if _is_at_defaults: return
	if Time.get_ticks_msec() - _last_update_msec > reset_timeout_msec:
		reset_to_defaults()

# keep a value inside a band around its default
func _clamp_around_default(value:float, default_value:float) -> float:
	if default_value == 0.0: return value
	var a:float = default_value * bound_low_ratio
	var b:float = default_value * bound_high_ratio
	# min/max handles negative defaults (falling slopes)
	return clampf(value, minf(a, b), maxf(a, b))

# move a setting part of the way toward a newly calculated target,
# pull it slightly back toward its default, then keep it inside its band
func _blend(key:String, target:float) -> void:
	var default_value:float = float(StepDetection.default_settings[key])
	var current:float = float(StepDetection.settings[key])
	
	var v:float = lerpf(current, target, blend_weight)
	v += default_pull * (default_value - v)
	v = _clamp_around_default(v, default_value)
	
	StepDetection.settings[key] = v

# restore original settings (also called automatically after reset_timeout_msec)
func reset_to_defaults() -> void:
	for key in StepDetection.default_settings:
		StepDetection.settings[key] = StepDetection.default_settings[key]
	_is_at_defaults = true

# calculate new parameter values based on recent data
# (call this every time a step is added once the buffer is full)
func update_parameters() -> void:
	# a step was just accepted, so restart the timeout
	_last_update_msec = Time.get_ticks_msec()
	
	var steps:Array = PedestrianDeadReckoning.steps_buffer
	var n:int = steps.size()
	if n < PedestrianDeadReckoning.steps_buffer_size or n < 2: return
	
	_is_at_defaults = false
>>>>>>> Stashed changes
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
>>>>>>> Stashed changes
	
	# initialize temporary values
	var ave_step_duration:float = 0.0
	
	var ave_peak_valley_difference:float = 0.0
	var ave_valley_difference:float = 0.0
	
	var ave_rising_slope:float = 0.0
	var ave_falling_slope:float = 0.0
	
	var ave_time_between_peaks:float = 0.0
	
	# calculate parameters
	for i in range(count):
		var step = steps[i]
		var last_index:int = step.data.size() - 1
		
		ave_step_duration += step.data[last_index].recorded_time - step.data[0].recorded_time
		
		ave_peak_valley_difference += step.data[step.peak_index].acc_magn_lerped - step.data[0].acc_magn_lerped
		ave_peak_valley_difference += step.data[last_index].acc_magn_lerped - step.data[step.peak_index].acc_magn_lerped
		
<<<<<<< Updated upstream
		ave_valley_difference += abs(step.data[0].acc_magn_lerped - step.data[step.data.size() - 1].acc_magn_lerped)
=======
<<<<<<< Updated upstream
<<<<<<< Updated upstream
		ave_valley_difference += abs(step.data[0].acc_magn_lerped - step.data[step.data.size() - 1].acc_magn_lerped)
=======
		ave_valley_difference += abs(step.data[0].acc_magn_lerped - step.data[last_index].acc_magn_lerped)
=======
	# calculate averages
	for i in range(n):
		var step:Dictionary = steps[i]
		var first = step.data[0]
		var peak = step.data[step.peak_index]
		var last = step.data[step.data.size() - 1]
		
		ave_step_duration += last.recorded_time - first.recorded_time
		
		# rise (valley -> peak) and fall (peak -> valley), both positive
		ave_peak_valley_difference += peak.acc_magn_lerped - first.acc_magn_lerped
		ave_peak_valley_difference += peak.acc_magn_lerped - last.acc_magn_lerped
		
		ave_valley_difference += abs(first.acc_magn_lerped - last.acc_magn_lerped)
>>>>>>> Stashed changes
>>>>>>> Stashed changes
=======
		ave_valley_difference += abs(step.data[0].acc_magn_lerped - step.data[last_index].acc_magn_lerped)
>>>>>>> Stashed changes
>>>>>>> Stashed changes
		
		var slopes:Array = StepDetection.calc_lin_regr(step)
		ave_rising_slope += slopes[0]
		ave_falling_slope += slopes[1]
		
<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
		ave_time_between_peaks += step.peak_time - PedestrianDeadReckoning.steps_buffer[i - 1].peak_time
		
	ave_step_duration = ave_step_duration / PedestrianDeadReckoning.steps_buffer.size()
	ave_peak_valley_difference = ave_peak_valley_difference / (PedestrianDeadReckoning.steps_buffer.size() * 2)
	ave_valley_difference = ave_valley_difference / PedestrianDeadReckoning.steps_buffer.size()
	ave_rising_slope = ave_rising_slope / PedestrianDeadReckoning.steps_buffer.size()
	ave_falling_slope = ave_falling_slope / PedestrianDeadReckoning.steps_buffer.size()
	ave_time_between_peaks = ave_time_between_peaks / PedestrianDeadReckoning.steps_buffer.size()
<<<<<<< Updated upstream
=======
=======
<<<<<<< Updated upstream
=======
>>>>>>> Stashed changes
		# FIX: skip the first step, steps[-1] would wrap to the newest step
		# and cancel out every other interval
		if i > 0:
			ave_time_between_peaks += step.peak_time - steps[i - 1].peak_time
	
	ave_step_duration /= count
	ave_peak_valley_difference /= (count * 2)
	ave_valley_difference /= count
	ave_rising_slope /= count
	ave_falling_slope /= count
	
	# FIX: there are only count - 1 intervals between peaks
	ave_time_between_peaks /= (count - 1)
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
>>>>>>> Stashed changes
	
	# set parameters
	StepDetection.settings.max_step_duration = ave_step_duration * (1.0 + window_ratio)
	StepDetection.settings.min_step_duration = ave_step_duration * (1.0 - window_ratio)
	
	# rising slope is positive
	StepDetection.settings.max_rising_slope = ave_rising_slope * (1.0 + window_ratio)
	StepDetection.settings.min_rising_slope = ave_rising_slope * (1.0 - window_ratio)
	
	# falling slope is negative: max is the steepest (most negative),
	# min is the shallowest (closest to zero)
	# FIX: this used ave_rising_slope before, which collapsed the window
	StepDetection.settings.max_falling_slope = ave_falling_slope * (1.0 + window_ratio)
	StepDetection.settings.min_falling_slope = ave_falling_slope * (1.0 - window_ratio)
	
	StepDetection.settings.max_valley_diff = ave_valley_difference * (1.0 + window_ratio)
	
<<<<<<< Updated upstream
	StepDetection.settings.min_peak_valley_diff = ave_peak_valley_difference - (ave_peak_valley_difference * window_ratio)
=======
<<<<<<< Updated upstream
<<<<<<< Updated upstream
	StepDetection.settings.min_peak_valley_diff = ave_peak_valley_difference - (ave_peak_valley_difference * window_ratio)
=======
	StepDetection.settings.min_time_between_peaks = ave_time_between_peaks * (1.0 - window_ratio)
	
	StepDetection.settings.min_peak_valley_diff = ave_peak_valley_difference * (1.0 - window_ratio)
=======
		# the first step has no previous peak, so start at 1
		if i > 0:
			ave_time_between_peaks += step.peak_time - steps[i - 1].peak_time
	
	ave_step_duration /= n
	ave_peak_valley_difference /= (n * 2)
	ave_valley_difference /= n
	ave_rising_slope /= n
	ave_falling_slope /= n
	ave_time_between_peaks /= (n - 1)
	
	# set parameters (blended, pulled toward defaults, and clamped per key)
	var hi:float = 1.0 + window_ratio
	var lo:float = 1.0 - window_ratio
	
	_blend("max_step_duration", ave_step_duration * hi)
	_blend("min_step_duration", ave_step_duration * lo)
	
	_blend("max_rising_slope", ave_rising_slope * hi)
	_blend("min_rising_slope", ave_rising_slope * lo)
	
	# falling slopes are negative, so *hi is the more negative bound
	# and *lo is the less negative bound (matches the check in StepDetection)
	_blend("max_falling_slope", ave_falling_slope * hi)
	_blend("min_falling_slope", ave_falling_slope * lo)
	
	_blend("max_valley_diff", ave_valley_difference * hi)
	_blend("min_time_between_peaks", ave_time_between_peaks * lo)
	_blend("min_peak_valley_diff", ave_peak_valley_difference * lo)
	
	_enforce_bounds()

# keep the settings valid so detection can never be locked out
func _enforce_bounds() -> void:
	var s:Dictionary = StepDetection.settings
	
	s.min_step_duration = clampf(s.min_step_duration, step_duration_floor, step_duration_ceiling)
	s.max_step_duration = clampf(s.max_step_duration, s.min_step_duration, step_duration_ceiling)
	
	# rising: min <= max
	if s.min_rising_slope > s.max_rising_slope:
		var t = s.min_rising_slope
		s.min_rising_slope = s.max_rising_slope
		s.max_rising_slope = t
	
	# falling (negative): max_falling is the lower bound, min_falling the upper bound
	if s.max_falling_slope > s.min_falling_slope:
		var t = s.max_falling_slope
		s.max_falling_slope = s.min_falling_slope
		s.min_falling_slope = t
	
	s.min_time_between_peaks = maxf(s.min_time_between_peaks, 0.0)
	s.min_peak_valley_diff = maxf(s.min_peak_valley_diff, 0.0)
>>>>>>> Stashed changes
>>>>>>> Stashed changes
=======
	StepDetection.settings.min_time_between_peaks = ave_time_between_peaks * (1.0 - window_ratio)
	
	StepDetection.settings.min_peak_valley_diff = ave_peak_valley_difference * (1.0 - window_ratio)
>>>>>>> Stashed changes
>>>>>>> Stashed changes
