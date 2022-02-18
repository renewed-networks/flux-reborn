PLUGIN:set_name('Flux Dev HUD')
PLUGIN:set_author('TeslaCloud Studios')
PLUGIN:set_description('Adds developer HUD.')

function PLUGIN:HUDPaint()
  if Flux.development then
    if hook.run('HUDPaintDeveloper') == nil then
      local flow_version = (Flow and Flow.__crate__ and Flow.__crate__.version) or 'UNKNOWN'
      draw.SimpleText('Flux version '..(GAMEMODE.version or 'UNKNOWN')..'. Core version '..flow_version..'.', 'default', 8, ScrH() - 18, Color(200, 100, 100, 200))
    end
  end
end
