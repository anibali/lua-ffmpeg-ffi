-- Some code is based on https://github.com/douglascrockford/monad

local M = {}

function M.new(modifier)
  local proto = {}

  local unit = {}

  local function unit_call(self, value)
    local monad = {is_monad=true}
    setmetatable(monad, {__index = proto})
    monad.bind = function(func, ...)
      func(value, ...)
    end
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
      return self.bind(func, ...)
    end
    return unit
  end

  unit.lift = function(name, func)
    proto[name] = function(self, ...)
      local result = self.bind(func, ...)
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
  return M.new(function(monad, value)
    if value == nil then
      monad.is_nil = true
      monad.bind = function() return monad end
      monad.get = function() error('Maybe monad is empty') end
    else
      monad.is_nil = false
    end
    return value
  end)
end

-- Expected usage:
--    return_value_or_error_monad(make_error_monad, pcall(func, ...))
local function return_value_or_error_monad(make_error_monad, ok, err, ...)
  if ok then
    return err, ...
  else
    return make_error_monad(debug.traceback(err, 3))
  end
end

function M.Error()
  return M.new(function(monad, value)
    monad.bind = function(func, ...)
      return return_value_or_error_monad(M.Error(), pcall(func, value, ...))
    end
    monad.get = function()
      error('Cannot get value because an error occurred: ' .. tostring(value))
    end
    monad.catch = function(self, callback)
      local result = self.bind(callback)
      if type(result) == 'table' and result.is_monad then
        return result
      else
        return M.Value()(result)
      end
    end
    monad.and_then = function(self, callback)
      return monad
    end
    setmetatable(monad, {__index = function(t, key)
      return function() return monad end
    end})
    return value
  end)
end

function M.Value()
  return M.new(function(monad, value)
    monad.bind = function(func, ...)
      return return_value_or_error_monad(M.Error(), pcall(func, value, ...))
    end
    monad.catch = function(self, callback)
      return monad
    end
    monad.and_then = function(self, callback)
      local result = self.bind(callback)
      if type(result) == 'table' and result.is_monad then
        return result
      else
        return M.Value()(result)
      end
    end
    setmetatable(monad, {__index = function(t, key)
      if type(value) == 'table' and type(value[key]) == 'function' then
        return function(self, ...)
          local result = self.bind(value[key], ...)
          if type(result) == 'table' and result.is_monad then
            return result
          else
            return M.Value()(result)
          end
        end
      else
        error(string.format('No method "%s" on value', key))
      end
    end})
    return value
  end)
end

return M
