call plug#begin()
" The default plugin directory will be as follows:
" Neovim (Linux): stdpath('data') . '/plugged'

Plug 'nvim-lua/plenary.nvim'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'L3MON4D3/LuaSnip', {'tag': 'v1.*', 'do': 'make install_jsregexp'}
Plug 'rafamadriz/friendly-snippets'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.x' }
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }
Plug 'tpope/vim-surround'
Plug 'vimwiki/vimwiki'
Plug 'michal-h21/vim-zettel'
Plug 'puremourning/vimspector' 
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'ap/vim-css-color'
Plug '~/.config/nvim/screenshotPathPlugin/'
Plug 'lervag/vimtex'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" git
Plug 'itchyny/vim-gitbranch'
Plug 'tpope/vim-fugitive'

" lsp
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'onsails/lspkind-nvim'
Plug 'jose-elias-alvarez/null-ls.nvim'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
" :MasonUpdate updates registry contents
Plug 'williamboman/mason.nvim', { 'do': ':MasonUpdate' }
Plug 'williamboman/mason-lspconfig.nvim'

" themes 
Plug 'morhetz/gruvbox'
Plug 'franbach/miramare'
Plug 'KeitaNakamura/neodark.vim'
Plug 'embark-theme/vim', { 'as': 'embark', 'branch': 'main' }
Plug 'ayu-theme/ayu-vim'
Plug 'sainnhe/gruvbox-material'

" Initialize plugin system
call plug#end()
