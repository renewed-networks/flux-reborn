ActiveRecord.define_model('whitelists', function(t)
  t:string 'faction_id'
  t:integer 'user_id'
end)

add_column('characters', { 'faction', type = 'string', default = '\'player\'' })
add_column('characters', { 'rank', type = 'integer', null = true })
