local api, fn, uv, os_sep = vim.api, vim.fn, vim.uv, vim.g.os_sep
local dbs = {}

local function default_session_name()
	local t_cwd = fn.getcwd()
	if uv.os_uname().sysname == "Windows_NT" then
		t_cwd = t_cwd:gsub(".:", ""):gsub("\\", "/")
	end
	-- split + concat
	local cwd = ""
	local size, last, pos = #os_sep, 1, t_cwd:find("/", 1, true)
	while pos do
		local item = t_cwd:sub(last, pos - 1)
		if item:find("%p") then
			item = item:gsub("%p", "_")
		end
		cwd = cwd .. "_" .. item
		last = pos + size
		pos = t_cwd:find("/", last, true)
	end
	cwd = cwd .. "_" .. t_cwd:sub(last)

	return fn.substitute(cwd, [[^\.]], "", "")
end

local function session_list()
	local sessions, text, split = {}, fn.globpath(dbs.opt.dir, "*.vim"), "\n"
	local last = 1
	local pos = text:find(split, 1, true)
	while pos do
		table.insert(sessions, text:sub(last, pos - 1))
		last = pos + 1
		pos = text:find(split, last, true)
	end
	table.insert(sessions, text:sub(last))
	return sessions
end

local function session_save(session_name)
	local file_name = (not session_name or #session_name == 0) and default_session_name() or session_name
	local file_path = dbs.opt.dir .. os_sep .. file_name .. ".vim"
	api.nvim_command("mksession! " .. fn.fnameescape(file_path))
	vim.v.this_session = file_path

	print("[dbsession] save " .. file_name)
end

local function session_load(session_name)
	local file_path
	-- if not session load the latest
	if not session_name or #session_name == 0 then
		local list = session_list()
		local sname = default_session_name()
		for i = 1, #list do
			local item = list[i]
			if item:find(sname) then
				file_path = item
				break
			end
		end
	else
		file_path = dbs.opt.dir .. os_sep .. session_name .. ".vim"
	end

	if vim.v.this_session ~= "" and fn.exists("g:SessionLoad") == 0 then
		api.nvim_command("mksession! " .. fn.fnameescape(vim.v.this_session))
	end

	if fn.filereadable(file_path) == 1 then
		--save before load session
		local curbuf = vim.api.nvim_get_current_buf()
		if vim.bo[curbuf].modified then
			vim.cmd.write()
		end
		vim.cmd([[ noautocmd silent! %bwipeout!]])
		return api.nvim_command("silent! source " .. file_path)
	end

	vim.notify("[dbsession] load failed " .. file_path, vim.log.levels.ERROR)
end

local function session_delete(name)
	if not name then
		vim.notify("[dbsession] please choice a session to delete", vim.log.levels.WARN)
		return
	end

	local file_path = dbs.opt.dir .. os_sep .. name .. ".vim"

	if fn.filereadable(file_path) == 1 then
		fn.delete(file_path)
		vim.notify("[dbsession] deleted " .. name, vim.log.levels.INFO)
		return
	end

	vim.notify("[dbsession] delete failed " .. name, vim.log.levels.ERROR)
end

local function complete_list()
	local list = session_list()
	--list[i] = path/to/(filename).ext
	for i = 1, #list do
		local rpath = list[i]:reverse()
		local i_dot, i_sep = rpath:find(".", 1, true), rpath:find(os_sep, 1, true)
		list[i] = rpath:sub(i_dot + 1, i_sep - 1):reverse()
	end
	return list
end

function dbs:command()
	local user_command = api.nvim_create_user_command
	if self.opt.is_autosave_on_exit then
		api.nvim_create_autocmd("VimLeavePre", {
			group = api.nvim_create_augroup("session_autosave", { clear = true }),
			callback = function()
				session_save()
			end,
		})
	end

	user_command("SessionSave", function(args)
		session_save(args.args)
	end, {
		nargs = "?",
	})

	user_command("SessionLoad", function(args)
		session_load(args.args)
	end, {
		nargs = "?",
		complete = complete_list,
	})

	user_command("SessionDelete", function(args)
		session_delete(args.args)
	end, {
		nargs = "?",
		complete = complete_list,
	})
end

function dbs.setup(opt)
	dbs.opt = {
		dir = vim.fs.normalize(opt.dir or fn.stdpath("cache") .. os_sep .. "session"),
		is_autosave_on_exit = opt.auto_save_on_exit,
	}
	if fn.isdirectory(dbs.opt.dir) == 0 then
		fn.mkdir(dbs.opt.dir, "p")
	end
	dbs:command()
end

return dbs
