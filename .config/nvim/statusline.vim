" set a single statusline
set laststatus=3
" create statusline
set statusline=
set statusline +=%4*\ %<%f%*                "full path
set statusline +=%2*%4m%*                   "modified flag
set statusline +=%5*%=%{gitbranch#name()}     "branch name
set statusline +=%1*%5n\ %*               "buffer number
set statusline +=%1*%5l%*                   "current line
set statusline +=%2*/%L%*                   "total lines
set statusline +=%1*%4v\ %*                 "virtual column number



