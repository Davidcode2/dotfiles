" vimwiki
let g:vimwiki_list = [{ 'path': '~/Documents/notes/',
			\ 'syntax':'markdown', 'ext': '.md',
			\ 'links_space_char': '_'}]

" vim-zettel
let g:zettel_options = [{"template" :  "~/.config/nvim/templates/zettelTemplate.tpl"}]
let g:zettel_format = "%y%m%d-%H%M-%title"

let g:markdown_fenced_languages = ['html', 'vim', 'python', 'css', 'typescript', 'javascript', 'c']
let g:vimwiki_global_ext = 0

