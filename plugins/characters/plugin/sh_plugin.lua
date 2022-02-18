PLUGIN:set_global('Characters')

require_relative 'cl_hooks'
require_relative 'sv_plugin'
require_relative 'sv_hooks'
require_relative 'sh_enums'

function Characters:RegisterConditions()
  Conditions:register_condition('character', {
    name = 'condition.character.name',
    text = 'condition.character.text',
    get_args = function(panel, data)
      local operator = util.operator_to_symbol(panel.data.operator) or ''
      local character_id = panel.data.character_id or ''

      return { operator = operator, character = character_id }
    end,
    icon = 'icon16/user.png',
    check = function(player, data)
      if !data.operator or !data.character_id then return false end

      return util.process_operator(data.operator, player:get_character_id(), data.character_id)
    end,
    set_parameters = function(id, data, panel, menu, parent)
      parent:create_selector(data.name, 'condition.character.message', 'condition.characters', player.all(),
      function(selector, player)
        if player:is_character_loaded() then
          selector:add_choice(player:name(), function()
            panel.data.character_id = player:get_character_id()

            panel.update()
          end)
        end
      end)
    end,
    set_operator = 'equal'
  })
end
