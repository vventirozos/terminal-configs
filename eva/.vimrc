" ~/.vimrc
set nocompatible
syntax on                          " colours
filetype plugin indent on
set background=dark
set backspace=indent,eol,start     " Backspace deletes anything
set autoindent
set incsearch hlsearch             " search as you type, highlight matches
set ignorecase smartcase           " case-insensitive unless the pattern has capitals
set ruler showcmd wildmenu
set ttimeoutlen=10                 " no lag after Esc
set scrolloff=3

map f w
