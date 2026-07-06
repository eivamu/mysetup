" Colors
if has('termguicolors')
  set termguicolors
endif
set background=dark
colorscheme tokyonight
syntax on
filetype plugin indent on

" UI
set number
set cursorline
set showmatch
set ruler
set showcmd
set laststatus=2
set wildmenu
set wildmode=longest:full,full
set scrolloff=5
set sidescrolloff=5
set linebreak
set splitbelow
set splitright

" Input
set mouse=a
set backspace=indent,eol,start
set ttimeoutlen=50
if has('clipboard')
  set clipboard=unnamedplus
endif

" Search
set incsearch
set hlsearch
set ignorecase
set smartcase
" Ctrl-L: clear search highlight, then redraw as usual
nnoremap <silent> <C-l> :nohlsearch<CR><C-l>

" Indentation
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent

" Files & buffers
set hidden
set autoread
set history=1000

" Persistent undo + keep swap/backup out of working dirs
if !isdirectory($HOME . '/.cache/vim/undo')
  call mkdir($HOME . '/.cache/vim/undo', 'p', 0700)
endif
set undofile
set undodir=~/.cache/vim/undo//
set directory=~/.cache/vim//
set nobackup

" Quiet
set noerrorbells
set visualbell
set t_vb=

" Extended % matching (if/endif, HTML tags, ...)
packadd! matchit
