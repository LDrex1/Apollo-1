extends Node
## Allows background loading of scenes for transitions or streaming, as well as other resources

signal _load_result(path: String, success: bool)

var pending_paths: Array[String] = []


## Takes a resource path and loads it into memory in the background. This is a coroutine, so it must
## be awaited. You can use this to load a scene file in the background, then instantiate it and
## provide it to `transition` in order to smoothly load a new level. You can also use it to stream
## in chunks of a level in the background, and load new items or assets.
func bg_load(path: String) -> LoadResult:
	if not path.begins_with("res://") and not path.begins_with("uid://"):
		assert(false, "Expected path '%s' to begin with 'res://' or 'uid://'" % path)
		return LoadResult.new(ERR_INVALID_PARAMETER)

	var error := ResourceLoader.load_threaded_request(
		path,
		"PackedScene",
		false,
		ResourceLoader.CACHE_MODE_REUSE,
	)

	if error:
		return LoadResult.new(error)

	pending_paths.append(path)

	while true:
		# Result is an array of the params to _load_result
		var result: Array = await _load_result

		# Keep waiting if the event is not for our path
		if result[0] != path:
			continue

		# If the load failed, return a generic error
		if not result[1]:
			return LoadResult.new(FAILED)

		var res := ResourceLoader.load_threaded_get(path)

		# Type guard to make sure what we got was a PackedScene

		return LoadResult.new(OK, res)

	# Unreachable, but need to provide a final return statement for the type system
	return LoadResult.new(ERR_BUG)


## Changes the active scene to a specific node at the end of the current frame, freeing the old
## scene. This function await the `scene_changed` event on success, so can be used as a complete
## subroutine. Returns the underlying status code of `SceneTree#change_scene_to_node`.
##
## Note that the SceneTree will take ownership of the node, so the your reference to it will become
## invalid.
func transition(node: Node) -> int:
	var tree := get_tree()
	var result := tree.change_scene_to_node(node)

	if result == OK:
		await tree.scene_changed
		return result
	else:
		return result


func _process(_delta: float) -> void:
	# Check the status of any pending loads or inits on each frame
	var status: ResourceLoader.ThreadLoadStatus

	for path in pending_paths:
		status = ResourceLoader.load_threaded_get_status(path)

		if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_load_result.emit(path, status == ResourceLoader.THREAD_LOAD_LOADED)
			pending_paths.erase(path)


## The result of a call to `bg_load`. If `error` is `OK`, then `res` will be populated with the
## loaded resource. Otherwise, `error` will contain an `Error` constant and `res` wil be null.
class LoadResult:
	var error: Error
	var res: Resource

	func _init(err: Error, result: Resource = null) -> void:
		error = err
		res = result
