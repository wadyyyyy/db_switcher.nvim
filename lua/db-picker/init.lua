local M = {}

local defaults = {
	source = "config.private_dbs",
	command = "DBS",
	reload_command = "DBSReload",
	picker = {
		layout_strategy = "center",
		layout_config = {
			width = 0.35,
			height = 0.25,
			prompt_position = "top",
		},
		previewer = false,
	},
}

local state = {
	opts = vim.deepcopy(defaults),
	dbs = {},
}

local function notify(message, level)
	vim.notify(message, level, { title = "DB Picker" })
end

local function load_dbs(source)
	local ok, value = pcall(require, source)
	if not ok then
		notify(("Could not load database source `%s`"):format(source), vim.log.levels.ERROR)
		return nil
	end

	if type(value) ~= "table" then
		notify(("Database source `%s` must return a table"):format(source), vim.log.levels.ERROR)
		return nil
	end

	local dbs = {}
	for name, url in pairs(value) do
		if type(name) ~= "string" or name == "" or type(url) ~= "string" or url == "" then
			notify("Database source contains an invalid entry", vim.log.levels.ERROR)
			return nil
		end
		dbs[name] = url
	end

	if vim.tbl_isempty(dbs) then
		notify(("Database source `%s` is empty"):format(source), vim.log.levels.WARN)
		return nil
	end

	return dbs
end

local function pick()
	local ok, pickers = pcall(require, "telescope.pickers")
	if not ok then
		notify("Telescope is required to choose a database", vim.log.levels.ERROR)
		return
	end

	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	local names = vim.tbl_keys(state.dbs)
	table.sort(names)

	pickers
		.new(vim.deepcopy(state.opts.picker), {
			prompt_title = "Databases",
			finder = finders.new_table({ results = names }),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local name = action_state.get_selected_entry()[1]
					actions.close(prompt_bufnr)
					vim.g.db = state.dbs[name]
					vim.g.db_name = name
					notify(("Selected database: %s"):format(name), vim.log.levels.INFO)
				end)
				return true
			end,
		})
		:find()
end

function M.reload()
	package.loaded[state.opts.source] = nil
	local dbs = load_dbs(state.opts.source)
	if not dbs then
		return false
	end

	state.dbs = dbs
	vim.g.dbs = dbs
	return true
end

function M.select()
	if vim.tbl_isempty(state.dbs) and not M.reload() then
		return
	end
	pick()
end

function M.setup(opts)
	state.opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
	if type(state.opts.source) ~= "string" or state.opts.source == "" then
		notify("The `source` option must be a non-empty module name", vim.log.levels.ERROR)
		return
	end

	M.reload()

	if vim.fn.exists(":" .. state.opts.command) == 2 then
		vim.api.nvim_del_user_command(state.opts.command)
	end
	vim.api.nvim_create_user_command(state.opts.command, M.select, {
		desc = "Choose a database connection",
	})

	if vim.fn.exists(":" .. state.opts.reload_command) == 2 then
		vim.api.nvim_del_user_command(state.opts.reload_command)
	end
	vim.api.nvim_create_user_command(state.opts.reload_command, function()
		M.reload()
	end, {
		desc = "Reload database connections",
	})
end

return M
