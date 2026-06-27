-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local diary = require("config.diary")

local diary_group = vim.api.nvim_create_augroup("personal_diary", { clear = true })

vim.api.nvim_create_autocmd("BufNewFile", {
  group = diary_group,
  callback = function(args)
    if not diary.is_diary_file(args.buf) then
      return
    end

    diary.insert_header(args.buf)
    diary.setup_buffer(args.buf)
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = diary_group,
  callback = function(args)
    if not diary.is_diary_file(args.buf) then
      return
    end

    diary.setup_buffer(args.buf)
  end,
})
