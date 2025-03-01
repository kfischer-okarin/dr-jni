require 'app/test_helper'

test_case 'Access Game Activity' do
  activity = JNI.game_activity
  raise 'Activity reference is nil' if activity.reference.nil?

  puts "Game activity: #{activity.inspect}"
end

test_case 'Calling static methods' do
  JNI['java.lang.Boolean'].register do
    static_method :parse_boolean,
                   argument_types: [:string],
                   return_type: :boolean
  end
  result = JNI['java.lang.Boolean'].parse_boolean 'true'
  expect_equal_values result, true

  JNI['java.lang.Integer'].register do
    static_method :value_of,
                   argument_types: [:int],
                   return_type: 'java.lang.Integer'
  end
  result = JNI['java.lang.Integer'].value_of 42
  expect_equal_values result.java_class.name, 'java.lang.Integer'
end

test_case 'Building object instances' do
  JNI['java.net.URL'].register do
    constructor argument_types: [:string]
  end
  instance = JNI['java.net.URL'].build_new_instance 'https://echo.free.beeceptor.com'
  expect_equal_values instance.java_class.name, 'java.net.URL'
end
