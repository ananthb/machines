-- Lazy
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	BOOTSTRAP = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
if BOOTSTRAP then
	-- Stop loading config on bootstrap
	return
end
vim.opt.rtp:prepend(lazypath)

-- HOST PYTHON VENV
local python_venv = vim.fn.stdpath("data") .. "/pyvenv"
if vim.fn.empty(vim.fn.glob(python_venv .. "/bin/python")) > 0 then
	vim.fn.system({ "python3", "-m", "venv", python_venv })
	vim.fn.system({ python_venv .. "/bin/pip", "install", "-qU", "pynvim" })
end

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required
--  (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("lazy").setup("plugins")

-- CONFIG
vim.cmd([[colorscheme codedark]])

vim.g.loaded_netrwPlugin = 1
vim.g.python3_host_prog = vim.fn.stdpath("data") .. "/pyvenv/bin/python"
vim.g.poetv_auto_activate = 1
vim.cmd([[
  let g:poetv_executables = ['poetry']
]])
vim.o.termguicolors = true
vim.o.updatetime = 250
vim.o.hlsearch = false
vim.o.mouse = "a"
vim.o.number = true
vim.o.relativenumber = true
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.completeopt = "menuone,noselect"

-- KEYMAPS
-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- YANK HIGHLIGHT
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

-- DIAGNOSTIC KEYMAPS
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)
