local install_path = vim.fn.stdpath("data") .. "/site/pack/core/opt/markdown-preview.nvim/app"

if vim.fn.isdirectory(install_path) == 0 then
  vim.fn["mkdp#util#install"]()
end

vim.keymap.set("n", "<leader>mp",":MarkdownPreview<CR>")

