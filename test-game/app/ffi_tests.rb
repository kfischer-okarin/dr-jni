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

test_case 'FFI.new_object' do
  string_class = JNI::FFI.find_class('java/lang/String')
  constructor_method = JNI::FFI.get_method_id(string_class, '<init>', '()V')
  string_object = JNI::FFI.new_object(string_class, constructor_method)
  puts "Created empty String object: #{string_object.inspect}"

  string_from_str_constructor = JNI::FFI.get_method_id(string_class, '<init>', '(Ljava/lang/String;)V')
  string_copy = JNI::FFI.new_object(string_class, string_from_str_constructor, 'Hello String')
  puts "Created String copy: #{string_copy.inspect}"
end

test_case 'FFI.get_object_class' do
  string_class = JNI::FFI.find_class('java/lang/String')
  constructor_method = JNI::FFI.get_method_id(string_class, '<init>', '()V')
  string_object = JNI::FFI.new_object(string_class, constructor_method)

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

  JNI::FFI.call_static_void_method(thread_class, sleep_method, 10)
end

test_case 'FFI.call_static_object_method' do
  string_class = JNI::FFI.find_class('java/lang/String')
  value_of_method = JNI::FFI.get_static_method_id(
    string_class,
    'valueOf',
    '(I)Ljava/lang/String;'
  )

  result_string = JNI::FFI.call_static_object_method(string_class, value_of_method, 42)
  expect_equal_values(result_string, '42')

  puts 'Successfully called String.valueOf:'
  puts "  valueOf(42) = #{result_string.inspect}"

  integer_class = JNI::FFI.find_class('java/lang/Integer')
  value_of_method = JNI::FFI.get_static_method_id(
    integer_class,
    'valueOf',
    '(I)Ljava/lang/Integer;'
  )

  integer_object = JNI::FFI.call_static_object_method(integer_class, value_of_method, 42)

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

  result_true = JNI::FFI.call_static_boolean_method(boolean_class, parse_boolean_method, 'true')
  expect_equal_values(result_true, true)

  puts 'Successfully called Boolean.parseBoolean:'
  puts "  parseBoolean(\"true\") = #{result_true}"
end

test_case 'FFI.call_static_int_method' do
  integer_class = JNI::FFI.find_class('java/lang/Integer')
  compare_method = JNI::FFI.get_static_method_id(integer_class, 'compare', '(II)I')

  result_int = JNI::FFI.call_static_int_method(integer_class, compare_method, 42, 42)
  expect_equal_values(result_int, 0)

  puts 'Successfully called Integer.compare:'
  puts "  compare(42, 42) = #{result_int}"
end
