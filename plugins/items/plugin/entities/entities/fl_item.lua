AddCSLuaFile()

ENT.Type = 'anim'
ENT.PrintName = 'Item'
ENT.Category = 'Flux'
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

if SERVER then
  function ENT:Initialize()
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetUseType(ONOFF_USE)

    local phys_obj = self:GetPhysicsObject()

    if IsValid(phys_obj) then
      phys_obj:EnableMotion(true)
      phys_obj:Wake()
    end
  end

  function ENT:Use(activator, caller, use_type, value)
    local last_activator = self:get_nv('last_activator')

    -- prevent minge-grabbing glitch
    if IsValid(last_activator) and last_activator != activator then return end

    local hold_start = activator:get_nv('hold_start')

    if use_type == USE_ON then
      if !hold_start then
        activator:set_nv('hold_start', CurTime())
        activator:set_nv('hold_entity', self)
        self:set_nv('last_activator', activator)
      end
    elseif use_type == USE_OFF then
      if !hold_start then return end

      if CurTime() - hold_start < 0.5 then
        if IsValid(caller) and caller:IsPlayer() then
          if self.item then
            hook.run('PlayerUseItemEntity', caller, self, self.item)
          else
            Flux.dev_print('Player attempted to use an item entity without item object tied to it!')
          end
        end
      end

      activator:set_nv('hold_start', false)
      activator:set_nv('hold_entity', false)
      self:set_nv('last_activator', false)
    end
  end

  function ENT:Think()
    local last_activator = self:get_nv('last_activator')

    if !IsValid(last_activator) then return end

    local hold_start = last_activator:get_nv('hold_start')

    if hold_start and CurTime() - hold_start > 0.5 then
      if self.item then
        self.item:do_menu_action('on_take', last_activator)
      end

      last_activator:set_nv('hold_start', false)
      last_activator:set_nv('hold_entity', false)
      self:set_nv('last_activator', false)
    end
  end

  function ENT:set_item(item_obj)
    if !item_obj then return false end

    hook.run('PreEntityItemSet', self, item_obj)

    self:SetModel(item_obj:get_model())
    self:SetSkin(item_obj:get_skin())
    self:SetColor(item_obj:get_color())

    self.item = item_obj

    Item.network_entity_data(nil, self)

    hook.run('OnEntityItemSet', self, item_obj)
  end
else
  function ENT:Draw()
    self:DrawModel()
  end

  function ENT:DrawTargetID(x, y, distance)
    if distance > 150 then return end

    local text = 'ERROR'
    local desc = 'Meow probably broke it again'
    local alpha = self.alpha or 255

    if distance > 100 then
      local d = distance - 100
      alpha = math.Clamp(255 * (50 - d) / 50, 0, 255)
    end

    local col = Color(255, 255, 255, alpha)
    local col2 = Color(0, 0, 0, alpha)

    if self.item then
      if hook.run('PreDrawItemTargetID', self, self.item, x, y, alpha, distance) == false then
        return
      end

      text = t(self.item:get_name())
      desc = t(self.item:get_description())
    else
      if !self.data_requested then
        Cable.send('fl_items_data_request', self:EntIndex())
        self.data_requested = true
      end

      Flux.draw_rotating_cog(x, y - 48, 48, 48, Color(255, 255, 255))

      return
    end

    local name_font = Theme.get_font('tooltip_large')
    local desc_font = Theme.get_font('tooltip_small')
    local width, height = util.text_size(text, name_font)
    local max_width = width
    local desc_height = 0
    local wrapped = util.wrap_text(desc, desc_font, ScrW() * 0.33, 0)

    for k, v in pairs(wrapped) do
      local w, h = util.text_size(v, desc_font)

      desc_height = desc_height + h

      if w > max_width then
        max_width = w
      end
    end

    local box_x, box_y = x - max_width * 0.5 - 8, y - 8
    local box_width, box_height = max_width + 16, height + desc_height + 16
    local accent_color = Theme.get_color('accent'):alpha(200)
    local ent_pos = self:GetPos():ToScreen()
    local anim_id = 'itemid_gradient_'..self.item.instance_id

    Flux.register_animation(anim_id, box_x - max_width, nil, FrameTime() * 8)

    render.SetScissorRect(box_x, box_y, box_x + box_width, box_y + box_height, true)
      Flux.draw_animation(anim_id, alpha > 150 and box_x or box_x - max_width, box_y, function(x, y)
        draw.textured_rect(Theme.get_material('gradient'), alpha > 240 and box_x or x, y, box_width, box_height, accent_color)
      end)
    render.SetScissorRect(0, 0, 0, 0, false)

    if alpha > 100 then
      draw.line(box_x, y + height + desc_height + 8, ent_pos.x, ent_pos.y, accent_color)
    end

    draw.SimpleTextOutlined(text, name_font, x - width * 0.5, y, col, nil, nil, 1, col2)

    y = y + 26

    for k, v in pairs(wrapped) do
      local w, h = util.text_size(v, desc_font)

      draw.SimpleTextOutlined(v, desc_font, x - w * 0.5, y, col, nil, nil, 1, col2)

      y = y + h
    end

    hook.run('PostDrawItemTargetID', self, self.item, x, y, alpha, distance)
  end
end
