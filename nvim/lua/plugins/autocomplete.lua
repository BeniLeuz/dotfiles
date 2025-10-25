require("blink.cmp").setup({
    keymap = {
      preset = 'enter',
      ['<Tab>'] = {
        function(cmp)
          if cmp.snippet_active() then
            return cmp.snippet_forward()
          else
            return cmp.select_next()
          end
        end,
        'fallback'
      },
    },
    completion = {
      menu = {
        draw = {
          columns = {
            { "label", "label_description", gap = 1 },
            { "kind" },
          },
        },
      },
      documentation = {
        auto_show = true,
      },
      list = {
        selection = {
          preselect = false
        }
      },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      providers = {
        cmdline = {
          -- ignores cmdline completions when executing shell commands
          enabled = function()
            return vim.fn.getcmdtype() ~= ':' or not vim.fn.getcmdline():match("^[%%0-9,'<>%-]*!")
          end
        },
        buffer = {
          enabled = function()
            local buftype = vim.bo.buftype

            if buftype == 'prompt' or buftype == 'nofile' then
              return false
            end

            return true
          end
        },
        snippets = {
          enabled = function()
            local buftype = vim.bo.buftype

            if buftype == 'prompt' or buftype == 'nofile' then
              return false
            end

            return true
          end,
          opts = {
            extended_filetypes = {
              svelte = { "html" },
              eruby = { "html" },
              html = { "javascript", "typescript" },
              javascript = { "html", "jsdoc" },
            },
            ignored_filetypes = {},
          },
        },
      }
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  }
)
