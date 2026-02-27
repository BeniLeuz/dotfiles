local neotest = require("neotest")

-- run nearest
vim.keymap.set("n", "<leader>nn", function()
	neotest.run.run()
end, { desc = "run current test" })

-- run file
vim.keymap.set("n", "<leader>nf", function()
	neotest.run.run(vim.fn.expand("%"))
end, { desc = "run test file" })

vim.keymap.set("n", "<leader>no", function()
	local buf = require("neotest").output_panel.buffer()
	if buf then
		vim.api.nvim_set_current_buf(buf)
		vim.cmd("keepjumps normal! G")
	end
end)

vim.keymap.set("n", "<leader>ns", function()
	neotest.summary.toggle()
end, { desc = "Open test summary" })

neotest.setup({
	icons = {
		child_indent = "│",
		child_prefix = "├",
		collapsed = "─",
		expanded = "╮",
		failed = "F",
		final_child_indent = " ",
		final_child_prefix = "╰",
		non_collapsible = "─",
		notify = "N",
		passed = "P",
		running = "R",
		running_animated = { "/", "|", "\\", "-", "/", "|", "\\", "-" },
		skipped = "S",
		unknown = "U",
		watching = "W",
	},
	adapters = {
		require("neotest-java")({}),
		-- c#
		-- this literally BREAKS alt-t terminal behavior because it always loads?????
		-- require("neotest-vstest"),
		-- mark tests
		-- then :ConfigureGtest
		-- also nice to have for recompile in terminal just run this:
		-- find folder | entr -c make or cmake
		require("neotest-gtest").setup({}),
	},
	summary = {
		open = "botright vsplit | vertical resize 40", -- pick any resize you want
	},
})
