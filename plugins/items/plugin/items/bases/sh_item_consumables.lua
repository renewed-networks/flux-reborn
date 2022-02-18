if !ItemUsable then
  require_relative 'sh_item_usable'
end

class 'ItemConsumable' extends 'ItemUsable'

ItemConsumable.name = 'Consumables Base'
ItemConsumable.description = 'An item that can be consumed.'
ItemConsumable.category = 'item.category.consumables'

function ItemConsumable:on_use(player)
  if hook.run('PrePlayerConsumeItem', player, self) != false then
    hook.run('PlayerConsumeItem', player, self)
  end
end
