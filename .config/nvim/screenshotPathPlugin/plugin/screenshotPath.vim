" Title:        screenshot path Plugin
" Description:  A plugin to provide an example for creating Neovim plugins.
" Last Change:  8 November 2021
" Maintainer:   Jakob Lingel

" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_exampleplugin")
    finish
endif
let g:loaded_exampleplugin = 1

" Exposes the plugin's functions for use as commands in Neovim.
command! -nargs=0 AdjustPath lua require("screenshotPath").adjustPath()
