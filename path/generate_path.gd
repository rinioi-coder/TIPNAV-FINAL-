# script for generating path points from a mesh`s faces as node3ds
@tool
extends MeshInstance3D

var points = []

@export_tool_button("Generate Points","PinJoint3D") var generate:Callable = gen_points
@export_tool_button("Delete Points","CurveDelete") var delete:Callable = delete_points


func gen_points():
	var faces_pos = get_faces_pos(self)
	
	for pos in faces_pos:
		var point = MeshInstance3D.new()
		point.mesh = SphereMesh.new()
		add_child(point)
		points.append(point)
		point.global_position = pos
		point.scale = Vector3(0.1,0.1,0.1)

func delete_points():
	for point in points:
		point.queue_free()

func get_faces_pos(mesh_instance:MeshInstance3D):
	var mesh = mesh_instance.mesh
	var faces_array:Array = []
	
	for surface_idx in mesh.get_surface_count():
		var tool = MeshDataTool.new()
		tool.create_from_surface(mesh,surface_idx)
		
		for face_idx in tool.get_face_count():
			var face_pos:Vector3
			for vert_in_face in 3:
				var vert_idx = tool.get_face_vertex(face_idx,vert_in_face)
				var pos = tool.get_vertex(vert_idx)
				face_pos += pos
			faces_array.append(mesh_instance.to_global(face_pos / 3))
	
	return faces_array
