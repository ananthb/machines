-- DASHBOARD
local home = os.getenv('HOME')
local db = require('dashboard')
local sysname = vim.loop.os_uname().sysname
if sysname == "Linux" then
  -- linux
  db.preview_command = 'ueberzug'
elseif sysname == "Darwin" then
  -- macos
  db.preview_command = 'cat | lolcat -F 0.3'
end

db.preview_file_path = home .. '/.local/share/nvim/neovim.cat'
db.preview_file_height = 11
db.preview_file_width = 70
db.custom_center = {
  {
    icon = '  ',
    desc = 'Recently latest session                 ',
    shortcut = 'SPC s l',
    action ='SessionLoad'
  },
  {
    icon = '  ',
    desc = 'Recently opened files                   ',
    action =  'DashboardFindHistory',
    shortcut = 'SPC f h'
  },
  {
    icon = '  ',
    desc = 'Find  File                              ',
    action = 'Telescope find_files find_command=rg,--hidden,--files',
    shortcut = 'SPC f f'
  },
  {
    icon = '  ',
    desc ='File Browser                            ',
    action =  'Telescope file_browser',
    shortcut = 'SPC f b'
  },
  {
    icon = '  ',
    desc = 'Find  word                              ',
    action = 'Telescope live_grep',
    shortcut = 'SPC f w'
  },
  {
    icon = '  ',
    desc = 'Open Personal dotfiles                  ',
    action = 'Telescope dotfiles path=' .. home ..'/.dotfiles',
    shortcut = 'SPC f d'
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

