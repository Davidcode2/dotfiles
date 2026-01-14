-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = LazyVim.safe_keymap_set

map("n", "ö", ":", { desc = "enter command mode", remap = true })
map("i", "jh", "<esc>", { desc = "enter command mode", remap = true })
