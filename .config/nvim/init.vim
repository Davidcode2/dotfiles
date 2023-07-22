set nocompatible
filetype plugin on
syntax on

source $HOME/.config/nvim/plugins.vim
source $HOME/.config/nvim/plenary.lua
source $HOME/.config/nvim/vimwiki.vim
source $HOME/.config/nvim/lsp.lua
source $HOME/.config/nvim/lsp-config.lua
source $HOME/.config/nvim/null-ls.lua
source $HOME/.config/nvim/vimspector.vim
source $HOME/.config/nvim/treesitter.lua
source $HOME/.config/nvim/statusline.vim
source $HOME/.config/nvim/keymaps.lua
source $HOME/.config/nvim/telescope.lua
source $HOME/.config/nvim/vimtex.vim
source $HOME/.config/nvim/copilot.lua
source $HOME/.config/nvim/snippets.lua
source $HOME/.config/nvim/snippets.vim
source $HOME/.config/nvim/mason.lua
source $HOME/.config/nvim/cmp.lua

" permanent undo
set undofile

" colorscheme
let g:gruvbox_contrast_dark='hard'
let ayucolor="dark"
let g:gruvbox_material_background='hard'
colorscheme gruvbox-material

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

" automatically change to notes dir when in notes
autocmd BufEnter * if expand("%:p:h") =~# '**/notes$' | lcd %:p:h | endif
" automatically change to current location when in courses folder
autocmd BufEnter * if expand("%:p:h:h") =~# '**/WS\d\d$\|**/SS\d\d$' | lcd %:p:h | endif

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

nmap <leader>< <Plug>VimwikiAddHeaderLevel

" colors 
hi User1 guifg=#eea390 guibg=#363834
hi User2 guifg=#ff86ff guibg=#363834
hi User3 guifg=#ff98ff guibg=#363834
hi User4 guifg=#a0ee67 guibg=#363834
hi User5 guifg=#eeee73 guibg=#363834
