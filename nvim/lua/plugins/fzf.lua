local fzfbin = vim.fn.stdpath("data") .. "/site/pack/core/opt/fzf/bin/fzf"

if vim.fn.filereadable(fzfbin) == 0 then
	vim.schedule(function()
		vim.notify("Installing fzf binary…", vim.log.levels.INFO)
		vim.cmd("silent! call fzf#install()")
	end)
end

require("fzf-lua").setup({
	keymap = {
		builtin = {
			["<tab>"] = "toggle-preview",
			["<C-d>"] = "preview-page-down",
			["<C-u>"] = "preview-page-up",
		},
		fzf = {
			["ctrl-q"] = "select-all+accept",
		},
	},
	winopts = {
		preview = {
			backend = "builtin",
			hidden = "hidden",
		},
	},
})

-- make sure harpoon bindings dont trigger here...
vim.api.nvim_create_autocmd("FileType", {
	pattern = "fzf",
	callback = function(args)
		vim.keymap.set("t", "<C-h>", "<C-h>", { buffer = args.buf })
		vim.keymap.set("t", "<C-j>", "<C-j>", { buffer = args.buf })
		vim.keymap.set("t", "<C-k>", "<C-k>", { buffer = args.buf })
		vim.keymap.set("t", "<C-l>", "<C-l>", { buffer = args.buf })
		vim.keymap.set("t", "<C-f>", "<C-f>", { buffer = args.buf })
		vim.keymap.set("t", "<C-g>", "<C-g>", { buffer = args.buf })
		vim.keymap.set("t", "<C-e>", "<C-e>", { buffer = args.buf })
	end,
})

vim.keymap.set("n", "<leader>sf", FzfLua.files, { desc = "[S]earch [F]iles" })

-- keep the grep search completely normal... without regex default atleast!
vim.keymap.set("n", "<leader>sg", function()
	local rg_opts = require("fzf-lua.config").globals.grep.rg_opts
	FzfLua.live_grep_native({
		rg_opts = "--fixed-strings " .. rg_opts,
	})
end, { desc = "[S]earch by [G]rep (literal)" })

-- this has regex support!
vim.keymap.set("n", "<leader>sG", FzfLua.live_grep_native, { desc = "[S]earch by [G]rep (regex)" })
