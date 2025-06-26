call plug#begin()
" The default plugin directory will be as follows:
" Neovim (Linux): stdpath('data') . '/plugged'

Plug 'nvim-lua/plenary.nvim'
Plug 'saadparwaiz1/cmp_luasnip'
Plug 'L3MON4D3/LuaSnip', {'tag': 'v1.*', 'do': 'make install_jsregexp'}
Plug 'rafamadriz/friendly-snippets'
Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.x' }
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'tpope/vim-surround'
Plug 'vimwiki/vimwiki'
Plug 'michal-h21/vim-zettel'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'ap/vim-css-color'
Plug '~/.config/nvim/screenshotPathPlugin/'
Plug 'lervag/vimtex'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'alex-laycalvert/flashcards.nvim'

" debugging
"Plug 'puremourning/vimspector' 
Plug 'mxsdev/nvim-dap-vscode-js'
Plug 'mfussenegger/nvim-dap'
Plug 'nvim-neotest/nvim-nio'
Plug 'rcarriga/nvim-dap-ui'

" git
Plug 'itchyny/vim-gitbranch'
Plug 'tpope/vim-fugitive'

" lsp
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'onsails/lspkind-nvim'
Plug 'nvimtools/none-ls.nvim'
Plug 'nvimtools/none-ls-extras.nvim'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
" :MasonUpdate updates registry contents
Plug 'williamboman/mason.nvim', { 'do': ':MasonUpdate' }
Plug 'williamboman/mason-lspconfig.nvim'

" highlighting
Plug 'glench/vim-jinja2-syntax'

" themes 
Plug 'morhetz/gruvbox'
Plug 'franbach/miramare'
Plug 'KeitaNakamura/neodark.vim'
Plug 'embark-theme/vim', { 'as': 'embark', 'branch': 'main' }
Plug 'ayu-theme/ayu-vim'
Plug 'sainnhe/gruvbox-material'

" clojure
Plug 'Olical/conjure', { 'tag': 'v4.3.1' }

" python
Plug 'dccsillag/magma-nvim', { 'do': ':UpdateRemotePlugins' }

""""""""""""""""""""""
" avante.vim
""""""""""""""""""""""

" Deps
Plug 'stevearc/dressing.nvim'
Plug 'MunifTanjim/nui.nvim'
Plug 'MeanderingProgrammer/render-markdown.nvim'

" Optional deps
Plug 'nvim-tree/nvim-web-devicons'
Plug 'HakonHarnes/img-clip.nvim'
Plug 'zbirenbaum/copilot.lua'

" Yay, pass source=true if you want to build from source
" Plug 'yetone/avante.nvim', { 'branch': 'main', 'do': 'make' }

"""""""""""""""""""""""

" Initialize plugin system
call plug#end()
