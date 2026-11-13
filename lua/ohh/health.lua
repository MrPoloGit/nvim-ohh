-- :checkhealth ohh, same role as nvim-phh/lua/phh/health.lua.

local M = {}

local function file_exists(path)
  local fd = io.open(path, "r")
  if fd then
    fd:close()
    return true
  end
  return false
end

local function dir_exists(path)
  return vim.fn.isdirectory(path) == 1
end

function M.check()
  local health = vim.health or require("health")
  health.start("ohh")

  local ohh = require("ohh")
  local state = ohh._state

  if not state then
    health.warn('require("ohh").setup() has not been called yet, nothing else can be checked.')
    return
  end

  if vim.fn.executable(state.server_path) == 1 then
    health.ok(("ohh-ls found: %s"):format(state.server_path))
  else
    health.error(
      ("ohh-ls not found or not executable: %s"):format(state.server_path),
      { "Set ohh.server_path to an absolute path, or add ohh-ls to your PATH." }
    )
  end

  local registry_files = { "fields.json", "objects.json", "enums.json" }
  if dir_exists(state.registry_path) then
    local missing = {}
    for _, name in ipairs(registry_files) do
      if not file_exists(state.registry_path .. "/" .. name) then
        table.insert(missing, name)
      end
    end
    if #missing == 0 then
      health.ok(("registry found: %s"):format(state.registry_path))
    else
      health.error(
        ("registry at %s is missing: %s"):format(state.registry_path, table.concat(missing, ", "))
      )
    end
  else
    health.error(("registry_path does not exist: %s"):format(state.registry_path))
  end

  local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h")
  local so_path = root .. "/parser/ohh.so"
  if file_exists(so_path) then
    health.ok(("ohh.so present: %s"):format(so_path))
  else
    health.error(("ohh.so not found: %s (rebuild with the sibling grammar repo)"):format(so_path))
  end

  local missing = {}
  for _, name in ipairs({ "highlights", "folds", "indents" }) do
    if not file_exists(state.grammar_path .. "/queries/" .. name .. ".scm") then
      table.insert(missing, name)
    end
  end
  if #missing == 0 then
    health.ok(("ohh queries found at %s"):format(state.grammar_path))
  else
    health.warn(
      ("ohh: missing query files at %s: %s"):format(state.grammar_path, table.concat(missing, ", "))
    )
  end
end

return M
