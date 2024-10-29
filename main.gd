extends Node

signal pause_clicked

var grid : Array[Array]
var GRID_COLS = 20
var GRID_ROWS = 18
var CELL_SIZE = 8

var RESTART_WAIT_TIME = 0.7
var DENSITY_DELTA = 0.1
var DURATION_DELTA = 0.2
var MIN_DURATION = 0.05
var MAX_DURATION = 5.0

var init_density = 0.25
var init_step_duration = 0.7

func _init() -> void:
	# Default to full screen on start up.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load the title screen and connect button signals.
	var title_scene = preload("res://title.tscn")
	var title = title_scene.instantiate()
	title.get_node("TitleContainer/StartButton").button_down.connect(Callable(self, "_on_start_button_down").bind(title))
	title.get_node("TitleContainer/OptionsButton").button_down.connect(Callable(self, "_on_options_button_down").bind(title))
	add_child(title)
	
func restartGrid() -> void:
	# Fill grid with new cells and connect them to the StepTimer.
	var cell_scene = preload("res://cell.tscn")
	var cell = cell_scene.instantiate()
	# Remove any existing cells
	for i in range(len(grid)):
		for j in range(len(grid[i])):
			if grid[i][j]:
				grid[i][j].queue_free()
			var new_cell = cell.duplicate()
			new_cell.position.x = j * CELL_SIZE
			new_cell.position.y = i * CELL_SIZE
			$StepTimer.timeout.connect(Callable(new_cell, "_on_main_steptimer_timeout"))
			add_child(new_cell)
			grid[i][j] = new_cell

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _input(event) -> void:
	if Input.is_action_pressed("pause_key"):
		pause_clicked.emit()

func restartSimulation() -> void:
	# Restart the grid, have a brief pause, reset any relevant vars, then
	# resume simulation by restarting StepTimer.
	restartGrid()
	$StepTimer.wait_time = init_step_duration
	$StepTimer.start()
	$StepTimer.paused = false
	
func _on_density_dec_btn_down() -> void:
	init_density -= DENSITY_DELTA
	init_density = max(init_density, 0.01)
	
func _on_density_inc_btn_down() -> void:
	init_density += DENSITY_DELTA
	init_density = min(init_density, 0.99)
	
func _on_duration_dec_btn_down() -> void:
	$StepTimer.wait_time -= DURATION_DELTA
	$StepTimer.wait_time = max($StepTimer.wait_time, MIN_DURATION)
	init_step_duration = $StepTimer.wait_time
	
func _on_duration_inc_btn_down() -> void:
	$StepTimer.wait_time += DURATION_DELTA
	$StepTimer.wait_time = min($StepTimer.wait_time, MAX_DURATION)
	init_step_duration = $StepTimer.wait_time
	
func _on_start_button_down(scene_instance) -> void:
	# Hide the title menu. Use a "screen" to hide the cells until they're all
	# loaded and put into position.
	scene_instance.queue_free()
	if not grid:
		for i in range(GRID_ROWS):
			grid.append([])
			for j in range(GRID_COLS):
				grid[i].append(null)
	# Begin simulation.
	restartSimulation()
	
func _on_options_button_down(scene_instance) -> void:
	# Want to pass the scene that contained the options button because
	# I want to call queue_free on it.
	var title_options_scene = preload("res://title_options.tscn")
	var title_options = title_options_scene.instantiate()
	title_options.get_node("Options/StartButton").button_down.connect(Callable(self, "_on_start_button_down").bind(title_options))
	title_options.get_node("Options/DensityDecBtn").button_down.connect(Callable(self, "_on_density_dec_btn_down"))
	title_options.get_node("Options/DensityIncBtn").button_down.connect(Callable(self, "_on_density_inc_btn_down"))
	title_options.get_node("Options/DurationDecBtn").button_down.connect(Callable(self, "_on_duration_dec_btn_down"))
	title_options.get_node("Options/DurationIncBtn").button_down.connect(Callable(self, "_on_duration_inc_btn_down"))
	add_child(title_options)
	scene_instance.queue_free()

func _on_timer_timeout() -> void:
	# Update life status of all cells based on neighbors and current status.
	var dirs = [[-1, -1], [-1, 0], [-1, 1], 
		[0, -1], [0, 1], 
		[1, -1], [1, 0], [1, 1]]
	var ALIVE = grid[0][0].LifeStatus.ALIVE
	var DYING = grid[0][0].LifeStatus.DYING
	var DEAD = grid[0][0].LifeStatus.DEAD
	var REVIVING = grid[0][0].LifeStatus.REVIVING
	for i in range(len(grid)):
		for j in range(len(grid[i])):
			var curCell = grid[i][j]
			var liveNeighbors = 0
			for d in dirs:
				var y = d[0]
				var x = d[1]
				if 0 <= i + y and i + y < len(grid) and 0 <= j + x and j + x < len(grid[i]):
					var neighbor = grid[i+y][j+x]
					if neighbor.curStatus == ALIVE or neighbor.curStatus == DYING:
						liveNeighbors += 1
			# If one or zero live neighbors, ALIVE -> DYING
			if liveNeighbors < 2 and curCell.curStatus == ALIVE:
				curCell.curStatus = DYING
			# If two or three live neighbors, ALIVE -> ALIVE
			# If four or more live neighbors, ALIVE -> DYING
			elif liveNeighbors >= 4 and curCell.curStatus == ALIVE:
				curCell.curStatus = DYING
			# If three live neighbors, DEAD -> REVIVING
			elif liveNeighbors == 3 and curCell.curStatus == DEAD:
				curCell.curStatus = REVIVING

func _on_pause_clicked() -> void:
	$StepTimer.paused = true
	var pause_options_scene = preload("res://pause_options.tscn")
	var pause_options = pause_options_scene.instantiate()
	pause_options.get_node("Options/RestartButton").button_down.connect(Callable(self, "_on_start_button_down").bind(pause_options))
	pause_options.get_node("Options/ContinueButton").button_down.connect(Callable(self, "_on_continue_button_down").bind(pause_options))
	pause_options.get_node("Options/DensityDecBtn").button_down.connect(Callable(self, "_on_density_dec_btn_down"))
	pause_options.get_node("Options/DensityIncBtn").button_down.connect(Callable(self, "_on_density_inc_btn_down"))
	pause_options.get_node("Options/DurationDecBtn").button_down.connect(Callable(self, "_on_duration_dec_btn_down"))
	pause_options.get_node("Options/DurationIncBtn").button_down.connect(Callable(self, "_on_duration_inc_btn_down"))
	add_child(pause_options)
	
func _on_continue_button_down(scene_instance) -> void:
	$StepTimer.paused = false
	scene_instance.queue_free()
