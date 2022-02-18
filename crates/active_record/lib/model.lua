class 'ActiveRecord::Model'

ActiveRecord.Model.models = {}

function ActiveRecord.Model:add(model)
  self.models[model.class_name] = model
  return self
end

function ActiveRecord.Model:all()
  return self.models
end

function ActiveRecord.Model:generate_helpers(model, column, type)
  model['find_by_'..column] = function(obj, value, callback)
    return obj:find_by(column, value, callback)
  end
end

function ActiveRecord.Model:populate()
  for k, v in pairs(self.models) do
    local schema = ActiveRecord.schema[v.table_name]

    if schema then
      for column, data in pairs(schema) do
        if !isstring(column) or !istable(data) then continue end

        self:generate_helpers(v, column, data.type)
      end

      v.schema = schema
    end
  end
  return self
end
