# singleton for managing paths
extends Node


var batch_size: int = 500
var points:PackedVector3Array = []

# get closest
func get_closest_point(pos: Vector3, search_radius: float = 5.0) -> Vector3:
	var closest_point := Vector3.ZERO
	var closest_distance := search_radius * search_radius
	
	for point in points:
		var distance := pos.distance_squared_to(point)
		
		if distance < closest_distance:
			closest_distance = distance
			closest_point = point
	
	return closest_point

# initialize path
func initialize(mesh_instance: MeshInstance3D):
	if points.size() > 0:
		points.clear()
	
	if not is_instance_valid(mesh_instance):
		return points
	
	var mesh := mesh_instance.mesh
	
	if mesh == null:
		return points
	
	var processed_faces := 0
	
	for surface_idx in mesh.get_surface_count():
		var tool := MeshDataTool.new()
		var error := tool.create_from_surface(mesh, surface_idx)
		
		if error != OK:
			continue
		
		for face_idx in tool.get_face_count():
			var face_pos := Vector3.ZERO
			
			for vert_in_face in 3:
				var vert_idx := tool.get_face_vertex(face_idx, vert_in_face)
				face_pos += tool.get_vertex(vert_idx)
			
			# Convert face center to global coordinates.
			points.append(
				mesh_instance.to_global(face_pos / 3.0)
			)
			
			processed_faces += 1
			
			if processed_faces % batch_size == 0:
				await get_tree().process_frame
		
		tool.clear()
