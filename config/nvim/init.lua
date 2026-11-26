local diary = require("config.diary")
local diary_group = vim.api.nvim_create_augroup("diary_template", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
  group = diary_group,
  callback = function(args)
    if diary.is_diary_file(args.buf) then
      diary.setup_buffer(args.buf)
      if args.event == "BufNewFile" then
        diary.insert_header(args.buf)
      end
    end
  end,
})

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
