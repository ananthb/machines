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

