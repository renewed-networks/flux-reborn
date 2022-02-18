local PANEL = {}

function PANEL:Init()
  self:SetSize(ScrW(), ScrH())
  self:SetPos(0, 0)

  self:start_animation()

  timer.Simple(4, function()
    self:close_menu()
  end)

  hook.run('OnIntroPanelCreated', self)
end

local logo_w, logo_h = math.scale(800), math.scale(150)
local logo_data = {
  width = logo_w,
  height = logo_h,
  x = 0,
  y = 0
}
local w_mod, h_mod = 6, 1.1
local cur_radius, cur_alpha = 0, 0
local exx, exy = 0, 0
local color = Color(140, 0, 220)
local remove_alpha = 255
local delta_modifier = 80
local logo_tween = Tween.new(1.5, logo_data, { width = logo_w * 0.6, height = logo_h * 0.6 }, 'inOutCubic')

function PANEL:Paint(w, h)
  local frame_time = FrameTime()

  logo_tween:update(frame_time)

  draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, remove_alpha))

  draw.textured_rect(
    util.get_material('materials/flux/tc_logo.png'),
    w * 0.5 - logo_data.width * 0.5,
    h * 0.5 - logo_data.height * 0.5,
    logo_data.width,
    logo_data.height,
    Color(255, 255, 255, remove_alpha)
  )

  if self.started then
    if self.should_remove then
      self:MoveToFront()

      remove_alpha = math.Clamp(remove_alpha - 3, 0, 255)
    end

    if !self.should_remove then
      if logo_data.width < logo_w * 0.7 then
        local cx, cy = ScrC()
        exx, exy = cx, cy

        if cur_alpha == 0 then
          cur_alpha = 255

          sound.PlayFile('sound/ambient/machines/thumper_hit.wav', 'noplay noblock', function(channel, error, err_string)
            if channel then
              channel:SetVolume(0.5)
              channel:Play()
            end
          end)
        end

        surface.SetDrawColor(color.r, color.g, color.b, cur_alpha)
        surface.draw_circle(exx, exy, cur_radius, 180)

        cur_radius = cur_radius + 3
        cur_alpha = math.Clamp(Lerp(frame_time * 8, cur_alpha, 1), 0, 255)
      end
    end
  end
end

function PANEL:close_menu()
  self.should_remove = true

  timer.Simple(1, function()
    self:Remove()
  end)

  hook.run('OnIntroPanelRemoved')
end

function PANEL:start_animation()
  timer.Simple(0.6, function()
    self.started = true
  end)
end

derma.DefineControl('fl_intro', '', PANEL, 'EditablePanel')
