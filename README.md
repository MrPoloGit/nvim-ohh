# nvim-ohh

Neovim support for OHH (.ohh).
Same shape as `nvim-phh`: uses the exact same artifacts every other
editor in this project does, `tree-sitter-ohh`'s grammar and canonical
`queries/` for highlighting, and `ohh-ls` itself for diagnostics/hover/
completion via Neovim's built-in LSP client.

## Setup

```lua
require("ohh").setup({
  server_path = "/absolute/path/to/ohh-ls/build/ohh-ls", -- default: "ohh-ls" on PATH
  registry_path = "/absolute/path/to/ohh/registry", -- required, no default
  -- grammar_path defaults to the sibling tree-sitter-ohh checkout used
  -- throughout this project; override if yours lives elsewhere.
})
```

Add this plugin's directory to Neovim's runtime path however your plugin
manager expects, then call `setup()` from your config.

## What's implemented

- **Filetype detection** (`ftdetect/ohh.lua`): `.ohh` → `ohh`.
- **Tree-sitter highlighting**: the grammar ships pre-compiled as
  `parser/ohh.so` (built from `../tree-sitter-ohh`'s generated
  `src/parser.c`, no external scanner needed, same one-`clang`-call
  build as `nvim-phh`'s two grammars). `setup()` registers it with
  `vim.treesitter.language.add` and loads its queries
  (`highlights`/`folds`/`indents`) directly from the canonical grammar
  checkout via `vim.treesitter.query.set`. Deliberately **not**
  `injections` (OHH has no sub-grammar to inject, unlike PHH's action
  strings, every OHH field is already structured JSON) and **not**
  `outline` (same omission `nvim-phh` makes: Neovim has no built-in
  consumer of a tree-sitter "outline" query the way Zed's symbol view
  does, `tree-sitter-ohh/queries/outline.scm` follows Zed's own
  convention and is confirmed only via `tree-sitter query`, not against
  a live Neovim or Zed install).
- **LSP**: `vim.lsp.start` on every `ohh` buffer, via Neovim's built-in
  client, no `nvim-lspconfig` dependency, same as `nvim-phh`.
- **`:checkhealth ohh`** (`lua/ohh/health.lua`): reports whether `ohh-ls`
  is reachable, the registry is present and complete, the compiled
  grammar exists, and its query files are reachable at the configured
  path.

## How this was verified

`test/headless_test.lua`, run via:

```sh
nvim --headless --clean -u NONE -l nvim-ohh/test/headless_test.lua
```

drives the real plugin against the real corpus (`../ohh/corpus/`) inside
an actual (headless) Neovim instance. For every valid and invalid
fixture, it opens the file, waits for the real `ohh-ls` process to attach
and respond, and checks: correct `filetype`, the `ohh-ls` LSP client
actually attached, diagnostics matching the corpus's own zero/non-zero
expectations (`ohh/corpus/README.md`), and the tree-sitter highlighter
active. It also exercises `hover` on the real spec-sourced example's
`game_type` field through the same LSP client. **25/25 checks pass, on
the first real run**, same result `nvim-phh` got, confirming the
prediction that Neovim is the cheapest editor integration once the
grammar and server already exist (true again here, for a second
language). `:checkhealth ohh` was separately run and confirmed all-green.

## Known limitations

- **Compiled `.so` parser is checked in rather than built on install**, same known limitation as `nvim-phh`, same reason (local, sibling-
  checkout development workflow; real distribution is later work).
- **No `:checkhealth`-driven install instructions beyond path
  reporting**, same as `nvim-phh`.
