-- Credit: https://github.com/douglascrockford/monad

local M = {}

function M.new(modifier)
  local proto = {is_monad=true}

  local unit = {}

  local function unit_call(self, value)
    local monad = {}
    setmetatable(monad, {__index = proto})
    monad.bind = function(func, name, ...)
      func(value, ...)
    end
    -- Using this function is a cop-out
    monad.get = function()
      return value
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
    proto[name] = function(self, ...)
      return self.bind(func, name, ...)
    end
    return unit
  end

  unit.lift = function(name, func)
    proto[name] = function(self, ...)
      local result = self.bind(func, name, ...)
      if type(result) == 'table' and result.is_monad then
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
      monad.get = function() error('Maybe monad is empty') end
    else
      monad.is_nil = false
    end
    return value
  end)

  return maybe
end

function M.Either()
  local either = M.new(function(monad, value)
    monad.is_error = false
    monad.bind = function(func, name, ...)
      if (name == 'catch') ~= monad.is_error then
        return monad
      else
        return func(value, ...)
      end
    end
    -- Using this function is a cop-out
    monad.get = function()
      if monad.is_error then
        -- Can't get value when monad is error, so raise the error
        error(value)
      else
        return value
      end
    end
    return value
  end)

  either.lift('catch', function(value, callback)
    callback(value)
  end)

  either.lift('and_then', function(value, callback)
    callback(value)
  end)

  function either.error(value)
    local monad = either(value)
    monad.is_error = true
    return monad
  end

  return either
end

return M
