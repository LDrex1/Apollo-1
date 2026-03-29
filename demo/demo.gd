extends Node2D

@onready var background: ColorRect = $Background
@onready  var earth: ColorRect = $Earth
@onready var moon: Node2D = $Moon
@onready var rocket: CharacterBody2D = $Rocket
@onready var body_polygon: Polygon2D = $Rocket/Body
@onready var flame: Polygon2D = $Rocket/Flame
@onready var camera: Camera2D = $Camera2D
@onready var label: Label = $UI/Label

@onready var fuel: float = MAX_FUEL
@onready var landed: bool = false
@onready var crashed: bool = false
@onready var angular_velocity: float = 0.0

const EARTH_RADIUS: float = 128
const ATMOSPHERE_HEIGHT: float = 3000
const MOON_POSITION_FROM_EARTH := 5000
const LANDING_RADIUS := 90.0

# Science
const EARTH_GRAVITY := 9.81
const MOON_GRAVITY := 1.62
const THRUST := 40.0
const TORQUE := 0.2
const MAX_SPEED = 100.0
const MOON_Y = -9000 
const DRAG := 0.4
const SPACE_DRAG := 0.006
const MAX_FUEL := 1000.0
const FUEL_BURN_RATE := 10.0
const SAFE_LANDING_SPEED := 30.0
const EARTH_SURFACE_Y := 500.0
const MAX_ANGULAR_SPEED := 2.5

func reset() -> void:
	rocket.position = Vector2(0, EARTH_SURFACE_Y)
	rocket.velocity = Vector2.ZERO
	rocket.rotation = 0
	fuel = MAX_FUEL
	landed = false
	crashed = false
	angular_velocity = 0.0
	flame.visible = false

	moon.position = Vector2(400, MOON_Y)
	
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		reset()
		return

	var altitude: float = max(EARTH_SURFACE_Y - rocket.position.y, 0.0)
	var atmosphere_factor:float = clamp(1.0 - (altitude / ATMOSPHERE_HEIGHT), 0.0, 1.0)
	var current_drag: float = lerp(SPACE_DRAG, DRAG, atmosphere_factor)
	var angular_drag: float = lerp(2.0, 0.13, atmosphere_factor)

	if not landed and not crashed:
		handle_input(delta)
		apply_gravity(delta)
		apply_drag(delta, current_drag)
		apply_rotation(delta, angular_drag)

		rocket.move_and_slide()

		check_earth_collision()
		check_moon_landing()
	else:
		flame.visible = false

	update_background()
	update_moon_visual()
	update_camera()
	update_ui(altitude, current_drag)

func handle_input(delta: float) -> void:
	var thrusting := Input.is_action_pressed("thrust") and fuel > 0.0
	var turning_left := Input.is_action_pressed("move_left") and fuel > 0.0
	var turning_right := Input.is_action_pressed("move_right") and fuel > 0.0

	if thrusting:
		var thrust_dir := Vector2.UP.rotated(rocket.rotation)
		rocket.velocity += thrust_dir * THRUST * delta
		fuel = max(0.0, fuel - FUEL_BURN_RATE * delta)
		AudioSystem.play_with_variance("Thruster")

	if turning_left:
		angular_velocity -= TORQUE * delta
		
	if turning_right:
		angular_velocity += TORQUE * delta

	flame.visible = thrusting

func apply_gravity(delta: float) -> void:
	var moon_proximity: float = clamp((-rocket.position.y - 9000.0) / 3000.0, 0.0, 1.0)
	var effective_gravity: float = lerp(EARTH_GRAVITY, MOON_GRAVITY, moon_proximity)
	rocket.velocity.y += effective_gravity * delta

func apply_drag(delta: float, drag_strength: float) -> void:
	rocket.velocity -= rocket.velocity * drag_strength * delta

func apply_rotation(delta: float, angular_drag: float) -> void:
	angular_velocity -= angular_velocity * angular_drag * delta
	angular_velocity = clamp(angular_velocity, -MAX_ANGULAR_SPEED, MAX_ANGULAR_SPEED)
	rocket.rotation += angular_velocity * delta


func check_earth_collision() -> void:
	var rocket_bottom: float = rocket.position.y

	if (rocket.position.y - 180) > EARTH_SURFACE_Y:

		if rocket.velocity.length() > SAFE_LANDING_SPEED * 0.7:
			crash("That was awful, can you even drive a bicycle?\nPress R to restart.")
		else:
			pass

func check_moon_landing() -> void:
	var moon_radius: float = 20.0 * moon.scale.y
	var moon_top: float = moon.position.y - moon_radius
	var moon_left: float = moon.position.x - moon_radius
	var moon_right: float = moon.position.x + moon_radius

	var rocket_bottom: float = rocket.position.y + 60.0
	var rocket_left: float = rocket.position.x - 3.0
	var rocket_right: float = rocket.position.x + 3.0

	var speed: float = rocket.velocity.length()
	var angle_deg: float = abs(wrapf(rad_to_deg(rocket.rotation), -180.0, 180.0))

	var overlapping_horizontally: bool = rocket_right >= moon_left and rocket_left <= moon_right
	var near_moon_top: bool = abs(rocket_bottom - moon_top) <= 1.0

	if near_moon_top and overlapping_horizontally:
		if  speed <= SAFE_LANDING_SPEED and angle_deg <= 10.0:
			rocket.position.y = moon_top - 10 
			rocket.velocity = Vector2.ZERO
			angular_velocity = 0.0
			rocket.rotation = 0.0
			landed = true
			label.text = "Good job!\nPress R to restart."
		else:
			crash("Thank God you were not the Apollo pilot.\nPress R to restart.")

func crash(message: String) -> void:
	crashed = true
	rocket.velocity = Vector2.ZERO
	angular_velocity = 0.0
	flame.visible = false
	label.text = message

func update_camera() -> void:
	camera.position = rocket.position

func update_background() -> void:
	var altitude: float = max(EARTH_SURFACE_Y - rocket.position.y, 0.0)
	var t: float= clamp(altitude / ATMOSPHERE_HEIGHT, 0.0, 1.0)

	background.color = Color(
		lerp(0.45, 0.02, t),
		lerp(0.75, 0.02, t),
		lerp(1.00, 0.08, t),
		1.0
	)

	earth.modulate.a = 1.0 - t

func update_moon_visual() -> void:
	var dist: float = abs(rocket.position.y - moon.position.y)
	var zoom: float = clamp(1.0 + (5000.0 - dist) / 1200.0, 0.25, 4.5)
	moon.scale = Vector2.ONE * zoom
	moon.position.x = 0.0
	moon.position.y = MOON_Y

func update_ui(altitude: float, drag_strength: float) -> void:
	var speed: float = rocket.velocity.length()
	var angle_deg: float = wrapf(rad_to_deg(rocket.rotation), -180.0, 180.0)
	var message: String = ""
	var fuel_bar_len: int = 20
	var fuel_ratio: float = fuel / MAX_FUEL
	var filled: int = int(round(fuel_bar_len * fuel_ratio))
	var empty: int = fuel_bar_len - filled
	var fuel_bar: String = "[" + "=".repeat(filled) + " ".repeat(empty) + "]"

	var state: String = "Flying"
	if crashed:
		state = "Crashed"
		message = "Thank God you were not the Apollo pilot.\nPress R to restart."
	elif landed:
		message = "Good job!\nPress R to restart."

	label.text = (
		"State: " + state +
		"\nAltitude: " + str(int(altitude)) +
		"\nSpeed: " + str(int(speed)) +
		"\nAngle: " + str(int(angle_deg)) +
		"\nAir Drag: " + str(snapped(drag_strength, 0.01)) +
		"\nFuel: " + str(int(fuel)) + " / " + str(int(MAX_FUEL)) +
		"\n" + fuel_bar +
		"\n\nControls:" +
		"\nSpace = thrust" +
		"\nA/Left = rotate left" +
		"\nD/Right = rotate right" +
		"\nR = restart" +
		"\n" + message
	)
