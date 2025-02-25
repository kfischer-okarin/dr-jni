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
  raise 'Expected true from parseBoolean("true")' unless result == true
end
