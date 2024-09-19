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
        (not item.filter_func or not item.filter_func(context)) then
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

local function trigger_action(context, local_buf_win)
  local current_buf = context.menu_buffer_stack[local_buf_win.level]
  vim.api.nvim_set_current_buf(current_buf)

  local selected_cmd = MenuItem.parse(vim.api.nvim_get_current_line())
  local item = MenuItems.find_item_by_cmd(selected_cmd.cmd)

  MenuItem.trigger_action(item, local_buf_win, context)
end


local function create_local_keymap(items, local_level, context)
  local current_buf = context.menu_buffer_stack[local_level.level]

  local function map(lhs, rhs)
    vim.keymap.set({ "v", "n" }, lhs, rhs, {
      noremap = true,
      silent = true,
      nowait = true,
      buffer = current_buf,
    })
  end

  -- Map index keys and item keymaps
  for index, item in ipairs(items) do
    local action = function() MenuItem.trigger_action(item, local_level, context) end
    if index < 10 then map(tostring(index), action) end
    if item.keymap then map(item.keymap, action) end
  end

  -- Map default action keymaps
  for _, k in ipairs(vim.g.context_menu_config.default_action_keymaps.close_menu) do
    map(k, function() M.close_menu(context) end)
  end
  for _, k in ipairs(vim.g.context_menu_config.default_action_keymaps.trigger_action) do
    map(k, function() trigger_action(context, local_level) end)
  end
end

function M.prepare_items(menu_items, context)
  return apply_sort(apply_filter(menu_items, context), context)
end

function M.trigger_context_menu()
  local context = Context.init()
  local items = M.prepare_items(vim.g.context_menu_config.menu_items, context)
  M.menu_popup_window(items, context, { level = 1 })
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

  create_local_keymap(menu_items, {
    buf = popup_buffer,
    win = window,
    level = local_level.level,
  }, context)

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
