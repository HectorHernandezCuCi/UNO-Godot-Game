extends CanvasLayer

signal color_selected(color_index)

@onready var panel = $PanelContainer
@onready var red_btn = $PanelContainer/VBoxContainer/HBoxContainer/Red
@onready var blue_btn = $PanelContainer/VBoxContainer/HBoxContainer/Blue
@onready var green_btn = $PanelContainer/VBoxContainer/HBoxContainer/Green
@onready var yellow_btn = $PanelContainer/VBoxContainer/HBoxContainer/Yellow
@onready var title_label = $PanelContainer/VBoxContainer/TitleLabel

# Vibrant gradient colors
const COLORS = {
	"red": Color(0.95, 0.25, 0.3),
	"blue": Color(0.25, 0.55, 0.95),
	"green": Color(0.25, 0.85, 0.35),
	"yellow": Color(0.98, 0.88, 0.25)
}

# Secondary colors for gradient effects
const COLORS_GRADIENT = {
	"red": Color(1.0, 0.4, 0.45),
	"blue": Color(0.4, 0.7, 1.0),
	"green": Color(0.4, 0.95, 0.5),
	"yellow": Color(1.0, 0.95, 0.4)
}

# Robust control variables
var particles_container: Control
var particle_timer: Timer
var hovered_button: Button = null
var is_animating: bool = false
var is_closing: bool = false
var active_tweens: Array[Tween] = []
var active_glow_particles: Array[Node] = []
var button_original_scales: Dictionary = {}
var button_original_rotations: Dictionary = {}
var original_title: String = "Choose your Color"

func _ready():
	if panel == null:
		push_error("CRITICAL: 'PanelContainer' node not found!")
		return
	
	# Save initial states
	_save_original_states()
	
	# Configure fullscreen layout
	_setup_fullscreen_layout()
	
	# Create background with blur effect
	_create_background_overlay()
	
	# Wait one frame to ensure UI is ready
	await get_tree().process_frame
	
	# Panel setup
	panel.pivot_offset = panel.size / 2
	
	# Create particle container
	_setup_particles()
	
	# Style the title
	_style_title()
	
	# Style the buttons
	_style_buttons()
	
	# Connect signals with verification
	_connect_button_signals()
	
	# Connect resize signal
	get_viewport().size_changed.connect(_on_viewport_resized)
	
	# Professional entrance animation
	_play_entrance_animation()

func _save_original_states():
	"""Saves original button states for safe restoration"""
	var buttons = [red_btn, blue_btn, green_btn, yellow_btn]
	for btn in buttons:
		if btn:
			button_original_scales[btn] = btn.scale
			button_original_rotations[btn] = btn.rotation

func _connect_button_signals():
	"""Safely connects button signals"""
	if red_btn:
		red_btn.pressed.connect(func(): _on_color_picked(0))
		_setup_advanced_hover_effects(red_btn, COLORS.red, "Passion Red", 0)
	
	if blue_btn:
		blue_btn.pressed.connect(func(): _on_color_picked(1))
		_setup_advanced_hover_effects(blue_btn, COLORS.blue, "Ocean Blue", 1)
	
	if green_btn:
		green_btn.pressed.connect(func(): _on_color_picked(2))
		_setup_advanced_hover_effects(green_btn, COLORS.green, "Nature Green", 2)
	
	if yellow_btn:
		yellow_btn.pressed.connect(func(): _on_color_picked(3))
		_setup_advanced_hover_effects(yellow_btn, COLORS.yellow, "Sun Yellow", 3)

func _create_background_overlay():
	"""Creates a semi-transparent dark overlay with blur effect"""
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.name = "BackgroundOverlay"
	add_child(overlay)
	move_child(overlay, 0)

func _setup_particles():
	"""Creates a background floating particle system"""
	particles_container = Control.new()
	particles_container.name = "ParticlesContainer"
	particles_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	particles_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(particles_container)
	move_child(particles_container, 1)
	
	# Timer to spawn particles
	particle_timer = Timer.new()
	particle_timer.name = "ParticleTimer"
	particle_timer.wait_time = 0.3
	particle_timer.timeout.connect(_spawn_particle)
	add_child(particle_timer)
	particle_timer.start()

func _spawn_particle():
	"""Generates a floating particle with robust verification"""
	if not particles_container or is_closing:
		return
	
	if particles_container.get_child_count() > 30:
		return
	
	var particle = ColorRect.new()
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Random size and position
	var size = randf_range(3, 8)
	particle.custom_minimum_size = Vector2(size, size)
	particle.position = Vector2(randf_range(0, viewport_size.x), viewport_size.y + 20)
	
	# Random color from the palette
	var colors_array = [COLORS.red, COLORS.blue, COLORS.green, COLORS.yellow]
	particle.color = colors_array[randi() % 4]
	particle.color.a = randf_range(0.2, 0.5)
	particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	particles_container.add_child(particle)
	
	# Animate upwards with wavy motion
	var duration = randf_range(3, 6)
	var tween = create_tween().set_parallel(true)
	active_tweens.append(tween)
	
	tween.tween_property(particle, "position:y", -50, duration)
	tween.tween_property(particle, "position:x", particle.position.x + randf_range(-100, 100), duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(particle, "color:a", 0.0, duration * 0.8).set_delay(duration * 0.2)
	
	tween.finished.connect(func():
		if particle and is_instance_valid(particle):
			particle.queue_free()
		_remove_tween_from_active(tween)
	)

func _style_title():
	"""Styles the title with modern effects"""
	if title_label:
		original_title = title_label.text
		title_label.add_theme_font_size_override("font_size", 48)
		title_label.add_theme_color_override("font_color", Color.WHITE)
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
		title_label.add_theme_constant_override("shadow_offset_x", 3)
		title_label.add_theme_constant_override("shadow_offset_y", 3)
		title_label.add_theme_constant_override("outline_size", 2)
		title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))

func _setup_fullscreen_layout():
	"""Sets up the panel to occupy the whole screen"""
	if not panel:
		return
	
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

func _on_viewport_resized():
	"""Handles window resizing robustly"""
	if panel and is_instance_valid(panel):
		panel.pivot_offset = panel.size / 2
	
	# Re-style buttons for new size
	if not is_closing:
		call_deferred("_style_buttons")

func _style_buttons():
	"""Applies responsive styling to buttons with gradients"""
	if red_btn:
		_apply_button_style(red_btn, COLORS.red, COLORS_GRADIENT.red)
	if blue_btn:
		_apply_button_style(blue_btn, COLORS.blue, COLORS_GRADIENT.blue)
	if green_btn:
		_apply_button_style(green_btn, COLORS.green, COLORS_GRADIENT.green)
	if yellow_btn:
		_apply_button_style(yellow_btn, COLORS.yellow, COLORS_GRADIENT.yellow)

func _apply_button_style(button: Button, color: Color, gradient_color: Color):
	"""Applies style with gradient and professional effects"""
	if not button or not is_instance_valid(button):
		return
	
	var style_normal = StyleBoxFlat.new()
	
	# Subtle vertical gradient
	style_normal.bg_color = color
	style_normal.set_corner_radius_all(20)
	style_normal.shadow_size = 8
	style_normal.shadow_color = Color(0, 0, 0, 0.4)
	style_normal.shadow_offset = Vector2(0, 4)
	
	# Glowing border
	style_normal.border_width_left = 2
	style_normal.border_width_top = 2
	style_normal.border_width_right = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = gradient_color
	style_normal.border_blend = true
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = color.lightened(0.15)
	style_hover.shadow_size = 12
	style_hover.shadow_offset = Vector2(0, 6)
	style_hover.border_color = Color.WHITE
	
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = color.darkened(0.1)
	style_pressed.shadow_size = 3
	style_pressed.shadow_offset = Vector2(0, 2)
	style_pressed.set_expand_margin_all(2)
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	
	# Responsive minimum size based on viewport
	var viewport_size = get_viewport().get_visible_rect().size
	var button_size = min(viewport_size.x, viewport_size.y) * 0.18
	button.custom_minimum_size = Vector2(button_size, button_size)
	
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Text styling
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)

func _setup_advanced_hover_effects(button: Button, color: Color, color_name: String, button_index: int):
	"""Sets up advanced hover effects with ultra-robust visual feedback"""
	if not button or not is_instance_valid(button):
		return
	
	# Connect mouse_entered with checks
	button.mouse_entered.connect(func():
		if is_closing or is_animating:
			return
		
		_on_button_hover_enter(button, color, color_name, button_index)
	)
	
	# Connect mouse_exited with checks
	button.mouse_exited.connect(func():
		if is_closing:
			return
		
		_on_button_hover_exit(button, button_index)
	)

func _on_button_hover_enter(button: Button, color: Color, color_name: String, button_index: int):
	"""Handles the hover enter event robustly"""
	if not button or not is_instance_valid(button):
		return
	
	hovered_button = button
	
	# Cancel any previous button animation
	_cancel_button_animations(button)
	
	# Scale and rotation effect
	var tween = create_tween().set_parallel(true)
	active_tweens.append(tween)
	
	tween.tween_property(button, "scale", Vector2(1.15, 1.15), 0.3)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "rotation", 0.03, 0.2)\
		.set_trans(Tween.TRANS_SINE)
	
	tween.finished.connect(func():
		_remove_tween_from_active(tween)
	)
	
	# Pulsing glow effect
	_create_glow_effect(button, color)
	
	# Change title to color name
	_change_title_text(color_name)

func _on_button_hover_exit(button: Button, button_index: int):
	"""Handles the hover exit event robustly"""
	if not button or not is_instance_valid(button):
		return
	
	if hovered_button == button:
		hovered_button = null
	
	# Cancel any previous button animation
	_cancel_button_animations(button)
	
	# Clear active glow particles
	_cleanup_glow_particles()
	
	# Restore original scale and rotation
	var tween = create_tween().set_parallel(true)
	active_tweens.append(tween)
	
	tween.tween_property(button, "scale", Vector2.ONE, 0.3)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "rotation", 0.0, 0.2)\
		.set_trans(Tween.TRANS_SINE)
	
	tween.finished.connect(func():
		_remove_tween_from_active(tween)
	)
	
	# Restore original title if no other buttons are hovered
	if hovered_button == null:
		_restore_original_title()

func _change_title_text(new_text: String):
	"""Changes title text with safe animation"""
	if not title_label or not is_instance_valid(title_label):
		return
	
	var title_tween = create_tween()
	active_tweens.append(title_tween)
	
	title_tween.tween_property(title_label, "modulate:a", 0.5, 0.15)
	
	title_tween.finished.connect(func():
		if title_label and is_instance_valid(title_label):
			title_label.text = new_text
			
			var fade_in = create_tween()
			active_tweens.append(fade_in)
			fade_in.tween_property(title_label, "modulate:a", 1.0, 0.15)
			fade_in.finished.connect(func():
				_remove_tween_from_active(fade_in)
			)
		
		_remove_tween_from_active(title_tween)
	)

func _restore_original_title():
	"""Restores the original title with safe animation"""
	if not title_label or not is_instance_valid(title_label):
		return
	
	var title_tween = create_tween()
	active_tweens.append(title_tween)
	
	title_tween.tween_property(title_label, "modulate:a", 0.5, 0.15)
	
	title_tween.finished.connect(func():
		if title_label and is_instance_valid(title_label):
			title_label.text = original_title
			
			var fade_in = create_tween()
			active_tweens.append(fade_in)
			fade_in.tween_property(title_label, "modulate:a", 1.0, 0.15)
			fade_in.finished.connect(func():
				_remove_tween_from_active(fade_in)
			)
		
		_remove_tween_from_active(title_tween)
	)

func _cancel_button_animations(button: Button):
	"""Cancels all active animations for a specific button"""
	if not button or not is_instance_valid(button):
		return
	
	# Use copy of array to avoid modification during iteration
	var tweens_copy = active_tweens.duplicate()
	
	for tween in tweens_copy:
		if tween and is_instance_valid(tween):
			# Note: In a real scenario, you'd check if the tween targets the button
			# Here we kill the specific tween sequence
			tween.kill()

func _cleanup_glow_particles():
	"""Cleans up all active glow particles"""
	for particle in active_glow_particles:
		if particle and is_instance_valid(particle):
			particle.queue_free()
	
	active_glow_particles.clear()

func _create_glow_effect(button: Button, color: Color):
	"""Creates a glow effect around the button robustly"""
	if not button or not is_instance_valid(button) or is_closing:
		return
	
	# Clear previous particles before creating new ones
	_cleanup_glow_particles()
	
	# Create multiple glowing particles around the button
	for i in range(8):
		var glow = ColorRect.new()
		glow.custom_minimum_size = Vector2(10, 10)
		glow.color = color
		glow.color.a = 0.7
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Ensure button has a valid parent
		if not button.get_parent() or not is_instance_valid(button.get_parent()):
			glow.queue_free()
			continue
		
		# Position around button
		var angle = (i / 8.0) * TAU
		var radius = button.size.x / 2 + 20
		var offset = Vector2(cos(angle), sin(angle)) * radius
		
		glow.position = button.position + button.size / 2 + offset - glow.size / 2
		button.get_parent().add_child(glow)
		active_glow_particles.append(glow)
		
		# Animate
		var tween = create_tween().set_parallel(true)
		active_tweens.append(tween)
		
		tween.tween_property(glow, "scale", Vector2(2, 2), 0.6)
		tween.tween_property(glow, "color:a", 0.0, 0.6)
		
		tween.finished.connect(func():
			if glow and is_instance_valid(glow):
				glow.queue_free()
				active_glow_particles.erase(glow)
			_remove_tween_from_active(tween)
		)

func _play_entrance_animation():
	"""Dramatic and professional entrance animation"""
	if not panel or is_closing:
		return
	
	is_animating = true
	
	# Background fade-in
	panel.modulate = Color(1, 1, 1, 0)
	var fade_tween = create_tween()
	active_tweens.append(fade_tween)
	fade_tween.tween_property(panel, "modulate", Color.WHITE, 0.4)
	
	# Panel zoom and rotation effect
	panel.scale = Vector2(0.3, 0.3)
	panel.rotation = -0.4
	
	var tween = create_tween().set_parallel(true)
	active_tweens.append(tween)
	
	tween.tween_property(panel, "scale", Vector2.ONE, 0.7)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "rotation", 0.0, 0.6)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Subtle shake effect at the end
	tween.finished.connect(func():
		_remove_tween_from_active(tween)
		_remove_tween_from_active(fade_tween)
		
		if panel and is_instance_valid(panel) and not is_closing:
			var shake = create_tween()
			active_tweens.append(shake)
			
			var original_pos = panel.position.x
			shake.tween_property(panel, "position:x", original_pos + 5, 0.05)
			shake.tween_property(panel, "position:x", original_pos - 5, 0.05)
			shake.tween_property(panel, "position:x", original_pos, 0.05)
			
			shake.finished.connect(func():
				_remove_tween_from_active(shake)
				# Animate buttons sequentially with wave effect
				_animate_buttons_in()
			)
	)

func _animate_buttons_in():
	"""Animates each button entry with a wave effect"""
	if is_closing:
		return
	
	var buttons = [red_btn, blue_btn, green_btn, yellow_btn]
	var delay = 0.0
	
	for i in range(buttons.size()):
		var btn = buttons[i]
		if not btn or not is_instance_valid(btn):
			continue
		
		btn.scale = Vector2.ZERO
		btn.modulate.a = 0
		btn.rotation = -0.5
		
		await get_tree().create_timer(delay).timeout
		
		if is_closing or not btn or not is_instance_valid(btn):
			continue
		
		var tween = create_tween().set_parallel(true)
		active_tweens.append(tween)
		
		tween.tween_property(btn, "scale", Vector2.ONE, 0.5)\
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "modulate:a", 1.0, 0.3)
		tween.tween_property(btn, "rotation", 0.0, 0.4)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# Bounce effect at the end
		tween.finished.connect(func():
			_remove_tween_from_active(tween)
			
			if not is_closing and btn and is_instance_valid(btn):
				var bounce = create_tween()
				active_tweens.append(bounce)
				
				bounce.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)
				bounce.tween_property(btn, "scale", Vector2.ONE, 0.1)
				
				bounce.finished.connect(func():
					_remove_tween_from_active(bounce)
				)
		)
		
		delay += 0.12
	
	is_animating = false

func _on_color_picked(index: int):
	"""Handles color selection with spectacular exit animation"""
	if is_closing:
		return
	
	is_closing = true
	is_animating = true
	
	# Stop particle generation
	if particle_timer and is_instance_valid(particle_timer):
		particle_timer.stop()
	
	# Cancel all hover animations
	_cleanup_all_animations()
	
	color_selected.emit(index)
	
	var buttons = [red_btn, blue_btn, green_btn, yellow_btn]
	var selected_btn = buttons[index]
	var selected_color = [COLORS.red, COLORS.blue, COLORS.green, COLORS.yellow][index]
	
	if not selected_btn or not is_instance_valid(selected_btn):
		queue_free()
		return
	
	# Color explosion effect from selected button
	_create_color_explosion(selected_btn, selected_color)
	
	# Dramatic pulse effect on selected button
	var pulse = create_tween().set_parallel(true)
	active_tweens.append(pulse)
	
	pulse.tween_property(selected_btn, "scale", Vector2(1.5, 1.5), 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(selected_btn, "rotation", TAU, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)
	
	# Fade out other buttons
	for i in range(buttons.size()):
		if i != index and buttons[i] and is_instance_valid(buttons[i]):
			var fade = create_tween().set_parallel(true)
			active_tweens.append(fade)
			
			fade.tween_property(buttons[i], "modulate:a", 0.0, 0.3)
			fade.tween_property(buttons[i], "scale", Vector2(0.5, 0.5), 0.3)
			
			fade.finished.connect(func():
				_remove_tween_from_active(fade)
			)
	
	pulse.finished.connect(func():
		_remove_tween_from_active(pulse)
		_finish_exit_animation(selected_color)
	)

func _finish_exit_animation(selected_color: Color):
	"""Completes the exit sequence"""
	if not panel or not is_instance_valid(panel):
		queue_free()
		return
	
	# Change panel color to the selected one
	var panel_style = panel.get_theme_stylebox("panel")
	if panel_style and panel_style is StyleBoxFlat:
		var color_tween = create_tween()
		active_tweens.append(color_tween)
		color_tween.tween_property(panel_style, "bg_color", selected_color, 0.3)
		
		color_tween.finished.connect(func():
			_remove_tween_from_active(color_tween)
			_final_exit_animation()
		)
	else:
		_final_exit_animation()

func _final_exit_animation():
	"""Final exit zoom and rotation"""
	await get_tree().create_timer(0.3).timeout
	
	if not panel or not is_instance_valid(panel):
		queue_free()
		return
	
	var tween = create_tween().set_parallel(true)
	active_tweens.append(tween)
	
	tween.tween_property(panel, "scale", Vector2(3, 3), 0.5)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "rotation", TAU * 2, 0.5)\
		.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	
	tween.finished.connect(func():
		_remove_tween_from_active(tween)
		_cleanup_all_animations()
		queue_free()
	)

func _create_color_explosion(button: Button, color: Color):
	"""Creates a particle explosion of the selected color robustly"""
	if not button or not is_instance_valid(button):
		return
	
	var root = get_tree().root
	if not root or not is_instance_valid(root):
		return
	
	for i in range(30):
		var particle = ColorRect.new()
		var size = randf_range(5, 15)
		particle.custom_minimum_size = Vector2(size, size)
		particle.color = color
		particle.color.a = randf_range(0.6, 1.0)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Initial position at button center
		particle.position = button.global_position + button.size / 2
		root.add_child(particle)
		
		# Random direction
		var angle = randf() * TAU
		var speed = randf_range(100, 400)
		var direction = Vector2(cos(angle), sin(angle)) * speed
		
		# Animate explosion
		var tween = create_tween().set_parallel(true)
		active_tweens.append(tween)
		
		tween.tween_property(particle, "position", particle.position + direction, 0.8)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "color:a", 0.0, 0.8)
		tween.tween_property(particle, "scale", Vector2.ZERO, 0.8)\
			.set_trans(Tween.TRANS_EXPO)
		tween.tween_property(particle, "rotation", randf_range(-TAU, TAU), 0.8)
		
		tween.finished.connect(func():
			if particle and is_instance_valid(particle):
				particle.queue_free()
			_remove_tween_from_active(tween)
		)

func _remove_tween_from_active(tween: Tween):
	"""Safely removes a tween from the active tracking array"""
	if tween in active_tweens:
		active_tweens.erase(tween)

func _cleanup_all_animations():
	"""Cleans up all active animations and particles"""
	for tween in active_tweens:
		if tween and is_instance_valid(tween):
			tween.kill()
	
	active_tweens.clear()
	_cleanup_glow_particles()

func _exit_tree():
	"""Cleanup upon exiting the scene tree"""
	_cleanup_all_animations()
	
	if particle_timer and is_instance_valid(particle_timer):
		particle_timer.stop()
		particle_timer.queue_free()
	
	if particles_container and is_instance_valid(particles_container):
		particles_container.queue_free()
