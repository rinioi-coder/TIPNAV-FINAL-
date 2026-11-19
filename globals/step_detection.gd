# class used for peak finding and validation
extends Node

# create validation settings
var settings:Dictionary =  {
	# max and min step duration (msec)
	"max_step_duration":1000,
	"min_step_duration":100,
	
	# max and min slope for rising and falling of data
	"max_rising_slope":100,
	"min_rising_slope":1.5,
	"max_falling_slope":-100,
	"min_falling_slope":-1.5,
	
	# max difference between neg and pos valley
	"max_valley_diff":50,
	
	# min time between peaks (msec)
	"min_time_between_peaks":50,
	
	# minimum difference between peak and valley
	"min_peak_valley_diff":0,
	
	# min peak height
	"min_peak_value":0,
	"max_peak_value":100,
}

# temporary peak data
var temp_peak_data:Dictionary = {
	"data":[],
	"peak_index":null,
	"peak_time":null,
	"length":null,
	"heading":null,
}
# default settings
var default_settings:Dictionary ={}

# previous peak time
var prev_peak_time:float = -INF

# initialize
func _ready() -> void:
	
	# store default settings
	default_settings = settings.duplicate(true)

# reset temporary data
func reset_temp():
	temp_peak_data.data.clear()
	temp_peak_data.peak_index = null
	temp_peak_data.peak_time = null

# find steps
func find(buffer:Array):
	if buffer.size() < 3: return
	
	# get data
	var newest_data = buffer[buffer.size() - 1]
	var second_data = buffer[buffer.size() - 2]
	var third_data = buffer[buffer.size() - 3]
	
	if (temp_peak_data.data.size() == 0
	and temp_peak_data.peak_index == null
	and temp_peak_data.peak_time == null
	):
		# find neg valley
		
		# monitor movement
		if (newest_data.acc_magn_smooth > second_data.acc_magn_smooth
		and second_data.acc_magn_smooth <= third_data.acc_magn_smooth):
			
			# record neg valley
			temp_peak_data.data.append(second_data.duplicate(true))
			
	elif temp_peak_data.peak_index == null:
		# find peak
		
		# check condition
		var time = second_data.recorded_time
		if (time - temp_peak_data.data[0].recorded_time > settings.max_step_duration):
			reset_temp()
			return
		
		# monitor movement and check conditions
		if (newest_data.acc_magn_smooth < second_data.acc_magn_smooth
		and second_data.acc_magn_smooth > third_data.acc_magn_smooth
		
		# check condition
		and second_data.acc_magn_smooth - temp_peak_data.data[0].acc_magn_smooth
		>= settings.min_peak_valley_diff
		
		# check condition
		and second_data.recorded_time - prev_peak_time >= settings.min_time_between_peaks):
			
			# record peak
			temp_peak_data.data.append(second_data.duplicate(true))
			temp_peak_data.peak_index = temp_peak_data.data.size() - 1
			temp_peak_data.peak_time = second_data.recorded_time
			
		else:
			temp_peak_data.data.append(second_data.duplicate(true))
	else:
		# find pos valley
		
		# check condition
		var time = second_data.recorded_time
		if (time - temp_peak_data.data[0].recorded_time > settings.max_step_duration):
			reset_temp()
			return
		
		# monitor movement and check conditions
		if (newest_data.acc_magn_smooth >= second_data.acc_magn_smooth
		and second_data.acc_magn_smooth <= third_data.acc_magn_smooth
		
		# check condition
		and abs(temp_peak_data.data[0].acc_magn_smooth - second_data.acc_magn_smooth) <= settings.max_valley_diff
		
		# check condition
		and temp_peak_data.data[temp_peak_data.peak_index].acc_magn_smooth - second_data.acc_magn_smooth
		>= settings.min_peak_valley_diff):
			
			# record last data (positive valley)
			temp_peak_data.data.append(second_data.duplicate(true))
			
			# --- FINAL CHECK OF CONDITIONS --- #
			
			# check condition
			if (time - temp_peak_data.data[0].recorded_time < settings.min_step_duration):
				reset_temp()
				return
			
			# check condition
			if (temp_peak_data.data[temp_peak_data.peak_index].acc_magn_smooth < settings.min_peak_value
			or temp_peak_data.data[temp_peak_data.peak_index].acc_magn_smooth > settings.max_peak_value):
				reset_temp()
				return
			
			# check condition
			var slopes = calc_lin_regr(temp_peak_data)
			var rising_slope = slopes[0]
			var falling_slope = slopes[1]
			if (rising_slope > settings.max_rising_slope
			or rising_slope < settings.min_rising_slope):
				reset_temp()
				return
			if (falling_slope > settings.min_falling_slope
			or falling_slope < settings.max_falling_slope):
				reset_temp()
				return
			
			# calculate heading
			temp_peak_data.heading = temp_peak_data.data[0].heading - temp_peak_data.data[temp_peak_data.data.size() - 1].heading
			
			# calculate step length
			temp_peak_data.length = StepLength.calculate(temp_peak_data)
			
			# once set is completed (negative valley, peak, positive valley)
			# validate, then reset temporary data to repeat cycle
			var peak = temp_peak_data.duplicate(true)
			
			# reset template
			reset_temp()
			
			# set prev peak time
			prev_peak_time = peak.peak_time
			
			# validate other conditions
			return peak
		else:
			temp_peak_data.data.append(second_data.duplicate(true))

# Linear regression
func calc_lin_regr(peak_data:Dictionary) -> Array:
	
	var data:Array = peak_data.data
	var peak_index:int = peak_data.peak_index
	
	# Validate data
	if data.size() < 3 or peak_index <= 0 or peak_index >= data.size() - 1:
		return [ 0.0 , 0.0 ]
	
	# Get sample counts
	var count_1:int = peak_index + 1
	var count_2:int = data.size() - peak_index
	
	# Initialize averages
	var ave_time_1:float = 0.0
	var ave_time_2:float = 0.0
	
	var ave_acc_1:float = 0.0
	var ave_acc_2:float = 0.0
	
	# Calculate averages for both segments
	for i in range(data.size()):
		var sample = data[i]
		
		# Negative valley to peak
		if i <= peak_index:
			ave_time_1 += sample.recorded_time
			ave_acc_1 += sample.acc_magn_smooth
		
		# Peak to positive valley
		if i >= peak_index:
			ave_time_2 += sample.recorded_time
			ave_acc_2 += sample.acc_magn_smooth
	
	# Divide by respective sample counts
	ave_time_1 /= count_1
	ave_time_2 /= count_2
	
	ave_acc_1 /= count_1
	ave_acc_2 /= count_2
	
	# Initialize regression components
	var numerator_1:float = 0.0
	var denominator_1:float = 0.0
	
	var numerator_2:float = 0.0
	var denominator_2:float = 0.0
	
	# Calculate numerator and denominator
	for i in range(data.size()):
		var sample = data[i]
		
		# Negative valley to peak
		if i <= peak_index:
			var x1:float = (sample.recorded_time - ave_time_1) / 1000.0
			var y1:float = sample.acc_magn_smooth - ave_acc_1
			
			numerator_1 += x1 * y1
			denominator_1 += x1 * x1
		
		# Peak to positive valley
		if i >= peak_index:
			var x2:float = (sample.recorded_time - ave_time_2) / 1000.0
			var y2:float = sample.acc_magn_smooth - ave_acc_2
			
			numerator_2 += x2 * y2
			denominator_2 += x2 * x2
	
	# Calculate slopes
	var slope_1:float = 0.0
	var slope_2:float = 0.0
	
	if denominator_1 > 0.0:
		slope_1 = numerator_1 / denominator_1
	
	if denominator_2 > 0.0:
		slope_2 = numerator_2 / denominator_2
	
	# Return results
	return [ slope_1 , slope_2 ]
