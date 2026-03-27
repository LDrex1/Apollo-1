extends Node
## Simple access to reading and writing key-value pairs to persistent files

## The prefix/protocol used for persistent local data
const DATA_PREFIX: String = "user://"
## The path to the global data file, this should be used for settings and other data which might
## span across multiple 'save files'
const GLOBAL_FILE_NAME: String = "global.dat"
## The format for slot data files, this should be used for individual save 'slots' or 'files' which
## may have different states of progress
const SLOT_FILE_TEMPLATE: String = "slot_%d.dat"


## Internal method for reading from a data file, shared by both read methods
func _read(filename: String, key: String, default: Variant) -> Variant:
	var file := FileAccess.open(DATA_PREFIX + filename, FileAccess.READ)

	# Just return the default value if the file doesn't exist
	if file == null:
		return default

	var data: Variant = file.get_var()

	assert(
		data is Dictionary,
		"Expected %s to be dictionary but was '%s'" % [filename, typeof(data)],
	)

	# If the data isn't the expected type, just return the default
	if data is not Dictionary or data == null:
		return default

	var dict: Dictionary = data
	return dict.get(key, default)


## Internal method for saving to a data file, shared by both save methods
func _save(filename: String, key: String, value: Variant) -> void:
	# Initially open the file in read-only mode when getting the contents to update
	var file := FileAccess.open(DATA_PREFIX + filename, FileAccess.READ)

	var data: Variant
	if file:
		data = file.get_var()

		assert(
			data is Dictionary,
			"Expected %s to be dictionary but was '%s'" % [filename, typeof(data)],
		)

		# If the data isn't the expected type, assume no data (you may want to replace this with
		# recovery logic)
		if data is not Dictionary:
			data = {}
	else:
		data = {}

	# Re-open the file for writing
	file = FileAccess.open(DATA_PREFIX + filename, FileAccess.WRITE)

	# Update the key, write the updated dictionary, and flush the data to disk in case of crashes
	var dict: Dictionary = data
	dict.set(key, value)
	file.store_var(dict)
	file.flush()


## Get a non-Object value from the global data file with a given key
func get_global(key: String, default: Variant) -> Variant:
	return _read(GLOBAL_FILE_NAME, key, default)


## Get a non-Object value from a slot data file with a given key
func get_slot(slot: int, key: String, default: Variant) -> Variant:
	return _read(SLOT_FILE_TEMPLATE % slot, key, default)


## Save a non-Object value to the global data file with a given key
func save_global(key: String, value: Variant) -> void:
	_save(GLOBAL_FILE_NAME, key, value)


## Save a non-Object value to a slot data file with a given key
func save_slot(slot: int, key: String, value: Variant) -> void:
	_save(SLOT_FILE_TEMPLATE % slot, key, value)
