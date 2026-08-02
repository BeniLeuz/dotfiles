-- Markview renders buffer decorations itself, but conceal options belong to a
-- window. Reapply its current-mode window setup whenever an attached buffer is
-- shown in a window (for example, after a Harpoon selection)
vim.api.nvim_create_autocmd("BufWinEnter", {
	group = vim.api.nvim_create_augroup("MarkviewInitialRedraw", { clear = true }),
	callback = function(args)
			if not vim.api.nvim_buf_is_valid(args.buf) then
				return
			end

			local state = require("markview.state")
			local buffer_state = state.get_buffer_state(args.buf, false)

			if state.buf_attached(args.buf) and buffer_state and buffer_state.enable then
				require("markview.actions").autocmd(
					"on_mode_change",
					args.buf,
					vim.fn.win_findbuf(args.buf),
					vim.fn.mode()
				)
			end
	end,
})
