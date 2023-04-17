local makeIndexableFunction = require "jestronaut.utils.metatables".makeIndexableFunction
local customEqualityTesters = {}
local customMatchers = {}
local expect

local modifiers = {
  ["not"] = function(expect)
    expect.inverse = true
    return expect
  end,
}

local function getMatcher(key)
  if customMatchers[key] then
    return customMatchers[key]
  end

  local success, matcher = pcall(require, 'jestronaut.expect.matchers.' .. key)

  if success then
    return matcher
  end

  return nil
end

--- @class Expect
--- @field value any
--- @field toBe fun(value: any): boolean
--- @field toHaveBeenCalled fun(): boolean
local EXPECT_META = {
  value = nil,

  __index = function(self, key)
    -- If the value is the expect function, try that first
    if(self.value and type(self.value) == 'table' and self.value.isExpect)then
      local value = self.value[key]

      if value ~= nil then
        return value
      end
    end

    local modifier = modifiers[key]

    if modifier then
      return modifier(self)
    end

    local matcher = getMatcher(key)
    if matcher then
      if key == 'toEqual' then
        return matcher.build(self, customEqualityTesters)
      elseif matcher.build ~= nil then
        return matcher.build(self)
      end

      return matcher.default
    end

    error('Unknown matcher or modifier: ' .. key)
  end
}

function expect(value)
  local expectInstance = {
    value = value,
    inverse = false,
  }

  setmetatable(expectInstance, EXPECT_META)

  return expectInstance
end

--- Exposes the expect function to the global environment.
--- @param targetEnvironment table
local function exposeTo(targetEnvironment)
  targetEnvironment.expect = makeIndexableFunction(expect, {
    isExpect = true,

    addEqualityTesters = function(self, testers)
      for _, tester in ipairs(testers) do
        table.insert(customEqualityTesters, tester)
      end
    end,

    addSnapshotSerializer = function(self, serializer)
      --- @Not implemented
      -- TODO: You can call expect.addSnapshotSerializer to add a module that formats application-specific data structures.
    end,

    extend = function(self, matchers)
      for key, matcher in pairs(matchers) do
        customMatchers[key] = matcher
      end
    end,
  })

  local metaTable = getmetatable(targetEnvironment.expect)
  metaTable.__index = function(self, key)
    -- Create a new expect instance with the expect function as the value
    local expectInstance = expect(self)
    local modifier = modifiers[key]

    if modifier then
      return modifier(expectInstance)
    end

    local success, asymetricMatcher = pcall(require, 'jestronaut.expect.asymetricmatchers.' .. key)

    if success then
      if asymetricMatcher.build ~= nil then
        return asymetricMatcher.build(expectInstance, customEqualityTesters)
      end

      return asymetricMatcher.default
    end
  end
end

return {
  EXPECT_META = EXPECT_META,
  expect = expect,
  exposeTo = exposeTo,
}