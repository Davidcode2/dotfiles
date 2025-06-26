local dap = require('dap')

-- Set up dap-ui
require("dapui").setup()

-- python adapter
dap.adapters.python = {
  type = 'executable',
  command = os.getenv('HOME') .. '/.virtualenvs/tools/bin/python',
  args = { '-m', 'debugpy.adapter' },
}

-- pwa node adapter
dap.adapters['pwa-node'] = {
  type = 'server',
  host = 'localhost',
  port = '${port}',
  executable = {
    command = 'node',
    args = {
      "/home/jakob/.local/share/nvim/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
      "${port}"
    },
  },
}

local js_based_languages = {
  "typescript",
  "javascript",
  "typescriptreact",
  "javascriptreact",
  "vue",
}

-- set up configurations for js based languages
for _, language in ipairs(js_based_languages) do
  dap.configurations[language] = {
    -- Debug single nodejs files
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch file",
      program = "${file}",
      cwd = vim.fn.getcwd(),
      sourceMaps = true,
    },
    -- Debug nodejs processes (make sure to add --inspect when you run the process)
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach",
      processId = require("dap.utils").pick_process,
      cwd = vim.fn.getcwd(),
      sourceMaps = true,
    },
    -- Debug jest tests
    {
      type = "pwa-node",
      request = "launch",
      name = "Debug Jest Tests",
      -- trace = true, -- include debugger info
      runtimeExecutable = "node",
      runtimeArgs = {
        "./node_modules/jest/bin/jest.js",
        "--runInBand",
        function()
          local co = coroutine.running()
          return coroutine.create(function()
            vim.ui.input({
              prompt = "Enter Runtime args: ",
              default = "",
            }, function(url)
              if url == nil or url == "" then
                return
              else
                coroutine.resume(co, url)
              end
            end)
          end)
        end,
      },
      rootPath = "${workspaceFolder}",
      cwd = "${workspaceFolder}",
      console = "integratedTerminal",
      internalConsoleOptions = "neverOpen",
    },
    -- Debug web applications (client side)
    {
      type = "pwa-chrome",
      request = "launch",
      name = "Launch & Debug Chrome",
      url = function()
        local co = coroutine.running()
        return coroutine.create(function()
          vim.ui.input({
            prompt = "Enter URL: ",
            default = "http://localhost:3000",
          }, function(url)
            if url == nil or url == "" then
              return
            else
              coroutine.resume(co, url)
            end
          end)
        end)
      end,
      webRoot = vim.fn.getcwd(),
      protocol = "inspector",
      sourceMaps = true,
      userDataDir = false,
    },
    -- Divider for the launch.json derived configs
    {
      name = "----- ↓ launch.json configs ↓ -----",
      type = "",
      request = "launch",
    },
  }
end

-- commented out due to https://github.com/mxsdev/nvim-dap-vscode-js/issues/58#issuecomment-2582575821
-- setup dap-vscode-js for debugging nodejs and web applications
-- require("dap-vscode-js").setup({
--   debugger_path = "/home/jakob/vscode-js-debug",
--   adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
-- })
