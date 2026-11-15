# nvim-ohh

Neovim support for OHH (.ohh).

## Setup

```lua
require("ohh").setup({
  server_path = "/absolute/path/to/ohh-ls/build/ohh-ls", -- default: "ohh-ls" on PATH
  registry_path = "/absolute/path/to/ohh-data/registry", -- required, no default
  -- grammar_path defaults to the sibling tree-sitter-ohh checkout used
  -- throughout this project; override if yours lives elsewhere.
})
```

Add this plugin's directory to Neovim's runtime path however your plugin
manager expects, then call `setup()` from your config.

**Not listed anywhere.** This repo is pushed to
`github.com/MrPoloGit/nvim-ohh`, usable today by any plugin manager
that takes a plain git URL, but it isn't listed in awesome-neovim or
any other curated index, nothing has been submitted anywhere.
