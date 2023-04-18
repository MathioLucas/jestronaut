local optionsLib = require "jestronaut.environment.options"
local currentDescribeOrTest = nil

local function getCurrentDescribeOrTest()
  return currentDescribeOrTest
end

--- @type DescribeOrTest[]
local isExecutingTests = false

--- @type DescribeOrTest
local currentParent = nil

local function getIsExecutingTests()
  return isExecutingTests
end

local function setIsExecutingTests(executing)
  isExecutingTests = executing
end

local function incrementAssertionCount()
  if not currentDescribeOrTest then
    error("Cannot increase the assertion count outside of a test or describe block", 2)
  end

  currentDescribeOrTest.assertionCount = currentDescribeOrTest.assertionCount + 1
end

local function getAssertionCount()
  if not currentDescribeOrTest then
    error("Cannot get the assertion count outside of a test or describe block", 2)
  end
  
  return currentDescribeOrTest.assertionCount
end

local function setExpectAssertion()
  if not currentDescribeOrTest then
    error("Cannot set the expect assertion outside of a test or describe block", 2)
  end

  currentDescribeOrTest.expectAssertion = true
end

local function getExpectedAssertionCount()
  if not currentDescribeOrTest then
    error("Cannot get the expected assertion count outside of a test or describe block", 2)
  end
  
  return currentDescribeOrTest.expectedAssertionCount
end

local function setExpectedAssertionCount(count)
  if not currentDescribeOrTest then
    error("Cannot set the expected assertion count outside of a test or describe block", 2)
  end

  currentDescribeOrTest.expectedAssertionCount = count
end

local function beforeDescribeOrTest(describeOrTest)
  currentDescribeOrTest = describeOrTest
end

local function afterDescribeOrTest(describeOrTest, success)
  currentDescribeOrTest = nil

  if not success then
    return
  end

  if describeOrTest.expectedAssertionCount ~= nil and describeOrTest.expectedAssertionCount ~= describeOrTest.assertionCount then
    error("Expected " .. describeOrTest.expectedAssertionCount .. " assertions, but " .. describeOrTest.assertionCount .. " were run")
  end

  if describeOrTest.expectAssertion and describeOrTest.assertionCount == 0 then
    error("Expected at least one assertion to be run, but none were run")
  end
end

--- @class DescribeOrTest
local DESCRIBE_OR_TEST_META = {
  indentationLevel = 0,
  name = "",
  fn = function() end,
  isOnly = false,
  isSkipping = false,

  assertionCount = 0,
  parent = nil,
  childCount = 0,
  grandChildrenCount = 0,

  --- Adds a child describe or test.
  --- @param child DescribeOrTest
  addChild = function(self, child)
    self.childCount = self.childCount + 1

    self.children[self.childCount] = child
    self.childrenLookup[child.name] = self.childCount

    child.parent = self

    if self.parent then
      self.parent.grandChildrenCount = self.parent.grandChildrenCount + 1
    end
  end,

  --- Runs the test and returns the amount of failed tests.
  --- @param self DescribeOrTest
  --- @param printer Printer
  --- @param runnerOptions RunnerOptions
  --- @return number
  run = function(self, printer, runnerOptions)
    local failedTestCount = 0

    if self.isSkipping then
      printer:printSkip(self)
      return failedTestCount
    end

    if self.isTest then
      if getIsExecutingTests() then
        if runnerOptions.testPathIgnorePatterns then
          for _, pattern in ipairs(runnerOptions.testPathIgnorePatterns) do
            if self.name:find(pattern) then
              printer:printSkip(self)
              return failedTestCount
            end
          end
        elseif runnerOptions.testNamePattern then
          if not self.name:find(runnerOptions.testNamePattern) then
            printer:printSkip(self)
            return failedTestCount
          end
        end

        beforeDescribeOrTest(self)

        local success = printer:printResult(self, xpcall(self.fn, function(err)
          return debug.traceback(err, 2)
        end))

        afterDescribeOrTest(self, success)

        if not success then
          failedTestCount = failedTestCount + 1

          if runnerOptions.bail ~= nil and failedTestCount >= runnerOptions.bail then
            error("Bail after " .. failedTestCount .. " failed " .. (failedTestCount == 1 and "test" or "tests"))
          end
        end
      else
        printer:printSkip(self)
        return failedTestCount
      end
    elseif #self.children > 0 then
      for _, child in pairs(self.children) do
        printer:printName(child)
        failedTestCount = failedTestCount + child:run(printer, runnerOptions)
      end
    end

    if self.isOnly then
      setIsExecutingTests(false)
    end

    return failedTestCount
  end,
}

DESCRIBE_OR_TEST_META.__index = DESCRIBE_OR_TEST_META

--- Registers a Describe or Test to be run.
--- Must be called once befrore all others with a Describe to set as root.
--- @param describeOrTest DescribeOrTest
local function registerDescribeOrTest(describeOrTest)
  describeOrTest.filePath = debug.getinfo(5, "S").source:sub(2)
  describeOrTest.lineNumber = debug.getinfo(5, "l").currentline
  
  if not currentParent then
    currentParent = describeOrTest
  else
    currentParent:addChild(describeOrTest)
  end

  describeOrTest.indentationLevel = currentParent and currentParent.indentationLevel + 1 or 0

  if describeOrTest.isDescribe then
    local oldParent = currentParent
    currentParent = describeOrTest

    describeOrTest.fn()

    currentParent = oldParent
  end

  return describeOrTest
end

--- Runs all registered tests.
--- @param printer Printer
--- @param runnerOptions RunnerOptions
local function runTests(printer, runnerOptions)
  runnerOptions = optionsLib.merge(runnerOptions)

  local startTime = os.clock()
  setIsExecutingTests(true)

  printer:printStart(currentParent)

  local success, errOrFailedTestCount = pcall(currentParent.run, currentParent, printer, runnerOptions)

  if not success then
    if not errOrFailedTestCount:find("^Bail after") then
      error(errOrFailedTestCount)
    end

    printer:printFailFast(currentParent)
  else
    printer:printSuccess(currentParent, errOrFailedTestCount)
  end

  local endTime = os.clock()
  printer:printEnd(endTime - startTime)

  setIsExecutingTests(false)
end

return {
  DESCRIBE_OR_TEST_META = DESCRIBE_OR_TEST_META,
  getCurrentDescribeOrTest = getCurrentDescribeOrTest,

  registerDescribeOrTest = registerDescribeOrTest,
  runTests = runTests,

  getIsExecutingTests = getIsExecutingTests,
  setIsExecutingTests = setIsExecutingTests,

  incrementAssertionCount = incrementAssertionCount,
  getAssertionCount = getAssertionCount,
  setExpectAssertion = setExpectAssertion,
  getExpectedAssertionCount = getExpectedAssertionCount,
  setExpectedAssertionCount = setExpectedAssertionCount,
}