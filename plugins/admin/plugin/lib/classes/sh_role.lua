class 'Role'

Role.name = 'Undefined'
Role.description = 'Undefined'
Role.color = Color(255, 255, 255)
Role.icon = 'icon16/user.png'
Role.immunity = 0
Role.protected = false
Role.base = nil

function Role:init(id)
  if !id then return end

  self.role_id = id:to_id()
  self.permissions = {}
end

function Role:allow(action, object, callback)
  object = (istable(object) and object.class_name) or
        (isstring(object) and object) or
        'anything'

  local perm = self.permissions[object] or {}
  perm[action] = {
    callback = callback,
    allowed = true
  }

  self.permissions[object] = perm
end

function Role:disallow(action, object)
  object = (istable(object) and object.class_name) or
        (isstring(object) and object) or
        'anything'

  local perm = self.permissions[object] or {}

  perm[action] = {
    allowed = false
  }

  self.permissions[object] = perm
end

function Role:allow_anything()
  self.can_anything = true
end

function Role:can(player, action, object)
  if self.can_anything then return true end
  if action == '' then return true end

  local permissions = self.permissions[object or 'anything']

  if permissions then
    local perm = permissions[action]

    if perm then
      if perm.callback then
        return perm.callback(player, object)
      else
        return perm and perm.allowed
      end
    end
  end

  return false
end

-- Called when player's role is being set to this role.
function Role:on_role_set(player, old_group) end

-- Called when player's role is taken or modified.
function Role:on_role_taken(player, new_group) end

Role.set_parent = Role.set_base

function Role:get_id()
  return self.role_id
end

function Role:get_name()
  return self.name or 'Unknown'
end

function Role:get_description()
  return self.description or 'This group has no description'
end

function Role:get_color()
  return self.color or Color('white')
end

function Role:get_immunity()
  return self.immunity or 0
end

function Role:is_protected()
  return self.protected or false
end

function Role:get_permissions()
  return self.permissions or {}
end

function Role:get_icon()
  return self.icon or 'icon16/user.png'
end

function Role:get_base()
  return self.base or nil
end

function Role:register()
  if self.define_permissions then
    local old_can, old_cannot, old_anything = can, cannot, allow_anything
      function can(action, object, callback)
        self:allow(action, object, callback)
      end
      function cannot(action, object)
        self:disallow(action, object)
      end
      function allow_anything(action, object, callback)
        self:allow_anything(action, object)
      end
      self:define_permissions()

      hook.run('OnDefinePermissions', self)

    can, cannot, allow_anything = old_can, old_cannot, old_anything
  end

  Bolt:create_role(self.role_id, self)
end

Role.get_parent = Role.get_base
