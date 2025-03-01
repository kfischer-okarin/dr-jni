require_relative 'jni/ffi'

module JNI
  class << self
    def game_activity
      @game_activity ||= JavaObject.new(FFI.game_activity_reference)
    end

    def [](java_class_name)
      @classes ||= {}
      @classes[java_class_name] ||= JavaClass.new(FFI.find_class(java_class_name.gsub('.', '/')))
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
      elsif type.is_a? Array
        raise 'Invalid array type' unless type.size == 1

        "[#{type_signature(type.first)}"
      else
        raise "Unknown type: #{type}"
      end
    end
  end

  TYPE_SIGNATURES = {
    boolean: 'Z',
    byte: 'B',
    char: 'C',
    short: 'S',
    int: 'I',
    long: 'J',
    float: 'F',
    double: 'D',
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

    def register_methods(methods)
      methods.each do |name, method|
        case method[:return_type]
        when String
          define_singleton_method name do |*args|
            result = @ffi.send(method[:ffi_method_name], @reference, method[:method_id], method[:argument_types], *args)
            JavaObject.new(result, ffi: @ffi)
          end
        else
          define_singleton_method name do |*args|
            @ffi.send(method[:ffi_method_name], @reference, method[:method_id], method[:argument_types], *args)
          end
        end
      end
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
      @methods = {}
      @constructor_by_argument_count = {}
    end

    def register(&block)
      RegisterDSL.new(self, @methods, @constructor_by_argument_count, @ffi).instance_eval(&block)
    end

    def build_new_instance(*args)
      constructor = @constructor_by_argument_count[args.size]
      raise NoSuchMethod, "No constructor for #{inspect} with #{args.size} arguments" unless constructor

      reference = @ffi.new_object(@reference, constructor[:method_id], constructor[:argument_types], *args)
      instance = JavaObject.new(reference, ffi: @ffi, java_class: self)
      instance.register_methods(@methods)
      instance
    end

    def name
      # qualifier has format 'class com.example.MyClass'
      @name ||= @reference.qualifier.split.last
    end

    def inspect
      "#<#{self.class} #{name}>"
    end

    class RegisterDSL
      def initialize(java_class, methods, constructor_by_argument_count, ffi)
        @java_class = java_class
        @methods = methods
        @constructor_by_argument_count = constructor_by_argument_count
        @ffi = ffi
      end

      def method(name, argument_types: [], return_type: :void)
        signature = JNI.method_signature(argument_types, return_type)
        java_method_name = JNI.snake_case_to_camel_case(name)
        method_id = @ffi.get_method_id(@java_class.reference, java_method_name, signature)
        ffi_method_name = case return_type
                          when :string, String
                            :call_object_method
                          else
                            :"call_#{return_type}_method"
                          end
        @methods[name] = { method_id: method_id, argument_types: argument_types, return_type: return_type, ffi_method_name: ffi_method_name }
      end

      def constructor(argument_types: [])
        signature = JNI.method_signature(argument_types, :void)
        method_id = @ffi.get_method_id(@java_class.reference, '<init>', signature)
        @constructor_by_argument_count[argument_types.size] = {
          method_id: method_id,
          argument_types: argument_types
        }
      end

      def static_method(name, argument_types: [], return_type: :void)
        reference = @java_class.reference
        java_method_name = JNI.snake_case_to_camel_case(name)
        signature = JNI.method_signature(argument_types, return_type)
        method_id = @ffi.get_static_method_id(reference, java_method_name, signature)

        %i[boolean byte char short int long float double].each do |type|
          if type == return_type
            method_name = "call_static_#{type}_method"
            @java_class.define_singleton_method name do |*args|
              @ffi.send(method_name, reference, method_id, argument_types, *args)
            end
            return
          end
        end

        case return_type
        when :string
          @java_class.define_singleton_method name do |*args|
            @ffi.call_static_object_method(reference, method_id, argument_types, *args)
          end
        when String
          @java_class.define_singleton_method name do |*args|
            result_reference = @ffi.call_static_object_method(reference, method_id, argument_types, *args)
            JavaObject.new(result_reference, ffi: @ffi)
          end
        end
      end
    end
  end
end
