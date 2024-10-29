extends Area2D

enum LifeStatus {
	ALIVE, DYING, DEAD, REVIVING
}
var curStatus : LifeStatus
var click_held = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if randf() < get_parent().init_density:
		curStatus = LifeStatus.ALIVE
	else:
		curStatus = LifeStatus.DEAD


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Enforce the effects of the different LifeStatus values
	if curStatus == LifeStatus.ALIVE or curStatus == LifeStatus.DYING:
		modulate.a = 1.0
	else:
		modulate.a = 0.0

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# Clicking will kill live or reviving cells and revive dead or dying ones. 
	if event.is_action_pressed("left_click"):
		if curStatus == LifeStatus.ALIVE:
			curStatus = LifeStatus.DYING
		elif curStatus == LifeStatus.DYING:
			curStatus = LifeStatus.ALIVE
		elif curStatus == LifeStatus.DEAD:
			curStatus = LifeStatus.REVIVING
		elif curStatus == LifeStatus.REVIVING:
			curStatus = LifeStatus.DEAD
	
			
func _on_main_steptimer_timeout() -> void:
	if curStatus == LifeStatus.DYING:
		curStatus = LifeStatus.DEAD
	elif curStatus == LifeStatus.REVIVING:
		curStatus = LifeStatus.ALIVE


func _on_mouse_entered() -> void:
	# Allow click and drag
	if Input.is_action_pressed("left_click"):
		if curStatus == LifeStatus.ALIVE:
			curStatus = LifeStatus.DYING
		elif curStatus == LifeStatus.DYING:
			curStatus = LifeStatus.ALIVE
		elif curStatus == LifeStatus.DEAD:
			curStatus = LifeStatus.REVIVING
		elif curStatus == LifeStatus.REVIVING:
			curStatus = LifeStatus.DEAD
