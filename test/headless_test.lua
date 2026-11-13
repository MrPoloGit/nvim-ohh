-- End-to-end smoke test for nvim-ohh, run via:
--   nvim --headless --clean -u NONE -l nvim-ohh/test/headless_test.lua
--
-- Mirrors nvim-phh/test/headless_test.lua's discipline: drives the real
-- plugin against real corpus files inside a real (headless) Neovim
-- instance, not a mock.

local root = vim.fn.fnamemodify(vim.fn.getcwd(), ":p")
vim.opt.runtimepath:append(root .. "/nvim-ohh")

local failures = 0
local function check(label, cond)
  print(("[%s] %s"):format(cond and "ok" or "FAIL", label))
  if not cond then failures = failures + 1 end
end

dofile(root .. "/nvim-ohh/ftdetect/ohh.lua")

local ohh = require("ohh")
ohh.setup({
  server_path = root .. "/ohh-ls/build/ohh-ls",
  registry_path = root .. "/ohh/registry",
})

check("setup() recorded state", ohh._state ~= nil)

local function open_and_wait(path)
  vim.cmd.edit(path)
  local bufnr = vim.api.nvim_get_current_buf()
  check(path .. ": filetype detected as ohh", vim.bo[bufnr].filetype == "ohh")

  local got_diagnostics = false
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    buffer = bufnr,
    once = true,
    callback = function() got_diagnostics = true end,
  })

  local attached = vim.wait(5000, function()
    return #vim.lsp.get_clients({ bufnr = bufnr, name = "ohh-ls" }) > 0
  end, 50)
  check(path .. ": ohh-ls client attached", attached)

  vim.wait(3000, function() return got_diagnostics end, 50)

  return bufnr
end

local valid_files = vim.fn.glob(root .. "/ohh/corpus/valid/*.ohh", false, true)
local invalid_files = vim.fn.glob(root .. "/ohh/corpus/invalid/*.ohh", false, true)

for _, path in ipairs(valid_files) do
  local bufnr = open_and_wait(path)
  local diags = vim.diagnostic.get(bufnr)
  check(vim.fn.fnamemodify(path, ":t") .. ": zero diagnostics", #diags == 0)

  local highlighter_active = vim.treesitter.highlighter.active[bufnr] ~= nil
  check(vim.fn.fnamemodify(path, ":t") .. ": tree-sitter highlighter active", highlighter_active)
end

for _, path in ipairs(invalid_files) do
  local bufnr = open_and_wait(path)
  local diags = vim.diagnostic.get(bufnr)
  check(vim.fn.fnamemodify(path, ":t") .. ": at least one diagnostic", #diags >= 1)
end

-- Hover, via the same built-in LSP client, on the real spec example's
-- game_type field value, same position ohh-ls/tests/lsp_smoke_test.py
-- and vscode-ohh/test already know lands there: line 6 (0-indexed),
-- inside "Holdem".
do
  local path = root .. "/ohh/corpus/valid/holdem-cash-pokerstars.ohh"
  local bufnr = open_and_wait(path)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "ohh-ls" })
  if #clients > 0 then
    local result = clients[1]:request_sync(
      "textDocument/hover",
      {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
        position = { line = 6, character = 25 },
      },
      5000,
      bufnr
    )
    local hover_ok = result and result.result and result.result.contents ~= nil
    check("hover on game_type field returns content", hover_ok)
  else
    check("hover on game_type field returns content", false)
  end
end

print()
if failures > 0 then
  print(("%d FAILURE(S)"):format(failures))
  vim.cmd("cquit 1")
else
  print("All checks passed.")
  vim.cmd("qa")
end
