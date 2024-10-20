local ffi = require("ffi")
local log = require('libs.lua.log.log')
local xio = require('libs.lua.utils.io') -- TODO: replace with normal io
local paths = require('libs.lua.utils.paths')
local container = require('libs.lua.utils.container')
require('src.types')

--- -----------------------------------------------
---@param file file*
---@return PakHeader
local function load_pak_file_header(file)
	log.dbg("loading .PAK file header")

	local data = file:read(ffi.sizeof("PakHeader"))
	local header = ffi.cast("PakHeader*", data)
	return header
end

--- -----------------------------------------------
---@param header PakHeader
local function verify_pak_header(header)
	log.dbg("verifying .PAK file header")

	local haeder_code = ffi.string(header.Code, 4)
	print(header.Length)
	print(header.Offset)
	if haeder_code ~= PAK_MAGIC or header.Length <= 0 or header.Offset <= 0 then
		log.fatal(string.format(".PAK file header is not valid"))
	end
end

--- -----------------------------------------------
---@param header PakHeader
local function calculate_pak_items_count(header)
	log.dbg("calculating the number of items in the .PAK")

	return header.Length / ffi.sizeof("PakItemHeader")
end

--- -----------------------------------------------
---@param file file*
---@param header PakHeader
local function seek_to_pak_items_header(file, header)
	log.dbg("seeking to the .PAK items header")

	file:seek("set", header.Offset)
end

--- -----------------------------------------------
---@param file file*
---@param header PakItemHeader
---@return any
local function read_pak_item_data(file, header)
	log.dbg("reading .PAK item data")

	file:seek("set", header.Position)
	local data = file:read(header.Length)
	if not data then
		log.fatal(string.format("failed to read data from input pak item '%s'", ffi.string(header.Name, 56)))
	end

	return data
end

--- -----------------------------------------------
---@param file file*
---@param items_count integer
---@return PakItemHeader[]
local function load_pak_items_header(file, items_count)
	log.dbg("loading .PAK items header")

	---@type PakItemHeader[]
	local items = {}

	for index = 1, items_count do
		local data = file:read(ffi.sizeof("PakItemHeader"))
		local header = ffi.cast("PakItemHeader*", data)
		items[index] = header
	end

	return items
end

--- -----------------------------------------------
---@param p string
local function create_extraction_toplevel_dir(p)
	log.dbg("creating top level extraction directory")

	return paths.create_dir_if_doesnt_exist(p)
end

--- -----------------------------------------------
---@param p string
local function create_extraction_item_dir(p)
	log.dbg("creating .PAK item extraction directory")

	return paths.create_dir_if_doesnt_exist(p)
end

--- -----------------------------------------------
---@param pak_file file*
---@param headers PakItemHeader[]
---@param out_dir_path any
local function extract_items(pak_file, headers, out_dir_path)
	log.dbg("extracting items from .PAK file")

	local count = #headers
	for progress, header in pairs(headers) do
		print(string.format("%d/%d extracting '%s", progress, count, ffi.string(header.Name, 56)))

		local item_path, item_dir = paths.join_item_path(out_dir_path, ffi.string(header.Name, 56))
		create_extraction_item_dir(item_dir)
		local item_file = xio.open(item_path, "wb")
		local item_data = read_pak_item_data(pak_file, header)
		item_file:write(item_data)
		item_file:close()
	end
end

--- -----------------------------------------------
---@param items PakItemHeader[]
local function print_items_name(items)
	log.dbg("listing items from .PAK file")

	for _, item in pairs(items) do
		print(ffi.string(item.Name, 56))
	end
end

--- -----------------------------------------------
---@param pak_path string
---@param items PakItemHeader[]
---@param items_count integer
local function print_pak_info(pak_path, items, items_count)
	log.dbg("printing .PAK file information")

	local disk_size = paths.get_file_disk_size(pak_path)
	local names = {}
	for index, item in pairs(items) do names[index] = ffi.string(item.Name, 56) end
	local mapping = container.get_container_files_mapping(names)

	print("--- Information ------------------------------------------")
	print(string.format("  ◉ Path:            %s", pak_path))
	print(string.format("  ◉ Number of items: %d", items_count))
	print(string.format("  ◉ Size on disk:    %d bytes", disk_size))
	print("--- Items count per category -----------------------------")
	for _, item in ipairs(mapping) do
		print(string.format("  ◉ %s: %d", item[1], item[2]))
	end
end

--- -----------------------------------------------
---@param files string[]
---@return PakItemHeader[]
local function create_pak_items_header_from_files(files)
	log.dbg("creating .PAK items header info from the files in the source directory")

	---@type PakItemHeader[]
	local pak_items_header = {}
	local header_size = ffi.sizeof("PakHeader")
	local current_position = header_size

	for _, file in ipairs(files) do
		---@type PakItemHeader
		local pak_item_header = {
			Name = file,
			Length = paths.get_file_disk_size(file),
			Position = current_position
		}

		table.insert(pak_items_header, pak_item_header)
		current_position = current_position + pak_item_header.Length
	end

	return pak_items_header
end

--- -----------------------------------------------
---@param items_header PakItemHeader[]
---@return PakHeader
local function create_pak_header_from_pak_items_header(items_header)
	log.dbg(string.format("creating .PAK header info from its items header info"))

	---@type PakHeader
	local pak_header = {
		Code = PAK_MAGIC,
		Offset = ffi.sizeof("PakHeader"),
		Length = #items_header * ffi.sizeof("PakItemHeader")
	}

	for _, item in ipairs(items_header) do
		pak_header.Offset = pak_header.Offset + item.Length
	end

	return pak_header
end

--- -----------------------------------------------
---@param header PakHeader
---@param items_header PakItemHeader[]
---@param input_dir string
---@param output_pak string
local function create_pak_file(header, items_header, input_dir, output_pak)
	log.dbg(string.format("creating the actual .PAK file inti '%s'", output_pak))

	local pak_f = xio.open(output_pak, "wb")

	pak_f:write(ffi.string(header, ffi.sizeof("PakHeader")))
	for _, item_header in ipairs(items_header) do
		local data = paths.read_file_data(ffi.string(item_header.Name, 56))
		pak_f:write(data)
	end

	for _, pak_item_header in ipairs(items_header) do
		local new_name = paths.trim_path(ffi.string(pak_item_header.Name, 56), input_dir)
		pak_f:write(ffi.string(pak_item_header, ffi.sizeof("PakItemHeader")))
	end

	pak_f:close()
end

--- ===============================================
--- info command
--- ===============================================
---@param pak_file_path string
local function cmd_info(pak_file_path)
	local pak_f = xio.open(pak_file_path, "rb")
	local header = load_pak_file_header(pak_f)
	verify_pak_header(header)
	local items_count = calculate_pak_items_count(header)
	seek_to_pak_items_header(pak_f, header)
	local items_header = load_pak_items_header(pak_f, items_count)
	print_pak_info(pak_file_path, items_header, items_count)
	pak_f:close()
end

--- ===============================================
--- list command
--- ===============================================
---@param pak_file_path string
local function cmd_list(pak_file_path)
	local pak_f = xio.open(pak_file_path, "rb")
	local pak_header = load_pak_file_header(pak_f)
	verify_pak_header(pak_header)
	local items_count = calculate_pak_items_count(pak_header)
	seek_to_pak_items_header(pak_f, pak_header)
	local items_header = load_pak_items_header(pak_f, items_count)
	print_items_name(items_header)
	pak_f:close()
end

--- ===============================================
--- extract command
--- ===============================================
---@param pak_file_path string
---@param out_dir_path string
local function cmd_extract(pak_file_path, out_dir_path)
	local pak_f = xio.open(pak_file_path, "rb")
	local pak_header = load_pak_file_header(pak_f)
	verify_pak_header(pak_header)
	local items_count = calculate_pak_items_count(pak_header)
	seek_to_pak_items_header(pak_f, pak_header)
	local items_header = load_pak_items_header(pak_f, items_count)
	create_extraction_toplevel_dir(out_dir_path)
	extract_items(pak_f, items_header, out_dir_path)
	pak_f:close()
end

--- ===============================================
--- create command
--- ===============================================
---@param input_dir_path string
---@param output_pak_path string
local function cmd_create(input_dir_path, output_pak_path)
	local files = paths.list_files_in_dir(input_dir_path)
	local pak_items_header = create_pak_items_header_from_files(files)
	local pak_header = create_pak_header_from_pak_items_header(pak_items_header)
	create_pak_file(pak_header, pak_items_header, input_dir_path, output_pak_path)
end

--- ===============================================
--- Module
--- ===============================================
return {
	info = cmd_info,
	list = cmd_list,
	extract = cmd_extract,
	create = cmd_create
}
