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

" del
"inoremap <S-BS> <Del>

set tabstop=4
set softtabstop=4
set shiftwidth=4

" relative line numbers
set number relativenumber
set cursorline
set cursorlineopt=number 
highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE
highlight CursorLineNr term=bold cterm=NONE ctermfg=Gray ctermbg=NONE gui=NONE guifg=Grey guibg=NONE

set timeoutlen=200

" Have Vim jump to the last position when reopening a file
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"zz" | endif
endi
