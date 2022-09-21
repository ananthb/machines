-- COQ
local coq = require'coq'

-- LSP
local lsp = require'lspconfig'
lsp.gopls.setup{}
lsp.pyright.setup{}

-- GO
require'go'.setup()

