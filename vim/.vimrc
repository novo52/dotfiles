call plug#begin()
Plug 'rust-lang/rust.vim'
call plug#end()

syntax enable
filetype plugin indent on

let g:rustfmt_autosave = 1

" esc in insert & visual mode
inoremap kj <esc>
vnoremap kj <esc>

" esc in command mode
cnoremap kj <C-C>

" dw in insert mode
inoremap sdf <C-w>
inoremap df <BS>

set timeoutlen=200
