local colors = {
  type = "#ff9e64",      -- for @type
  variable = "#73daca",  -- for @variable
  function_ = "#729FCF", -- for @function
  keyword = "#FFCF70",   -- for @keyword
  string = "#B2DC7E",    -- for @string
  comment = "#5C6370",   -- for @comment
}


local type_groups = {
  "Type", "@type", "@type.builtin", "@type.definition",
  "@type.qualifier", "@namespace"
}

local var_groups = {
  "@variable", "@variable.builtin", "@variable.local",
  "@parameter", "@property", "@field", "@identifier"
}

for _, group in ipairs(type_groups) do
  vim.api.nvim_set_hl(0, group, { fg = colors.type })
end

for _, group in ipairs(var_groups) do
  vim.api.nvim_set_hl(0, group, { fg = colors.variable })
end

-- html tag
vim.api.nvim_set_hl(0, "@tag.html", { fg = colors.function_ })
-- because java is sus
vim.api.nvim_set_hl(0, "@lsp.type.modifier.java", { fg = colors.keyword })

-- words like struct, class local function etc
vim.api.nvim_set_hl(0, "Keyword", { fg = colors.keyword })
vim.api.nvim_set_hl(0, "Function", { fg = colors.function_ })
vim.api.nvim_set_hl(0, "String", { fg = colors.string })

-- make it all black lmao
vim.api.nvim_set_hl(0, "Normal", { bg = "#000000" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "#000000" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#000000" })
vim.api.nvim_set_hl(0, "Pmenu", { bg = "#000000" })

-- make dirs the same color as debian dirs
-- printf "\033]4;12;?\033\\"
vim.api.nvim_set_hl(0, "Directory", { fg = "#6871ff" })

-- tabline
-- vim.api.nvim_set_hl(0, "TabLine", { bg = "#1a1a1a", fg = "#666666" })      -- inactive: dark gray
-- vim.api.nvim_set_hl(0, "TabLineSel", { bg = "#ffffff", fg = "#000000", bold = true })  -- active: white bg, black text
-- vim.api.nvim_set_hl(0, "TabLineFill", { bg = "#000000" })

vim.api.nvim_set_hl(0, "TabLine", { bg = "#000000", fg = "#ffffff" })
vim.api.nvim_set_hl(0, "TabLineSel", { bg = "#ffffff", fg = "#000000", bold = true })
vim.api.nvim_set_hl(0, "TabLineFill", { bg = "#000000" })


-- statusline (works because i set highlight groups in vimopts)
vim.api.nvim_set_hl(0, "StatusLine", { fg = "#ffffff", bg = "#000000" })       -- white text on black
vim.api.nvim_set_hl(0, "StatusLineNC", { fg = "#ffffff", bg = "#000000" })       -- when inactive so quikcfix
vim.api.nvim_set_hl(0, "StatusModified", { fg = "#ffffff", bg = "#000000" })   -- orange on black
vim.api.nvim_set_hl(0, "StatusRO", { fg = "#ffffff", bg = "#000000" })   -- orange on black

function _G.custom_tabline()
  local s = ""
  for i = 1, vim.fn.tabpagenr("$") do
    if i == vim.fn.tabpagenr() then
      s = s .. "%#TabLineSel#"
    else
      s = s .. "%#TabLine#"
    end
    local cwd = vim.fn.getcwd(-1, i)
    cwd = vim.fn.fnamemodify(cwd, ":t")
    s = s .. " " .. cwd .. " "
  end

  -- Fill empty space and reset tab target
  s = s .. "%#TabLineFill#"
  return s
end

-- some fugitive styling
vim.api.nvim_set_hl(0, "DiffDelete", {
  bg = "#330000",
})

vim.api.nvim_set_hl(0, "diffRemoved", { link = "DiffDelete" })
vim.o.tabline = "%!v:lua.custom_tabline()"
vim.api.nvim_set_hl(0, "diffAdded", { link = "DiffAdd"})
