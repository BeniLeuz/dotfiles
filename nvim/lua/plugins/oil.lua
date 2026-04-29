local oil = require("oil")

oil.setup({
	skip_confirm_for_simple_edits = true,
	view_options = {
		show_hidden = true,
	},
	watch_for_changes = true,
	columns = {
		"icon",
		"permissions",
    "owner",
    "group",
		"size",
		"mtime",
	},
	keymaps = {
		["<C-h>"] = {},
		["<leader>oc"] = "actions.copy_to_system_clipboard",
		["<C-l>"] = {},
	},
})

vim.keymap.set("n", "<leader>pv", require("oil").open, { desc = "Open parent directory with Oil" })
