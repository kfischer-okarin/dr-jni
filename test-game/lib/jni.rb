require_relative 'jni/ffi'

module JNI
  class << self
    def game_activity
      @game_activity ||= JavaObject.new(FFI.game_activity_reference)
    end

    def get_class(name)
      JavaClass.new(FFI.find_class(name))
    end

    def snake_case_to_camel_case(snake_case)
      parts = snake_case.to_s.split('_')
      [parts[0], *parts[1..].map(&:capitalize)].join
    end

    def method_signature(argument_types, return_type)
      argument_types = argument_types.map { |arg| type_signature(arg) }.join
      return_type = type_signature(return_type)
      "(#{argument_types})#{return_type}"
    end

    def type_signature(type)
      if TYPE_SIGNATURES.key? type
        TYPE_SIGNATURES[type]
      elsif type.is_a? String
        type_with_slashes = type.gsub('.', '/')
        "L#{type_with_slashes};"
      else
        raise "Unknown type: #{type}"
      end
    end
  end

  TYPE_SIGNATURES = {
    boolean: 'Z',
    byte: 'B',
    int: 'I',
    string: 'Ljava/lang/String;',
    void: 'V'
  }

  class JavaObject
    attr_reader :reference

    def initialize(reference, ffi: FFI, java_class: nil)
      @reference = reference
      @ffi = ffi
      @java_class = java_class
    end

    def java_class
      @java_class ||= JavaClass.new(@ffi.get_object_class(reference), ffi: @ffi)
    end

    def inspect
      class_name = java_class.name
      qualifier = @reference.qualifier

      if qualifier.include? class_name
        "#<#{self.class} #{qualifier}>"
      else
        "#<#{self.class} #{qualifier} (#{class_name})>"
      end
    end
  end

  class JavaClass
    attr_reader :reference

    def initialize(reference, ffi: FFI)
      @reference = reference
      @ffi = ffi
      @constructor_by_argument_count = {}
    end

    def build_new_instance(*args)
      constructor = @constructor_by_argument_count[args.size]
      raise NoSuchMethod, "No constructor for #{inspect} with #{args.size} arguments" unless constructor

      reference = @ffi.new_object(@reference, constructor[:method_id], constructor[:argument_types], *args)
      JavaObject.new(reference, ffi: @ffi, java_class: self)
    end

    def register_constructor(argument_types: [])
      signature = JNI.method_signature(argument_types, :void)
      method_id = @ffi.get_method_id(@reference, '<init>', signature)
      @constructor_by_argument_count[argument_types.size] = {
        method_id: method_id,
        argument_types: argument_types
      }
    end

    def register_static_method(name, argument_types: [], return_type: :void)
      method_name = JNI.snake_case_to_camel_case(name)
      signature = JNI.method_signature(argument_types, return_type)
      method_id = @ffi.get_static_method_id(@reference, method_name, signature)

      case return_type
      when :boolean
        define_singleton_method name do |*args|
          @ffi.call_static_boolean_method(@reference, method_id, argument_types, *args)
        end
      when :string
        define_singleton_method name do |*args|
          @ffi.call_static_object_method(@reference, method_id, argument_types, *args)
        end
      when String
        define_singleton_method name do |*args|
          result_reference = @ffi.call_static_object_method(@reference, method_id, argument_types, *args)
          JavaObject.new(result_reference, ffi: @ffi)
        end
      end
    end

    def name
      # qualifier has format 'class com.example.MyClass'
      @name ||= @reference.qualifier.split.last
    end

    def inspect
      "#<#{self.class} #{name}>"
    end
  end
end
