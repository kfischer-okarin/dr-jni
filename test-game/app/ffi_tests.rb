require 'app/test_helper'

test_case 'FFI.find_class' do
  string_class = JNI::FFI.find_class('java/lang/String')
  puts "Found String class: #{string_class.inspect}"

  begin
    JNI::FFI.find_class('nonexistent/Class')
    raise 'Should have thrown ClassNotFound exception'
  rescue JNI::FFI::ClassNotFound => e
    puts 'Successfully caught exception for non-existent class:'
    puts "  #{e.message} (#{e.class})"
  end
end

test_case 'FFI.get_static_method_id' do
  string_class = JNI::FFI.find_class('java/lang/String')

  value_of_method = JNI::FFI.get_static_method_id(string_class, 'valueOf', '(I)Ljava/lang/String;')
  puts "Found valueOf method: #{value_of_method.inspect}"

  begin
    JNI::FFI.get_static_method_id(string_class, 'nonExistentMethod', '()V')
    raise 'Should have thrown NoSuchMethod exception'
  rescue JNI::FFI::NoSuchMethod => e
    puts 'Successfully caught exception for non-existent static method'
    puts "  #{e.message} (#{e.class})"
  end
end

test_case 'FFI.get_method_id' do
  string_class = JNI::FFI.find_class('java/lang/String')

  length_method = JNI::FFI.get_method_id(string_class, 'length', '()I')
  puts "Found length method: #{length_method.inspect}"

  begin
    JNI::FFI.get_method_id(string_class, 'nonExistentMethod', '()V')
    raise 'Should have thrown NoSuchMethod exception'
  rescue JNI::FFI::NoSuchMethod => e
    puts 'Successfully caught exception for non-existent method:'
    puts "  #{e.message} (#{e.class})"
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

test_case 'FFI.call_static_boolean_method' do
  boolean_class = JNI::FFI.find_class('java/lang/Boolean')
  parse_boolean_method = JNI::FFI.get_static_method_id(
    boolean_class,
    'parseBoolean',
    '(Ljava/lang/String;)Z'
  )

  result_true = JNI::FFI.call_static_boolean_method(boolean_class, parse_boolean_method, 'true')
  raise 'Expected true from parseBoolean("true")' unless result_true == true

  puts 'Successfully called Boolean.parseBoolean:'
  puts "  parseBoolean(\"true\") = #{result_true}"
end

test_case 'FFI.call_static_object_method' do
  string_class = JNI::FFI.find_class('java/lang/String')
  value_of_method = JNI::FFI.get_static_method_id(
    string_class,
    'valueOf',
    '(I)Ljava/lang/String;'
  )

  result_string = JNI::FFI.call_static_object_method(string_class, value_of_method, 42)
  raise "Expected '42' from valueOf(42)" unless result_string == '42'

  puts 'Successfully called String.valueOf:'
  puts "  valueOf(42) = #{result_string.inspect}"
end
