ActiveRecord.Adapters = ActiveRecord.Adapters or {}

class 'ActiveRecord::Adapters::Abstract'

ActiveRecord.Adapters.Abstract._queue = {}
ActiveRecord.Adapters.Abstract._connected = false
ActiveRecord.Adapters.Abstract._sync = false
ActiveRecord.Adapters.Abstract._sql_syntax = 'abstract'

function ActiveRecord.Adapters.Abstract:init()
  self._connected = false
  self._sync = false
  self._queue = {}
end

function ActiveRecord.Adapters.Abstract:sync(sync)
  self._sync = sync
  return self
end

function ActiveRecord.Adapters.Abstract:get_sql_std()
  return self._sql_syntax
end

function ActiveRecord.Adapters.Abstract:is_postgres()
  return false
end

function ActiveRecord.Adapters.Abstract:is_mysql()
  return false
end

function ActiveRecord.Adapters.Abstract:is_sqlite()
  return false
end

function ActiveRecord.Adapters.Abstract:connect(config, on_connected)
  self._connected = true
end

function ActiveRecord.Adapters.Abstract:disconnect(config)
  self._connected = false
end

function ActiveRecord.Adapters.Abstract:escape(str)
  return str
end

function ActiveRecord.Adapters.Abstract:unescape(str)
  return str
end

function ActiveRecord.Adapters.Abstract:quote(str)
  return "'"..self:escape(str).."'"
end

function ActiveRecord.Adapters.Abstract:quote_name(str)
  return str
end

function ActiveRecord.Adapters.Abstract:raw_query(query, callback, query_type)
end

function ActiveRecord.Adapters.Abstract:queue(query, callback, query_type)
  if isstring(query) then
    table.insert(self._queue, { query, callback, query_type })
  end
end

function ActiveRecord.Adapters.Abstract:append_query(query, query_type, queue)
end

function ActiveRecord.Adapters.Abstract:append_query_string(query, query_string, query_type)
end

function ActiveRecord.Adapters.Abstract:create_column(query, column, args, obj, type, def)
end

function ActiveRecord.Adapters.Abstract:think()
  if #self._queue > 0 then
    if istable(self._queue[1]) then
      local queue_obj = self._queue[1]
      local query_string = queue_obj[1]

      if isstring(query_string) then
        self:raw_query(query_string, queue_obj[2], queue_obj[3])
      end

      table.remove(self._queue, 1)
    end
  end
end

function ActiveRecord.Adapters.Abstract:is_result(result)
  return istable(result) and #result > 0
end

-- Called when the Database connects sucessfully.
function ActiveRecord.Adapters.Abstract:on_connected()
  self._connected = true
  self:sync(true)

  ActiveRecord.on_connected()
  hook.run('DatabaseConnected')

  self:sync(false)
end

-- Called when the Database connection fails.
function ActiveRecord.Adapters.Abstract:on_connection_failed(error_text)
  ErrorNoHalt('ActiveRecord - Unable to connect to the database!\n'..error_text..'\n')

  if error_text:find('does not exist') and !self:is_sqlite() then
    ErrorNoHalt('HINT:\ntry running "flux db:create" to create the databases.\n\n')
  end

  hook.run('DatabaseConnectionFailed', error_text)
end

-- A function to check whether or not the module is connected to a Database.
function ActiveRecord.Adapters.Abstract:connected()
  return self._connected
end
