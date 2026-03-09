vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.number = true
opt.relativenumber = true

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

opt.wrap = false

opt.ignorecase = true
opt.smartcase = true

opt.splitright = true
opt.splitbelow = true

opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true

opt.scrolloff = 8
opt.sidescrolloff = 8

opt.clipboard = "unnamedplus"

opt.undofile = true
opt.swapfile = false

opt.updatetime = 250
opt.timeoutlen = 300
