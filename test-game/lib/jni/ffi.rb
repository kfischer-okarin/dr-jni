module JNI
  module FFI
    class << self
      attr_reader :game_activity_reference

      # def find_class(name) -> Reference
      # def new_object(class_reference, method_id, argument_types, *args) -> Reference
      # def get_object_class(object_reference) -> Reference
      # def get_method_id(object_reference, name, signature) -> Pointer
      # def call_void_method(object_reference, method_id, argument_types, *args) -> nil
      # def call_object_method(object_reference, method_id, argument_types, *args) -> Reference
      # def call_boolean_method(object_reference, method_id, argument_types, *args) -> TrueClass/FalseClass
      # def call_byte_method(object_reference, method_id, argument_types, *args) -> Integer
      # def call_char_method(object_reference, method_id, argument_types, *args) -> String
      # def call_short_method(object_reference, method_id, argument_types, *args) -> Integer
      # def call_int_method(object_reference, method_id, argument_types, *args) -> Integer
      # def call_long_method(object_reference, method_id, argument_types, *args) -> Integer
      # def call_float_method(object_reference, method_id, argument_types, *args) -> Float
      # def call_double_method(object_reference, method_id, argument_types, *args) -> Float
      # def get_static_method_id(class_reference, name, signature) -> Pointer
      # def call_static_void_method(class_reference, method_id, argument_types, *args) -> nil
      # def call_static...
    end

    class Exception < StandardError; end
    class ClassNotFound < Exception; end
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
