-- pipes ! outputs in commandwindow (:q) to a buffer called "output"
-- makes it so i can have stuff like !make in a buffer where i can edit the output unlike in my term
-- since i am using editable term
-- probably in the future just copy the output and put it into scratch buffer and remove this bloatware....

local M = {}

function executeModifiedCommand()
  -- Get the current line (command)
  local cmd = vim.fn.getline(".")
  vim.fn.histadd(":", cmd)
  -- Exit insert mode and quit the command-line window
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("<Esc>:quit<CR>", true, false, true),
    "n", -- non-recursive
    false
  )

  -- Schedule command execution after window closes
  vim.schedule(function()
    if cmd:sub(1, 1) == "!" then
      -- If the previous buffer exists, wipe it
      if M.previous_buffer then
        vim.api.nvim_buf_delete(M.previous_buffer, { force = true }) -- Delete the previous buffer
      end

      -- Run the shell command and capture the output if it is ! command
      local output = vim.fn.system(cmd:sub(2))

      vim.cmd("enew")
      local buf = vim.api.nvim_get_current_buf()

      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, "\n"))
      vim.api.nvim_buf_set_name(0, "cmdout")
      vim.cmd("setlocal buftype=nofile") -- Treat the buffer as 'nofile'
      vim.cmd("setlocal filetype=projterm")
      -- set current buffer as previous buffer
      M.previous_buffer = buf
    else
      vim.cmd(cmd)
    end
  end)
end

vim.api.nvim_create_autocmd("CmdwinEnter", {
  pattern = ":",
  callback = function()
    -- Create a local mapping for the command window
    vim.keymap.set({ 'n', 'i', 'v' }, '<CR>',
      [[<cmd>lua executeModifiedCommand()<CR>]],
      { buffer = 0 })
  end
})

