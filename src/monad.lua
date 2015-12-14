-- Credit: https://github.com/douglascrockford/monad

M = {}

function M.new(modifier)
  local proto = {is_monad=true}

  local unit = {}

  local function unit_call(self, value)
    local monad = {}
    setmetatable(monad, {__index = proto})
    monad.bind = function(func)
      func(value)
    end
    if modifier ~= nil then
      value = modifier(monad, value)
    end
    return monad
  end
  setmetatable(unit, {__call = unit_call})

  unit.method = function(name, func)
    proto[name] = func
    return unit
  end

  unit.lift_value = function(name, func)
    proto[name] = function(self)
      return self.bind(func)
    end
    return unit
  end

  unit.lift = function(name, func)
    proto[name] = function(self)
      local result = self.bind(func)
      if result and result.is_monad then
        return result
      else
        return unit(result)
      end
    end
    return unit
  end

  return unit
end

function M.Maybe()
  local maybe = M.new(function(monad, value)
    if value == nil then
      monad.is_nil = true
      monad.bind = function() return monad end
    else
      monad.is_nil = false
    end
    return value
  end)

  return maybe
end

return M
