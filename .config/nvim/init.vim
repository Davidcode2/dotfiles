call plug#begin()
" The default plugin directory will be as follows:
" Neovim (Linux): stdpath('data') . '/plugged'

Plug 'neovim/nvim-lspconfig'
Plug 'vimwiki/vimwiki'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'michal-h21/vim-zettel'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'L3MON4D3/LuaSnip'
Plug 'rafamadriz/friendly-snippets'
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

" inkscape-figures
inoremap <C-f> <Esc>: silent exec '.!inkscape-figures create "'.getline('.').'" "'.'figures/"'<CR><CR>:w<CR>
nnoremap <C-f> : silent exec '!inkscape-figures edit "'.'figures/" > /dev/null 2>&1 &'<CR><CR>:redraw!<CR>

" netrw-gx
" let g:netrw_browsex_viewer = "xdg-open"

" automatically change to notes dir when in notes
autocmd BufEnter * if expand("%:p:h") =~# '**/notes$' | lcd %:p:h | endif

" automatically change to current location when in courses folder
autocmd BufEnter * if expand("%:p:h:h") =~# '**/WS\d\d$\|**/SS\d\d$' | lcd %:p:h | endif

" map ß to put <br> and then enter if in vimwiki file
autocmd Filetype vimwiki inoremap <buffer> ß <br><cr>

" map change dir command
nnoremap <leader>cd :lcd %:p:h<cr> :pwd<cr>

" keymapping
" i is for input mode
" n is for normal mode 
" v is for visual mode
inoremap jh <Esc>
" inoremap ö ;
nnoremap ö :
vnoremap ö :
nnoremap <C-s> :Ag<cr>

command Bd bp\|bd \#

" surround
inoremap " ""<left>
inoremap ' ''<left>
inoremap ( ()<left>
inoremap [ []<left>
inoremap { {}<left>
inoremap {<CR> {<CR>}<ESC>O
inoremap {;<CR> {<CR>};<ESC>O 

" when typing closing bracket do not write again if it's already there.
inoremap <expr> ) strpart(getline('.'), col('.')-1, 1) == ")" ? "\<Right>" : ")"
inoremap <expr> } strpart(getline('.'), col('.')-1, 1) == "}" ? "\<Right>" : "}"
inoremap <expr> ] strpart(getline('.'), col('.')-1, 1) == "]" ? "\<Right>" : "]"

" colorscheme
colorscheme gruvbox

" show line numbers
set number
" show line at width
set colorcolumn=80

autocmd Filetype css setlocal tabstop=2
set tabstop=2
set shiftwidth=2

let g:LanguageClient_serverCommands = {
			\ 'sql': ['sql-language-server', 'up', '--method', 'stdio'],
			\ }
