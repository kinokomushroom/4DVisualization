extends Spatial


# N-dimensional vector class
class Vector extends Resource:
	var value = []
	
	func _init(size : int):
		assert(size > 0)
		for index in size:
			value.append(0)
	
	func size() -> int:
		return value.size()
	
	func set_value(new_value):
		assert(new_value is Array and new_value.size() == size())
		value = new_value
	
	func set_element(index, new_value):
		value[index] = new_value
	
	func get_element(index) -> float:
		return value[index]
	
	func get_vector():
		match size():
			1:
				return get_element(0)
			2:
				return Vector2(get_element(0), get_element(1))
			3:
				return Vector3(get_element(0), get_element(1), get_element(2))
			_:
				assert(false)
	
	func add(vector : Vector) -> Vector:
		assert(size() == vector.size())
		var result : Vector = Vector.new(size())
		for index in size():
			result.set_element(index, get_element(index) + vector.get_element(index))
		return result
	
	func scale(scalar : float) -> Vector:
		var result : Vector = Vector.new(size())
		for index in size():
			result.set_element(index, get_element(index) * scalar)
		return result
	
	func subtract(vector : Vector) -> Vector:
		assert(size() == vector.size())
		var result : Vector = Vector.new(size())
		result = add(vector.scale(-1))
		return result
	
	func dot(vector : Vector) -> float:
		assert(size() == vector.size())
		var result : float = 0
		for index in size():
			result += get_element(index) * vector.get_element(index)
		return result
	
	func length() -> float:
		var result : float = sqrt(self.dot(self))
		return result
	
	func normalize() -> Vector:
		var result : Vector = Vector.new(size())
		result = scale(1.0 / length())
		return result
	
	func print():
		print(value)


# NxN Matrix class
class Matrix extends Resource:
	var value = []
	
	func _init(size : int):
		assert(size > 0)
		for row_index in size:
			var column_vector = Vector.new(size)
			value.append(column_vector)
	
	func size() -> int:
		return value.size()
	
	func set_value(new_value):
		assert(size() == new_value.size())
		for column_index in size():
			assert(size() == new_value[column_index].size())
			var new_column : Vector = Vector.new(size())
			new_column.set_value(new_value[column_index])
			set_column(column_index, new_column)
	
	func set_element(column_index, row_index, new_value):
		value[column_index].value[row_index] = new_value
	
	func set_column(column_index, new_value):
		assert(new_value.size() == size())
		value[column_index] = new_value
	
	func set_row(row_index, new_value):
		assert(new_value.size() == size())
		for column_index in size():
			set_element(column_index, row_index, new_value.get_element(column_index))
	
	func get_element(column_index, row_index) -> float:
		return value[column_index].value[row_index]
	
	func get_column(column_index) -> Vector:
		return value[column_index]
	
	func get_row(row_index) -> Vector:
		var result : Vector = Vector.new(size())
		for column_index in size():
			result.set_element(column_index, get_element(column_index, row_index))
		return result
	
	func init_zero():
		for column_index in size():
			for row_index in size():
				set_element(column_index, row_index, 0)
	
	func init_identity():
		for column_index in size():
			for row_index in size():
				set_element(column_index, row_index, int(column_index == row_index))
	
	func init_rotation(first_index : int, second_index : int, angle : float):
		assert(first_index != second_index)
		init_identity()
		set_element(first_index, first_index, cos(angle))
		set_element(first_index, second_index, sin(angle))
		set_element(second_index, first_index, -sin(angle))
		set_element(second_index, second_index, cos(angle))
	
	func add(matrix : Matrix) -> Matrix:
		assert(size() == matrix.size())
		var result : Matrix = Matrix.new(size())
		for column_index in size():
			result.set_column(column_index, get_column(column_index).add(matrix.get_column(column_index)))
		return result
	
	func scale(scalar : float) -> Matrix:
		var result : Matrix = Matrix.new(size())
		for column_index in size():
			result.set_column(column_index, get_column(column_index).scale(scalar))
		return result
	
	func multiply_vector(vector : Vector) -> Vector:
		assert(size() == vector.size())
		var result : Vector = Vector.new(size())
		for row_index in size():
			result.set_element(row_index, get_row(row_index).dot(vector))
		return result
	
	func multiply_matrix(matrix : Matrix) -> Matrix:
		assert(size() == matrix.size())
		var result : Matrix = Matrix.new(size())
		for column_index in size():
			result.set_column(column_index, multiply_vector(matrix.get_column(column_index)))
		return result
	
	func eliminated(eliminate_column_index, eliminate_row_index) -> Matrix:
		var result : Matrix = Matrix.new(size() - 1)
		for column_index in size() - 1:
			for row_index in size() - 1:
				result.set_element(column_index, row_index, get_element(column_index + int(column_index >= eliminate_column_index), row_index + int(row_index >= eliminate_row_index)))
		return result
	
	func determinant() -> float:
		var result : float = 0
		if size() == 1:
			result = get_element(0, 0)
		else:
			for column_index in size():
				result += get_element(column_index, 0) * pow(-1, column_index) * eliminated(column_index, 0).determinant()
		return result
	
	func inverse() -> Matrix:
		var result : Matrix = Matrix.new(size())
		for column_index in size():
			for row_index in size():
				result.set_element(column_index, row_index, eliminated(row_index, column_index).determinant() * pow(-1, column_index + row_index))
		result = result.scale(1.0 / determinant())
		return result
	
	func print():
		for row_index in size():
			print(value[row_index].value)
		print("")


# variable declarations
var ball_scene = load("res://Ball.tscn")
var rod_scene = load("res://Rod.tscn")

var camera_rotation_speed = 0.6
var camera_zoom_speed = 0.2

var camera_4d_fixed_position : Vector = Vector.new(4)
var camera_4d_fixed_basis : Matrix = Matrix.new(4)
var camera_4d_free_position : Vector = Vector.new(4)
var camera_4d_free_basis : Matrix = Matrix.new(4)
var camera_4d_free_distance : float = 1.5
var camera_4d_free_translation_speed : float = 1.0
var camera_4d_free_rotation_speed : float = 1.0

var axis_colors = [Color(1, 0, 0), Color(0, 1, 0), Color(0, 0, 1), Color(1, 1, 0)]

var is_perspective : bool = false
var show_coordinates : bool = false
var show_basis : bool = true
var show_orientation : bool = false
var show_points : bool = false
var show_lines : bool = true

var points = [] # stores the position vectors of every point in the 4D shape
var lines = [] # stores the start and end point indices for every line in the 4D shape


# clear all balls and rods
func reset_shapes():
	for ball in $CameraPosition/Viewport/Balls.get_children():
		$CameraPosition/Viewport/Balls.remove_child(ball)
		ball.queue_free()
	for ball in $Projection/Viewport/Balls.get_children():
		$Projection/Viewport/Balls.remove_child(ball)
		ball.queue_free()
	for rod in $CameraPosition/Viewport/Rods.get_children():
		$CameraPosition/Viewport/Rods.remove_child(rod)
		rod.queue_free()
	for rod in $Projection/Viewport/Rods.get_children():
		$Projection/Viewport/Rods.remove_child(rod)
		rod.queue_free()

# add ball
func draw_ball(position : Vector3, color : Color, size : float, viewport_1 : bool):
	var ball : Spatial = ball_scene.instance()
	if viewport_1:
		$CameraPosition/Viewport/Balls.add_child(ball)
	else:
		$Projection/Viewport/Balls.add_child(ball)
	ball.translation = position
	ball.scale = Vector3(size, size, size)
	ball.get_node("MeshInstance").get_surface_material(0).albedo_color = color

# add rod
func draw_rod(position_1 : Vector3, position_2 : Vector3, color : Color, size : float, viewport_1 : bool):
	var rod : Spatial = rod_scene.instance()
	if viewport_1:
		$CameraPosition/Viewport/Rods.add_child(rod)
	else:
		$Projection/Viewport/Rods.add_child(rod)
	# scale rod to (position_1 - position_2)'s length
	var rod_length : float = (position_2 - position_1).length()
	rod.scale.z = rod_length
	# set rod's starting position to position_1 and rotate it towards position_2
	if rod_length != 0:
		if (position_2 - position_1).cross(Vector3(0, 1, 0)).length() != 0:
			rod.look_at_from_position(position_1, position_2, Vector3(0, 1, 0))
		else:
			rod.look_at_from_position(position_1, position_2, Vector3(1, 0, 0))
	else:
		rod.translation = position_1
	rod.scale *= Vector3(size, size, 1.0)
	rod.get_node("MeshInstance").get_surface_material(0).albedo_color = color

# calculate projection from 4d to 3d
func project_4d_3d(vector_4d : Vector, camera_4d_position : Vector, camera_4d_basis_inverse : Matrix, perspective : bool) -> Vector3:
	assert(vector_4d.size() == 4 and camera_4d_position.size() == 4 and camera_4d_basis_inverse.size() == 4)
	var transformed_vector : Vector = Vector.new(4)
	transformed_vector = vector_4d.subtract(camera_4d_position)
	transformed_vector = camera_4d_basis_inverse.multiply_vector(transformed_vector)
	var result : Vector = Vector.new(3)
	result.set_value([transformed_vector.get_element(0), transformed_vector.get_element(1), transformed_vector.get_element(2)])
	if perspective: # divide XYZ coordinates by W coordinate for perspective projection
		result = result.scale(1.0 / abs(transformed_vector.get_element(3)))
	return result.get_vector() * 2.0

# draw basis vectors
func draw_basis(origin : Vector, basis_matrix : Matrix, camera_4d_position : Vector, camera_4d_basis_inverse : Matrix, viewport_1 : bool, perspective : bool, scale : float = 1.0):
	draw_ball(project_4d_3d(origin, camera_4d_position, camera_4d_basis_inverse, perspective), Color(1, 1, 1), 0.5 * scale, viewport_1)
	for axis_index in 4:
		var axis_basis : Vector = basis_matrix.get_column(axis_index).scale(scale).add(origin)
		draw_ball(project_4d_3d(axis_basis, camera_4d_position, camera_4d_basis_inverse, perspective), axis_colors[axis_index], 0.5 * scale, viewport_1)
		draw_rod(project_4d_3d(origin, camera_4d_position, camera_4d_basis_inverse, perspective), project_4d_3d(axis_basis, camera_4d_position, camera_4d_basis_inverse, perspective), axis_colors[axis_index], 0.5 * scale, viewport_1)

func update_camera_position():
	camera_4d_free_position = camera_4d_free_basis.get_column(3).scale(-camera_4d_free_distance)

func reset_geometry():
	points.clear()
	lines.clear()

# functions below calculate the position vectors and lines of respective 4D shape
func generate_hypercube(size : float):
	reset_geometry()
	
	for x in 2:
		for y in 2:
			for z in 2:
				for w in 2:
					var point_position : Vector = Vector.new(4)
					point_position.set_value([x * 2 - 1, y * 2 - 1, z * 2 - 1, w * 2 - 1])
					points.append(point_position)
	
	for index_1 in points.size():
		for index_2 in points.size():
			var point_1 : Vector = points[index_1]
			var point_2 : Vector = points[index_2]
			if point_1.subtract(point_2).length() == 2:
				if lines.find([index_2, index_1]) == -1:
					lines.append([index_1, index_2])
	
	for index in points.size():
		points[index] = points[index].scale(size)

func generate_cube(size : float):
	reset_geometry()
	
	for x in 2:
		for y in 2:
			for z in 2:
				var point_position : Vector = Vector.new(4)
				point_position.set_value([x * 2 - 1, y * 2 - 1, z * 2 - 1, 0])
				points.append(point_position)
	
	for index_1 in points.size():
		for index_2 in points.size():
			var point_1 : Vector = points[index_1]
			var point_2 : Vector = points[index_2]
			if point_1.subtract(point_2).length() == 2:
				if lines.find([index_2, index_1]) == -1:
					lines.append([index_1, index_2])
	
	for index in points.size():
		points[index] = points[index].scale(size)

func generate_planes(size : float):
	reset_geometry()
	
	for x in 2:
		for y in 2:
			var point_position : Vector = Vector.new(4)
			point_position.set_value([x * 2 - 1, y * 2 - 1, 0, 0])
			points.append(point_position)
	for z in 2:
		for w in 2:
			var point_position : Vector = Vector.new(4)
			point_position.set_value([0, 0, z * 2 - 1, w * 2 - 1])
			points.append(point_position)
	
	for index_1 in 2:
		for index_2 in 2:
			lines.append([index_1 * 3, index_2 + 1])
			lines.append([4 + index_1 * 3, 4 + index_2 + 1])
	
	for index in points.size():
		points[index] = points[index].scale(size)

func generate_fivecell(size : float):
	reset_geometry()
	
	for index in 5:
		points.append(Vector.new(4))
	points[0].set_value([1, 1, 1, 0])
	points[1].set_value([-1, 1, -1, 0])
	points[2].set_value([1, -1, -1, 0])
	points[3].set_value([-1, -1, 1, 0])
	var rotation_matrix_1 : Matrix = Matrix.new(4)
	var rotation_matrix_2 : Matrix = Matrix.new(4)
	rotation_matrix_1.init_rotation(0, 2, PI/4)
	rotation_matrix_2.init_rotation(1, 2, atan(sqrt(2)))
	for index in 4:
		points[index] = rotation_matrix_2.multiply_matrix(rotation_matrix_1).multiply_vector(points[index])
	points[4].set_value([0, 0, 0, sqrt(5)])
	
	for index_1 in points.size():
		for index_2 in points.size():
			var point_1 : Vector = points[index_1]
			var point_2 : Vector = points[index_2]
			if index_1 != index_2 and lines.find([index_2, index_1]) == -1:
				lines.append([index_1, index_2])
	
	for index in points.size():
		points[index] = points[index].scale(1.0 / sqrt(3) * size)

# helper function for generate_sphere
func generate_circle(axis_1 : int, axis_2 : int, point_count : int):
	var point_position : Vector = Vector.new(4)
	point_position.set_element(axis_1, 1)
	var rotation_matrix : Matrix = Matrix.new(4)
	rotation_matrix.init_rotation(axis_1, axis_2, 2 * PI / point_count)
	
	for index in point_count:
		var start_index : int = floor(points.size() / point_count) * point_count
		points.append(point_position)
		lines.append([start_index + index, start_index + (index + 1) % point_count])
		point_position = rotation_matrix.multiply_vector(point_position)

# actually generates six 2D circles
func generate_sphere(point_count : int, size : float):
	reset_geometry()
	
	generate_circle(0, 1, point_count)
	generate_circle(0, 2, point_count)
	generate_circle(0, 3, point_count)
	generate_circle(1, 2, point_count)
	generate_circle(1, 3, point_count)
	generate_circle(2, 3, point_count)
	
	for index in points.size():
		points[index] = points[index].scale(size)

func print_rotation(coord_1 : String, coord_2 : String, sign_direction : int):
	if sign_direction > 0:
		$rotation.text = coord_1 + coord_2 + " rotation"
	else:
		$rotation.text = coord_2 + coord_1 + " rotation"


# called at start of program
func _ready():
	camera_4d_fixed_position.set_value([3, 3, 3, 3])
	camera_4d_fixed_basis.set_value([[1, -1, -1, 1], [-1, 1, -1, 1], [-1, -1, 1, 1], [-1, -1, -1, -1]])
	camera_4d_free_basis.init_identity()
	update_camera_position()
	
	reset_geometry()
	
	$controls_panel.visible = false


# handle mouse inputs
func _input(event):
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("Camera1"):
			$CameraPosition/Viewport/CameraOrigin.rotation_degrees.y += -event.relative.x * camera_rotation_speed
			$CameraPosition/Viewport/CameraOrigin.rotation_degrees.x += -event.relative.y * camera_rotation_speed
		if Input.is_action_pressed("Camera2"):
			$Projection/Viewport/CameraOrigin.rotation_degrees.y += -event.relative.x * camera_rotation_speed
			$Projection/Viewport/CameraOrigin.rotation_degrees.x += -event.relative.y * camera_rotation_speed
	if event is InputEventMouseButton:
		if Input.is_action_pressed("Camera1"):
			$CameraPosition/Viewport/CameraOrigin/Camera.translation.z += (-int(event.button_index == BUTTON_WHEEL_UP) + int(event.button_index == BUTTON_WHEEL_DOWN)) * camera_zoom_speed
		if Input.is_action_pressed("Camera2"):
			$Projection/Viewport/CameraOrigin/Camera.translation.z += (-int(event.button_index == BUTTON_WHEEL_UP) + int(event.button_index == BUTTON_WHEEL_DOWN)) * camera_zoom_speed


# called every frame
func _process(delta):
	reset_shapes()
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	# invert rotation direction when Shift key is pressed
	var sign_direction : int = 1
	if Input.is_action_pressed("Negative"):
		sign_direction = -1
	
	# rotate camera position and basis based on keyboard inputs
	var rotation_matrix : Matrix = Matrix.new(4)
	rotation_matrix.init_identity()
	print_rotation("no", "", sign_direction)
	if Input.is_action_pressed("X"):
		if Input.is_action_pressed("Y"):
			rotation_matrix.init_rotation(0, 1, sign_direction * camera_4d_free_rotation_speed * delta)
			print_rotation("X", "Y", sign_direction)
		if Input.is_action_pressed("Z"):
			rotation_matrix.init_rotation(0, 2, sign_direction * camera_4d_free_rotation_speed * delta)
			print_rotation("X", "Z", sign_direction)
		if Input.is_action_pressed("W"):
			rotation_matrix.init_rotation(0, 3, sign_direction * camera_4d_free_rotation_speed * delta)
			print_rotation("X", "W", sign_direction)
	if Input.is_action_pressed("Y"):
		if Input.is_action_pressed("Z"):
			rotation_matrix.init_rotation(1, 2, sign_direction * camera_4d_free_rotation_speed * delta)
			print_rotation("Y", "Z", sign_direction)
		if Input.is_action_pressed("W"):
			rotation_matrix.init_rotation(1, 3, sign_direction * camera_4d_free_rotation_speed * delta)
			print_rotation("Y", "W", sign_direction)
	if Input.is_action_pressed("Z"):
		if Input.is_action_pressed("W"):
			rotation_matrix.init_rotation(2, 3, sign_direction * camera_4d_free_rotation_speed * delta)
			print_rotation("Z", "W", sign_direction)
	if Input.is_action_pressed("Closer"):
		camera_4d_free_distance += -camera_4d_free_translation_speed * delta
	if Input.is_action_pressed("Further"):
		camera_4d_free_distance += camera_4d_free_translation_speed * delta
	camera_4d_free_basis = rotation_matrix.multiply_matrix(camera_4d_free_basis)
	update_camera_position()
	
	
	# draw left half of window
	var camera_4d_fixed_basis_inverse = camera_4d_fixed_basis.inverse()
	var origin : Vector = Vector.new(4)
	var basis : Matrix = Matrix.new(4)
	basis.init_identity()
	# draw world basis
	draw_basis(origin, basis, camera_4d_fixed_position, camera_4d_fixed_basis_inverse, true, false)
	# draw camera position
	draw_ball(project_4d_3d(camera_4d_free_position, camera_4d_fixed_position, camera_4d_fixed_basis_inverse, false), Color(0, 0, 0), 0.8, true)
	# draw camera basis
	if show_orientation:
		draw_basis(camera_4d_free_position, camera_4d_free_basis, camera_4d_fixed_position, camera_4d_fixed_basis_inverse, true, false, 0.5)
	# draw camera coordinates with lines
	if show_coordinates:
		var x_position : Vector = Vector.new(4)
		x_position.set_value([camera_4d_free_position.get_element(0), 0, 0, 0])
		var xy_position : Vector = Vector.new(4)
		xy_position.set_value([camera_4d_free_position.get_element(0), camera_4d_free_position.get_element(1), 0, 0])
		var xyz_position : Vector = Vector.new(4)
		xyz_position.set_value([camera_4d_free_position.get_element(0), camera_4d_free_position.get_element(1), camera_4d_free_position.get_element(2), 0])
		draw_rod(project_4d_3d(origin, camera_4d_fixed_position, camera_4d_fixed_basis_inverse, false), project_4d_3d(x_position, camera_4d_fixed_position, camera_4d_fixed_basis_inverse, false), axis_colors[0], 0.2, true)
		draw_rod(project_4d_3d(x_position, camera_4d_fixed_position, camera_4d_fixed_basis_inverse, false), project_4d_3d(xy_position, camera_4d_fixed_position, camera_4d_fixed_basis_inverse, false), axis_colors[1], 0.2, true)
		draw_rod(project_4d_3d(xy_position, camera_4d_fixed_position, camera_4d_fixed_basis_inverse, false), project_4d_3d(xyz_position, camera_4d_fixed_position, camera_4d_fixed_basis_inverse, false), axis_colors[2], 0.2, true)
		draw_rod(project_4d_3d(xyz_position, camera_4d_fixed_position, camera_4d_fixed_basis_inverse, false), project_4d_3d(camera_4d_free_position, camera_4d_fixed_position, camera_4d_fixed_basis_inverse, false), axis_colors[3], 0.2, true)
	
	
	# draw right half of window
	var camera_4d_free_basis_inverse = camera_4d_free_basis.inverse()
	var projected_points = []
	# calculate projected coordinate of every point in 4D shape
	for point_position in points:
		projected_points.append(project_4d_3d(point_position, camera_4d_free_position, camera_4d_free_basis_inverse, is_perspective))
	# draw world basis
	if show_basis:
		draw_basis(origin, basis, camera_4d_free_position, camera_4d_free_basis_inverse, false, is_perspective)
	# draw points of 4D shape as balls
	if show_points:
		for point in projected_points:
			draw_ball(point, Color(0, 0, 0), 0.8, false)
	# draw lines of 4D shape as rods
	if show_lines:
		for line in lines:
			draw_rod(projected_points[line[0]], projected_points[line[1]], Color(0, 0, 0), 0.8, false)


# all functions below are called when respective UI inputs are sent
func _on_perspective_toggled(button_pressed):
	is_perspective = button_pressed
	if is_perspective:
		$perspective.text = "perspective"
	else:
		$perspective.text = "orthographic"

func _on_coordinates_toggled(button_pressed):
	show_coordinates = button_pressed
	if show_coordinates:
		$coordinates.text = "hide coordinates"
	else:
		$coordinates.text = "show coordinates"

func _on_reset_pressed():
	camera_4d_free_basis.init_identity()
	update_camera_position()

func _on_show_basis_toggled(button_pressed):
	show_basis = button_pressed
	if show_basis:
		$show_basis.text = "hide basis"
	else:
		$show_basis.text = "show basis"

func _on_none_pressed():
	reset_geometry()
	$geometry.text = "none"

func _on_hypercube_pressed():
	generate_hypercube(0.5)
	$geometry.text = "tesseract"

func _on_cube_pressed():
	generate_cube(0.5)
	$geometry.text = "cube"

func _on_planes_pressed():
	generate_planes(0.5)
	$geometry.text = "planes"

func _on_fivecell_pressed():
	generate_fivecell(0.8)
	$geometry.text = "fivecell"

func _on_sphere_pressed():
	generate_sphere(12, 1.0)
	$geometry.text = "4-sphere"

func _on_orientation_toggled(button_pressed):
	show_orientation = button_pressed
	if show_orientation:
		$orientation.text = "hide orientation"
	else:
		$orientation.text = "show orientation"

func _on_points_toggled(button_pressed):
	show_points = button_pressed
	if show_points:
		$points.text = "hide points"
	else:
		$points.text = "show points"

func _on_lines_toggled(button_pressed):
	show_lines = button_pressed
	if show_lines:
		$lines.text = "hide lines"
	else:
		$lines.text = "show lines"


func _on_show_control_toggled(button_pressed):
	if button_pressed:
		$controls_panel.visible = true
		$show_control.text = "hide controls"
	else:
		$controls_panel.visible = false
		$show_control.text = "show controls"
		
