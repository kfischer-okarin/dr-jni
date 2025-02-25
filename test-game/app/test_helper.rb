TESTS = {}

def test_case(description, &block)
  TESTS[description] = block
end
