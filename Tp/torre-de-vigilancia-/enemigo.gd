extends Area3D

@export var velocidad := 2.0
@export var vida := 1
var objetivo := Vector3(0, 1, 0)
var tiempo_random := 0.0

signal llego_a_la_torre
signal murio

func _ready() -> void:
	add_to_group("enemigos")
	tiempo_random = randf() * 10.0

func _process(delta: float) -> void:
	look_at(objetivo, Vector3.UP)
	
	var t = Time.get_ticks_msec() * 0.006 + tiempo_random
	rotation.z = sin(t) * 0.15
	position.y = 1.0 + abs(cos(t)) * 0.12
	
	global_position = global_position.move_toward(objetivo, velocidad * delta)
	
	if global_position.distance_to(objetivo) < 1.5:
		llego_a_la_torre.emit()
		queue_free()

func recibir_dano(cantidad: int = 1) -> void:
	vida -= cantidad
	position.y += 0.2
	if vida <= 0:
		murio.emit()
		queue_free()
