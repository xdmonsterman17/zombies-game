extends CharacterBody3D

# How fast this meatbag can flee from impending doom.
@export var speed := 6.0

# Because sometimes you just need to hop slightly over a zombie's ankle.
@export var jump_velocity := 4.5

# Isaac Newton's fault. We grab it from project settings so the physics play nice.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# The magic window through which we view the apocalypse.
@onready var camera: Camera3D = $Camera3D

func _enter_tree() -> void:
	# Call dibs on this character. 
	# "str(name).to_int()" turns the player's network peer ID into the boss of this node.
	# Without this, everyone drives the same flesh-suit and it's a disaster.
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	# Blindfold the clones! If this isn't OUR character, turn off their camera.
	# Otherwise, you'll be experiencing a very confusing, multiplayer out-of-body experience.
	if not is_multiplayer_authority():
		camera.current = false

func _physics_process(delta: float) -> void:
	# The endless treadmill of existence.
	
	# If I don't own this character, I have no business telling it what to do. Back away slowly.
	if not is_multiplayer_authority():
		return

	# 1. Handle Gravity (Reminding the player they aren't a bird)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Handle Jump (The panic button)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# 3. Handle Movement (The "run away" vectors)
	# get_vector is a saint. It seamlessly handles elegant WASD keystrokes 
	# AND frantic, sweaty mobile thumb swiping on the left joystick.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		# We have a destination. Go there!
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Screeching halt.
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# 4. Handle Aiming (Where to point the boomstick)
	handle_aiming()

	# 5. Handle Shooting (Doing a violence)
	if Input.is_action_just_pressed("shoot"):
		# Shout across the network: "HEY GUYS, I'M SHOOTING!"
		shoot.rpc()

	# Actually move the rigid character through 3D space.
	move_and_slide()

func handle_aiming() -> void:
	# MOBILE AIMING: Did they aggressively smudge the right side of their phone screen?
	var aim_dir := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	
	if aim_dir.length() > 0.1:
		# Yep, mobile player detected. Spin the character to match their thumb's chaotic energy.
		var look_angle := atan2(-aim_dir.x, -aim_dir.y)
		rotation.y = look_angle
	else:
		# PC AIMING: Ah, the trusty mouse. Let's do some math to look at the cursor.
		var mouse_pos := get_viewport().get_mouse_position()
		
		# An invisible floor at crotch-height to catch our mouse laser.
		var drop_plane := Plane(Vector3.UP, transform.origin.y) 
		
		# Shoot an imaginary laser from the camera to the mouse position.
		var ray_origin := camera.project_ray_origin(mouse_pos)
		var ray_dir := camera.project_ray_normal(mouse_pos)
		
		# Where did the imaginary laser hit the invisible floor?
		var intersection = drop_plane.intersects_ray(ray_origin, ray_dir)
		if intersection != null:
			# Stare intensely at that exact spot on the ground.
			look_at(Vector3(intersection.x, global_position.y, intersection.z), Vector3.UP)

# @rpc is the megaphone. 
# "any_peer" = Anyone can yell it. "call_local" = Yell it to myself too so I can hear it.
@rpc("any_peer", "call_local")
func shoot() -> void:
	# TODO: Add actual bullets, muzzle flashes, and zombie-splattering logic here.
	# For now, just spam the output log to prove we tried.
	print("Meatbag %s went pew pew!" % name)
