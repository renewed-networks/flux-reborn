--- The inventory class is used to manage player's items,
-- transferring them from one player or object to another,
-- using the same interface and functionality.
class 'Inventory'

-- Initializes the new inventory class
-- and loads it to the server cache.
-- ```
-- -- Creating new inventory
-- local inventory = Inventory.new()
-- inventory.title = 'Test inventory'
-- inventory:set_size(4, 4)
-- inventory.type = 'testing_inventory'
-- inventory.multislot = false
-- ```
-- @param id [Number]
function Inventory:init(id)
  self.title = 'ui.inventory.title'
  self.icon = nil
  self.type = 'default'
  self.width = 1
  self.height = 1
  self.slots = {}
  self.multislot = true
  self.disabled = false

  if SERVER then
    self.infinite_width = false
    self.infinite_height = false
    self.default = false
    self.receivers = {}

    id = table.insert(Inventories.stored, self)
  else
    Inventories.stored[id] = self
  end

  self.id = id
end

--- Returns the values of the inventory
-- that will be sent to the client.
-- @return [Hash]
function Inventory:to_networkable()
  return {
    id = self.id,
    title = self.title,
    icon = self.icon,
    inv_type = self.type,
    width = self.width,
    height = self.height,
    slots = self.slots,
    multislot = self.multislot,
    disabled = self.disabled,
    owner = self.owner,
    instance_id = self.instance_id
  }
end

--- Sets the width of the inventory and rebuilds its slots.
function Inventory:set_width(width)
  self.width = width

  self:rebuild()
end

--- Sets the height of the inventory and rebuilds its slots.
function Inventory:set_height(height)
  self.height = height

  self:rebuild()
end

--- Sets the width and height of the inventory and rebuilds its slots.
function Inventory:set_size(width, height)
  self.width = width
  self.height = height

  self:rebuild()
end

--- Gets the X axis size of the inventory in a number of slots.
-- @return [Number]
function Inventory:get_width()
  return self.width
end

--- Gets the Y axis size of the inventory in a number of slots.
-- @return [Number]
function Inventory:get_height()
  return self.height
end

--- Gets the X and Y axes size of the inventory in a number of slots.
-- @return [Number, Number]
function Inventory:get_size()
  return self.width, self.height
end

--- Get the type of the inventory.
-- @return [String]
function Inventory:get_type()
  return self.type
end

--- Get the slots grid.
-- @return [Hash]
function Inventory:get_slots()
  return self.slots
end

--- Get the entity this inventory belongs to.
-- @return [Entity]
function Inventory:get_owner()
  return self.owner
end

--- Checks if the inventory is multislot.
-- @return [Boolean]
function Inventory:is_multislot()
  return self.multislot
end

--- Checks if the inventory is disabled.
-- @return [Boolean]
function Inventory:is_disabled()
  return self.disabled
end

--- Checks if the inventory has infinite width.
-- @return [Boolean]
function Inventory:is_width_infinite()
  return self.infinite_width
end

--- Checks if the inventory has infinite height.
-- @return [Boolean]
function Inventory:is_height_infinite()
  return self.infinite_height
end

--- Checks if the inventory is default.
-- If there's no certain inventory specified,
-- default one is used for it.
-- @see [player_meta#add_item]
-- @return [Boolean]
function Inventory:is_default()
  return self.default
end

--- @warning [Internal]
-- Rebuilds inventory slots hash.
function Inventory:rebuild()
  for i = 1, self.height do
    self.slots[i] = self.slots[i] or {}

    for k = 1, self.width do
      self.slots[i][k] = self.slots[i][k] or {}
    end
  end
end

--- Get item objects that the inventory contains.
-- Also includes items from the containers.
-- @return [Hash items]
function Inventory:get_items()
  local items = {}

  for k, v in pairs(self:get_items_ids()) do
    local item_obj = Item.find_instance_by_id(v)

    if item_obj then
      table.insert(items, item_obj)

      local inventory = item_obj.inventory

      if inventory then
        table.add(items, inventory:get_items())
      end
    end
  end

  return items
end

--- Get item ids that the inventory contains.
-- @return [Hash items ids]
function Inventory:get_items_ids()
  local items = {}

  for i = 1, self.height do
    for k = 1, self.width do
      local stack = self.slots[i][k]

      if istable(stack) and !table.is_empty(stack) then
        for _, v in pairs(stack) do
          items[v] = true
        end
      end
    end
  end

  return table.get_keys(items)
end

--- Get the items ids that located in the specified slot.
-- @param x [Number]
-- @param y [Number]
-- @return [Hash items ids]
function Inventory:get_slot(x, y)
  if x <= self.width and y <= self.height then
    return self.slots[y][x]
  end
end

--- Get the first item id that located in the specified slot.
-- @param x [Number]
-- @param y [Number]
-- @return [Number]
function Inventory:get_first_in_slot(x, y)
  local slot = self:get_slot(x, y)

  if istable(slot) and !table.is_empty(slot) then
    return slot[1]
  end
end

--- Get amount of items by their id.
-- @param id [String]
-- @return [Number]
function Inventory:get_items_count(id)
  return table.count(self:find_items(id))
end

--- Checks if the inventory is empty.
-- ```
-- if player:get_inventory('main_inventory'):is_empty() then
--   player:notify('Your main inventory is empty!')
-- end
-- ```
-- @return [Boolean]
function Inventory:is_empty()
  return table.is_empty(self:get_items_ids())
end

--- Find a specified item object by its id.
-- @param id [String]
-- @return [Item]
function Inventory:find_item(id)
  for k, v in pairs(self:get_items()) do
    if v.id == id then
      return v
    end
  end
end

--- Find a specified items objects by their id.
-- @param id [String]
-- @return [Hash items]
function Inventory:find_items(id)
  local items = {}

  for k, v in pairs(self:get_items()) do
    if v.id == id then
      table.insert(items, v)
    end
  end

  return items
end

--- Check if the inventory contains item by its id.
-- @param id [String]
-- @return [Boolean]
function Inventory:has_item(id)
  local item_obj = self:find_item(id)

  if item_obj then
    return true, item_obj
  end

  return false
end

--- Check if the inventory contains items by their id.
-- @param id [String]
-- @return [Boolean, Hash found items]
function Inventory:has_items(id, amount)
  amount = amount or 1

  local items = self:find_items(id)

  if table.count(items) >= amount then
    return true, items
  end

  return false, items
end

--- Check if the inventory contains item by its instance id.
-- @param instance_id [Number]
-- @return [Boolean, Item found item]
function Inventory:has_item_by_id(instance_id)
  if table.has_value(self:get_items_ids(), instance_id) then
    return true, Item.find_instance_by_id(instance_id)
  end

  return false
end

--- Find the best position for the item to be placed.
-- @param item_obj [Item]
-- @param w [Number width of the item]
-- @param h [Number height of the item]
-- @return [Number x, Number y, Boolean do a rotation need]
function Inventory:find_position(item_obj, w, h)
  local x, y, need_rotation

  if item_obj.stackable then
    x, y, need_rotation = self:find_stack(item_obj, w, h)

    if x and y then
      need_rotation = need_rotation != item_obj.rotated
    end
  end

  if !x or !y then
    x, y = self:find_empty_slot(w, h)

    if !x or !y then
      x, y = self:find_empty_slot(h, w)

      need_rotation = true
    end
  end

  return x, y, need_rotation
end

--- Find the stack position for the item.
-- @param item_obj [Item]
-- @param w [Number width of the item]
-- @param h [Number height of the item]
-- @return [Number x, Number y, Boolean do a rotation need]
function Inventory:find_stack(item_obj, w, h)
  for k, v in pairs(self:find_items(item_obj.id)) do
    if self:can_stack(item_obj, v) then
      return v.x, v.y, v.rotated
    end
  end
end

--- Check if two items may be stacked.
-- @param item_obj [Item]
-- @param stack_item [Item]
-- @return [Boolean]
function Inventory:can_stack(item_obj, stack_item)
  local slot = self:get_slot(stack_item.x, stack_item.y)

  if stack_item and stack_item.id == item_obj.id
  and item_obj.stackable and #slot < item_obj.max_stack then
    return true
  end

  return false
end

--- Find free space in the inventory.
-- @param w [Number]
-- @param h [Number]
-- @return [Number x, Number y]
function Inventory:find_empty_slot(w, h)
  for i = 1, self:get_height() - h + 1 do
    for k = 1, self:get_width() - w + 1 do
      if self:slots_empty(k, i, w, h) then
        return k, i
      end
    end
  end
end

--- Check if the specified slots are empty.
-- @param x [Number]
-- @param y [Number]
-- @param w [Number]
-- @param h [Number]
-- @return [Boolean]
function Inventory:slots_empty(x, y, w, h)
  for i = y, y + h - 1 do
    for k = x, x + w - 1 do
      if !table.is_empty(self.slots[i][k]) then
        return false
      end
    end
  end

  return true
end

--- Check if the item overlaps other stackable item and return adjusted data.
-- @param item_obj [Item]
-- @param x [Number]
-- @param y [Number]
-- @param w [Number]
-- @param h [Number]
-- @return [Boolean, Number x, Number y, Boolean do a rotation need]
function Inventory:overlaps_stack(item_obj, x, y, w, h)
  for i = y, y + h - 1 do
    for k = x, x + w - 1 do
      local slot = self:get_slot(k, i)
      local stack_item = Item.find_instance_by_id(slot[1])

      if stack_item and self:can_stack(item_obj, stack_item) and !table.has_value(slot, item_obj.instance_id) then
        return true, stack_item.x, stack_item.y, stack_item.rotated != item_obj.rotated
      end
    end
  end
end

--- Check if the item overlaps itself.
-- @param instance_id [Number]
-- @param x [Number]
-- @param y [Number]
-- @param w [Number]
-- @param h [Number]
-- @return [Boolean]
function Inventory:overlaps_itself(instance_id, x, y, w, h)
  for i = y, y + h - 1 do
    for k = x, x + w - 1 do
      local slot = self.slots[i][k]

      if table.has_value(slot, instance_id) then
        return true
      end
    end
  end

  return false
end

--- Check if the item overlaps only itself.
-- @param instance_id [Number]
-- @param x [Number]
-- @param y [Number]
-- @param w [Number]
-- @param h [Number]
-- @return [Boolean]
function Inventory:overlaps_only_itself(instance_id, x, y, w, h)
  for i = y, y + h - 1 do
    for k = x, x + w - 1 do
      local slot = self.slots[i][k]

      if !table.has_value(slot, instance_id) and !table.is_empty(slot) then
        return false
      end
    end
  end

  return true
end

--- Get item size based on inventory and item params.
-- @param item_obj [Item]
-- @return [Number width, Number height]
function Inventory:get_item_size(item_obj)
  if !self:is_multislot() then
    return 1, 1
  end

  local item_w, item_h = item_obj.width, item_obj.height

  if item_obj.rotated then
    return item_h, item_w
  else
    return item_w, item_h
  end
end

if SERVER then

  -- Add item object to a inventory.
  -- @variant Inventory:add_item(item_obj, x, y)
  --   @param item_obj [Item]
  --   @param x [Number]
  --   @param y [Number]
  -- In this case finds best position for the item.
  -- @variant Inventory:add_item(item_obj)
  --   @param item_obj [Item]
  -- @return [Boolean was the item added successfully, String text of the error that occurred]
  function Inventory:add_item(item_obj, x, y)
    if !item_obj then return false, 'error.inventory.invalid_item' end

    local need_rotation = false
    local w, h = self:get_item_size(item_obj)

    if !x or !y or x < 1 or y < 1 or x + w - 1 > self:get_width() or y + h - 1 > self:get_height() then
      x, y, need_rotation = self:find_position(item_obj, w, h)
    end

    if x and y then
      item_obj.inventory_id = self.id
      item_obj.inventory_type = self.type
      item_obj.x = x
      item_obj.y = y

      if need_rotation then
        w, h = h, w

        item_obj.rotated = !item_obj.rotated
      end

      for i = y, y + h - 1 do
        for k = x, x + w - 1 do
          table.insert(self.slots[i][k], item_obj.instance_id)
        end
      end

      hook.run('OnItemAdded', item_obj, self, x, y)

      self:check_size()
    else
      return false, 'error.inventory.no_space'
    end

    return true
  end

  -- Add item to a inventory by its instance id.
  -- @variant Inventory:add_item(item_obj, x, y)
  --   @param item_obj [Item]
  --   @param x [Number]
  --   @param y [Number]
  -- In this case finds best position for the item.
  -- @variant Inventory:add_item(item_obj)
  --   @param item_obj [Item]
  -- @return [Boolean was the item added successfully, String text of the error that occurred]
  function Inventory:add_item_by_id(instance_id, x, y)
    return self:add_item(Item.find_instance_by_id(instance_id), x, y)
  end

  -- Create an item and add it to a inventory.
  -- @param id [String]
  -- @param amount [Number]
  -- @param data [Hash]
  -- @return [Boolean was the item given successfully, String text of the error that occurred]
  function Inventory:give_item(id, amount, data)
    amount = amount or 1

    for i = 1, amount do
      local item_obj = Item.create(id, data)
      local success, error_text = self:add_item(item_obj)

      if !success then
        return success, error_text
      end

      hook.run('OnItemGiven', item_obj, self, data)
    end

    return true
  end

  -- Take item object from the inventory.
  -- @param item_obj [Item]
  -- @return [Boolean was the item taken successfully, String text of the error that occurred]
  function Inventory:take_item_table(item_obj)
    if !item_obj then return false, 'error.inventory.invalid_item' end

    local x, y = item_obj.x, item_obj.y
    local w, h = self:get_item_size(item_obj)

    item_obj.inventory_id = nil
    item_obj.inventory_type = nil
    item_obj.x = nil
    item_obj.y = nil
    item_obj.rotated = false

    for i = y, y + h - 1 do
      for k = x, x + w - 1 do
        table.remove_by_value(self.slots[i][k], item_obj.instance_id)
      end
    end

    self:check_size()

    hook.run('OnItemTaken', item_obj, self)

    return true
  end

  -- Take item object from the inventory based on its id.
  -- @param id [String]
  -- @return [Boolean was the item taken successfully, String text of the error that occurred]
  function Inventory:take_item(id)
    local item_obj = self:find_item(id)

    if item_obj then
      return self:take_item_by_id(item_obj.instance_id)
    end

    return false, 'error.inventory.invalid_item'
  end

  -- Take certain amount of items from the inventory based on their id.
  -- @param id [String]
  -- @param amount [Number]
  -- @return [Boolean was the item taken successfully, String text of the error that occurred]
  function Inventory:take_items(id, amount)
    if self:get_items_count(id) < amount then
      return false, 'error.inventory.not_enough_items'
    end

    for i = 1, amount do
      self:take_item(id)
    end

    return true
  end

  -- Take item object from the inventory based on its instance id.
  -- @param instance_id [Number]
  -- @return [Boolean was the item taken successfully, String text of the error that occurred]
  function Inventory:take_item_by_id(instance_id)
    return self:take_item_table(Item.find_instance_by_id(instance_id))
  end

  --- @warning [Internal]
  -- Move the item inside the inventory.
  -- @param instance_id [Number]
  -- @param x [Number]
  -- @param y [Number]
  -- @param was_rotated [Boolean]
  -- @return [Boolean was the item moved successfully, String text of the error that occurred]
  function Inventory:move_item(instance_id, x, y, was_rotated)
    local item_obj = Item.find_instance_by_id(instance_id)

    if !item_obj then return false, 'error.inventory.invalid_item' end

    local success, error_text = hook.run('CanItemMove', item_obj, self, x, y)

    if success == false then
      return false, error_text
    end

    local need_rotation = false
    local old_x, old_y = item_obj.x, item_obj.y
    local w, h = self:get_item_size(item_obj)
    local old_w, old_h = w, h

    if was_rotated then
      w, h = h, w
    end

    if !x or !y or x < 1 or y < 1 or x + w - 1 > self:get_width() or y + h - 1 > self:get_height() then
      x, y, need_rotation = self:find_position(item_obj, w, h)

      if !x or !y then
        return false, 'error.inventory.no_space'
      end
    elseif !self:slots_empty(x, y, w, h) then
      local overlap, new_x, new_y, new_rotation = self:overlaps_stack(item_obj, x, y, w, h)

      if overlap then
        x, y = new_x, new_y

        if new_rotation != was_rotated then
          need_rotation = true
        end
      elseif !self:overlaps_only_itself(instance_id, x, y, w, h) then
        return false, 'error.inventory.slot_occupied'
      end
    end

    item_obj.x = x
    item_obj.y = y

    if need_rotation then
      w, h = h, w
    end

    if was_rotated != need_rotation then
      item_obj.rotated = !item_obj.rotated
    end

    for i = old_y, old_y + old_h - 1 do
      for k = old_x, old_x + old_w - 1 do
        table.remove_by_value(self.slots[i][k], instance_id)
      end
    end

    for i = y, y + h - 1 do
      for k = x, x + w - 1 do
        table.insert(self.slots[i][k], instance_id)
      end
    end

    self:check_size()

    return true
  end

  --- @warning [Internal]
  -- Move the item to another inventory.
  -- @param instance_id [Number]
  -- @param inventory [Inventory]
  -- @param x [Number]
  -- @param y [Number]
  -- @param was_rotated [Boolean]
  -- @return [Boolean was the item transferred successfully, String text of the error that occurred]
  function Inventory:transfer_item(instance_id, inventory, x, y, was_rotated)
    local item_obj = Item.find_instance_by_id(instance_id)

    if !item_obj then return false, 'error.inventory.invalid_item' end

    local success, error_text = hook.run('CanItemTransfer', item_obj, inventory, x, y)

    if success == false then
      return false, error_text
    end

    local need_rotation = false
    local old_x, old_y = item_obj.x, item_obj.y
    local w, h = inventory:get_item_size(item_obj)
    local old_w, old_h = self:get_item_size(item_obj)

    if was_rotated then
      w, h = h, w
    end

    if !x or !y or x < 1 or y < 1 or x + w - 1 > inventory:get_width() or y + h - 1 > inventory:get_height() then
      x, y, need_rotation = inventory:find_position(item_obj, w, h)

      if !x or !y then
        return false, 'error.inventory.no_space'
      end
    elseif !inventory:slots_empty(x, y, w, h) then
      local overlap, new_x, new_y, new_rotation = inventory:overlaps_stack(item_obj, x, y, w, h)

      if overlap then
        x, y = new_x, new_y

        if new_rotation != was_rotated then
          need_rotation = true
        end
      else
        return false, 'error.inventory.slot_occupied'
      end
    end

    hook.run('PreItemTransfer', item_obj, inventory, self)

    item_obj.inventory_id = inventory.id
    item_obj.inventory_type = inventory.type
    item_obj.x = x
    item_obj.y = y

    if need_rotation then
      w, h = h, w
    end

    if was_rotated != need_rotation then
      item_obj.rotated = !item_obj.rotated
    end

    for i = old_y, old_y + old_h - 1 do
      for k = old_x, old_x + old_w - 1 do
        table.remove_by_value(self.slots[i][k], instance_id)
      end
    end

    for i = y, y + h - 1 do
      for k = x, x + w - 1 do
        table.insert(inventory.slots[i][k], instance_id)
      end
    end

    self:check_size()
    inventory:check_size()

    hook.run('ItemTransferred', item_obj, inventory, self)

    return true
  end

  --- @warning [Internal]
  -- Move the whole stack inside the inventory.
  -- @param instance_ids [Hash instance ids]
  -- @param x [Number]
  -- @param y [Number]
  -- @param was_rotated [Boolean]
  -- @return [Boolean have the items been moved successfully, String text of the error that occurred]
  function Inventory:move_stack(instance_ids, x, y, was_rotated)
    local instance_id = instance_ids[1]
    local item_obj = Item.find_instance_by_id(instance_id)
    local old_x, old_y = item_obj.x, item_obj.y
    local slot = self:get_slot(old_x, old_y)
    local w, h = self:get_item_size(item_obj)

    if !table.equal(instance_ids, slot) and self:overlaps_itself(instance_id, x, y, w, h) then
      return true
    end

    for k, v in ipairs(instance_ids) do
      local success, error_text = self:move_item(v, x, y, was_rotated)

      if !success then
        return success, error_text
      end
    end

    return true
  end

  --- @warning [Internal]
  -- Move the whole stack to another inventory.
  -- @param instance_ids [Hash instance ids]
  -- @param inventory [Inventory]
  -- @param x [Number]
  -- @param y [Number]
  -- @param was_rotated [Boolean]
  -- @return [Boolean have the items been transferred successfully, String text of the error that occurred]
  function Inventory:transfer_stack(instance_ids, inventory, x, y, was_rotated)
    for k, v in ipairs(instance_ids) do
      local success, error_text = self:transfer_item(v, inventory, x, y, was_rotated)

      if !success then
        return success, error_text
      end
    end

    return true
  end

  --- Get the players that currently receive the inventory data.
  -- @return [Hash players]
  function Inventory:get_receivers()
    return self.receivers
  end

  --- Add new receiver to the inventory.
  -- @param player [Player]
  function Inventory:add_receiver(player)
    table.insert(self.receivers, player)
  end

  --- Remove the receiver from the inventory.
  -- @param player [Player]
  function Inventory:remove_receiver(player)
    table.remove_by_value(self.receivers, player)
  end

  --- Send inventory data to its receivers.
  function Inventory:sync()
    for k, v in pairs(self:get_receivers()) do
      if IsValid(v) then
        for k1, v1 in pairs(self:get_items_ids()) do
          Item.network_item(v, v1)
        end

        Cable.send(v, 'fl_inventory_sync', self:to_networkable())
      else
        self:remove_receiver(v)
      end
    end
  end

  --- @warning [Internal]
  -- Check the size of the inventory and resize it if needed.
  function Inventory:check_size()
    if !self:is_height_infinite() and !self:is_width_infinite() then return end

    local max_x, max_y = 0, 0

    for i = 1, self:get_height() do
      for k = 1, self:get_width() do
        if !table.is_empty(self:get_slot(k, i)) then
          max_x, max_y = k, i
        end
      end
    end

    if self:is_height_infinite() then
      self.height = max_y + 1
    end

    if self:is_width_infinite() then
      self.width = max_x + 1
    end

    self:rebuild()
    self:sync()
  end

  --- @warning [Internal]
  -- Fill the inventory with certain items by their ids.
  -- @param items_ids [Hash]
  function Inventory:load_items(items_ids)
    for k, v in pairs(items_ids) do
      local item_obj = Item.find_instance_by_id(v)

      if item_obj then
        local x, y = item_obj.x, item_obj.y

        self:add_item(item_obj, x, y)
      end
    end
  end

  --- Disables the inventory, preventing to manipulate items inside it.
  -- @param disabled [Boolean]
  function Inventory:set_disabled(disabled)
    self.disabled = disabled

    self:sync()
  end
else

  --- Creates a panel for the inventory.
  -- It will update automatically every time
  -- inventory synchronizes itself.
  -- @param parent [Panel]
  -- @return [Panel]
  function Inventory:create_panel(parent)
    local panel = vgui.create('fl_inventory', parent)
    panel:set_title(t(self.title or self.type))
    panel:set_icon(self.icon)
    panel:set_inventory_id(self.id)
    panel:rebuild()

    self.panel = panel

    return panel
  end
end
