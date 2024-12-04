-- toBe



local tests = {

	(function()
		-- For example, this code will validate some properties of the `can` object:
		-- -- Don't use `.toBe` with floating-point numbers. For example, due to rounding, in JavaScript `0.2 + 0.1` is not strictly equal to `0.3`. If you have floating point numbers, try `.toBeCloseTo` instead.
		local can = {name = "pamplemousse", ounces = 12}
		describe(
		    "the can",
		    function()
		        test(
		            "has 12 ounces",
		            function()
		                expect(can.ounces):toBe(12)
		            end
		        )
		        test(
		            "has a sophisticated name",
		            function()
		                expect(can.name):toBe("pamplemousse")
		            end
		        )
		    end
		)
            ocal obj1 = nil
        local obj2 = nil
        local obj3 = "not nil"

        describe(
            "testing :toBe(nil) functionality",
            function()
                test(
                    "both nil values should pass",
                    function()
                        expect(obj1):toBe(nil)  -- Expectation: obj1 is nil
                    end
                )

                test(
                    "non-nil value should fail for nil",
                    function()
                        expect(obj3):toBe(nil)  -- Expectation: obj3 is not nil, so this should fail
                    end
                )

                test(
                    "nil should not equal non-nil",
                    function()
                        expect(obj1):toBe(obj3)  -- Expectation: obj1 is nil, obj3 is non-nil, this should fail
                    end
                )
            end
        )
		
	
	end)(),
	

}

return tests
