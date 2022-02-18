class 'Faction'

function Faction:init(id)
  if !id then return end

  self.faction_id = id:to_id()
  self.name = 'Unknown Faction'
  self.description = 'This faction has no description set!'
  self.phys_desc = 'This faction has no default physical description set!'
  self.whitelisted = false
  self.default_class = nil
  self.color = Color(255, 255, 255)
  self.material = nil
  self.has_name = true
  self.has_description = true
  self.has_gender = true
  self.model_classes = { male = 'player', female = 'player', universal = 'player'}
  self.models = { male = {}, female = {}, universal = {} }
  self.rank = {}
  self.data = {}
  self.name_template = '{rank} {name}'
  -- You can also use {data:key} to insert data
  -- set via Faction:set_data.
end

function Faction:get_name()
  return self.name
end

function Faction:get_color()
  return self.color
end

function Faction:get_material()
  return self.material and util.get_material(self.material)
end

function Faction:get_image()
  return self.material
end

function Faction:get_name()
  return self.name
end

function Faction:get_data(key)
  return self.data[key]
end

function Faction:get_description()
  return self.description
end

function Faction:get_ranks()
  return self.rank
end

function Faction:get_rank(number)
  return self.rank[number]
end

function Faction:get_rank_name(number)
  return self:get_rank(number).id
end

function Faction:get_models()
  return self.models
end

function Faction:get_gender_models(gender)
  local faction_models = self:get_models()

  if gender == 'no_gender' or !faction_models[gender] or #faction_models[gender] == 0 then
    gender = 'universal'
  end

  return faction_models[gender]
end

function Faction:get_random_model(player)
  return table.random(self:get_gender_models(player:get_gender()))
end

function Faction:add_rank(id, name_filter)
  if !id then return end

  if !name_filter then name_filter = id end

  table.insert(self.rank, {
    id = id,
    name = name_filter
  })
end

function Faction:generate_name(player, rank, default_data)
  local char_name = player:name()

  default_data = default_data or {}

  if hook.run('ShouldNameGenerate', player, self, char_name, rank, default_data) == false then return player:name() end

  if isfunction(self.make_name) then
    return self:make_name(player, char_name, rank, default_data) or 'John Doe'
  end

  local final_name = self.name_template

  if final_name:find('{name}') then
    final_name = final_name:Replace('{name}', char_name or '')
  end

  if final_name:find('{rank}') then
    for k, v in ipairs(self.rank) do
      if v.id == rank or k == rank then
        final_name = final_name:replace('{rank}', v.name)

        break
      end
    end
  end

  local helpers = string.find_all(final_name, '{([%w_]+):([%w_]+)}')

  for k, v in ipairs(helpers) do
    local m1, m2 = v.matches[1], v.matches[2]

    if m1 == 'callback' then
      local callback = self[m2]

      if isfunction(callback) then
        final_name = final_name:replace(v.text, callback(self, player))
      end
    elseif m1 == 'data' then
      local data = default_data[m2] or self.data[m2] or ''

      if isstring(data) then
        final_name = final_name:replace(v.text, data)
      end
    end
  end

  return final_name
end

function Faction:set_data(key, value)
  key = tostring(key)

  if !key then return end

  self.data[key] = tostring(value)
end

function Faction:on_player_join(player)
end

function Faction:on_player_leave(player)
end

function Faction:register()
  Factions.add_faction(self.faction_id, self)
end
