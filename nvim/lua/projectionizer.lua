local function term_intercept_cr()
  local line = vim.api.nvim_get_current_line()

  -- THIS SPECIFICALLY BREAKS WITH NVIM IN PATH IF SPACES LIKE OSX LIKE .config nvim % in prompt lol
  local s, e = line:find("nvim%s[^%%]")

  if not s then
    vim.env.CLOSE_UNNEST = 0
  else
    vim.env.CLOSE_UNNEST = 1
  end

  return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
end

vim.keymap.set("t", "<CR>", term_intercept_cr, { expr = true, noremap = true })

if not vim.env.NVIM then
  return
end

local _, parent_chan = pcall(vim.fn.sockconnect, "pipe", vim.env.NVIM, { rpc = true })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.o.diff then
      local cmd_string = vim.v.argv[6]
      local full_cmd = "tabnew | " .. cmd_string
      vim.rpcrequest(parent_chan, "nvim_command", full_cmd)
    else
      vim.rpcrequest(parent_chan, "nvim_command", "tabnew " .. vim.api.nvim_buf_get_name(0))
    end

    vim.rpcrequest(parent_chan, "nvim_command", "tcd " .. vim.fn.getcwd())
    -- make sure the au group is gone always at this point
    vim.rpcrequest(parent_chan, "nvim_command", "augroup UnnestAutoClose | autocmd! | augroup END")

    local close = vim.rpcrequest(parent_chan, "nvim_eval", 'getenv("CLOSE_UNNEST")')
    if close == "1" then
      vim.cmd(":q!")
      return
    end
    -- now safely create a new autocmd for this child
    local tabpagenr = vim.rpcrequest(parent_chan, "nvim_call_function", "tabpagenr", {})
    local child_server = vim.v.servername

    local cmd = string.format([[
    augroup UnnestAutoClose
      autocmd TabClosed * ++once if expand("<afile>") == "%d"
        call rpcnotify(sockconnect('pipe', '%s', #{ rpc: v:true }), 'nvim_command', 'quitall!')
      endif
    augroup END
    ]], tabpagenr, child_server)

    vim.rpcrequest(parent_chan, "nvim_command", cmd)
  end
})
