call plug#begin()
" The default plugin directory will be as follows:
" Neovim (Linux): stdpath('data') . '/plugged'

Plug 'neovim/nvim-lspconfig'

Plug 'vimwiki/vimwiki'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'michal-h21/vim-zettel'

Plug 'morhetz/gruvbox'

" Initialize plugin system
call plug#end()

set nocompatible
filetype plugin on
syntax on

" vimwiki
let g:vimwiki_list = [{ 'path': '~/OneDrive/notes/',
       \ 'syntax':'markdown', 'ext': '.md' }]

" vim-zettel
let g:zettel_options = [{"template" :  "~/.config/nvim/zettelTemplate.tpl"}]

let g:markdown_fenced_languages = ['html', 'vim', 'python', 'css', 'typescript', 'javascript', 'c']
let g:vimwiki_global_ext = 0

" netrw-gx
let g:netrw_browsex_viewer = "xdg-open"

" keymapping
" i is for input mode
" n is for normal mode 
" v is for visual mode
inoremap jh <Esc>
" inoremap ö ;
nnoremap ö :
vnoremap ö :
nnoremap <C-s> :Ag<cr>

" colorscheme
colorscheme gruvbox

set number
set colorcolumn=80

" enable nvim to work with language servers
lua << EOF
local nvim_lsp = require('lspconfig')
-- add additional language servers in here:
local servers = { 'clangd', 'pyright' }

-- adds keymaps
local on_attach = function(client, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local opts = { noremap=true, silent=true }

    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
    buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

-- Use LSP as the handler for omnifunc.
--    See `:help omnifunc` and `:help ins-completion` for more information.
vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

-- Use LSP as the handler for formatexpr.
--    See `:help formatexpr` for more information.
vim.api.nvim_buf_set_option(0, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
end

for _, lsp in ipairs(servers) do
	nvim_lsp[lsp].setup {
		on_attach = on_attach
	}
end

EOF
