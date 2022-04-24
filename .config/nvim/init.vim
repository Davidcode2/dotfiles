call plug#begin()
" The default plugin directory will be as follows:
" Neovim (Linux): stdpath('data') . '/plugged'

Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'L3MON4D3/LuaSnip'
Plug 'rafamadriz/friendly-snippets'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-surround'
Plug 'vimwiki/vimwiki'
Plug 'michal-h21/vim-zettel'
Plug 'puremourning/vimspector'
Plug 'morhetz/gruvbox'

" Initialize plugin system
call plug#end()

set nocompatible
filetype plugin on
syntax on

source $HOME/.config/nvim/vimwiki.vim
source $HOME/.config/nvim/lsp.lua
source $HOME/.config/nvim/vimspector.vim

" netrw-gx
" let g:netrw_browsex_viewer = "xdg-open"

" permanent undo
set undofile

" colorscheme
set termguicolors
let g:gruvbox_contrast_dark='hard'
colorscheme gruvbox

" show line numbers
set number
" set relative line numbers
autocmd BufEnter * set relativenumber
autocmd BufLeave * set norelativenumber
" show line at width
set colorcolumn=80

" automatically change to notes dir when in notes
autocmd BufEnter * if expand("%:p:h") =~# '**/notes$' | lcd %:p:h | endif

" automatically change to current location when in courses folder
autocmd BufEnter * if expand("%:p:h:h") =~# '**/WS\d\d$\|**/SS\d\d$' | lcd %:p:h | endif

" map ß to put <br> and then enter if in vimwiki file
autocmd Filetype vimwiki inoremap <buffer> ß <br><cr>

" keymapping
" i is for input mode
" n is for normal mode 
" v is for visual mode
inoremap jh <Esc>
" inoremap ö ;
nnoremap ö :
vnoremap ö :
nnoremap <C-s> :Ag<cr>
nnoremap <C-h> :Files ~/<cr>
" vnoremap < <gv
" vnoremap > >gv

" map change dir command
nnoremap <leader>cd :lcd %:p:h<cr> :pwd<cr>

" delete buffer while retaining the split pane
command Bd bp\|bd \#

highlight CursorLineNr guibg=#1d2021
set cursorline
set cursorlineopt=number

autocmd Filetype css setlocal tabstop=2
set tabstop=2
set shiftwidth=2

let g:LanguageClient_serverCommands = {
			\ 'sql': ['sql-language-server', 'up', '--method', 'stdio'],
			\ }
