extends CharacterBody3D

const HUMAN_SPEED = 5.0
const RAT_SPEED = 2.5
const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var look_dir: Vector2 
@onready var camera = $Camera3D
@onready var humanMesh = $HumanMesh
@onready var humanCollisionShape = $HumanCollisionShape
@onready var ratMesh = $RatMesh
@onready var ratCollisionShape = $RatCollisionShape
var camera_sens = 50
var is_mouse_visible = true

var isRat

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	get_parent().change_color.connect(_on_change_color)
	
	camera.current = is_multiplayer_authority()
	if is_multiplayer_authority(): 
		position.y = 6
		isRat = $"../".playerInformation[name.to_int()][0]
		change_form()
		

func change_form():
	if isRat:
		humanMesh.hide()
		humanCollisionShape.disabled = true
		ratMesh.show()
		ratCollisionShape.disabled = false
	else:
		humanMesh.show()
		humanCollisionShape.disabled = false
		ratMesh.hide()
		ratCollisionShape.disabled = true

func _on_change_color(color, id):
	if id == name.to_int():
		match color:
			1:
				humanMesh.set_surface_override_material(0, load("res://materials/human_blue.tres"))
				ratMesh.set_surface_override_material(0, load("res://materials/rat_blue.tres"))
			2:
				humanMesh.set_surface_override_material(0, load("res://materials/human_brown.tres"))
				ratMesh.set_surface_override_material(0, load("res://materials/rat_brown.tres"))
			3:
				humanMesh.set_surface_override_material(0, load("res://materials/human_green.tres"))
				ratMesh.set_surface_override_material(0, load("res://materials/rat_green.tres"))
			4:
				humanMesh.set_surface_override_material(0, load("res://materials/human_red.tres"))
				ratMesh.set_surface_override_material(0, load("res://materials/rat_red.tres"))
			5:
				humanMesh.set_surface_override_material(0, load("res://materials/human_white.tres"))
				ratMesh.set_surface_override_material(0, load("res://materials/rat_white.tres"))

func _physics_process(delta):
	if is_multiplayer_authority():
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta

		# Handle Jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var input_dir = Input.get_vector("left", "right", "up", "down")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			if isRat:
				velocity.x = direction.x * RAT_SPEED
				velocity.z = direction.z * RAT_SPEED
			else:
				velocity.x = direction.x * HUMAN_SPEED
				velocity.z = direction.z * HUMAN_SPEED
		else:
			if isRat:
				velocity.x = move_toward(velocity.x, 0, RAT_SPEED)
				velocity.z = move_toward(velocity.z, 0, RAT_SPEED)
			else:
				velocity.x = move_toward(velocity.x, 0, HUMAN_SPEED)
				velocity.z = move_toward(velocity.z, 0, HUMAN_SPEED)
		
		if Input.is_action_just_pressed("quit"):
			get_tree().quit()
		
		if Input.is_action_just_pressed("left_click"):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			is_mouse_visible = false
		
		if Input.is_action_just_pressed("right_click"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			is_mouse_visible = true
		
		if Input.is_action_just_pressed("change_form"):
			if isRat: isRat = false
			else: isRat = true
			position.y = 6
			change_form()
		
		_rotate_camera(delta)
		move_and_slide()

func _input(event: InputEvent):
	if event is InputEventMouseMotion and !is_mouse_visible: look_dir = event.relative * 0.01
	
func _rotate_camera(delta: float, sens_mod: float = 1.0):
	rotation.y -= look_dir.x *camera_sens * delta
	camera.rotation.x = clamp(camera.rotation.x - look_dir.y * camera_sens * sens_mod * delta, -1.5, 1.5)
	look_dir = Vector2.ZERO
