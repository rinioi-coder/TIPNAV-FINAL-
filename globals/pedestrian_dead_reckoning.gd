# singleton for handling pedestrian dead reckoning stuff
extends Node

#	----------	DATA STRUCTURE	----------

# data point structure
#{
	#"recorded_time":Time.get_ticks_msec(),
	#
	#"acc_time":Accelerometer.data_timestamp,
	#"gyro_time":Gyroscope.data_timestamp,
	
	#"acc":Accelerometer.data,
	#"acc_magn":Accelerometer.data_magn,
	#"acc_magn_smooth":Accelerometer.data_magn_smooth,
	
	#"heading":Magnetometer.heading,
	#"heading_smooth":Magnetometer.heading_smooth,
	
	#"gyro":Gyroscope.data,
	#"gyro_magn":Gyroscope.data_magn,
	#"gyro_magn_smooth":Gyroscope.data_magn_smooth,
	#}

# step data structure
#{
	#"data":[ array of multiple data points ],
	#"peak_index":int,
	#"peak_time":float,
	#"length":float,
	#"heading":float,
#}

#	----------	SETTINGS	----------
var sampling_rate:int = 100
var steps_buffer_size:int = 20

#	-----------	SIGNALS	----------
signal step_occured(step_data:Dictionary)

#	-----------	VARIABLES	----------

# buffer
var buffer:Array = []
var steps_buffer:Array = []

# sampling rate variables
var sampling_interval:float:
	get:
		return 1.0 / sampling_rate
var accumulator:float = 0.0

# data timestamp
var prev_acc_timestamp:float = -1.0
var prev_gyro_timestamp:float = -1.0

#	-----------	FUNCTIONS	----------

# calculate
func _process(delta: float) -> void:
	
	# execute according to sampling rate
	accumulator += delta
	while  accumulator >= sampling_interval:
		accumulator -= sampling_interval
		
		# check data timestamp
		if Accelerometer.data_timestamp == prev_acc_timestamp: continue
		if Gyroscope.data_timestamp == prev_gyro_timestamp: continue
		
		# record data
		var data:Dictionary = {
			"recorded_time":Time.get_ticks_msec(),
			
			"acc_time":Accelerometer.data_timestamp,
			"gyro_time":Gyroscope.data_timestamp,
			
			"acc":Accelerometer.data,
			"acc_magn":Accelerometer.data_magn,
			"acc_magn_lerped":Accelerometer.data_magn_lerped,
			"acc_magn_smooth":Accelerometer.data_magn_smooth,
			
			"heading":Magnetometer.heading,
			"heading_smooth":Magnetometer.heading_smooth,
			
			"gyro":Gyroscope.data,
			"gyro_magn":Gyroscope.data_magn,
			"gyro_magn_lerped":Gyroscope.data_magn_lerped,
			"gyro_magn_smooth":Gyroscope.data_magn_smooth,
		}
		
		buffer.append(data)
		
		# update time stamp
		prev_acc_timestamp = Accelerometer.data_timestamp
		prev_gyro_timestamp = Gyroscope.data_timestamp
		
		# find steps
		var step = StepDetection.find(buffer)
		
		if step != null:
			# emit signal & record step
			step_occured.emit(step)
			steps_buffer.append(step)
<<<<<<< Updated upstream
			if not steps_buffer.size() > steps_buffer_size: 
=======
<<<<<<< Updated upstream
<<<<<<< Updated upstream
			if not steps_buffer.size() > steps_buffer_size: 
=======
<<<<<<< Updated upstream
=======
>>>>>>> Stashed changes
			
			# clean steps buffer
			if steps_buffer.size() > steps_buffer_size:
				steps_buffer.pop_front()
			
			# update parameters
			AdaptiveDetectionParameters.update_parameters()
<<<<<<< Updated upstream
=======
			if steps_buffer.size() >= steps_buffer_size:
>>>>>>> Stashed changes
>>>>>>> Stashed changes
				AdaptiveDetectionParameters.update_parameters()
		
		# clean steps buffer
		if steps_buffer.size() > steps_buffer_size:
			steps_buffer.pop_front()
<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
=======
>>>>>>> Stashed changes
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
>>>>>>> Stashed changes
		
		# clean buffer
		if buffer.size() > 3:
			buffer.pop_front()
