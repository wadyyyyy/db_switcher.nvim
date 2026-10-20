local M = {}

local defaults = {
	source = "config.private_dbs",
	default = nil,
	command = "DBS",
	reload_command = "DBSReload",
}

local state = {
	opts = vim.deepcopy(defaults),
	dbs = {},
}

local function notify(message, level)
	vim.notify(message, level, { title = "DB Switcher" })
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
	local names = vim.tbl_keys(state.dbs)
	table.sort(names)

	vim.ui.select(names, {
		prompt = "Databases:",
	}, function(name)
		if not name then
			return
		end

		vim.g.db = state.dbs[name]
		vim.g.db_name = name
		notify(("Selected database: %s"):format(name), vim.log.levels.INFO)
	end)
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

	if not M.reload() then
		return
	end

	if state.opts.default ~= nil then
		if type(state.opts.default) ~= "string" or not state.dbs[state.opts.default] then
			notify(("Default database `%s` was not found"):format(tostring(state.opts.default)), vim.log.levels.ERROR)
			return
		end
		vim.g.db = state.dbs[state.opts.default]
		vim.g.db_name = state.opts.default
	end

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
