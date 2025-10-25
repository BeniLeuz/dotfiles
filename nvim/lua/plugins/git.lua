-- workflow if i use this
-- leader gs open window
-- literal = = togglin the inline diff
-- i = jump through hunks and auto open top down
-- s = stage
-- u = unstage
-- dv = diffview for a inline change etc
-- I = interactive hunk by hunk adding removing etc
-- cc = commit
-- X = delete change
-- in a gvdiffspit i can use
-- do = diffobtain other side into mine
-- dp = diff put mine into other so like unchange stuff
-- ]q[q = jump quickfix
-- [c]c = jump hunks in same file

-- overview
vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
-- diff unstaged against working dir
-- vim.keymap.set("n", "<leader>da", ":Git difftool -y<CR>")
-- diff staged against head
-- vim.keymap.set("n", "<leader>dh", ":Git difftool -y HEAD<CR>")
-- diff all against upstream in TABS
-- vim.keymap.set('n', '<leader>du', ':Git difftool -y @{upstream}<CR>')


-- if i EVER have issues with this implementation that are annoying just do this:
-- i could also use opptionnset callback or sumn to only set this on diff buffers (pattern = diff)
-- this would make it so i could take something riskier like dv
-- IF I EVER HAVE ISSUES WITH THIS, DO THIS PLS THIS IMPLEMENTATION IS DISGUSTING
-- vim.keymap.set("n", "dv", ":Gvdiffsplit<CR>")
-- vim.keymap.set('n', '<leader>du', ":Git difftool @{upstream}<CR>")

local function is_difftool_qf()
  local qf_list = vim.fn.getqflist({ title = 0 })
  return qf_list.title and string.match(qf_list.title, 'tool') ~= nil
end

local function open_qf_diff()
  vim.cmd('.cc')
  local qf_list = vim.fn.getqflist({ title = 0 })
  if string.match(qf_list.title, 'mergetool') ~= nil then
    vim.cmd('Gvdiffsplit!')
  else
    vim.cmd('Gvdiffsplit @{upstream}')
  end
  local height = math.floor(vim.o.lines / 3)
  vim.cmd('copen ' .. height)
  vim.cmd('wincmd k')
  vim.cmd('wincmd l')
end

-- diff with a double view and quickfix
vim.keymap.set('n', '<leader>du', function()
  vim.cmd('Git difftool @{upstream}')
  pcall(function()
    open_qf_diff()
  end)
end)


-- just so we dont reset on subsequent autocmds
local qf_mapping_set = false

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function(args)
    -- vim.o.statusline = "%#StatusLine#%F %#StatusModified#%m %#StatusRO#%r"
    if qf_mapping_set then return end
    qf_mapping_set = true

    vim.keymap.set('n', '<CR>', function()
      if not is_difftool_qf() then
        vim.cmd('.cc')
        return
      end

      pcall(function()
        vim.cmd('windo if &filetype != "qf" | execute "close" | endif')
        open_qf_diff()
      end)
    end, { buffer = args.buf })
  end
})

vim.keymap.set('n', '[q', function()
  if is_difftool_qf() then
    local _, _ = pcall(function()
      vim.cmd('cprevious')
      vim.cmd('windo if &filetype != "qf" | execute "close" | endif')
      open_qf_diff()
    end)
  else
    pcall(vim.cmd, 'cprevious')
  end
end)

vim.keymap.set('n', ']q', function()
  if is_difftool_qf() then
    local ok, err = pcall(function()
      vim.cmd('cnext')
      vim.cmd('windo if &filetype != "qf" | execute "close" | endif')
      open_qf_diff()
    end)
  else
    pcall(vim.cmd, 'cnext')
  end
end)
