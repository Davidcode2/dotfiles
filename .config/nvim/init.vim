call plug#begin()
" The default plugin directory will be as follows:
" Neovim (Linux): stdpath('data') . '/plugged'

Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'onsails/lspkind-nvim'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'L3MON4D3/LuaSnip'
Plug 'rafamadriz/friendly-snippets'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-fugitive'
Plug 'vimwiki/vimwiki'
Plug 'michal-h21/vim-zettel'
Plug 'puremourning/vimspector', { 'on': 'VimspectorReset' }
Plug 'morhetz/gruvbox'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'ap/vim-css-color'
Plug '~/.config/nvim/screenshotPathPlugin/'

" Initialize plugin system
call plug#end()

set nocompatible
filetype plugin on
syntax on

source $HOME/.config/nvim/vimwiki.vim
source $HOME/.config/nvim/lsp.lua
source $HOME/.config/nvim/sumneko_lua.lua
source $HOME/.config/nvim/lsp-config.lua
source $HOME/.config/nvim/vimspector.vim
source $HOME/.config/nvim/treesitter.lua

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
" set colorcolumn=80
" put a mark where a line extends over 80 characters
highlight ColorColumn ctermbg=lightgrey
call matchadd('ColorColumn', '\%81v', 100)

" set a single statusline
set laststatus=3

" automatically change to notes dir when in notes
autocmd BufEnter * if expand("%:p:h") =~# '**/notes$' | lcd %:p:h | endif
" automatically change to current location when in courses folder
autocmd BufEnter * if expand("%:p:h:h") =~# '**/WS\d\d$\|**/SS\d\d$' | lcd %:p:h | endif

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

" search across current directory and open quickfix window with results 
" taken from here:
" https://stackoverflow.com/questions/2190844/how-to-search-across-a-directory-of-files-in-vim
funct! GallFunction(re)
  cexpr []
  execute 'silent! noautocmd bufdo vimgrepadd /' . a:re . '/j %'
  cw  
endfunct
command! -nargs=1 Gall call GallFunction(<q-args>)

" delete buffer while retaining the split pane
command Bd bp\|bd \#

" cursorline optics
highlight CursorLineNr guibg=#1d2021
set cursorline
set cursorlineopt=number

" tabwidth
autocmd Filetype css setlocal tabstop=2
set tabstop=2
set shiftwidth=2
" turn tabs to spaces
set expandtab
