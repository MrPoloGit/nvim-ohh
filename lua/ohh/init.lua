-- Neovim support for OHH (.ohh).
--
-- Same shape as nvim-phh/lua/phh/init.lua: registers the one grammar
-- every other editor in this project uses (tree-sitter-ohh's compiled
-- grammar + its canonical queries/) for highlighting, and ohh-ls itself
-- for diagnostics/hover/completion via Neovim's built-in LSP client.
-- Simpler than nvim-phh in exactly one way: OHH has only one grammar, no
-- second "actions" grammar to register .
--
-- By design, this module does nothing on require(); call M.setup() from
-- your config.

local M = {}

local function plugin_root()
  local source = debug.getinfo(1, "S").source
  local this_file = source:sub(2)
  -- this_file is .../nvim-ohh/lua/ohh/init.lua; three ":h" hops up reach
  -- the plugin root (init.lua -> ohh/ -> lua/ -> nvim-ohh/).
  return vim.fn.fnamemodify(this_file, ":h:h:h")
end

local function read_file(path)
  local fd = io.open(path, "r")
  if not fd then return nil end
  local content = fd:read("*a")
  fd:close()
  return content
end

local function load_queries(lang, grammar_path, names)
  for _, name in ipairs(names) do
    local path = grammar_path .. "/queries/" .. name .. ".scm"
    local content = read_file(path)
    if content then
      local ok, err = pcall(vim.treesitter.query.set, lang, name, content)
      if not ok then
        vim.notify(
          ("ohh: failed to register %s query for %s: %s"):format(name, lang, err),
          vim.log.levels.WARN
        )
      end
    else
      vim.notify(
        ("ohh: query file not found: %s (grammar_path may be wrong)"):format(path),
        vim.log.levels.WARN
      )
    end
  end
end

-- Exposed so lua/ohh/health.lua can report exactly what setup() resolved.
M._state = nil

function M.setup(opts)
  opts = opts or {}
  local root = plugin_root()

  local config = {
    server_path = opts.server_path or "ohh-ls",
    registry_path = opts.registry_path,
    -- Same sibling-repository default assumption as nvim-phh: override
    -- once these are installed independently rather than checked out
    -- together.
    grammar_path = opts.grammar_path or vim.fn.fnamemodify(root .. "/../tree-sitter-ohh", ":p"),
  }
  M._state = config

  if not config.registry_path or config.registry_path == "" then
    vim.notify(
      "ohh: setup() needs registry_path ',
      vim.log.levels.ERROR
    )
    return
  end

  -- 1. Tree-sitter: register the one compiled grammar this plugin
  --    bundles, then load its queries from the canonical grammar
  --    checkout.
  local ok_ohh, err_ohh = pcall(vim.treesitter.language.add, "ohh", {
    path = root .. "/parser/ohh.so",
  })
  if not ok_ohh then
    vim.notify("ohh: failed to load parser/ohh.so: " .. tostring(err_ohh), vim.log.levels.ERROR)
  end

  if ok_ohh then
    -- Deliberately NOT "outline" here, matching nvim-phh's own omission:
    -- Neovim has no built-in consumer of a tree-sitter "outline" query
    -- the way Zed's symbol view does (tree-sitter-ohh/queries/outline.scm
    -- follows Zed's own @item/@name convention, confirmed only via
    -- `tree-sitter query`, not against a live Zed or Neovim install).
    -- "injections" is also absent, correctly: OHH has no sub-grammar to
    -- inject, unlike tree-sitter-phh.
    load_queries("ohh", config.grammar_path, { "highlights", "folds", "indents" })
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "ohh",
    group = vim.api.nvim_create_augroup("ohh_treesitter", { clear = true }),
    callback = function(args)
      if ok_ohh then
        pcall(vim.treesitter.start, args.buf, "ohh")
      end
    end,
  })

  -- 2. LSP: start ohh-ls over stdio for every ohh buffer, via Neovim's
  --    built-in client, no nvim-lspconfig dependency, same as nvim-phh.
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "ohh",
    group = vim.api.nvim_create_augroup("ohh_lsp", { clear = true }),
    callback = function(args)
      vim.lsp.start({
        name = "ohh-ls",
        cmd = { config.server_path, config.registry_path },
        root_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":p:h"),
      })
    end,
  })
end

return M
