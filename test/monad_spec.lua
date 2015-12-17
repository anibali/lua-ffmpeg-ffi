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

  describe('Either', function()
    describe('when successful', function()
      local either_success
      local catch_function
      local bound_function

      before_each(function()
        local either = monad.Either()
        catch_function = spy.new(function() end)
        bound_function = spy.new(function() end)
        either.lift('do_something', bound_function)
        either_success = either('Some value')
      end)

      it('should not call catch function callback', function()
        either_success:catch(catch_function)
        assert.spy(catch_function).was_not.called()
      end)

      it('should call bound function', function()
        either_success:do_something()
        assert.spy(bound_function).was.called()
      end)
    end)

    describe('when not successful', function()
      local either_error
      local catch_function
      local bound_function

      before_each(function()
        local either = monad.Either()
        catch_function = spy.new(function() end)
        bound_function = spy.new(function() end)
        either.lift('do_something', bound_function)
        either_error = either.error('An error message')
      end)

      it('should call catch function callback', function()
        either_error:catch(catch_function)
        assert.spy(catch_function).was.called()
      end)

      it('should not call bound function', function()
        either_error:do_something()
        assert.spy(bound_function).was_not.called()
      end)

      it('should skip bound function to call catch function callback', function()
        either_error:do_something():catch(catch_function)
        assert.spy(bound_function).was_not.called()
        assert.spy(catch_function).was.called()
      end)
    end)
  end)
end)
