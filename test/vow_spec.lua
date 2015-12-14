local vow = require('vow')

describe('vow', function()
  describe('when kept', function()
    local promise
    before_each(function()
      promise = vow.make().keep('A value').promise
    end)

    it('should trigger and_then callback', function()
      local kept = spy.new(function() end)
      promise.and_then(kept)
      assert.spy(kept).was.called()
    end)

    it('should not trigger catch callback', function()
      local rejected = spy.new(function() end)
      promise.catch(rejected)
      assert.spy(rejected).was_not.called()
    end)
  end)

  describe('when rejected', function()
    local promise
    before_each(function()
      promise = vow.make().reject('An error').promise
    end)

    it('should not trigger and_then callback', function()
      local kept = spy.new(function() end)
      promise.and_then(kept)
      assert.spy(kept).was_not.called()
    end)

    it('should trigger catch callback', function()
      local rejected = spy.new(function() end)
      promise.catch(rejected)
      assert.spy(rejected).was.called()
    end)
  end)
end)
