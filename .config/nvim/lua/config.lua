local data_dir = vim.fn.stdpath('data')


-- AUTO SESSION

require('auto-session').setup({
  auto_session_root_dir = data_dir..'/sessions/',
  auto_session_enabled = true,
  auto_save_enabled = true,
  auto_restore_enabled = true,
  auto_session_allowed_dirs = { "~/src/*" },
})


-- SESSION LENS
require('session-lens').setup {}


-- DASHBOARD

local db = require('dashboard')
local sysname = vim.loop.os_uname().sysname
if sysname == "Linux" then
  -- linux
  db.preview_command = 'ueberzug'
elseif sysname == "Darwin" then
  -- macos
  db.preview_command = 'cat | lolcat -F 0.3'
end

db.preview_file_path = data_dir..'/neovim.cat'
db.preview_file_height = 5
db.preview_file_width = 55
db.custom_center = {
  {
    icon = '  ',
    desc = 'Sessions                     ',
    action = 'Telescope session-lens search_session',
    shortcut = '<leader> fs',
  },
  {
    icon = '  ',
    desc = 'Live Grep                    ',
    action = 'Telescope live_grep',
    shortcut = '<leader> fg',
  },
  {
    icon = '  ',
    desc = 'Find Files                   ',
    action = 'Telescope find_files',
    shortcut = '<leader> ff',
  },
  {
    icon = '  ',
    desc = 'Help Tags                    ',
    action = 'Telescope help_tags',
    shortcut = '<leader> fh',
  },
  {
    icon = '  ',
    desc = 'Buffers                      ',
    action = 'Telescope buffers',
    shortcut = '<leader> fb',
  },
}


-- NVIM TREE

vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1
require'nvim-tree'.setup()


--NVIM TREESITTER

require'nvim-treesitter.configs'.setup {
  ensure_installed = {
    "c", "cpp", "css", "dockerfile", "elm", "fish", "go", "gomod",
    "haskell", "http", "javascript", "json", "lua", "make", "python",
    "toml", "typescript", "yaml", "zig"
  },
  auto_install = true,
}


-- COQ

local coq = require'coq'


-- LSP

local lsp = require'lspconfig'
lsp.gopls.setup{}
lsp.pyright.setup{}


-- GO

require'go'.setup()

