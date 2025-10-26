vim.pack.add({
	{ src = "https://github.com/barreiroleo/ltex_extra.nvim" },
	{ src = "https://github.com/habamax/vim-polar" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
	{ src = "https://github.com/nvim-telescope/telescope.nvim" },
	{ src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/rafamadriz/friendly-snippets" },
	{ src = "https://github.com/Saghen/blink.cmp", version = "v1.7.0" },
	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/mason-org/mason-lspconfig.nvim" },
	{ src = "https://github.com/mason-org/mason.nvim" },
	{ src = "https://github.com/chomosuke/term-edit.nvim", version = "v1.4.0" },
	{ src = "https://github.com/tpope/vim-fugitive" },
	-- neotest
	-- INFO: needs to be ran to download junit console
	-- :NeotestJava setup
	{ src = "https://github.com/nvim-neotest/nvim-nio" },
	{ src = "https://github.com/antoinemadec/FixCursorHold.nvim" },
	{ src = "https://github.com/alfaix/neotest-gtest" },
	{ src = "https://github.com/mfussenegger/nvim-jdtls" },
	{ src = "https://github.com/mfussenegger/nvim-dap" },
	{ src = "https://github.com/rcarriga/nvim-dap-ui" },
	{ src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
	{ src = "https://github.com/rcasia/neotest-java" },
	{ src = "https://github.com/nvim-neotest/neotest" },
})

-- vim.o.shell = '/bin/bash -l'
-- vim.g.clipboard = {
--     name = 'iTerm2 copy',
--     copy = {
--         ['+'] = {'bash', '-c', '~/.iterm2/it2copy>$SSH_TTY'},
--         ['*'] = {'bash', '-c', '~/.iterm2/it2copy>$SSH_TTY'}
--     },
--     paste = {['+'] = 'true', ['*'] = 'true'}
-- }

-- add this to .gitconfig for git d -d main working as expected
-- [diff]
--   tool = nvim_difftool
-- [difftool "nvim_difftool"]
--     cmd = nvim -c \"set diff\" -c \"silent! DiffTool $LOCAL $REMOTE\"
vim.cmd("packadd nvim.difftool")
require("vim-options")
require("vim-remaps")
require("theme")
require("projectionizer")
require("commandwindow")
-- currently broken in nvim 12 not sure why just rewrite this XDDD
-- require("plugins.editable_term")
require("plugins.harpoon")
require("plugins.treesitter")
require("plugins.telescope")
require("plugins.git")
require("plugins.oil")
require("plugins.autocomplete")
require("plugins.lsp")
require("plugins.git")
require("plugins.term-edit")
require("plugins.neotest")



-- require("termbuf").setup({})
-- for printing
-- vim.cmd("colorscheme polar");
--
--
--
-- vim.keymap.set('n', '<leader>di', function()
--   local remote_branch = vim.fn.system('git rev-parse --abbrev-ref @{upstream} 2>/dev/null'):gsub('\n', '')
--   if remote_branch == '' then
--     vim.notify('No upstream branch set', vim.log.levels.WARN)
--     return
--   end
--   local chan = vim.fn.termopen(vim.o.shell)
--   -- Send the git difftool command
--   vim.fn.chansend(chan, 'git d -d ' .. remote_branch .. '\n')
-- end, { desc = 'Git difftool vs upstream' })

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


