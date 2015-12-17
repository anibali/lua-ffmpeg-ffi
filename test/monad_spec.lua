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

  describe('Error', function()
    local error_monad

    before_each(function()
      error_monad = monad.Error()('An error')
    end)

    it('should call catch function callback', function()
      catch_function = spy.new(function() end)
      error_monad:catch(catch_function)
      assert.spy(catch_function).was.called_with('An error')
    end)

    it('should not call and_then function callback', function()
      and_then_function = spy.new(function() end)
      error_monad:and_then(and_then_function)
      assert.spy(and_then_function).was_not.called()
    end)
  end)

  describe('Value', function()
    local value_monad

    before_each(function()
      value_monad = monad.Value()('A value')
    end)

    it('should call catch function callback', function()
      catch_function = spy.new(function() end)
      value_monad:catch(catch_function)
      assert.spy(catch_function).was_not.called()
    end)

    it('should not call and_then function callback', function()
      and_then_function = spy.new(function() end)
      value_monad:and_then(and_then_function)
      assert.spy(and_then_function).was.called_with('A value')
    end)
  end)
end)
