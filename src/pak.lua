require('libs.lua.app.types')
local log = require('libs.lua.log.log')
local xio = require('libs.lua.utils.io')
local bits = require('libs.lua.utils.bits')
local paths = require('libs.lua.utils.paths')
local container = require('libs.lua.utils.container')

local read = bits.reader
local write = bits.writer

--- -----------------------------------------------
---@param file file*
---@return PakHeader
local load_pak_file_header = function(file)
	log.dbg("loading .PAK file header")

	---@type PakHeader
	local header = {
		Code = read.bytes(file, PakHeader_.Code),
		Offset = read.integer(file),
		Length = read.integer(file),
	}

	return header
end

--- -----------------------------------------------
---@param header PakHeader
local verify_pak_header = function(header)
	log.dbg("verifying .PAK file header")

	if header.Code ~= PakHeader_.CODE or header.Length <= 0 or header.Offset <= 0 then
		log.fatal(string.format(".PAK file header is not valid"))
	end
end

--- -----------------------------------------------
---@param header PakHeader
local calculate_pak_items_count = function(header)
	log.dbg("calculating the number of items in the .PAK")

	local header_size = PakItemHeader_.Name + PakItemHeader_.Position + PakItemHeader_.Length
	return header.Length / header_size
end

--- -----------------------------------------------
---@param file file*
---@param header PakHeader
local seek_to_pak_items_header = function(file, header)
	log.dbg("seeking to the .PAK items header")

	file:seek("set", header.Offset)
end

--- -----------------------------------------------
---@param file file*
---@param header PakItemHeader
---@return any
local read_pak_item_data = function(file, header)
	log.dbg("reading .PAK item data")

	file:seek("set", header.Position)
	local data = read.bytes(file, header.Length)
	if not data then
		log.fatal(string.format("failed to read data from input pak item '%s'", header.Name))
	end

	return data
end

--- -----------------------------------------------
---@param file file*
---@param items_count integer
---@return PakItemHeader
local load_pak_items_header = function(file, items_count)
	log.dbg("loading .PAK items header")

	---@type PakItemsHeader
	local items = {}

	for index = 1, items_count do
		items[index] = {
			Name = read.cstring(file, PakItemHeader_.Name),
			Position = read.integer(file),
			Length = read.integer(file),
		}
	end

	return items
end

--- -----------------------------------------------
---@param p string
local create_extraction_toplevel_dir = function(p)
	log.dbg("creating top level extraction directory")

	return paths.create_dir_if_doesnt_exist(p)
end

--- -----------------------------------------------
---@param p string
local create_extraction_item_dir = function(p)
	log.dbg("creating .PAK item extraction directory")

	return paths.create_dir_if_doesnt_exist(p)
end

--- -----------------------------------------------
---@param pak_file file*
---@param headers PakItemsHeader
---@param out_dir_path any
local extract_items = function(pak_file, headers, out_dir_path)
	log.dbg("extracting items from .PAK file")

	local count = #headers
	for progress, header in pairs(headers) do
		print(string.format("%d/%d extracting '%s", progress, count, header.Name))

		local item_path, item_dir = paths.join_item_path(out_dir_path, header.Name)
		create_extraction_item_dir(item_dir)
		local item_file <close> = xio.open(item_path, "wb")
		local item_data = read_pak_item_data(pak_file, header)
		write.all(item_file, item_data)
	end
end

--- -----------------------------------------------
---@param items PakItemsHeader
local print_items_name = function(items)
	log.dbg("listing items from .PAK file")

	for _, item in pairs(items) do
		print(item.Name)
	end
end

--- -----------------------------------------------
---@param pak_path string
---@param items PakItemsHeader
---@param items_count integer
local print_pak_info = function(pak_path, items, items_count)
	log.dbg("printing .PAK file information")

	local disk_size = paths.get_file_disk_size(pak_path)
	local names = {}
	for index, item in pairs(items) do names[index] = item.Name end
	local mapping = container.get_container_files_mapping(names)

	print("--- Information ------------------------------------------")
	print(string.format("  ◉ Path:            %s", pak_path))
	print(string.format("  ◉ Number of items: %d", items_count))
	print(string.format("  ◉ Size on disk:    %d bytes", disk_size))
	print("--- Items count per category -----------------------------")
	for _, item in ipairs(mapping) do
		print(string.format("  ◉ %8s: %d", item[1], item[2]))
	end
end

--- -----------------------------------------------
---@param files string[]
---@return PakItemsHeader
local create_pak_items_header_from_files = function(files)
	log.dbg("creating .PAK items header info from the files in the source directory")

	---@type PakItemsHeader
	local pak_items_header = {}
	local header_size = PakHeader_.Code + PakHeader_.Offset + PakHeader_.Length
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
---@param items_header PakItemsHeader
---@return PakHeader
local create_pak_header_from_pak_items_header = function(items_header)
	log.dbg(string.format("creating .PAK header info from its items header info"))

	local header_size = PakHeader_.Code + PakHeader_.Offset + PakHeader_.Length
	local item_header_size = PakItemHeader_.Name + PakItemHeader_.Position + PakItemHeader_.Length
	---@type PakHeader
	local pak_header = {
		Code = "PACK",
		Offset = header_size,
		Length = #items_header * item_header_size
	}

	for _, item in ipairs(items_header) do
		pak_header.Offset = pak_header.Offset + item.Length
	end

	return pak_header
end

--- -----------------------------------------------
---@param pak_header PakHeader
---@param pak_items_header PakItemsHeader
---@param input_dir_path string
---@param output_pak_path string
local create_pak_file = function(pak_header, pak_items_header, input_dir_path, output_pak_path)
	log.dbg(string.format("creating the actual .PAK file inti '%s'", output_pak_path))

	local pak_f <close> = xio.open(output_pak_path, "wb")
	if not pak_f then
		log.fatal(string.format("failed to open '%s' for writing .PAK data", output_pak_path), err)
	end

	write.all(pak_f, pak_header.Code)
	write.integer(pak_f, pak_header.Offset)
	write.integer(pak_f, pak_header.Length)

	for _, pak_item_header in ipairs(pak_items_header) do
		local data = paths.read_file_data(pak_item_header.Name)
		write.all(pak_f, data)
	end

	for _, pak_item_header in ipairs(pak_items_header) do
		local new_name = paths.trim_path(pak_item_header.Name, input_dir_path)
		write.string(pak_f, new_name, 56)
		write.integer(pak_f, pak_item_header.Position)
		write.integer(pak_f, pak_item_header.Length)
	end
end

--- ===============================================
--- info command
--- ===============================================
---@param pak_file_path string
local cmd_info = function(pak_file_path)
	local pak_f <close> = xio.open(pak_file_path, "rb")
	local header = load_pak_file_header(pak_f)
	verify_pak_header(header)
	local items_count = calculate_pak_items_count(header)
	seek_to_pak_items_header(pak_f, header)
	local items_header = load_pak_items_header(pak_f, items_count)
	print_pak_info(pak_file_path, items_header, items_count)
end

--- ===============================================
--- list command
--- ===============================================
---@param pak_file_path string
local cmd_list = function(pak_file_path)
	local pak_f <close> = xio.open(pak_file_path, "rb")
	local pak_header = load_pak_file_header(pak_f)
	verify_pak_header(pak_header)
	local items_count = calculate_pak_items_count(pak_header)
	seek_to_pak_items_header(pak_f, pak_header)
	local items_header = load_pak_items_header(pak_f, items_count)
	print_items_name(items_header)
end

--- ===============================================
--- extract command
--- ===============================================
---@param pak_file_path string
---@param out_dir_path string
local cmd_extract = function(pak_file_path, out_dir_path)
	local pak_f <close> = xio.open(pak_file_path, "rb")
	local pak_header = load_pak_file_header(pak_f)
	verify_pak_header(pak_header)
	local items_count = calculate_pak_items_count(pak_header)
	seek_to_pak_items_header(pak_f, pak_header)
	local items_header = load_pak_items_header(pak_f, items_count)
	create_extraction_toplevel_dir(out_dir_path)
	extract_items(pak_f, items_header, out_dir_path)
end

--- ===============================================
--- create command
--- ===============================================
---@param input_dir_path string
---@param output_pak_path string
local cmd_create = function(input_dir_path, output_pak_path)
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
