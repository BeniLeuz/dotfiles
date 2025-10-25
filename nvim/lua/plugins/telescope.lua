local actions = require("telescope.actions")

require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ["<esc>"] = actions.close,
      },
    },
    file_ignore_patterns = { "^.git/" },
    hidden = true
  },
  pickers = {
    find_files = {
      hidden = true
    },
  },
}

local plugin_path = vim.fn.stdpath('data') .. '/site/pack/core/opt/telescope-fzf-native.nvim'
if not vim.uv.fs_stat(plugin_path .. "/build/libfzf.so") then
  vim.fn.system('cd ' .. plugin_path .. '&& make')
end

local builtin = require("telescope.builtin")
require("telescope").load_extension("fzf")

vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
-- vim.keymap.set('n', '<leader><space>', builtin.buffers, { desc = '[ ] Find existing buffers' })
