-- dap repl commands
-- - .c continue
-- - .into step into
-- - .out step out
-- - .p pause
-- - .help list commands

local dap = require("dap")
require("dap-view").setup({})
require("nvim-dap-virtual-text").setup({})

vim.keymap.set("n", "<Leader>db", function()
	dap.toggle_breakpoint()
end, { desc = "Debug toggle breakpoint" })

vim.keymap.set("n", "<Leader>ds", function()
	dap.step_over()
end, { desc = "Debug step over" })

vim.keymap.set("n", "<Leader>dsi", function()
	dap.step_into()
end, { desc = "Debug step into" })

vim.keymap.set("n", "<Leader>dso", function()
	dap.step_out()
end, { desc = "Debug step out" })

vim.keymap.set("n", "<leader>dv", "<cmd>DapViewToggle<cr>", { desc = "Debug view toggle" })

vim.keymap.set("n", "<leader>dc", function()
	local session = dap.session()
	if not session then
		dap.continue({ new = true })
		return
	end
	if session.stopped_thread_id then
		dap.continue()
		return
	end
	vim.notify("Debuggee is running. Use leader dt to stop", vim.log.levels.INFO)
end, { desc = "Debug start/continue" })

vim.keymap.set("n", "<leader>dt", function()
	dap.terminate()
end, { desc = "Debug stop" })

vim.keymap.set("n", "<leader>dr", function()
	dap.repl.open()
end, { desc = "Debug REPL open" })

require("dap-view").setup({
	winbar = {
		sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl", "console" },
		default_section = "watches",
    base_sections = {
      watches = { label = "", keymap = "W" },
      scopes = { label = "", keymap = "S" },
      exceptions = { label = "", keymap = "E" },
      breakpoints = { label = "", keymap = "B" },
      threads = { label = "", keymap = "T" },
      repl = { label = "", keymap = "R" },
      console = { label = "", keymap = "C" },
      -- getting merged weith rest :)
      -- sessions = { label = "", keymap = "K" },
    },
	},
	auto_toggle = true,
	windows = {
		position = "right",
		size = 0.50,
	},
})
