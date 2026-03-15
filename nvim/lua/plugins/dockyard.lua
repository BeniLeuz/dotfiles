require("dockyard").setup()
vim.keymap.set("n", "<leader>dy", function() 
  vim.cmd("Dockyard")
end, { desc = "Dockyard in new tab" })
