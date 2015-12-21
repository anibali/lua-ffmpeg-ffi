------------
-- A theoretical union type for `Value` and `Error`.
--
-- For example, if a function is documented as returning a `string` `Result`,
-- this means that it returns a `Value` wrapping a `string` on success, or an
-- `Error` otherwise.
--
-- Here's an example of using a function that returns a `Result`:
--
--    some_function():and_then(function(value)
--      print('some_function returned ' .. value)
--    end):catch(function(error_message))
--      print('Error calling some_function: ' .. error_message)
--    end)
--
-- However, the real beauty of this approach comes with chaining calls:
--
--    create_a_shape()
--      :scale(2)
--      :rotate(45)
--      :translate(10, 5)
--      :catch(function(error_message))
--        print('Error creating and transforming shape: ' .. error_message)
--      end)
--
-- In the above example we assume that create_a_shape() returns a `Result`.
-- If any of the steps along the way fails, no further methods will be called
-- and the catch function will be triggered. If all of the steps are successful,
-- the catch function will not be called.
--
-- At some point you may want to unwrap a `Value` to get the actual value inside
-- of it. A good pattern for doing this is as follows:
--
--    local my_shape = create_a_shape()
--      :scale(2)
--      :rotate(45)
--      :translate(10, 5)
--      :catch(function(error_message))
--        return default_shape
--      end)
--      :get()
--
-- `:get` is a special function which returns the value wrapped by a `Value`.
-- But be careful! If you call `get` on an `Error` then a Lua error will be
-- raised - this is why in the example above we make sure that we make a
-- default value available in the case of an `Error`.
--
-- @module monad.result
-- @author Aiden Nibali
-- @license MIT
-- @copyright Aiden Nibali 2015

local monad = require('monad')

local M = {}

function M.of(func, ...)
  local ok, raw_result = pcall(func, ...)
  local result
  if type(raw_result) == 'table' and raw_result.is_monad then
    result = raw_result
  elseif ok then
    result = M.Value()(raw_result)
  else
    result = M.Error()(raw_result)
  end
  return result
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

---- Returns a factory for making `Error` monads.
--
-- @usage
-- local error_factory = monad.Error()
-- local error_monad = error_factory('An error occurred!')
function M.Error()
  ---- A monad which represents an error result.
  --
  -- An `ErrorMonad` will:
  --
  -- * Throw an error when `:get` or `:done` is called on it.
  -- * Call the function `callback` with the error message when `:catch(callback)`
  -- is called on it.
  -- * Return itself in response to all other method calls.
  -- @type ErrorMonad
  return monad.new(function(m, value)
    function m.bind(func, ...)
      return return_value_or_error_monad(M.Error(), pcall(func, value, ...))
    end
    ---- Alias for `Error:get`
    -- @see ErrorMonad:get
    function m:done(...)
      return self:get(...)
    end
    ---- Rethrows the error.
    --
    -- @return Nothing, since this method always throws an error.
    function m:get()
      error(tostring(value))
    end
    ---- Calls function `callback` with the error message.
    -- @func callback
    -- @treturn Result The result of calling `callback`.
    function m:catch(callback)
      local result = self.bind(callback)
      if type(result) == 'table' and result.is_monad then
        return result
      else
        return M.Value()(result)
      end
    end
    ---- Returns self (`callback` is *not* called).
    -- @func callback
    -- @treturn ErrorMonad Self.
    function m:and_then(callback)
      return self
    end
    setmetatable(m, {__index = function(t, key)
      return function() return m end
    end})
    return value
  end)
  --- @section end
end

---- Returns a factory for making `Value` monads.
--
-- @usage
-- local value_factory = monad.Value()
-- local value_monad = value_factory(42)
function M.Value()
  ---- A monad which represents a successful result value.
  --
  -- A `Value` monad will:
  --
  -- * Return its wrapped value when `:get` or `:done` is called on it.
  -- * Call the function `callback` with the wrapped value when
  -- `:and_then(callback)` is called on it.
  -- * Return itself in response to `:catch()`.
  -- * Delegate to the wrapped value in response to all other method calls and
  -- present the return value as a `Result`.
  --
  -- @type Value
  return monad.new(function(m, value)
    function m.bind(func, ...)
      return return_value_or_error_monad(M.Error(), pcall(func, value, ...))
    end
    ---- Alias for `Value:get`
    -- @see Value:get
    function m:done(...)
      return self:get()
    end
    ---- Returns the wrapped value.
    --
    -- @return The wrapped value.
    function m:get()
      return value
    end
    ---- Returns self (`callback` is *not* called).
    -- @func callback
    -- @treturn Value Self.
    function m:catch(callback)
      return self
    end
    ---- Calls function `callback` with the wrapped value.
    -- @func callback
    -- @treturn Result The result of calling `callback`.
    function m:and_then(callback)
      local result = self.bind(callback)
      if type(result) == 'table' and result.is_monad then
        return result
      else
        return M.Value()(result)
      end
    end
    setmetatable(m, {__index = function(t, key)
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
  --- @section end
end

return M
