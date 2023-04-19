require "jestronaut":withGlobals()

describe('mocks', function()
  describe('function mocks', function()
    it('can be created', function()
      local mockFn = jestronaut:fn()
      expect(mockFn):toBeType('function')
    end)

    it('can be called', function()
      local mockFn = jestronaut:fn()
      mockFn()
      expect(mockFn):toHaveBeenCalled()
    end)

    it('can be called with arguments', function()
      local mockFn = jestronaut:fn()
      mockFn(1, 2, 3)
      expect(mockFn):toHaveBeenCalledWith(1, 2, 3)
    end)

    it('can be called with arguments and return values', function()
      local mockFn = jestronaut:fn()
      mockFn:mockReturnValueOnce({4, 5, 6})
      expect(mockFn(1, 2, 3)):toEqual({4, 5, 6})
    end)

    it('can be called with arguments and return values', function()
      local mockFn = jestronaut:fn()
      mockFn:mockReturnValueOnce(4, 5, 6)
      expect(mockFn(1, 2, 3)):toEqual(4, 5, 6) -- This currently incorectly passes since it only checks the first value. It should check the entire vararg
    end)
  end)
end)