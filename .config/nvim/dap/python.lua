local dap = require('dap')

-- python adapter
dap.adapters.python = {
  type = 'executable',
  command = os.getenv('HOME') .. '/.virtualenvs/tools/bin/python',
  args = { '-m', 'debugpy.adapter' },
}
