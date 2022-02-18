class 'ActiveRecord::Schema' extends 'ActiveRecord::Migration'

function ActiveRecord.Schema:init(version)
  self.version = version
end

function ActiveRecord.Schema:define(version)
  return ActiveRecord.Schema.new(version)
end

function ActiveRecord.Schema:create_tables()
  return self
end

function ActiveRecord.Schema:setup_references()
  local references = {}
  local is_sqlite = ActiveRecord.adapter_name == 'sqlite'

  for key, model in pairs(ActiveRecord.Model:all()) do
    for k, v in ipairs(model.relations) do
      if !v.child then
        references[v.table_name] = references[v.table_name] or {}
        references[v.table_name][v.column_name] = model.table_name
      end
    end
  end

  for k, v in pairs(references) do
    for k2, v2 in pairs(v) do
      if !is_sqlite then
        create_reference({ table_name = k, key = k2, foreign_table = v2, foreign_key = 'id', cascade = true })
      else
        add_index { k, k2 } -- only add index if SQLite
      end
    end
  end
end
