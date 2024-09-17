local M = {}

---merge Items
---@param t1 ContextMenu.Items
---@param t2 ContextMenu.Items
---@return ContextMenu.Items
local function merge_cmds(t1, t2)
  -- If t1 is empty, early return t2
  if not t1 or #t1 == 0 then
    return t2
  end

  local result = {}
  -- Create a lookup table for the second table for quick access
  local t2_lookup = {}
  for _, item in ipairs(t2) do
    t2_lookup[item.cmd] = item
  end

  -- Iterate over the first table
  for _, item1 in ipairs(t1) do
    local item2 = t2_lookup[item1.cmd]

    if item2 then -- If duplicate item is found
      -- Validate action
      if not item1.action then
        error("Action is not found in menu_item [" .. item1.cmd .. "]")
      end
      if not item2.action then
        error("Action is not found in menu_item [" .. item2.cmd .. "]")
      end

      -- Validate action type
      if item1.action.type ~= item2.action.type then
        error("Action type is not matched in menu_item [" .. item1.cmd .. "]")
      end

      local merged_item = item1

      -- if both have sub_cmds, merge them
      if item1.action.type == "sub_menu" then -- 本質的にはitem1.action.type == item2.action.type == "sub_menu"
        if item1.action.sub_cmds and item2.action.sub_cmds then
          merged_item.action.sub_cmds = merge_cmds(item1.action.sub_cmds, item2.action.sub_cmds)
        end
      else
        -- If both have action, apply action from item2 (as it's the latest)
        merged_item.action = item2.action
      end

      -- Overwrite all other fields from item2
      for k, v in pairs(item2) do
        if k ~= "action" then
          merged_item[k] = v
        end
      end

      table.insert(result, merged_item)

      t2_lookup[item1.cmd] = nil -- We used this item2, so remove it from lookup
    else
      table.insert(result, item1)
    end
  end

  -- Add remaining items from t2 that weren't matched
  for _, item in ipairs(t2) do
    if t2_lookup[item.cmd] then
      table.insert(result, item)
    end
  end

  return result
end

M.setup = function(opts)
  opts = opts or {}
  local config = vim.deepcopy(vim.g.context_menu_config)
  if opts.menu_items then
    config.menu_items = merge_cmds(config.menu_items, opts.menu_items)
  end

  -- set other options
  for k, v in pairs(opts) do
    if k ~= "menu_items" then
      config[k] = v
    end
  end

  vim.g.context_menu_config = config
end

return M
