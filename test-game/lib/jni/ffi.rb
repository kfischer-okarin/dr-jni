module JNI
  module FFI
    class << self
      attr_reader :game_activity_reference

      # Class Operations
      # def find_class(name) -> Reference

      # Object Operations
      # def new_object(class_reference, method_id, argument_types, *args) -> Reference
      # def get_object_class(object_reference) -> Reference

      # Accessing Fields of Objects
      # def get_field_id(object_reference, name, signature) -> Pointer
      # def get_object_field(object_reference, field_id) -> Reference
      # def get_boolean_field(object_reference, field_id) -> TrueClass/FalseClass
      # def get_byte_field(object_reference, field_id) -> Integer
      # def get_char_field(object_reference, field_id) -> String
      # def get_short_field(object_reference, field_id) -> Integer
      # def get_int_field(object_reference, field_id) -> Integer
      # def get_long_field(object_reference, field_id) -> Integer
      # def get_float_field(object_reference, field_id) -> Float
      # def get_double_field(object_reference, field_id) -> Float
      # def set_object_field(object_reference, field_id, value)
      # def set_boolean_field(object_reference, field_id, value)
      # def set_byte_field(object_reference, field_id, value)
      # def set_char_field(object_reference, field_id, value)
      # def set_short_field(object_reference, field_id, value)
      # def set_int_field(object_reference, field_id, value)
      # def set_long_field(object_reference, field_id, value)

      # Calling Instance Methods
      # def get_method_id(object_reference, name, signature) -> Pointer
      # def call_void_method(object_reference, method_id, argument_types, *args)
      # def call_object_method(object_reference, method_id, argument_types, *args) -> Reference
      # def call_boolean_method(object_reference, method_id, argument_types, *args) -> TrueClass/FalseClass
      # def call_byte_method(object_reference, method_id, argument_types, *args) -> Integer
      # def call_char_method(object_reference, method_id, argument_types, *args) -> String
      # def call_short_method(object_reference, method_id, argument_types, *args) -> Integer
      # def call_int_method(object_reference, method_id, argument_types, *args) -> Integer
      # def call_long_method(object_reference, method_id, argument_types, *args) -> Integer
      # def call_float_method(object_reference, method_id, argument_types, *args) -> Float
      # def call_double_method(object_reference, method_id, argument_types, *args) -> Float

      # Accessing Static Fields
      # def get_static_field_id(class_reference, name, signature) -> Pointer
      # def get_static_object_field(class_reference, field_id) -> Reference
      # def get_static_boolean_field(class_reference, field_id) -> TrueClass/FalseClass
      # def get_static_byte_field(class_reference, field_id) -> Integer
      # def get_static_char_field(class_reference, field_id) -> String
      # def get_static_short_field(class_reference, field_id) -> Integer
      # def get_static_int_field(class_reference, field_id) -> Integer
      # def get_static_long_field(class_reference, field_id) -> Integer
      # def get_static_float_field(class_reference, field_id) -> Float
      # def get_static_double_field(class_reference, field_id) -> Float
      # def set_static_object_field(class_reference, field_id, value)
      # def set_static_boolean_field(class_reference, field_id, value)
      # def set_static_byte_field(class_reference, field_id, value)
      # def set_static_char_field(class_reference, field_id, value)
      # def set_static_short_field(class_reference, field_id, value)
      # def set_static_int_field(class_reference, field_id, value)
      # def set_static_long_field(class_reference, field_id, value)
      # def set_static_float_field(class_reference, field_id, value)
      # def set_static_double_field(class_reference, field_id, value)

      # Calling Static Methods
      # def get_static_method_id(class_reference, name, signature) -> Pointer
      # def call_static_void_method(class_reference, method_id, argument_types, *args)
      # def call_static_object_method(class_reference, method_id, argument_types, *args) -> Reference
      # def call_static_boolean_method(class_reference, method_id, argument_types, *args) -> TrueClass/FalseClass
      # def call_static_byte_method(class_reference, method_id, argument_types, *args) -> Integer
      # def call_static_char_method(class_reference, method_id, argument_types, *args) -> String
      # def call_static_short_method(class_reference, method_id, argument_types, *args) -> Integer
      # def call_static_int_method(class_reference, method_id, argument_types, *args) -> Integer
      # def call_static_long_method(class_reference, method_id, argument_types, *args) -> Integer
      # def call_static_float_method(class_reference, method_id, argument_types, *args) -> Float
      # def call_static_double_method(class_reference, method_id, argument_types, *args) -> Float
    end

    class Exception < StandardError; end
    class ClassNotFound < Exception; end
    class NoSuchField < Exception; end
    class NoSuchMethod < Exception; end
    class WrongArgumentType < Exception; end
    class JavaException < Exception; end

    # Stores a JNI global reference internally
    # Do not use this class directly
    class Reference
      attr_reader :type_name, :qualifier

      def inspect
        "#<#{self.class.name} #{@type_name} #{@qualifier}>"
      end
    end

    # Stores a JNI method or field ID internally
    # Do not use this class directly
    class Pointer
      attr_reader :type_name, :qualifier

      def inspect
        "#<#{self.class.name} #{@type_name} #{@qualifier}>"
      end
    end
  end
end

GTK.dlopen('jni') if $gtk.platform? :android
