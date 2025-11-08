local M = {}

-- NEWEREST NOTERES
-- 1. command used we are in a state where we dont know the prompt location.
-- 2. enable textchangedt and textchanged to search for a new prompt
-- 3. once found we do not always check on every input for performance reasons
-- 4. this would be the clean solution to handle weird shit

local function get_multiline(buf)
  if buf.prompt.row == nil or buf.prompt.col == nil then
    return
  end


	local lines = vim.api.nvim_buf_get_lines(0, buf.prompt.row - 1, buf.prompt.row + 3, false)
	local line = ""

	for k, v in ipairs(lines) do
		if k == 1 then
			line = lines[1]:sub(buf.prompt.col + 1)
		else
			line = line .. v
		end
	end

  -- vim.notify("got multiline with: " .. line)
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
	-- vim.notify("insert line with: " .. buf.prompt.line)
	return vim.api.nvim_chan_send(vim.bo.channel, buf.prompt.line)
end

-- todo:  here need to calculate on multilinin
local function set_term_cursor(cursor_col)
	local buf = M.buffers[vim.api.nvim_get_current_buf()]
	local p = replace_term_codes(buf.keybinds.goto_startof_line)
		.. vim.fn["repeat"](replace_term_codes(buf.keybinds.move_char_forward), cursor_col - buf.prompt.col)
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
	vim.keymap.set("n", "i", function()
		local buf = M.buffers[buffer]
		local cursor = vim.api.nvim_win_get_cursor(0)
		buf.prompt.cursor_col = cursor[2]
		vim.cmd("startinsert")
	end, { buffer = buffer })

	vim.keymap.set("n", "a", function()
		local buf = M.buffers[buffer]
		local cursor = vim.api.nvim_win_get_cursor(0)
		buf.prompt.cursor_col = cursor[2] + 1
		vim.cmd("startinsert")
	end, { buffer = buffer })

  -- todo: create a keybind for carriage return that makes the current prompt line empty.
  -- so that it is SURELY not reentering on termenter the old line from an old prompt if it hasnt refound a new one
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

			if start[1] ~= ent[1] then
			elseif vim.v.event.operator == "c" then
				local line = vim.api.nvim_get_current_line()
				line = line:sub(1, start[2]) .. line:sub(ent[2] + 2)
				buf.prompt.line = line:sub(buf.prompt.col + 1)
				if start[1] == ent[1] and start[2] == ent[2] then
					buf.prompt.cursor_col = start[2] - 1
				else
					buf.prompt.cursor_col = start[2]
				end
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

			if buf.prompt.col ~= nil and buf.prompt.col ~= nil then
				vim.bo.modifiable = (buf.prompt.row == cur[1] and buf.prompt.col <= cur[2]) or buf.prompt.row < cur[1]
			end
		end,
	})

	-- this triggers before a textyankpost. This is crucial since if we try to use ci" on an empty string no text
	-- yank post will be triggered but this STILL will be triggered and we can catch the edge case here.
	-- todo: we can probably just modifiable false here in the right occasion when cursor_col == nil
	-- then we can do modifiable false and then feedkeys a/i to land at exact location
	-- vim.api.nvim_create_autocmd("ModeChanged", {
	--   group = group,
	--   callback = function(args)
	--     if vim.bo[args.buf].buftype == "terminal" then
	--       local buf = M.buffers[args.buf]
	--
	--       if buf.prompt.cursor_col == nil then
	--         -- Save old error writer
	--         local old_err_write = vim.api.nvim_err_write
	--         vim.api.nvim_err_write = function(_) end
	--
	--         -- Flip modifiable off (cancels ci" etc.)
	--         vim.bo.modifiable = false
	--         buf.prompt.cursor_col = vim.api.nvim_win_get_cursor(0)
	--
	--         -- Restore error handler in the next tick
	--         vim.schedule(function()
	--           vim.api.nvim_err_write = old_err_write
	--
	--           vim.api.nvim_feedkeys(
	--             vim.api.nvim_replace_termcodes("i", true, false, true),
	--             "n", -- non-remappable
	--             false -- don't wait for input
	--           )
	--         end)
	--       end
	--     end
	--   end
	-- })
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
          cursor_row = nil
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
			[".*[$#%%][ ]"] = {},
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
