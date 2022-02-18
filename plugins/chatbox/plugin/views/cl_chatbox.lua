local PANEL = {}
PANEL.history = {}
PANEL.last_pos = 0
PANEL.is_open = false
PANEL.padding = Theme.get_option('chatbox_padding', math.scale(8))

function PANEL:Init()
  local w, h = self:GetWide(), self:GetTall()

  self.scroll_panel = vgui.Create('DScrollPanel', self)

  self.scroll_panel.Paint = function() return true end
  self.scroll_panel:GetVBar().Paint = function() return true end
  self.scroll_panel:GetVBar().btnUp.Paint = function() return true end
  self.scroll_panel:GetVBar().btnDown.Paint = function() return true end
  self.scroll_panel:GetVBar().btnGrip.Paint = function() return true end

  self.scroll_panel:GetVBar():SetWide(0)

  self.scroll_panel:SetPos(0, 0)
  self.scroll_panel:SetSize(w, h)
  self.scroll_panel:PerformLayout()

  self.text_entry = vgui.Create('fl_text_entry', self)
  self.text_entry:SetText('')
  self.text_entry:SetSize(1, 1)
  self.text_entry:set_limit(Config.get('max_message_length', 512))
  self.text_entry.history = {}
  self.text_entry.last_index = 0
  self.text_entry:SetMultiline(true)

  self.text_entry.OnValueChange = function(entry, value)
    local value_w, value_h = util.text_size(value, entry:GetFont())
    local div = math.round(entry:GetWide() / value_w * 2, 1)
    local offset = div > 2 and 0 or div > 1 and math.scale(25) or math.scale(50)

    self:SetSize(Chatbox.width, Chatbox.height + offset)
    entry:SetTall(Theme.get_option('chatbox_text_entry_height', 40) + offset)

    hook.run('ChatTextChanged', value)
  end

  self.text_entry.OnEnter = function(entry)
    local value = entry:GetValue()

    hook.run('ChatboxTextEntered', value)

    if entry.history[1] != value then
      table.insert(entry.history, 1, value)

      entry.last_index = 1
    end

    entry:SetText('')
    self:rebuild()
  end

  self.text_entry.OnKeyCodeTyped = function(entry, code)
    local should_set = false

    if code == KEY_ENTER then
      entry:OnEnter()

      return true
    elseif code == KEY_DOWN then
      if entry.last_index == 1 then
        entry.last_index = #entry.history
      else
        entry.last_index = math.Clamp(entry.last_index - 1, 1, #entry.history)
      end

      should_set = true
    elseif code == KEY_UP then
      if entry.last_index == #entry.history then
        entry.last_index = 1
      else
        entry.last_index = math.Clamp(entry.last_index + 1, 1, #entry.history)
      end

      should_set = true
    end

    local history_entry = entry.history[entry.last_index]

    if history_entry and history_entry != '' and should_set then
      entry:SetText(history_entry)
      entry:SetCaretPos(utf8.len(history_entry))
      entry:OnValueChange(history_entry)

      return true
    end
  end

  self.text_entry.Paint = function(entry, w, h)
    local offset = math.scale(4)

    DisableClipping(true)
      draw.rounded_box(offset * 2, 0, -offset, w, h + offset, Theme.get_color('chat_text_entry_background'))
    DisableClipping(true)

    entry:DrawTextEntryText(Theme.get_color('text'), Theme.get_color('accent'), Theme.get_color('text'))
  end

  self:rebuild()
end

function PANEL:Think()
  if self.is_open then
    if input.IsKeyDown(KEY_ESCAPE) then
      Chatbox.hide()

      if gui.IsGameUIVisible() then
        gui.HideGameUI()
      end
    end
  else
    self.scroll_panel:GetVBar():SetScroll(self.scroll_panel:GetVBar().CanvasSize)
  end
end

function PANEL:Paint(w, h)
  if self.is_open then
    Theme.hook('ChatboxPaintBackground', self, w, h)
  end
end

function PANEL:PaintOver(width, height)
  if Theme.hook('ChatboxPaintOver', self, width, height) == nil then
    local entry = self.text_entry

    if IsValid(entry) then
      local val = entry:GetValue()
      local is_command, prefix_len = string.is_command(val)

      if is_command then
        local space = string.find(val, ' ')
        local endpos = space

        if !endpos then
          endpos = (string.len(val) + 1)
        end

        local cmd = string.utf8lower(string.sub(val, prefix_len + 1, endpos - 1))
        local cmds = {}

        if cmd == '' or cmd == ' ' then return end

        if !space then
          cmds = Flux.Command:find_all(cmd)
        else
          local found = Flux.Command:find_by_id(cmd)

          if found then
            table.insert(cmds, found)
          end
        end

        draw.RoundedBox(0, 0, 0, width, height - entry:GetTall(), Color(0, 0, 0, 150))

        local font, color = Theme.get_font('text_normal'), Theme.get_color('accent')

        if #cmds > 0 then
          local last_y = 0
          local color_white = Color(255, 255, 255)

          for k, v in ipairs(cmds) do
            local w, h = draw.SimpleTextOutlined('/' + v.name, font, 16, 16 + last_y, color, nil, nil, 0.5, color_black)
            w, h = draw.SimpleTextOutlined(t(v.syntax), font, 16 + w + 8, 16 + last_y, color_white, nil, nil, 0.5, color_black)

            if #cmds == 1 then
              local cur_y = 20 + h
              local small_font = Theme.get_font('text_small')
              local desc = t(v:get_description())
              local wrapped = util.wrap_text(desc, small_font, width, 16)

              for k1, v1 in pairs(wrapped) do
                local text_w, text_h = draw.SimpleTextOutlined(v1, small_font, 16, cur_y, color_white, nil, nil, 0.5, color_black)

                cur_y = cur_y + text_h + math.scale(2)
              end

              local aliases = '[-]'

              if v.aliases and #v.aliases > 0 then
                aliases = table.concat(v.aliases or {}, ', ')
              end

              draw.SimpleTextOutlined(t'ui.chat.aliases'..': ' + aliases, small_font, 16, cur_y, color_white, nil, nil, 0.5, color_black)
            end

            last_y = last_y + h + 8

            if k >= 10 then break end
          end
        else
          draw.SimpleTextOutlined(t'ui.chat.no_commands_found', font, 16, 16, color, nil, nil, 0.5, color_black)
        end
      end
    end
  end
end

function PANEL:set_open(is_open)
  self.is_open = is_open

  if is_open then
    self:MakePopup()

    self.text_entry:SetVisible(true)
    self.text_entry:RequestFocus()
    self.text_entry.last_index = 0
  else
    if self.text_entry:GetValue():is_command() then
      self.text_entry:SetText('')
    end

    self:KillFocus()

    self.text_entry:SetVisible(false)
  end

  for k, v in ipairs(self.history) do
    if IsValid(v) then
      v.force_show = is_open
    end
  end
end

function PANEL:typing_command()
  if IsValid(self.text_entry) then
    local cmd = self.text_entry:GetValue()

    if cmd != '/' then
      return cmd:is_command()
    end
  end
end

function PANEL:create_message(message_data)
  local parsed = Chatbox.compile(message_data)

  if !parsed then return end

  local panel = vgui.Create('fl_chat_message', self)
  local half_padding = self.padding * 0.5

  panel:SetSize(self:GetWide() - self.padding * 2, self:GetWide() - self.padding * 2) -- Width is placeholder and is later set by compiled message table.
  panel:set_message(parsed)

  if self.is_open then
    panel.force_show = true
  end

  return panel
end

function PANEL:add_message(message_data)
  if message_data and Plugin.call('ChatboxShouldAddMessage', message_data) != false then
    local panel = self:create_message(message_data)

    if IsValid(panel) then
      self:add_panel(panel)

      timer.Simple(0.05, function()
        local scroll = self.scroll_panel
        local value = panel:GetTall() + self.padding

        if scroll:GetCanvas():GetTall() - scroll:GetTall() - scroll:GetVBar():GetScroll() <= value then
          self.scroll_panel:GetVBar():AddScroll(value)
        end
      end)
    end
  end
end

function PANEL:rebuild_history_indexes()
  local new_history = {}

  for k, v in ipairs(self.history) do
    if IsValid(v) then
      local idx = table.insert(new_history, v)
      v.msg_index = idx
    end
  end

  self.history = new_history
  self:rebuild()
end

function PANEL:add_panel(panel)
  if #self.history >= Config.get('max_messages') then
    local last_history = self.history[1]

    if IsValid(last_history) then
      last_history:eject()
    else
      self:rebuild_history_indexes()
    end
  end

  local idx = table.insert(self.history, panel)

  panel:SetPos(self.padding, self.last_pos)
  panel.msg_index = idx

  self.scroll_panel:AddItem(panel)
  self.scroll_panel:GetVBar():AnimateTo(self.last_pos, 1, 0, -1)

  self.last_pos = self.last_pos + Config.get('message_margin') + panel:GetTall()
end

function PANEL:remove_message(idx)
  table.remove(self.history, idx)
  self:rebuild_history_indexes()
end

function PANEL:rebuild()
  self:SetSize(Chatbox.width, Chatbox.height)
  self:SetPos(Chatbox.x, Chatbox.y)

  local text_entry_height = Theme.get_option('chatbox_text_entry_height', 40)

  self.text_entry:SetSize(Chatbox.width, text_entry_height)
  self.text_entry:SetPos(0, Chatbox.height - text_entry_height)
  self.text_entry:SetFont(Theme.get_font('chatbox_text_entry'))
  self.text_entry:SetTextColor(Theme.get_color('text'))
  self.text_entry:RequestFocus()

  self.scroll_panel:SetSize(Chatbox.width, Chatbox.height - self.text_entry:GetTall() - 16)
  self.scroll_panel:PerformLayout()
  self.scroll_panel:GetVBar():SetScroll(self.scroll_panel:GetVBar().CanvasSize or 0)

  self.last_pos = 0

  for k, v in ipairs(self.history) do
    if IsValid(v) then
      v:SetPos(self.padding, self.last_pos)

      self.last_pos = self.last_pos + Config.get('message_margin') + v:GetTall()
    end
  end
end

vgui.Register('fl_chat_panel', PANEL, 'fl_base_panel')
