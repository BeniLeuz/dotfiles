local ts = require("nvim-treesitter")

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = "*.lhs",
	callback = function()
		vim.bo.filetype = "haskell"
	end,
})

vim.filetype.add({
	extension = {
		html = "html",
	},
})

vim.treesitter.language.register("ruby", { "crystal" })
vim.treesitter.language.register("gotmpl", { "html" })

vim.api.nvim_create_autocmd("FileType", {
	callback = function(ev)
		local lang = vim.treesitter.language.get_lang(ev.match)
		local available_langs = require("nvim-treesitter").get_available()
		local is_available = vim.tbl_contains(available_langs, lang)
		if is_available then
      if not vim.tbl_contains(require("nvim-treesitter").get_installed(), lang) then
        vim.notify("Installing tree-sitter parser for " .. lang .. "...", vim.log.levels.INFO)
      end
			require("nvim-treesitter").install(lang):wait()
			vim.treesitter.start()
		end
	end,
})
