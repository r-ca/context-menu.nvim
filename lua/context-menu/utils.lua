local M = {}

---@param lines string[]
---@return number
function M.get_width(lines)
  local length = 0
  for _, line in ipairs(lines) do
    if #line > length then
      length = #line
    end
  end
  return length + 1
end

function M.log(msg)
  if vim.g.context_menu_config.enable_log then
    vim.print(msg)
  end
end

function M.table_contains(tbl, value)
  for _, v in ipairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end

return M
