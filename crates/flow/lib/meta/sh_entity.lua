local ent_meta = FindMetaTable('Entity')

--[[
  We store the original function here so we can override it from the player metaTable,
  which derives from the entity metaTable. This way we don't have to check if the entity is
  player every time the function is called.
--]]
ent_meta.flSetModel = ent_meta.flSetModel or ent_meta.SetModel

function ent_meta:stuck()
  local pos = self:GetPos()

  local trace = util.TraceHull({
    start = pos,
    endpos = pos,
    filter = self,
    mins = self:OBBMins(),
    maxs = self:OBBMaxs()
  })

  return trace.Entity and (trace.Entity:IsWorld() or trace.Entity:IsValid())
end

function ent_meta:is_door()
  if IsValid(self) then
    local class = self:GetClass():lower()

    if class and class:find('door') or
    class == 'prop_dynamic' and self:GetModel():lower():find('door') or
    class == 'func_movelinear' then
      return true
    end
  end

  return false
end

do
  local idle_anims = {
    'idle01',
    'idle_subtle',
    'batonidle1',
    'idle_unarmed'
  }

  function ent_meta:idle_animation()
    for k, v in pairs(idle_anims) do
      local seq = self:LookupSequence(v)

      if seq > 0 then
        return seq
      end
    end

    return ACT_IDLE
  end
end

function ent_meta:bodygroups()
  local bodygroups = {}

  for i = 0, self:GetNumBodyGroups() do
    bodygroups[i] = self:GetBodygroup(i)
  end

  return bodygroups
end

function ent_meta:set_bodygroups(bodygroups)
  for k, v in pairs(bodygroups) do
    self:SetBodygroup(k, v)
  end
end

function ent_meta:facing(entity)
  local aim_vector = self:GetAimVector():Angle()
  local target_aim_vector = entity:GetAimVector():Angle()

  return math.abs(aim_vector.y - target_aim_vector.y) > 50
end

function ent_meta:get_name()
  return self:IsPlayer() and (hook.run('GetPlayerName', self) or self:name())
  or hook.run('GetEntityName', self) or tostring(self) or self:GetClass()
end

function ent_meta:get_hitgroup_from_pos(pos)
  for i = 0, self:GetHitBoxGroupCount() - 1 do
    for k = 0, self:GetHitBoxCount(i) - 1 do
      local mins, maxs = self:GetHitBoxBounds(k, i)
      local bone_pos = self:GetBonePosition(self:GetHitBoxBone(k, i))

      mins = bone_pos + mins
      maxs = bone_pos + maxs

      if pos:WithinAABox(mins, maxs) then
        return k
      end
    end
  end

  return HITGROUP_GENERIC
end
