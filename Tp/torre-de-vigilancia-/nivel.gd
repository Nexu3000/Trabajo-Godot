extends Node3D

@export var escena_enemigo: PackedScene
@export var escena_enemigo_especial: PackedScene
@export_range(0.0, 1.0) var probabilidad_especial := 0.25

@export var puntos_para_sur := 50
@export var puntos_para_este := 120
@export var puntos_para_oeste := 200

@onready var torreta = $Torreta
@onready var label_puntos: Label = $CanvasLayer/LabelPuntos
@onready var label_aviso_zona: Label = $CanvasLayer/LabelAvisoZona
@onready var timer_spawn: Timer = $TimerSpawn
@onready var sonido_muerte: AudioStreamPlayer = $SonidoMuerteZombie
@onready var sonido_perder_vida: AudioStreamPlayer = $SonidoPerderVida

@onready var muro_sur: CSGBox3D = $MuroSur
@onready var muro_este: CSGBox3D = $MuroEste
@onready var muro_oeste: CSGBox3D = $MuroOeste

@onready var panel_game_over: PanelContainer = $CanvasLayer/PanelGameOver
@onready var label_puntaje_final: Label = $CanvasLayer/PanelGameOver/VBoxContainer/LabelPuntajeFinal
@onready var boton_reintentar: Button = $CanvasLayer/PanelGameOver/VBoxContainer/BotonReintentar
@onready var boton_menu: Button = $CanvasLayer/PanelGameOver/VBoxContainer/BotonMenu

@onready var panel_pausa: PanelContainer = $CanvasLayer/PanelPausa
@onready var boton_reanudar: Button = $CanvasLayer/PanelPausa/VBoxContainer/BotonReanudar
@onready var boton_reiniciar_pausa: Button = $CanvasLayer/PanelPausa/VBoxContainer/BotonReiniciarPausa
@onready var boton_menu_pausa: Button = $CanvasLayer/PanelPausa/VBoxContainer/BotonMenuPausa

var puntos := 0
var vidas := 5

var zonas_activas := [
	{"nombre": "NORTE", "angulo": -PI / 2.0}
]
var sur_desbloqueado := false
var este_desbloqueado := false
var oeste_desbloqueado := false

func _ready() -> void:
	get_tree().paused = false
	panel_game_over.hide()
	panel_pausa.hide()
	label_aviso_zona.text = ""
	
	timer_spawn.timeout.connect(_on_timer_spawn_timeout)
	boton_reintentar.pressed.connect(_on_reintentar_pressed)
	boton_menu.pressed.connect(_on_menu_pressed)
	boton_reanudar.pressed.connect(alternar_pausa)
	boton_reiniciar_pausa.pressed.connect(_on_reintentar_pressed)
	boton_menu_pausa.pressed.connect(_on_menu_pressed)
	
	mostrar_aviso("ZONA ACTIVA: NORTE (FRENTE)")
	actualizar_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not panel_game_over.visible:
		alternar_pausa()

func alternar_pausa() -> void:
	var pausado = not get_tree().paused
	get_tree().paused = pausado
	panel_pausa.visible = pausado
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if pausado else Input.MOUSE_MODE_CAPTURED

func _on_timer_spawn_timeout() -> void:
	if not escena_enemigo:
		return
	
	var prefab = escena_enemigo
	if escena_enemigo_especial and randf() < probabilidad_especial:
		prefab = escena_enemigo_especial
	
	var nuevo_enemigo = prefab.instantiate()
	add_child(nuevo_enemigo)
	
	# Aumenta la velocidad según los puntos (ej: +0.15 cada 10 puntos, con un tope de +3.5 extra)
	var extra_velocidad = min(3.5, puntos * 0.005)
	nuevo_enemigo.velocidad += extra_velocidad
	
	var zona_elegida = zonas_activas.pick_random()
	var angulo = zona_elegida["angulo"] + randf_range(-0.35, 0.35)
	var distancia := 25.0
	nuevo_enemigo.global_position = Vector3(cos(angulo) * distancia, 1.0, sin(angulo) * distancia)
	
	nuevo_enemigo.llego_a_la_torre.connect(_on_enemigo_llego)
	nuevo_enemigo.murio.connect(_on_enemigo_eliminado)
	
func _on_enemigo_eliminado() -> void:
	puntos += 10
	timer_spawn.wait_time = max(0.8, 2.0 - (puntos * 0.005))
	sonido_muerte.pitch_scale = randf_range(0.85, 1.15)
	sonido_muerte.play()
	
	verificar_desbloqueo_zonas()
	actualizar_ui()

func verificar_desbloqueo_zonas() -> void:
	if not sur_desbloqueado and puntos >= puntos_para_sur:
		sur_desbloqueado = true
		zonas_activas.append({"nombre": "SUR", "angulo": PI / 2.0})
		abrir_muro(muro_sur)
		mostrar_aviso("¡MURO SUR DERRIBADO! VIGILÁ TU ESPALDA")
	
	if not este_desbloqueado and puntos >= puntos_para_este:
		este_desbloqueado = true
		zonas_activas.append({"nombre": "ESTE", "angulo": 0.0})
		abrir_muro(muro_este)
		mostrar_aviso("¡MURO ESTE DERRIBADO! ATACAN POR LA DERECHA")
	
	if not oeste_desbloqueado and puntos >= puntos_para_oeste:
		oeste_desbloqueado = true
		zonas_activas.append({"nombre": "OESTE", "angulo": PI})
		abrir_muro(muro_oeste)
		mostrar_aviso("¡MURO OESTE DERRIBADO! TODOS LOS FRENTES ABIERTOS")

func abrir_muro(muro: CSGBox3D) -> void:
	# Desactiva la colisión al instante para poder disparar y hunde el muro bajo tierra
	muro.use_collision = false
	var tween = create_tween()
	tween.tween_property(muro, "position:y", -3.0, 1.2)
	tween.tween_callback(muro.hide)

func _on_enemigo_llego() -> void:
	vidas -= 1
	sonido_perder_vida.play()
	actualizar_ui()
	if vidas <= 0:
		mostrar_game_over()

func mostrar_aviso(texto: String) -> void:
	label_aviso_zona.text = texto
	await get_tree().create_timer(3.5).timeout
	if label_aviso_zona.text == texto:
		label_aviso_zona.text = ""

func mostrar_game_over() -> void:
	label_puntaje_final.text = "Puntaje final: %d" % puntos
	panel_game_over.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _on_reintentar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu_inicio.tscn")

func actualizar_ui() -> void:
	var nombres_zonas := []
	for z in zonas_activas:
		nombres_zonas.append(z["nombre"])
	var texto_zonas = " - ".join(nombres_zonas)
	
	var proximo := ""
	if not sur_desbloqueado:
		proximo = " (Próx. zona: %d pts)" % puntos_para_sur
	elif not este_desbloqueado:
		proximo = " (Próx. zona: %d pts)" % puntos_para_este
	elif not oeste_desbloqueado:
		proximo = " (Próx. zona: %d pts)" % puntos_para_oeste
	
	label_puntos.text = "Puntos: %d  |  Vidas: %d\nZonas activas: %s%s" % [puntos, vidas, texto_zonas, proximo]
