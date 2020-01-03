" --------
" VIM-PLUG
" --------

silent! if plug#begin()

  Plug 'airblade/vim-gitgutter'
  Plug 'vim-syntastic/syntastic'
  Plug 'scrooloose/nerdtree'
  Plug 'itchyny/lightline.vim'
  Plug 'tpope/vim-eunuch'
  Plug 'tpope/vim-surround'
  Plug 'editorconfig/editorconfig-vim'
  Plug 'airblade/vim-gitgutter'
  Plug 'dense-analysis/ale'
  Plug 'jiangmiao/auto-pairs'

  " LANGUAGE PLUGINS
  Plug 'python-mode/python-mode', { 'for': 'python' }
  Plug 'ElmCast/elm-vim', { 'for': 'elm' }
  Plug 'leafgarland/typescript-vim', { 'for': 'typescript' }

  call plug#end()
endif


" --------------------
" PLUGIN CONFIGURATION
" --------------------

" NERDTREE
map <C-n> :NERDTreeToggle<CR>

" Open NERDTree when vim is opened without any files or directories.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Automatically open NERDTree when vim starts up opening a directory.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif

" Close vim if only the NERDTree window is left open.
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" ALE
let g:ale_completion_enabled = 1


" -----------
"  VIM CONFIG
" -----------
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab
