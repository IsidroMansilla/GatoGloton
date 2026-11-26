class_name SafeAreaPage
extends Control

const DESIGN_SIZE := Vector2(360.0, 640.0)


func _ready() -> void:
	size = DESIGN_SIZE
	pivot_offset = Vector2.ZERO
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_reflow)
	_reflow()


static func get_safe_rect(viewport: Viewport) -> Rect2:
	var canvas_rect := Rect2(Vector2.ZERO, viewport.get_visible_rect().size)
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		return canvas_rect
	var safe_area := DisplayServer.get_display_safe_area()
	if safe_area.size.x <= 0 or safe_area.size.y <= 0:
		return canvas_rect
	var window_size := Vector2(DisplayServer.window_get_size())
	return compute_safe_rect(canvas_rect.size, window_size, Rect2(safe_area))


static func compute_safe_rect(canvas_size: Vector2, window_size: Vector2, safe_area: Rect2) -> Rect2:
	var canvas_rect := Rect2(Vector2.ZERO, canvas_size)
	if window_size.x <= 0.0 or window_size.y <= 0.0:
		return canvas_rect
	var factor := minf(window_size.x / canvas_size.x, window_size.y / canvas_size.y)
	if factor <= 0.0:
		return canvas_rect
	var letterbox := (window_size - canvas_size * factor) * 0.5
	var top_left := (safe_area.position - letterbox) / factor
	var bottom_right := (safe_area.position + safe_area.size - letterbox) / factor
	var mapped := Rect2(top_left, bottom_right - top_left).abs()
	var safe_rect := mapped.intersection(canvas_rect)
	if safe_rect.size.x < 1.0 or safe_rect.size.y < 1.0:
		return canvas_rect
	return safe_rect


func _reflow() -> void:
	if not is_inside_tree():
		return
	var safe_rect := get_safe_rect(get_viewport())
	var local_safe := safe_rect
	var parent_item := get_parent() as Control
	if parent_item != null:
		var parent_inverse := parent_item.get_global_transform_with_canvas().affine_inverse()
		var top_left := parent_inverse * safe_rect.position
		var bottom_right := parent_inverse * safe_rect.end
		local_safe = Rect2(top_left, bottom_right - top_left).abs()
	var fit := minf(local_safe.size.x / DESIGN_SIZE.x, local_safe.size.y / DESIGN_SIZE.y)
	fit = clampf(fit, 0.1, 1.0)
	scale = Vector2(fit, fit)
	position = local_safe.position
