local oil = require("oil")
oil.setup({
  skip_confirm_for_simple_edits = true,
  view_options = {
    show_hidden = true
  },
  keymaps = {
    ["<C-h>"] = {},
  },
})

vim.keymap.set("n", "<leader>pv", require("oil").open, { desc = "Open parent directory with Oil" })

