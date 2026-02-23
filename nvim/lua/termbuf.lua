local M = {}

-- todo: ciobject with empty object will just not work... callbacks ive tried to get cursor pos
-- textyankpost, textchanged, modechanged, ci" override, modechangefunc or something like that
-- all of the mwill not fire before termenter when doing empty "" i think i need to patch nvim core if i want
-- a termenterpre autocmd (would make this entire thing waaay easier btw)
--
-- NEWEREST NOTERES
-- 1. command used we are in a state where we dont know the prompt location.
-- 2. enable textchangedt and textchanged to search for a new prompt
-- 3. once found we do not always check on every input for performance reasons
-- 4. this would be the clean solution to handle weird shit

local function get_multiline(buf)
	if buf.prompt.row == nil or buf.prompt.col == nil then
		return
	end

	-- 4 lines multiline support right now
  -- todo make this configurable
	local lines = vim.api.nvim_buf_get_lines(0, buf.prompt.row - 1, buf.prompt.row + 3, false)
	local line = ""

	for k, v in ipairs(lines) do
		if k == 1 then
			line = lines[1]:sub(buf.prompt.col + 1)
		else
			line = line .. v
		end
	end
	return line
end

local function save_line(buf)
	buf.prompt.line = get_multiline(buf)
end

local function replace_term_codes(keys)
	return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function clear_line(buf)
	return vim.api.nvim_chan_send(vim.bo.channel, replace_term_codes(buf.keybinds.clear_line))
end

local function insert_line(buf)
	return vim.api.nvim_chan_send(vim.bo.channel, buf.prompt.line)
end

-- todo:  here need to calculate on multilinin
local function set_term_cursor(cursor_col)
	local buf = M.buffers[vim.api.nvim_get_current_buf()]

	local window_id = vim.api.nvim_get_current_win()
	local window_info = vim.fn.getwininfo(window_id)[1]

	-- we need textoff since .width actually includes the gutter and number = true width etc which is not what we need.
	local max_width = window_info.width - window_info.textoff
	local diff_row = buf.prompt.cursor_row - buf.prompt.row
	local movement = (diff_row * max_width) + (cursor_col - buf.prompt.col)

	local p = replace_term_codes(buf.keybinds.goto_startof_line)
		.. vim.fn["repeat"](replace_term_codes(buf.keybinds.move_char_forward), movement)
	vim.api.nvim_chan_send(vim.bo.channel, p)
end

local function update_line(buf)
	local err_clear = clear_line(buf)
	local err_insert = insert_line(buf)

	if err_clear or err_insert then
		return error("Wasn't able to update line in terminal")
	end
end

local function setup_keybinds(buffer)
  -- todo: add I and A keybinds
	vim.keymap.set("n", "i", function()
		local buf = M.buffers[buffer]
		local cursor = vim.api.nvim_win_get_cursor(0)
		buf.prompt.cursor_col = cursor[2]
		buf.prompt.cursor_row = cursor[1]
		vim.cmd("startinsert")
	end, { buffer = buffer })

	vim.keymap.set("n", "a", function()
		local buf = M.buffers[buffer]
		local cursor = vim.api.nvim_win_get_cursor(0)
		buf.prompt.cursor_col = cursor[2] + 1
		buf.prompt.cursor_row = cursor[1]
		vim.cmd("startinsert")
	end, { buffer = buffer })

	local original_cr = vim.fn.maparg("<CR>", "t", false, true)
	vim.keymap.set("t", "<CR>", function()
		local buf = M.buffers[buffer]
		buf.prompt.line = ""
		buf.prompt.row = nil
		buf.prompt.col = nil

		-- Execute any original mapping if it existed
		if original_cr and original_cr.callback then
			return original_cr.callback()
		end

		return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
	end, { expr = true, buffer = buffer })
end

local function setup_cmds()
	local group = vim.api.nvim_create_augroup("termbuf-edit", {})

	vim.api.nvim_create_autocmd("TextYankPost", {
		pattern = M.buf_pattern,
		group = group,
		callback = function(args)
			local start = vim.api.nvim_buf_get_mark(args.buf, "[")
			local ent = vim.api.nvim_buf_get_mark(args.buf, "]")
			local buf = M.buffers[args.buf]

			-- this next part was written by ai take it with a grain of salt XD but it tapped
			-- it so im keeping it for now todo: it does break on empty textyankpost like ci" on "" i think this never runs
			if vim.v.event.operator == "c" then
				local joined = get_multiline(buf)

				-- figure out absolute offsets for the yank marks inside that joined string
				local offset = 0
				for i = buf.prompt.row, start[1] - 1 do
					-- only count real lines between the prompt start and the change start
					local l = vim.api.nvim_buf_get_lines(args.buf, i - 1, i, false)[1]
					offset = offset + #l
				end

				local s_abs = (start[2] - buf.prompt.col) + offset
				local e_abs = (ent[2] - buf.prompt.col) + offset

				-- simulate what the buffer will look like after the change
				local new_line = joined:sub(1, s_abs) .. joined:sub(e_abs + 2)
				buf.prompt.line = new_line

				if start[1] == ent[1] and start[2] == ent[2] then
					buf.prompt.cursor_col = start[2] - 1
				else
					buf.prompt.cursor_col = start[2]
				end

				buf.prompt.cursor_row = start[1]
			end
		end,
	})

	vim.api.nvim_create_autocmd("TextChanged", {
		pattern = M.buf_pattern,
		group = group,
		callback = function(args)
			local buf = M.buffers[args.buf]

			if buf.prompt.col == nil then
				return
			end

			save_line(buf)
		end,
	})

	vim.api.nvim_create_autocmd("TextChangedT", {
		pattern = M.buf_pattern,
		group = group,
		callback = function(args)
			local buf = M.buffers[args.buf]
			local cursor = vim.api.nvim_win_get_cursor(0)
			vim.api.nvim_win_set_cursor(0, cursor)
			local line = vim.api.nvim_get_current_line()

			for prompt, _ in pairs(M.prompts) do
				local s, e = line:find(prompt)
				if s ~= nil then
					buf.prompt.row = cursor[1]
					buf.prompt.col = e
				end
			end

			save_line(buf)
		end,
	})

	-- TODO strip spaces
	vim.api.nvim_create_autocmd("TermEnter", {
		pattern = M.buf_pattern,
		group = group,
		callback = function(args)
			local buf = M.buffers[args.buf]

			if buf.prompt.row == nil or buf.prompt.col == nil then
				return
			end

			update_line(buf)
			set_term_cursor(buf.prompt.cursor_col)
		end,
	})

	vim.api.nvim_create_autocmd("CursorMoved", {
		pattern = M.buf_pattern,
		group = group,
		callback = function(args)
			local buf = M.buffers[args.buf]
			local cur = vim.api.nvim_win_get_cursor(0)
      -- todo fix afte rexecution prompt being editable in <CR> callback thanks modifiable true
      -- and then into modifiable false needs to be simply set or maybe external state var

			if buf.prompt.col ~= nil and buf.prompt.col ~= nil then
				vim.bo.modifiable = (buf.prompt.row == cur[1] and buf.prompt.col <= cur[2]) or buf.prompt.row < cur[1]
			end
		end,
	})
end

--- Set up the plugin internally on termopen
---@return nil
local function setup()
	setup_cmds()

	local augr_term = vim.api.nvim_create_augroup("termbuf", {})
	vim.api.nvim_create_autocmd("TermOpen", {
		pattern = M.buf_pattern,
		group = augr_term,
		callback = function(args)
			M.buffers[args.buf] = {
				keybinds = M.default_keybinds,
				prompt = {
					line = nil,
					row = nil,
					col = nil,

					-- this represents where we went into keybinds like a or I etc that we know where to go after on termenter
					cursor_col = nil,
					cursor_row = nil,
				},
			}
			setup_keybinds(args.buf)
		end,
	})
end

---@class Keybinds
---@field clear_line string Key to clear the current line in editable regions
---@field move_char_forward string Key to move forward one character
---@field goto_startof_line string Key to move to the start of the line

---@class PromptOptions
---@field keybinds? Keybinds Custom keybindings for this specific prompt pattern

---@class TermBufConfig
---@field prompts? {[string]: PromptOptions} Table of prompt patterns mapping to their options. Keys are Lua pattern strings that match terminal prompts (e.g., '.*[$#%%][ ]?')
---@field default_keybinds? Keybinds Default keybindings for your terminal

--- Set up the termbuf plugin with the configuration
---@param config TermBufConfig Configuration table for editable-term
---@return nil
M.setup = function(config)
	-- this might not make sense since modifiable ruined on different command term outputs
	M.buf_pattern = "term://*"
	M.buffers = {}
	M.prompts = config.prompts
		or {
			-- space needs to be included!!!
			[".*[$#%][ ]"] = {},
			["%(%gdb%)[ ]"] = {},
			["^ghci>%s"] = {},
			-- todo
			-- not yet supported!
			-- if you want to add different keybinds for the a prompt
			-- ['# '] = {
			--   keybinds = {
			--     clear_current_line = '<C-e><C-u>',
			--     forward_char = '<C-f>',
			--     goto_line_start = '<C-a>',
			--   }
			-- }
		}

	M.default_keybinds = {
		clear_line = "<C-e><C-u>",
		move_char_forward = "<C-f>",
		goto_startof_line = "<C-a>",
	}
	setup()
end

return M
