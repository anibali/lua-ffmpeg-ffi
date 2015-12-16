-- Credit: https://github.com/douglascrockford/monad

local M = {}
local Vow = {}

local function is_callable(thing)
  return type(func) == 'function' or
    type((getmetatable(thing) or {}).__call == 'function')
end

local function enlighten(queue, fate)
  for i, func in ipairs(queue) do
    func(fate)
  end
end

function M.make()
  local rejecters = {}
  local keepers = {}
  local fate
  local status = 'pending'

  local function enqueue(resolution, func, vow)
    local queue = resolution == 'keep' and keepers or rejecters
    if not is_callable(func) then
      table.insert(queue, vow[resolution])
    else
      table.insert(queue, function(value)
        local ok, result = pcall(func, value)
        if ok then
          if type(result) == 'table' and result.is_promise then
            result.when(vow.keep, vow.reject)
          else
            vow.keep(result)
          end
        else
          vow.reject(result)
        end
      end)
    end
  end

  local function herald(state, value, queue)
    if status ~= 'pending' then
      error('overpromise')
    end
    fate = value
    status = state
    enlighten(queue, fate)
    while #keepers > 0 do table.remove(keepers) end
    while #rejecters > 0 do table.remove(rejecters) end
  end

  local vow = {}

  vow.reject = function(value)
    herald('rejected', value, rejecters)
    return vow
  end

  vow.keep = function(value)
    herald('kept', value, keepers)
    return vow
  end

  vow.promise = {
    is_promise = true,
    catch = function(rejected)
      local vow = M.make()
      if status == 'pending' then
        enqueue('reject', rejected, vow)
      elseif status == 'rejected' then
        enqueue('reject', rejected, vow)
        enlighten(rejecters, fate)
      end
      return vow.promise
    end,
    and_then = function(kept)
      local vow = M.make()
      if status == 'pending' then
        enqueue('keep', kept, vow)
      elseif status == 'kept' then
        enqueue('keep', kept, vow)
        enlighten(keepers, fate)
      end
      return vow.promise
    end
  }

  return vow
end

-- TODO: M.every, M.first, M.any

return M
