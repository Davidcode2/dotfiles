-- Set up dap-ui
require("dapui").setup()

-- Import DAP adapter/configs
loadfile(vim.fn.stdpath('config') .. '/dap/cpp.lua')()
loadfile(vim.fn.stdpath('config') .. '/dap/python.lua')()
loadfile(vim.fn.stdpath('config') .. '/dap/js.lua')()

-- commented out due to https://github.com/mxsdev/nvim-dap-vscode-js/issues/58#issuecomment-2582575821
-- setup dap-vscode-js for debugging nodejs and web applications
-- require("dap-vscode-js").setup({
--   debugger_path = "/home/jakob/vscode-js-debug",
--   adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
-- })

