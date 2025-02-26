require 'app/test_helper'

test_case 'Access Game Activity' do
  activity = JNI.game_activity
  raise 'Activity reference is nil' if activity.reference.nil?

  puts "Game activity: #{activity.inspect}"
end

test_case 'Calling static methods' do
  boolean_class = JNI.get_class 'java.lang.Boolean'
  boolean_class.register_static_method :parse_boolean,
                                       argument_types: ['java.lang.String'],
                                       return_type: :boolean
  result = boolean_class.parse_boolean 'true'
  expect_equal_values result, true

  integer_class = JNI.get_class 'java.lang.Integer'
  integer_class.register_static_method :value_of,
                                       argument_types: [:int],
                                       return_type: 'java.lang.Integer'
  result = integer_class.value_of 42
  expect_equal_values result.java_class.name, 'java.lang.Integer'
end

test_case 'Building object instances' do
  url_class = JNI.get_class 'java.net.URL'
  url_class.register_constructor argument_types: [:string]
  instance = url_class.build_new_instance 'https://echo.free.beeceptor.com'
  expect_equal_values instance.java_class.name, 'java.net.URL'
end
