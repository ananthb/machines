-- NVIM TREE
-- disable netrw
vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1
require'nvim-tree'.setup()

-- COQ
local coq = require'coq'

-- LSP
local lsp = require'lspconfig'
lsp.gopls.setup{}
lsp.pyright.setup{}

-- GO
require'go'.setup()

