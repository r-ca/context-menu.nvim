local Utils = require('context-menu.utils')
local MenuItem = require('context-menu.domain.menu-item')
local Context = require('context-menu.domain.context')
local MenuItems = require('context-menu.domain.menu-items')

local M = {}

local function apply_filter(items, context)
  local filtered = {}

  for _, item in ipairs(items) do
    if (item.ft == nil or Utils.table_contains(item.ft, context.ft)) and
        (not item.not_ft or not Utils.table_contains(item.not_ft, context.ft)) and
        (not item.filter_func or item.filter_func(context)) then
      table.insert(filtered, item)
    end
  end

  return filtered
end

---@diagnostic disable-next-line: unused-local
local function apply_sort(items, context)
  -- TODO: implement sorting logic
  return items
end

local function create_local_keymap(items, local_level, context)
  -- body
end

function M.prepare_items(menu_items, context)
  return apply_sort(apply_filter(menu_items, context), context)
end

function M.trigger_context_menu()

end

function M.menu_popup_window(menu_items, context, local_level)
  local popup_buffer = vim.api.nvim_create_buf(false, true)
  local lines = MenuItems.format(menu_items)
  vim.api.nvim_buf_set_lines(popup_buffer, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(popup_buffer, "modifiable", false)

  local width, height = Utils.get_width(lines), #menu_items
  local win_opts = {
    relative = context.menu_window and "win" or "cursor",
    win = context.menu_window or nil,
    row = 0,
    col = context.menu_window and 15 or 0,
    width = context.menu_window and (width + 1) or width,
    height = height,
    style = "minimal",
    border = "single",
    title = "ContextMenu.", -- TODO: configurable title
  }

  local window = vim.api.nvim_open_win(popup_buffer, true, win_opts)
  Context.update_context(context, { menu = { buf = popup_buffer, win = window } })

  require("context-menu.hl").create_hight_light(popup_buffer)
end

function M.close_menu(context)
  for _, w in ipairs(context.menu_window_stack) do
    pcall(vim.api.nvim_win_close, w, true)
  end
  for _, b in ipairs(context.menu_buffer_stack) do
    pcall(vim.api.nvim_win_close, b, true)
  end
end

return M
