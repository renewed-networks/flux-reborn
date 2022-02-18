if ActiveNetwork then return end

mod 'ActiveNetwork'

local stored = ActiveNetwork.stored or {}
local globals = ActiveNetwork.globals or {}
ActiveNetwork.stored = stored
ActiveNetwork.globals = globals

local ent_meta = FindMetaTable('Entity')
local player_meta = FindMetaTable('Player')

-- A function to check if value's type cannot be serialized and print an error if it is so.
local function is_bad_type(key, val)
  if isfunction(val) then
    error_with_traceback('Cannot network functions! ('..key..')')
    return true
  end

  return false
end

-- A function to get a networked global.
function ActiveNetwork.get_nv(key, default)
  if globals[key] != nil then
    return globals[key]
  end

  return default
end

-- A function to set a networked global.
function ActiveNetwork.set_nv(key, value, send)
  if is_bad_type(key, value) then return end
  if ActiveNetwork.get_nv(key) == value then return end

  globals[key] = value

  Cable.send(send, 'fl_netvar_global_set', key, value)
end

-- A function to send entity's networked variables to a player (or players).
function ent_meta:send_net_var(key, recv)
  Cable.send(recv, 'fl_netvar_set', self:EntIndex(), key, (stored[self] and stored[self][key]))
end

-- A function to get entity's networked variable.
function ent_meta:get_nv(key, default)
  if stored[self] and stored[self][key] != nil then
    return stored[self][key]
  end

  return default
end

-- A function to flush all entity's networked variables.
function ent_meta:clear_net_vars(recv)
  stored[self] = nil
  Cable.send(recv, 'fl_netvar_delete', self:EntIndex())
end

-- A function to set entity's networked variable.
function ent_meta:set_nv(key, value, send)
  if is_bad_type(key, value) then return end
  if !istable(value) and self:get_nv(key) == value then return end

  stored[self] = stored[self] or {}
  stored[self][key] = value

  self:send_net_var(key, send)
end

-- A function to send all current networked globals and entities' variables
-- to a player.
function player_meta:sync_nv()
  for k, v in pairs(globals) do
    Cable.send(self, 'fl_netvar_global_set', k, v)
  end

  for k, v in pairs(stored) do
    if IsValid(k) then
      for k2, v2 in pairs(v) do
        Cable.send(self, 'fl_netvar_set', k:EntIndex(), k2, v2)
      end
    end
  end
end
