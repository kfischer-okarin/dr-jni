TESTS = {}

def test_case(description, &block)
  TESTS[description] = block
end

def expect_exception(exception_class, &block)
  block.call
  raise "Should have thrown #{exception_class}"
rescue exception_class => e
  puts 'Successfully caught exception:'
  puts "  #{e.message} (#{e.class})"
end

def expect_equal_values(actual, expected)
  return if expected == actual

  raise "Expected #{expected} but got #{actual}"
end
