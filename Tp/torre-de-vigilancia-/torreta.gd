extends Node3D

@export var sensibilidad_mouse := 0.003

@onready var pivote_h: Node3D = $PivoteHorizontal
@onready var pivote_v: Node3D = $PivoteHorizontal/PivoteVertical
@onready var rayo: RayCast3D = $PivoteHorizontal/PivoteVertical/RayoDisparo
@onready var bala_visual: MeshInstance3D = $PivoteHorizontal/PivoteVertical/BalaVisual
@onready var fogonazo: MeshInstance3D = $PivoteHorizontal/PivoteVertical/Fogonazo
@onready var canon: Node3D = $PivoteHorizontal/PivoteVertical/CSGBox3D
@onready var sonido_disparo: AudioStreamPlayer = $SonidoDisparo

signal enemigo_eliminado

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	bala_visual.visible = false
	fogonazo.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		pivote_h.rotate_y(-event.relative.x * Config.sensibilidad_mouse)
		pivote_v.rotate_x(-event.relative.y * Config.sensibilidad_mouse)
		pivote_v.rotation.x = clamp(pivote_v.rotation.x, deg_to_rad(-30), deg_to_rad(60))
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		disparar()

func disparar() -> void:
	sonido_disparo.pitch_scale = randf_range(0.95, 1.05)
	sonido_disparo.play()
	
	rayo.force_raycast_update()
	var distancia_impacto := 40.0
	
	if rayo.is_colliding():
		var impacto = rayo.get_collider()
		distancia_impacto = global_position.distance_to(rayo.get_collision_point())
		if impacto.is_in_group("enemigos"):
			if impacto.has_method("recibir_dano"):
				impacto.recibir_dano(1)
			else:
				impacto.queue_free()
				enemigo_eliminado.emit()
	
	mostrar_efectos_disparo(distancia_impacto)

func mostrar_efectos_disparo(distancia: float) -> void:
	# 1. Fogonazo en la boca del rifle
	fogonazo.visible = true
	fogonazo.rotation.z = randf() * TAU
	
	# 2. Bala trazadora que viaja desde la punta del cañón hasta el objetivo
	bala_visual.position = Vector3(0.35, -0.28, -1.7)
	bala_visual.visible = true
	
	var tween_bala = create_tween()
	var duracion_vuelo = clamp(distancia / 150.0, 0.03, 0.15)
	tween_bala.tween_property(bala_visual, "position:z", -distancia, duracion_vuelo)
	tween_bala.tween_callback(func(): bala_visual.visible = false)
	
	# 3. Retroceso del rifle
	var tween_canon = create_tween()
	tween_canon.tween_property(canon, "position:z", -0.6, 0.04)
	tween_canon.tween_property(canon, "position:z", -0.8, 0.08)
	
	await get_tree().create_timer(0.05).timeout
	fogonazo.visible = false
