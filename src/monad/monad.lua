------------
-- Monad stuffs.
--
-- Some code is based on
-- [Douglas Crockford's JavaScript monads](https://github.com/douglascrockford/monad).
--
-- @module monad
-- @author Aiden Nibali
-- @license MIT
-- @copyright Aiden Nibali 2015

local M = {}

function M.new(modifier)
  local proto = {}

  local unit = {}

  local function unit_call(self, value)
    local monad = {is_monad=true}
    setmetatable(monad, {__index = proto})
    function monad.bind(func, ...)
      func(value, ...)
    end
    function monad:get()
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
      function monad.bind()
        return monad
      end
      function monad:get()
        error('Maybe monad is empty')
      end
    else
      monad.is_nil = false
    end
    return value
  end)
end

return M
