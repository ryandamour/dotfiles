return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  main = "nvim-treesitter",
  opts = {
    ensure_installed = {
      "bash", "c", "css", "html", "javascript", "json",
      "lua", "markdown", "python", "rust", "toml",
      "typescript", "vim", "vimdoc", "yaml",
    },
  },
}
