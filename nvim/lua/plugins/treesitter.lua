local configs = require("nvim-treesitter.configs")

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = "*.lhs",
  callback = function()
    vim.bo.filetype = "haskell"
  end,
})

configs.setup({
  highlight = { enable = true },
  indent = { enable = true },
  auto_install = true,
})


vim.filetype.add({
  extension = {
    html = "html",
  },
})

vim.treesitter.language.register("ruby", "crystal")
-- Make sure both languages are recognized
vim.treesitter.language.register("gotmpl", "html")
