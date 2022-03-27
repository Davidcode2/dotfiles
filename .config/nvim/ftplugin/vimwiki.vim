
" inkscape-figures
"autocmd Filetype vimwiki inoremap <buffer> <C-f> <Esc>: silent exec '.!inkscape-figures create "'.getline('.').'" "'.'figures/"'<CR><CR>:w<CR>
"autocmd Filetype vimwiki inoremap <buffer> <C-f> <Esc>: silent exec '.!inkscape-figures create "'.getline('.').'" "'.'figures/"'<CR><CR>:w<CR>
nnoremap <buffer> <C-f> : silent exec '!inkscape-figures edit "'.'figures/" > /dev/null 2>&1 &'<CR><CR>:redraw!<CR>
inoremap <buffer> <C-f> <Esc>: silent exec '.!inkscape-figures create "'.getline('.').'" "'.'figures/"'<CR><CR>:w<CR>

