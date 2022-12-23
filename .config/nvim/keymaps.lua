function Map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

vim.g.mapleader = " "

-- i is for input mode
-- n is for normal mode
-- v is for visual mode
-- c is for command mode
Map("i", "jh", "<Esc>")
-- inoremap ö ;
Map("n", "ö", ":")
Map("v", "ö", ":")
Map("n", "<C-s>", ":Ag<cr>")
Map("n", "<leader>g", ":GFiles<cr>")
Map("n", "<leader>f", ":Files<CR>")
Map("n", "<leader>gf", ":vsp <cfile><CR>")
Map("n", "<leader>gd", ":vsp <bar> call lsp#definition()<CR>")

Map("n", "<leader>so", ":source $HOME/.config/nvim/init.vim<CR>")
Map("c", "init", ":e $HOME/.config/nvim/init.vim<CR>")
Map("c", "keymaps", ":e /home/jakob/.config/nvim/keymaps.lua<CR>")

-- map change dir command
Map("n", "<leader>cd", ":lcd %:p:h<cr> :pwd<cr>")

-- movements
Map("n", "<C-h>", "<C-w>h")
Map("n", "<C-j>", "<C-w>j")
Map("n", "<C-k>", "<C-w>k")
Map("n", "<C-l>", "<C-w>l")
