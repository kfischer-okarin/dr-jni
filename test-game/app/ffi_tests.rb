require 'app/test_helper'

test_case 'FFI.find_class' do
  string_class = JNI::FFI.find_class('java/lang/String')
  puts "Found String class: #{string_class.inspect}"

  expect_exception(JNI::FFI::ClassNotFound) do
    JNI::FFI.find_class('nonexistent/Class')
  end
end

test_case 'FFI.get_static_method_id' do
  string_class = JNI::FFI.find_class('java/lang/String')

  value_of_method = JNI::FFI.get_static_method_id(string_class, 'valueOf', '(I)Ljava/lang/String;')
  puts "Found valueOf method: #{value_of_method.inspect}"

  expect_exception(JNI::FFI::NoSuchMethod) do
    JNI::FFI.get_static_method_id(string_class, 'nonExistentMethod', '()V')
  end
end

test_case 'FFI.get_method_id' do
  string_class = JNI::FFI.find_class('java/lang/String')

  length_method = JNI::FFI.get_method_id(string_class, 'length', '()I')
  puts "Found length method: #{length_method.inspect}"

  expect_exception(JNI::FFI::NoSuchMethod) do
    JNI::FFI.get_method_id(string_class, 'nonExistentMethod', '()V')
  end
end

def test_parameters(valid_examples:, invalid_examples:, &block)
  valid_examples.each do |example|
    puts "Testing valid example: #{example.inspect}"
    block.call(example)
  rescue JNI::FFI::JavaException
    # ignore we don't care about the exception only about argument type errors
  end

  invalid_examples.each do |example|
    puts "Testing invalid example: #{example.inspect}"
    expect_exception(JNI::FFI::WrongArgumentType) do
      block.call(example)
    end
  end
end

test_case 'FFI boolean parameters' do
  boolean_class = JNI::FFI.find_class('java/lang/Boolean')

  value_of_method = JNI::FFI.get_static_method_id(
    boolean_class,
    'valueOf',
    '(Z)Ljava/lang/Boolean;'
  )

  test_parameters(
    valid_examples: [true, false],
    invalid_examples: [nil, 'not a boolean']
  ) do |value|
    JNI::FFI.call_static_object_method(boolean_class, value_of_method, %i[boolean], value)
  end
end

test_case 'FFI byte parameters' do
  byte_class = JNI::FFI.find_class('java/lang/Byte')

  value_of_method = JNI::FFI.get_static_method_id(
    byte_class,
    'valueOf',
    '(B)Ljava/lang/Byte;'
  )

  test_parameters(
    valid_examples: [127, -128],
    invalid_examples: [nil, 'not a byte']
  ) do |value|
    JNI::FFI.call_static_object_method(byte_class, value_of_method, %i[byte], value)
  end
end

test_case 'FFI char parameters' do
  char_class = JNI::FFI.find_class('java/lang/Character')

  value_of_method = JNI::FFI.get_static_method_id(
    char_class,
    'valueOf',
    '(C)Ljava/lang/Character;'
  )

  test_parameters(
    valid_examples: %w[A Z 9],
    invalid_examples: [nil, 'not a char']
  ) do |value|
    JNI::FFI.call_static_object_method(char_class, value_of_method, %i[char], value)
  end
end

test_case 'FFI short parameters' do
  short_class = JNI::FFI.find_class('java/lang/Short')

  value_of_method = JNI::FFI.get_static_method_id(
    short_class,
    'valueOf',
    '(S)Ljava/lang/Short;'
  )

  test_parameters(
    valid_examples: [12_345, -32_768],
    invalid_examples: [nil, 'not a short']
  ) do |value|
    JNI::FFI.call_static_object_method(short_class, value_of_method, %i[short], value)
  end
end

test_case 'FFI int parameters' do
  int_class = JNI::FFI.find_class('java/lang/Integer')

  value_of_method = JNI::FFI.get_static_method_id(
    int_class,
    'valueOf',
    '(I)Ljava/lang/Integer;'
  )

  test_parameters(
    valid_examples: [42, -2_147_483_648],
    invalid_examples: [nil, 'not an int']
  ) do |value|
    JNI::FFI.call_static_object_method(int_class, value_of_method, %i[int], value)
  end
end

test_case 'FFI long parameters' do
  long_class = JNI::FFI.find_class('java/lang/Long')

  value_of_method = JNI::FFI.get_static_method_id(
    long_class,
    'valueOf',
    '(J)Ljava/lang/Long;'
  )

  test_parameters(
    valid_examples: [9_223_372_036_854_775_807, -9_223_372_036_854_775_808],
    invalid_examples: [nil, 'not a long']
  ) do |value|
    JNI::FFI.call_static_object_method(long_class, value_of_method, %i[long], value)
  end
end

test_case 'FFI float parameters' do
  float_class = JNI::FFI.find_class('java/lang/Float')

  value_of_method = JNI::FFI.get_static_method_id(
    float_class,
    'valueOf',
    '(F)Ljava/lang/Float;'
  )

  test_parameters(
    valid_examples: [3.14, -1.23],
    invalid_examples: [nil, 'not a float']
  ) do |value|
    JNI::FFI.call_static_object_method(float_class, value_of_method, %i[float], value)
  end
end

test_case 'FFI double parameters' do
  double_class = JNI::FFI.find_class('java/lang/Double')

  value_of_method = JNI::FFI.get_static_method_id(
    double_class,
    'valueOf',
    '(D)Ljava/lang/Double;'
  )

  test_parameters(
    valid_examples: [3.14, -1.23],
    invalid_examples: [nil, 'not a double']
  ) do |value|
    JNI::FFI.call_static_object_method(double_class, value_of_method, %i[double], value)
  end
end

test_case 'FFI object parameters' do
  string_class = JNI::FFI.find_class('java/lang/String')
  constructor_method = JNI::FFI.get_method_id(string_class, '<init>', '()V')
  string_object = JNI::FFI.new_object(string_class, constructor_method, [])

  value_of_method = JNI::FFI.get_static_method_id(
    string_class,
    'valueOf',
    '(Ljava/lang/Object;)Ljava/lang/String;'
  )

  test_parameters(
    valid_examples: [string_object, nil],
    invalid_examples: [42]
  ) do |value|
    JNI::FFI.call_static_object_method(string_class, value_of_method, ['java.lang.Object'], value)
  end
end

test_case 'FFI string parameters' do
  string_class = JNI::FFI.find_class('java/lang/String')
  string_from_str_constructor = JNI::FFI.get_method_id(string_class, '<init>', '(Ljava/lang/String;)V')

  test_parameters(
    valid_examples: ['en-US', nil],
    invalid_examples: [42]
  ) do |value|
    JNI::FFI.new_object(string_class, string_from_str_constructor, %i[string], value)
  end
end

test_case 'FFI.new_object' do
  string_class = JNI::FFI.find_class('java/lang/String')
  constructor_method = JNI::FFI.get_method_id(string_class, '<init>', '()V')
  string_object = JNI::FFI.new_object(string_class, constructor_method, [])
  puts "Created empty String object: #{string_object.inspect}"

  string_from_str_constructor = JNI::FFI.get_method_id(string_class, '<init>', '(Ljava/lang/String;)V')
  string_copy = JNI::FFI.new_object(string_class, string_from_str_constructor, %i[string], 'Hello String')
  puts "Created String copy: #{string_copy.inspect}"
end

test_case 'FFI.get_object_class' do
  string_class = JNI::FFI.find_class('java/lang/String')
  constructor_method = JNI::FFI.get_method_id(string_class, '<init>', '()V')
  string_object = JNI::FFI.new_object(string_class, constructor_method, [])

  string_object_class = JNI::FFI.get_object_class(string_object)
  puts "String object class: #{string_object_class.inspect}"
end

test_case 'FFI.call_static_void_method' do
  thread_class = JNI::FFI.find_class('java/lang/Thread')
  sleep_method = JNI::FFI.get_static_method_id(
    thread_class,
    'sleep',
    '(J)V'
  )

  JNI::FFI.call_static_void_method(thread_class, sleep_method, %i[long], 1000)
end

test_case 'FFI.call_static_object_method (returning String)' do
  string_class = JNI::FFI.find_class('java/lang/String')
  value_of_method = JNI::FFI.get_static_method_id(
    string_class,
    'valueOf',
    '(I)Ljava/lang/String;'
  )

  result_string = JNI::FFI.call_static_object_method(string_class, value_of_method, %i[int], 42)
  expect_equal_values result_string, '42'

  puts 'Successfully called String.valueOf:'
  puts "  valueOf(42) = #{result_string.inspect}"
end

test_case 'FFI.call_static_object_method (returning an object)' do
  integer_class = JNI::FFI.find_class('java/lang/Integer')
  value_of_method = JNI::FFI.get_static_method_id(
    integer_class,
    'valueOf',
    '(I)Ljava/lang/Integer;'
  )

  integer_object = JNI::FFI.call_static_object_method(integer_class, value_of_method, %i[int], 42)

  integer_class_name = JNI::FFI.get_object_class(integer_object)
  puts 'Successfully called Integer.valueOf:'
  puts "  valueOf(42) = #{integer_object.inspect}"
  puts "  Object class: #{integer_class_name.inspect}"
end

test_case 'FFI.call_static_boolean_method' do
  boolean_class = JNI::FFI.find_class('java/lang/Boolean')
  parse_boolean_method = JNI::FFI.get_static_method_id(
    boolean_class,
    'parseBoolean',
    '(Ljava/lang/String;)Z'
  )

  result = JNI::FFI.call_static_boolean_method(boolean_class, parse_boolean_method, %i[string], 'true')
  expect_equal_values result, true

  puts 'Successfully called Boolean.parseBoolean:'
  puts "  parseBoolean(\"true\") = #{result}"
end

test_case 'FFI.call_static_byte_method' do
  byte_class = JNI::FFI.find_class('java/lang/Byte')
  parse_byte_method = JNI::FFI.get_static_method_id(
    byte_class,
    'parseByte',
    '(Ljava/lang/String;)B'
  )

  result = JNI::FFI.call_static_byte_method(byte_class, parse_byte_method, %i[string], '42')
  expect_equal_values result, 42

  puts 'Successfully called Byte.parseByte:'
  puts "  parseByte(\"42\") = #{result}"
end

test_case 'FFI.call_static_int_method' do
  integer_class = JNI::FFI.find_class('java/lang/Integer')
  compare_method = JNI::FFI.get_static_method_id(integer_class, 'compare', '(II)I')

  result = JNI::FFI.call_static_int_method(integer_class, compare_method, %i[int int], 42, 42)
  expect_equal_values result, 0

  puts 'Successfully called Integer.compare:'
  puts "  compare(42, 42) = #{result}"
end

test_case 'FFI.call_static_long_method' do
  long_class = JNI::FFI.find_class('java/lang/Long')
  max_method = JNI::FFI.get_static_method_id(long_class, 'max', '(JJ)J')

  result_long = JNI::FFI.call_static_long_method(long_class, max_method, %i[long long], 1000, 2000)
  expect_equal_values result_long, 2000

  puts 'Successfully called Long.max:'
  puts "  max(1000, 2000) = #{result_long}"
end
