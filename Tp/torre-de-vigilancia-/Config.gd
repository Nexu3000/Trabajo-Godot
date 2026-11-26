extends Node

var volumen_general := 1.0 # De 0.0 a 1.0
var sensibilidad_mouse := 0.003
var pantalla_completa := false
var resolucion := Vector2i(1280, 720)

func aplicar_volumen(valor: float) -> void:
	volumen_general = valor
	var bus_idx = AudioServer.get_bus_index("Master")
	# Convierte el deslizador (0 a 1) a decibeles reales y silencia si llega a 0
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(max(valor, 0.0001)))
	AudioServer.set_bus_mute(bus_idx, valor <= 0.01)

func aplicar_pantalla_completa(activar: bool) -> void:
	pantalla_completa = activar
	if activar:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		aplicar_resolucion(resolucion)

func aplicar_resolucion(nueva_res: Vector2i) -> void:
	resolucion = nueva_res
	if not pantalla_completa:
		# Si estaba maximizada, la pasamos a ventana normal primero
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
		# Evita pedir un tamaño más grande que el monitor actual
		var pantalla = DisplayServer.screen_get_usable_rect()
		var res_segura = Vector2i(
			min(nueva_res.x, pantalla.size.x),
			min(nueva_res.y, pantalla.size.y)
		)
		
		DisplayServer.window_set_size(res_segura)
		DisplayServer.window_set_position(pantalla.position + (pantalla.size - res_segura) / 2)
	
	# Además actualiza la resolución de renderizado interno del juego
	get_tree().root.content_scale_size = nueva_res
