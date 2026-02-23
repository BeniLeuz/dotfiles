require("mason").setup()
require("mason-lspconfig").setup()

vim.lsp.enable("sourcekit")

vim.lsp.config("ltex_plus", {
	settings = {
		ltex = {
			language = "en-US",
			additionalRules = {
				motherTongue = "en-US",
			},
		},
	},
})

vim.lsp.enable("ltex_plus", false)

vim.keymap.set("n", "<leader>cs", function()
	local client = vim.lsp.get_clients({ name = "ltex_plus", bufnr = 0 })[1]
	if client then
		vim.lsp.stop_client(client.id)
		vim.notify("[ltex] spellcheck disabled", vim.log.levels.INFO)
	else
		vim.cmd("LspStart ltex_plus")
		vim.notify("[ltex] spellcheck enabled", vim.log.levels.INFO)
	end
end, { desc = "Toggle ltex spellcheck" })

vim.lsp.config("ts_ls", {
	-- Server-specific settings. See `:help lsp-quickstart`
	settings = {
		implicitprojectconfiguration = {
			checkjs = true,
		},
	},
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
			},
		},
	},
})

vim.lsp.config("clangd", {
	init_options = {
		fallbackflags = {
			"-std=c99",
			"-i../include/",
			"-i./include/",
      "-pendantic",
      "-pendantic-errors",
      "-Werror",
      "-Wall",
      "-Wextra"
		},
	},
})

vim.lsp.config("html", {
	filetypes = { "html", "markdown", "htmldjango", "eruby" },
	settings = {
		html = {
			format = { indentinnerhtml = true },
		},
	},
})

-- latex lsp
vim.lsp.config("texlab", {
	settings = {
		texlab = {
			build = {
				executable = "latexmk",
				args = {
					"-pdf",
					"-interaction=nonstopmode",
					"-synctex=1",
					"-bibtex",
					"-auxdir=build",
					"%f",
				},
				-- rather for debounced saving
				-- forwardSearchAfter = true,
				onSave = true,
			},
			forwardSearch = {
				executable = "sioyek",
				args = {
					"--reuse-window",
					"--nofocus",
					"--forward-search-file",
					"%f",
					"--forward-search-line",
					"%l",
					"%p",
				},
			},
		},
	},
})

-- Lsp attach stuff for mostly latex
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if not client or client.name ~= "texlab" then
			return
		end

		vim.keymap.set(
			"n",
			"<leader>lf",
			"<Cmd>LspTexlabForward<CR>",
			{ buffer = args.buf, desc = "LaTeX forward search" }
		)

		-- Automatically setup inverse search in Sioyek when LSP attaches
		vim.defer_fn(function()
			local pdf = vim.fn.expand("%:p:r") .. ".pdf"
			if vim.fn.filereadable(pdf) == 1 then
				vim.fn.jobstart({
					"sioyek",
					"--nofocus",
					"--reuse-window",
					"--execute-command",
					"turn_on_synctex",
					"--inverse-search",
					string.format(
						'nvim --server %s --remote-send "<Cmd>edit %%1 | call cursor(%%2, 1)<CR>"',
						vim.v.servername
					),
					pdf,
				}, { detach = true })
			end
		end, 100)
	end,
})

vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, {})
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, {})
