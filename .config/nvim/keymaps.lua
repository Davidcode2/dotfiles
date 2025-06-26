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
Map("n", "ö", ":", { silent = false })
Map("v", "ö", ":", { silent = false })
Map("n", "<C-s>", ":Ag<cr>")
-- Map("n", "<leader>guf", ":GFiles<cr>")
-- Map("n", "<leader>f", ":Files<CR>")
Map("n", "<leader>gd", ":only <bar> vsplit<CR>:normal gd<CR>", { noremap=true, silent=true, buffer=bufnr })
Map("n", "<leader>gf", ":only <bar> vsplit<CR>:normal gf<CR>", { noremap=true, silent=true, buffer=bufnr })

Map("n", "<leader>so", ":source $HOME/.config/nvim/init.vim<CR>", {silent = false})
Map("c", "_init", ":e $HOME/.config/nvim/init.vim<CR>", {silent = false})
Map("c", "_keymaps", ":e /home/jakob/.config/nvim/keymaps.lua<CR>", {silent = false})

-- map change dir command
Map("n", "<leader>cd", ":lcd %:p:h<cr> :pwd<cr>")

-- movements
Map("n", "<C-h>", "<C-w>h")
Map("n", "<C-j>", "<C-w>j")
Map("n", "<C-k>", "<C-w>k")
Map("n", "<C-l>", "<C-w>l")

-- python jupyter
Map("n", "<leader>r", ":MagmaEvaluateOperator<CR>")
Map("n", "<LocalLeader>rr", ":MagmaEvaluateLine<CR>")
Map("x", "<LocalLeader>r ", ":<C-u>MagmaEvaluateVisual<CR>")
Map("n", "<LocalLeader>rc", ":MagmaReevaluateCell<CR>")
Map("n", "<LocalLeader>rd", ":MagmaDelete<CR>")
Map("n", "<LocalLeader>ro", ":MagmaShowOutput<CR>")

-- plantuml
Map("n", "<leader>pu", ":! java -jar ~/.plantuml/plantuml.jar %<CR><CR>")
Map("n", "<leader>ps", ":! java -jar ~/.plantuml/plantuml.jar %<CR><CR> :silent !xdg-open %:r.png &<CR>")

-- dap
local dap = require('dap')
Map('n', '<F5>', dap.continue, { desc = 'Debug: Continue' })
Map('n', '<F10>', dap.step_over, { desc = 'Debug: Step Over' })
Map('n', '<F11>', dap.step_into, { desc = 'Debug: Step Into' })
Map('n', '<F12>', dap.step_out, { desc = 'Debug: Step Out' })
Map('n', '<Leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
Map('n', '<Leader>B', function() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end,
  { desc = 'Debug: Set Conditional Breakpoint' })
Map('n', '<Leader>lp', function() dap.set_breakpoint(nil, nil, vim.fn.input 'Log point message: ') end,
  { desc = 'Debug: Set Log Point' })
Map('n', '<Leader>dr', dap.repl.open, { desc = 'Debug: Open REPL' })
Map('n', '<Leader>dl', dap.run_last, { desc = 'Debug: Run Last Configuration' })
Map('n', '<Leader>dt', dap.terminate, { desc = 'Debug: Terminate Session' })
Map('n', '<Leader>da', dap.attach, { desc = 'Debug: Attach to Process' })

-- dap-ui
local dap_ui = require("dapui")
Map('n', '<Leader>do', dap_ui.open, { desc = 'Open Dap UI' })
Map('n', '<Leader>dc', dap_ui.close, { desc = 'Close Dap UI' })
Map('n', '<Leader>dT', dap_ui.toggle, { desc = 'Toggle Dap UI' })
