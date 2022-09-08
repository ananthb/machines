" --------
" VIM-PLUG
" --------

silent! if plug#begin()
  Plug 'sts10/vim-pink-moon'
  Plug 'airblade/vim-gitgutter'
  Plug 'vim-syntastic/syntastic'
  Plug 'scrooloose/nerdtree'
  Plug 'itchyny/lightline.vim'
  Plug 'tpope/vim-eunuch'
  Plug 'tpope/vim-surround'
  Plug 'jiangmiao/auto-pairs'
  Plug 'github/copilot.vim'
  Plug 'vijaymarupudi/nvim-fzf'

  " LANGUAGE PLUGINS
  Plug 'neovim/nvim-lspconfig'
  Plug 'python-mode/python-mode', { 'for': 'python' }
  Plug 'ElmCast/elm-vim', { 'for': 'elm' }
  Plug 'leafgarland/typescript-vim', { 'for': 'typescript' }
  Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries', 'for': 'go' }
  Plug 'neovimhaskell/haskell-vim', { 'for': 'haskell' }
  Plug 'martinda/Jenkinsfile-vim-syntax', { 'for': 'Jenkinsfile' }
  Plug 'ziglang/zig.vim', { 'for': 'zig' }

  call plug#end()
endif

" -----------
"  VIM CONFIG
" -----------
set tabstop=2 softtabstop=0 expandtab shiftwidth=2 smarttab

" ----
"  LSP
" ----
lua << EOF
require'lspconfig'.gopls.setup{}
EOF

" --------------------
" PLUGIN CONFIGURATION
" --------------------

" colorscheme
set background=dark
colorscheme pink-moon

" line numbering
set number

" NERDTREE
map <C-n> :NERDTreeToggle<CR>

" Syntastic
let g:syntastic_check_on_open=1
let g:syntastic_enable_signs=1

" Open NERDTree when vim is opened without any files or directories.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Automatically open NERDTree when vim starts up opening a directory.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif

" Close vim if only the NERDTree window is left open.
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use U to show documentation in preview window
nnoremap <silent> U :call <SID>show_documentation()<CR>

" vim-go
" disable vim-go :GoDef short cut (gd)
" this is handled by LanguageClient [LC]
let g:go_def_mapping_enabled = 0

