extends Control

@onready var panel_menu: PanelContainer = $PanelMenu
@onready var boton_jugar: Button = $PanelMenu/VBoxContainer/BotonJugar
@onready var boton_ajustes: Button = $PanelMenu/VBoxContainer/BotonAjustes
@onready var boton_salir: Button = $PanelMenu/VBoxContainer/BotonSalir

@onready var panel_ajustes: PanelContainer = $PanelAjustes
@onready var slider_volumen: HSlider = $PanelAjustes/VBoxContainer/SliderVolumen
@onready var slider_sensibilidad: HSlider = $PanelAjustes/VBoxContainer/SliderSensibilidad
@onready var check_pantalla: CheckButton = $PanelAjustes/VBoxContainer/CheckPantallaCompleta
@onready var opcion_resolucion: OptionButton = $PanelAjustes/VBoxContainer/OpcionResolucion
@onready var boton_cerrar_ajustes: Button = $PanelAjustes/VBoxContainer/BotonCerrarAjustes

var resoluciones := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel_ajustes.hide()
	panel_menu.show()
	
	# Cargar valores actuales de Config
	slider_volumen.value = Config.volumen_general
	slider_sensibilidad.value = Config.sensibilidad_mouse
	check_pantalla.button_pressed = Config.pantalla_completa
	
	# Llenar el desplegable de resoluciones
	opcion_resolucion.clear()
	for i in range(resoluciones.size()):
		var res = resoluciones[i]
		opcion_resolucion.add_item("%d x %d" % [res.x, res.y], i)
		if res == Config.resolucion:
			opcion_resolucion.select(i)
	opcion_resolucion.disabled = Config.pantalla_completa
	
	# Conectar botones principales
	boton_jugar.pressed.connect(_on_boton_jugar_pressed)
	boton_ajustes.pressed.connect(_on_boton_ajustes_pressed)
	boton_salir.pressed.connect(_on_boton_salir_pressed)
	boton_cerrar_ajustes.pressed.connect(_on_cerrar_ajustes_pressed)
	
	# Conectar controles de ajustes en tiempo real
	slider_volumen.value_changed.connect(Config.aplicar_volumen)
	slider_sensibilidad.value_changed.connect(func(val): Config.sensibilidad_mouse = val)
	check_pantalla.toggled.connect(_on_pantalla_toggled)
	opcion_resolucion.item_selected.connect(_on_resolucion_seleccionada)

func _on_boton_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Nivel.tscn")

func _on_boton_ajustes_pressed() -> void:
	panel_menu.hide()
	panel_ajustes.show()

func _on_cerrar_ajustes_pressed() -> void:
	panel_ajustes.hide()
	panel_menu.show()

func _on_pantalla_toggled(activado: bool) -> void:
	Config.aplicar_pantalla_completa(activado)
	opcion_resolucion.disabled = activado

func _on_resolucion_seleccionada(indice: int) -> void:
	Config.aplicar_resolucion(resoluciones[indice])

func _on_boton_salir_pressed() -> void:
	get_tree().quit()
