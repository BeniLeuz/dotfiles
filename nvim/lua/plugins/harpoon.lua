-- Terminal management per tab
local function get_terminal_list()
	vim.t.terminal_list = vim.t.terminal_list or {}
	return vim.t.terminal_list
end

local function create_terminal()
	vim.cmd("terminal")
	local bufnr = vim.api.nvim_get_current_buf()
	return bufnr
end

local function select_term(index)
	-- Get the existing list or create new one
	local term_list = vim.t.terminal_list
	if not term_list then
		term_list = {}
		vim.t.terminal_list = term_list
	end

	local stored_bufnr = term_list[index]

	-- If terminal exists at this index, go to it
	if stored_bufnr and vim.api.nvim_buf_is_valid(stored_bufnr) then
		vim.api.nvim_set_current_buf(stored_bufnr)
	else
		-- Create new terminal and store it at this index
		local bufnr = create_terminal()
		term_list[index] = bufnr
		vim.t.terminal_list = term_list
	end
end

local function remove_closed_terms()
	local term_list = get_terminal_list()
	local valid_terms = {}

	for _, bufnr in ipairs(term_list) do
		if vim.api.nvim_buf_is_valid(bufnr) then
			table.insert(valid_terms, bufnr)
		end
	end

	vim.t.terminal_list = valid_terms
end

-- Autocommands
vim.api.nvim_create_autocmd({ "TermClose", "VimEnter" }, {
	pattern = "*",
	callback = remove_closed_terms,
})

vim.api.nvim_create_autocmd({ "BufDelete", "BufUnload" }, {
	pattern = "term://*",
	callback = remove_closed_terms,
})

vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "term://*",
	callback = function()
		vim.wo.scrolloff = 0
		vim.wo.number = true
		vim.wo.relativenumber = true
		vim.wo.wrap = false
	end,
})

-- Keymaps for terminals
vim.keymap.set("n", "<leader>h", function()
	select_term(1)
end, { desc = "Terminal 1" })
vim.keymap.set("n", "<leader>j", function()
	select_term(2)
end, { desc = "Terminal 2" })
vim.keymap.set("n", "<leader>k", function()
	select_term(3)
end, { desc = "Terminal 3" })
vim.keymap.set("n", "<leader>l", function()
	select_term(4)
end, { desc = "Terminal 4" })

-- Toggle terminal menu
vim.keymap.set({ "n", "t" }, "<C-g>", function()
	local term_list = get_terminal_list()

	if #term_list == 0 then
		vim.notify("No terminals in list", vim.log.levels.INFO)
		return
	end

	local lines = {}
	for i, bufnr in ipairs(term_list) do
		if vim.api.nvim_buf_is_valid(bufnr) then
			local name = vim.api.nvim_buf_get_name(bufnr)
			table.insert(lines, string.format("%d: %s", i, name))
		end
	end

	-- Simple floating window menu
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local width = 60
	local height = #lines
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = (vim.o.columns - width) / 2,
		row = (vim.o.lines - height) / 2,
		style = "minimal",
		border = "rounded",
	})

	vim.bo[buf].modifiable = false
	vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
	vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf })
	vim.keymap.set("n", "<C-c>", "<cmd>close<cr>", { buffer = buf })

	-- Select terminal on <CR>
	vim.keymap.set("n", "<CR>", function()
		local line = vim.api.nvim_win_get_cursor(0)[1]
		vim.api.nvim_win_close(win, true)
		select_term(line)
	end, { buffer = buf })
end, { desc = "Toggle terminal menu" })

-- Go to n arg, e.g. `2ga` to go to 2nd arg
vim.keymap.set("n", "<C-h>", "<cmd>1argu<cr>zz", { desc = "Go to arg 1" })
vim.keymap.set("n", "<C-j>", "<cmd>2argu<cr>zz", { desc = "Go to arg 2" })
vim.keymap.set("n", "<C-k>", "<cmd>3argu<cr>zz", { desc = "Go to arg 3" })
vim.keymap.set("n", "<C-l>", "<cmd>4argu<cr>zz", { desc = "Go to arg 4" })
 
vim.keymap.set("n", "<leader>a", "<cmd>$argadd %<bar>argded<cr>", { desc = "Add cur file to arglist" })
 
-- Edit arglist in floating window
vim.keymap.set("n", "<C-e>", function()
  -- Set dimensions
  local abs_height = 15
  local rel_width = 0.7
 
  -- Create buf
  local argseditor = vim.api.nvim_create_buf(false, true)
  local filetype = "argseditor"
  vim.api.nvim_set_option_value("filetype", filetype, { buf = argseditor })
 
  -- Create centered floating window
  local rows, cols = vim.opt.lines._value, vim.opt.columns._value
  vim.api.nvim_open_win(argseditor, true, {
    relative = "editor",
    height = abs_height,
    width = math.ceil(cols * rel_width),
    row = math.ceil(rows / 2 - abs_height / 2),
    col = math.ceil(cols / 2 - cols * rel_width / 2),
    border = "single",
    title = filetype,
  })
 
  -- Put current arglist
  local arglist = vim.fn.argv(-1)
  local to_read = type(arglist) == "table" and arglist or { arglist }
  vim.api.nvim_buf_set_lines(argseditor, 0, -1, false, to_read)
 
  -- Go to file under cursor
  vim.keymap.set("n", "<CR>", function()
    local f = vim.fn.getline(".")
    vim.api.nvim_buf_delete(argseditor, { force = true })
    vim.cmd.e(f)
  end, { desc = "Go to file under cursor" })
 
  -- Write new arglist and close argseditor
  vim.keymap.set("n", "<C-c>", function()
    local to_write = vim.api.nvim_buf_get_lines(argseditor, 0, -1, true)
    vim.cmd("%argd")
    vim.cmd.arga(table.concat(to_write, " "))
    vim.api.nvim_buf_delete(argseditor, { force = true })
  end, { buffer = argseditor, desc = "Update arglist" })
end, { desc = "Edit arglist" })
