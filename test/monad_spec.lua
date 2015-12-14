local monad = require('monad')

describe('monad', function()
  describe('Maybe', function()
    local maybe
    local bound_function

    before_each(function()
      maybe = monad.Maybe()
      bound_function = spy.new(function() end)
      maybe.lift('do_something', bound_function)
    end)

    it('should have truthy is_nil when value is nil', function()
      assert.is.truthy(maybe(nil).is_nil)
    end)

    it('should have falsy is_nil when value is not nil', function()
      assert.is.falsy(maybe('Some value').is_nil)
    end)

    it('should not call bound function when value is nil', function()
      maybe(nil):do_something()
      assert.spy(bound_function).was_not.called()
    end)

    it('should call bound function when value is not nil', function()
      maybe('Some value'):do_something()
      assert.spy(bound_function).was.called()
    end)
  end)
end)
