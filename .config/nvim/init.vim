" KEYMAPS

nnoremap <C-n> :NvimTreeToggle<CR>

" PLUGINS

silent! if plug#begin()
  Plug 'tomasiser/vim-code-dark'
  Plug 'glepnir/dashboard-nvim'
  Plug 'kyazdani42/nvim-web-devicons'
  Plug 'kyazdani42/nvim-tree.lua'
  Plug 'ms-jpq/coq_nvim', {'branch': 'coq'}
  Plug 'ms-jpq/coq.artifacts', {'branch': 'artifacts'}
  Plug 'neovim/nvim-lspconfig'
  Plug 'LoricAndre/OneTerm.nvim'
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'nvim-treesitter/nvim-treesitter-textobjects'
  Plug 'kylechui/nvim-surround'
  Plug 'gennaro-tedesco/nvim-peekup'
  Plug 'chentoast/marks.nvim'
  Plug 'nvim-lua/popup.nvim'
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-telescope/telescope.nvim'
  Plug 'jvgrootveld/telescope-zoxide'
  Plug 'f-person/git-blame.nvim'
  Plug 'beauwilliams/statusline.lua'
  Plug 'ellisonleao/glow.nvim'
  Plug 'petobens/poet-v'

  " languages
  Plug 'ray-x/go.nvim', {'for': 'go'}
  Plug 'ray-x/guihua.lua'

  call plug#end()
endif


" CONFIG

let g:python3_host_prog = "$HOME/.local/share/nvim/pyvenv/bin/python"
let g:poetv_auto_activate = 1
let g:coq_settings = { 'auto_start': 'shut-up' }

colorscheme codedark
set background=dark
set tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab
set number
set relativenumber
set autochdir
set clipboard=unnamedplus


" LUA

lua require'config'

