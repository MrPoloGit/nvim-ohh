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

## Platform note: the bundled grammar is macOS arm64 only

`parser/ohh.so` is a pre-compiled Mach-O arm64 dynamic library (`file
parser/ohh.so` confirms this), built from `../tree-sitter-ohh`'s
generated `src/parser.c`. On any other platform (Linux, Windows, or
macOS on Intel), `setup()` will fail to load it, and you need to rebuild
it yourself, which only needs the `tree-sitter` CLI (`npm install -g
tree-sitter-cli`, or see its own install docs) and a C compiler:

```sh
tree-sitter build ../tree-sitter-ohh -o parser/ohh.so
```

Despite the `.so` extension (kept for Neovim's own convention, which
doesn't care whether the file is actually an ELF `.so`, a Mach-O
`.dylib`, or (after this exact command, run on Windows) a PE `.dll`),
`tree-sitter build` always produces the right native format for whatever
platform it runs on, confirmed by running it on this machine and getting
back the same Mach-O arm64 library already bundled.

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

drives the real plugin against the real corpus (`../ohh-data/corpus/`) inside
an actual (headless) Neovim instance. For every valid and invalid
fixture, it opens the file, waits for the real `ohh-ls` process to attach
and respond, and checks: correct `filetype`, the `ohh-ls` LSP client
actually attached, diagnostics matching the corpus's own zero/non-zero
expectations (`ohh-data/corpus/README.md`), and the tree-sitter highlighter
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
