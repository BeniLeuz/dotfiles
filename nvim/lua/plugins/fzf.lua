local fzfbin = vim.fn.stdpath("data") .. "/site/pack/core/opt/fzf/bin/fzf"

if vim.fn.filereadable(fzfbin) == 0 then
	vim.schedule(function()
		vim.notify("Installing fzf binary…", vim.log.levels.INFO)
		vim.cmd("silent! call fzf#install()")
	end)
end

require("fzf-lua").setup({
	keymap = {
		builtin = {
			["<tab>"] = "toggle-preview",
			["<C-d>"] = "preview-page-down",
			["<C-u>"] = "preview-page-up",
		},
		fzf = {
			["ctrl-q"] = "select-all+accept",
		},
	},
	winopts = {
		preview = {
			backend = "builtin",
			hidden = "hidden",
		},
	},
})

-- make sure harpoon bindings dont trigger here...
vim.api.nvim_create_autocmd("FileType", {
	pattern = "fzf",
	callback = function(args)
		vim.keymap.set("t", "<C-h>", "<C-h>", { buffer = args.buf })
		vim.keymap.set("t", "<C-j>", "<C-j>", { buffer = args.buf })
		vim.keymap.set("t", "<C-k>", "<C-k>", { buffer = args.buf })
		vim.keymap.set("t", "<C-l>", "<C-l>", { buffer = args.buf })
		vim.keymap.set("t", "<C-f>", "<C-f>", { buffer = args.buf })
		vim.keymap.set("t", "<C-g>", "<C-g>", { buffer = args.buf })
		vim.keymap.set("t", "<C-e>", "<C-e>", { buffer = args.buf })
	end,
})

vim.keymap.set("n", "<leader>sf", FzfLua.files, { desc = "[S]earch [F]iles" })

-- keep the grep search completely normal... without regex default atleast!
vim.keymap.set("n", "<leader>sg", function()
	local rg_opts = require("fzf-lua.config").globals.grep.rg_opts
	FzfLua.live_grep_native({
		rg_opts = "--fixed-strings " .. rg_opts,
	})
end, { desc = "[S]earch by [G]rep (literal)" })

-- this has regex support!
vim.keymap.set("n", "<leader>sG", FzfLua.live_grep_native, { desc = "[S]earch by [G]rep (regex)" })

-- caching the manuals so we can keep the search of man pages fast. this happens async
local man_cache

local function build_man_cache()
	man_cache = {}
	vim.system({ "man", "-k", "." }, { text = true }, function(obj)
		if obj.code ~= 0 then
			return
		end

		man_cache = vim.split(obj.stdout, "\n", { trimempty = true })
	end)
end

build_man_cache()

local function cached_man_picker()
	if vim.tbl_isempty(man_cache) then
		vim.notify("man cache not ready yet", vim.log.levels.INFO)
		return
	end

	FzfLua.fzf_exec(man_cache, {
		prompt = "Man> ",
		previewer = "man",
		fn_transform = function(x)
			local man, desc = x:match("^(.-) %- (.*)$")
			return string.format("%-45s %s", man or x, desc or "")
		end,
		actions = {
			["enter"] = require("fzf-lua.actions").man,
		},
	})
end

-- search through man pages, especially nice when using c
vim.keymap.set("n", "<leader>sm", cached_man_picker, { desc = "search man pages" })
-- search the help files
vim.keymap.set("n", "<leader>sh", FzfLua.helptags, { desc = "search help tags" })

local function cycle_man_section(direction)
	local name = vim.api.nvim_buf_get_name(0):match("^man://([^()]+)%(")
	local current = vim.b.man_sect and vim.b.man_sect:lower()
	if not name or not current then
		return
	end

	local seen, sections = {}, {}
	for _, line in ipairs(man_cache) do
		local page, sect = line:match("^([^, (]+)[^(]*%(([^), ]*)")
		sect = sect and sect:lower()
		if page == name and sect and not seen[sect] then
			seen[sect] = true
			table.insert(sections, sect)
		end
	end

	table.sort(sections)

	local i = vim.fn.index(sections, current)
	if i < 0 or #sections < 2 then
		return
	end

	vim.cmd(("Man %s %s"):format(sections[(i + direction) % #sections + 1], name))
end

-- jump sections up and down when sadly at wrong section posix/cstdlib
vim.api.nvim_create_autocmd("FileType", {
	pattern = "man",
	callback = function(args)
		vim.keymap.set("n", "]s", function()
			cycle_man_section(1)
		end, { buffer = args.buf })

		vim.keymap.set("n", "[s", function()
			cycle_man_section(-1)
		end, { buffer = args.buf })
	end,
})
