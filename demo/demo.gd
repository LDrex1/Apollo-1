extends Node2D

## The scene for a asteroid instance
const ASTEROID_SCENE: PackedScene = preload("res://demo/asteroid.tscn")
## How far the laser should be from the ship when it is instantiated
const LASER_OFFSET: int = 64
## The scene for a laser instance
const LASER_SCENE: PackedScene = preload("res://demo/laser.tscn")
## An offset to compensate for the fact that the visual rotation does not match the node rotation
## (we could also fix this by angling the sprite 90deg to the right, but this makes it obvious)
const ROTATION_OFFSET: float = PI / 2

## The maximum number of asteroids to spawn
@export var asteroid_count: int
## The points to give for destroying an asteroid
@export var asteroid_points: int
## How fast the asteroids should move across the screen, in pixels per second
@export var asteroid_speed: float
## How quickly the asteroids should turn, in degrees per second
@export var asteroid_spin: float
## How fast the lasers move across the screen, in pixels per second
@export var laser_speed: float
## How much the velocity reduces each second when not thrusting
@export var ship_friction: float
## The amount of forward velocity the ship has when 'W' is held
@export var ship_thrust: float
## How quickly the ship turns when 'A' or 'D' are held, in degrees per second
@export var ship_turning: float

## A reference to the timer which controls whether asteroids should spawn
@onready var asteroid_timer: Timer = $AsteroidTimer
## The previous high score, defaulting to 0
@onready var high_score: int = SaveSystem.get_global("high_score", 0)
## A reference to the timer which controls whether the ship can fire
@onready var reload_timer: Timer = $ReloadTimer
## A reference to the label which displays the score
@onready var score_label: Label = %ScoreLabel
## A reference to the Ship node
@onready var ship: CharacterBody2D = $Ship
## A reference to the SpawnPoint node used for spawning asteroids
@onready var spawn_point: PathFollow2D = %SpawnPoint
## The 'ship_turning' property converted into radians
@onready var turn_rad: float = ship_turning * PI / 180

## An array of spawned asteroids that need to be moved each frame
var asteroids: Array[RigidBody2D] = []
## Whether the ship can fire, set by ReloadTimer via _on_reload
var can_fire: bool = true
## Whether the game can spawn another asteroid, set by AsteroidTimer via _on_asteroid
var can_spawn_asteroid: bool = true
## An array of spawned lasers that need to be moved each frame
var lasers: Array[Area2D] = []
## The player's accumulated score
var score: int = 0


# Runs every physics tick, `delta` is the time since last tick
func _physics_process(delta: float) -> void:
	# Note: Normally it would be better to configure actions in the project settings, but since this
	# is a demo project and I don't want to pollute the action map, I'm using direct checks here

	# Turn if either 'A' or 'D' is pressed, but not both
	var a_pressed := Input.is_physical_key_pressed(KEY_A)
	var d_pressed := Input.is_physical_key_pressed(KEY_D)

	if a_pressed and not d_pressed:
		ship.rotate(-turn_rad * delta)
	elif d_pressed and not a_pressed:
		ship.rotate(turn_rad * delta)

	# Thrust if 'W' is pressed, otherwise apply ship_friction
	if Input.is_physical_key_pressed(KEY_W):
		ship.velocity = Vector2.from_angle(ship.rotation - ROTATION_OFFSET) * ship_thrust
		AudioSystem.play_continuous("Thruster")
	elif ship.velocity != Vector2.ZERO:
		AudioSystem.stop_continuous("Thruster")

		var friction_vec := ship.velocity.normalized() * ship_friction

		if friction_vec.abs() > ship.velocity.abs():
			ship.velocity = Vector2.ZERO
		else:
			ship.velocity -= friction_vec * delta

	# Actually move the ship and process collisions
	ship.move_and_slide()

	# Fire a laser if 'Space' is pressed
	if Input.is_physical_key_pressed(KEY_SPACE) and can_fire:
		can_fire = false
		var laser: Area2D = LASER_SCENE.instantiate()

		# Copy the ship's orientation, then offset by 64px in that direction
		laser.rotation = ship.rotation - ROTATION_OFFSET
		laser.position = ship.position + Vector2.from_angle(laser.rotation) * LASER_OFFSET

		# Set up a signal connection for the 'body_entered' event to destroy the asteroid
		laser.body_entered.connect(_on_laser_collision.bind(laser))

		# Since the script is on the root node, we can add the child directly. If this script was on
		# the ship (as it usually would be), then we would want to add it to the ship's parent.
		add_child(laser)
		lasers.append(laser)

		# Play a sound effect with some pitch variance, then start the reload timer
		AudioSystem.play_with_variance("Laser")
		reload_timer.start()

	# Spawn asteroids if there are less than the expected amount
	if len(asteroids) < asteroid_count and can_spawn_asteroid:
		can_spawn_asteroid = false
		var asteroid: RigidBody2D = ASTEROID_SCENE.instantiate()

		# Put the spawn point at a random location on its path, and copy that global position to
		# the asteroid
		spawn_point.progress_ratio = randf_range(0.0, 1.0)
		asteroid.position = spawn_point.global_position

		# Apply a constant force to the asteroid towards the centre of the screen
		asteroid.add_constant_force(-asteroid.position.normalized() * asteroid_speed)

		# Also apply a constant torque to give the asteroid a slight spinning effect
		asteroid.add_constant_torque(asteroid_spin)

		# Set up a signal connection for the 'body_entered' event to destroy the asteroid
		asteroid.body_entered.connect(_on_asteroid_collision.bind(asteroid))

		# Add the asteroid to our scene and tracking list, then start the spawn delay timer
		add_child(asteroid)
		asteroids.append(asteroid)
		asteroid_timer.start()


	# Move each laser forward (this could be on a laser script instead, attached to the laser, but
	# I am trying to limit the number of scripts in the demo project)
	for laser in lasers:
		laser.position += Vector2.from_angle(laser.rotation) * laser_speed * delta


# Runs every frame, `delta` is the time since last tick
func _process(_delta: float) -> void:
	# This code is purely visual, so we should perform it every rendered frame
	score_label.text = "Score: %d\nHigh Score: %d" % [score, high_score]


## Ends the game, saving the current score if it's higher than the previous high score
func _end_game() -> void:
	# Stop running the physics and rendering loops
	process_mode = Node.PROCESS_MODE_DISABLED

	# Save the current score as the new high score if it's larger
	if score > high_score:
		SaveSystem.save_global("high_score", score)
		high_score = score


## This handler is called by the ReloadTimer's timeout signal, which triggers whenever the timer
## completes
func _on_reload() -> void:
	can_fire = true


## This handler is called by the AsteroidTimer's timeout signal, which triggers whenever the timer
## completes
func _on_asteroid() -> void:
	can_spawn_asteroid = true


## This handler is dynamically registered to the 'body_entered' signal on each spawned asteroid, and
## removes the asteroid from the tracking list then removes it from the scene
func _on_asteroid_collision(body: Node, asteroid: RigidBody2D) -> void:
	AudioSystem.play_with_variance("Explosion", 0.5)
	asteroids.erase(asteroid)
	asteroid.queue_free()

	# The only CharacterBody2D is our ship, so we know if this is the collided body then the game
	# should end
	if body is CharacterBody2D:
		# End the game, defer till end of frame to avoid breaking things
		_end_game.call_deferred()


## This handler is dynamically registered to the 'body_entered' signal on each spawned laser, and
## detects collisions with asteroids to generate points
func _on_laser_collision(body: Node2D, laser: Area2D) -> void:
	lasers.erase(laser)
	laser.queue_free()

	# The only RigidBody2Ds are our asteroids, so we know if this is the collided body then the body
	# should be removed and the score increased
	if body is RigidBody2D:
		score += asteroid_points

		AudioSystem.play_with_variance("Explosion", 0.5)
		var asteroid: RigidBody2D = body
		asteroids.erase(asteroid)
		asteroid.queue_free()
