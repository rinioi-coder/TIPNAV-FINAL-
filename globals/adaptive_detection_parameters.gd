# singleton for step detection adaptive parameter calculations
extends Node

# settings
var window_ratio:float = .2

# calculate new parameter values
# based on recent data
func update_parameters():
	if PedestrianDeadReckoning.steps_buffer.size() < PedestrianDeadReckoning.steps_buffer_size: return
	
	# initialize temporary values
	var ave_step_duration:float = 0.0
	
	var ave_peak_valley_difference:float = 0.0
	var ave_valley_difference:float = 0.0
	
	var ave_rising_slope:float = 0.0
	var ave_falling_slope:float = 0.0
	
	var ave_time_between_peaks:float = 0.0
	
	# calculate parameters
	for i in range(PedestrianDeadReckoning.steps_buffer.size()):
		var step = PedestrianDeadReckoning.steps_buffer[i]
		
		ave_step_duration += step.data[step.data.size() - 1].recorded_time - step.data[0].recorded_time
		
		ave_peak_valley_difference += step.data[step.peak_index].acc_magn_lerped - step.data[0].acc_magn_lerped
		ave_peak_valley_difference += step.data[step.data.size() - 1].acc_magn_lerped - step.data[step.peak_index].acc_magn_lerped
		
		ave_valley_difference += abs(step.data[0].acc_magn_lerped - step.data[step.data.size() - 1].acc_magn_lerped)
		
		ave_rising_slope += StepDetection.calc_lin_regr(step)[0]
		ave_falling_slope += StepDetection.calc_lin_regr(step)[1]
		
		ave_time_between_peaks += step.peak_time - PedestrianDeadReckoning.steps_buffer[i - 1].peak_time
		
	ave_step_duration = ave_step_duration / PedestrianDeadReckoning.steps_buffer.size()
	ave_peak_valley_difference = ave_peak_valley_difference / (PedestrianDeadReckoning.steps_buffer.size() * 2)
	ave_valley_difference = ave_valley_difference / PedestrianDeadReckoning.steps_buffer.size()
	ave_rising_slope = ave_rising_slope / PedestrianDeadReckoning.steps_buffer.size()
	ave_falling_slope = ave_falling_slope / PedestrianDeadReckoning.steps_buffer.size()
	ave_time_between_peaks = ave_time_between_peaks / PedestrianDeadReckoning.steps_buffer.size()
	
	# set parameters
	StepDetection.settings.max_step_duration = ave_step_duration + (ave_step_duration * window_ratio)
	StepDetection.settings.min_step_duration = ave_step_duration - (ave_step_duration * window_ratio)
	
	StepDetection.settings.max_rising_slope = ave_rising_slope + (ave_rising_slope * window_ratio)
	StepDetection.settings.min_rising_slope = ave_rising_slope - (ave_rising_slope * window_ratio)
	StepDetection.settings.max_falling_slope = ave_falling_slope + (ave_falling_slope * window_ratio)
	StepDetection.settings.min_falling_slope = ave_falling_slope - (ave_rising_slope * window_ratio)
	
	StepDetection.settings.max_valley_diff = ave_valley_difference + (ave_valley_difference * window_ratio)
	
	StepDetection.settings.min_time_between_peaks = ave_time_between_peaks - (ave_time_between_peaks * window_ratio)
	
	StepDetection.settings.min_peak_valley_diff = ave_peak_valley_difference - (ave_peak_valley_difference * window_ratio)
