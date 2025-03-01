require 'tests/test_helper'

describe JNI do
  describe 'can calculate a method signature' do
    [
      [[], :void, '()V'],
      [%i[int boolean], :boolean, '(IZ)Z'],
      [%i[string], :string, '(Ljava/lang/String;)Ljava/lang/String;'],
      [[], 'my.package.MyClass', '()Lmy/package/MyClass;'],
      [[%i[int]], :void, '([I)V'],
    ].each do |argument_types, return_type, expected|
      it "for #{argument_types} -> #{return_type}" do
        result = JNI.method_signature(argument_types, return_type)
        assert.equal! result, expected
      end
    end
  end
end

module JNI
  describe JavaObject do
    it 'can retrieve its JavaClass' do
      ffi = a_mock {
        responding_to(:get_object_class) {
          always_returning({ qualifier: 'class com.example.MyObject' })
        }
      }
      object_reference = Object.new
      object = JavaObject.new(object_reference, ffi: ffi)

      result = object.java_class

      assert.equal! result.name, 'com.example.MyObject'
      assert.received_call! ffi, :get_object_class, [object_reference]
    end
  end

  describe JavaClass do
    it 'can build a new instance' do
      method_id = 1234
      ffi = a_mock {
        responding_to(:get_method_id) {
          always_returning(method_id)
        }
        responding_to(:new_object) {
          always_returning({ qualifier: 'com.example.MyClass' })
        }
      }

      class_reference = { qualifier: 'class com.example.MyClass' }
      java_class = JavaClass.new(class_reference, ffi: ffi)

      java_class.register do
        constructor argument_types: []
      end
      assert.received_call! ffi, :get_method_id, [class_reference, '<init>', '()V']

      instance = java_class.build_new_instance
      assert.received_call! ffi, :new_object, [class_reference, method_id, []]
      assert.equal! instance.class, JavaObject
    end

    it 'can register and call a static boolean method' do
      method_id = 1234
      ffi = a_mock {
        responding_to(:get_static_method_id) {
          always_returning(method_id)
        }
        responding_to(:call_static_boolean_method) {
          always_returning(true)
        }
      }
      class_reference = { qualifier: 'class com.example.MyClass' }
      java_class = JavaClass.new(class_reference, ffi: ffi)

      java_class.register do
        static_method :my_method, argument_types: %i[int boolean], return_type: :boolean
      end

      assert.received_call! ffi, :get_static_method_id, [class_reference, 'myMethod', '(IZ)Z']

      result = java_class.my_method(1, true)

      assert.received_call! ffi, :call_static_boolean_method, [class_reference, method_id, %i[int boolean], 1, true]
      assert.equal! result, true
    end

    it 'can register and call a static string method' do
      method_id = 1234
      ffi = a_mock {
        responding_to(:get_static_method_id) {
          always_returning(method_id)
        }
        responding_to(:call_static_object_method) {
          always_returning('Hello, World!')
        }
      }
      class_reference = { qualifier: 'class com.example.MyClass' }
      java_class = JavaClass.new(class_reference, ffi: ffi)

      java_class.register do
        static_method :my_method, argument_types: %i[int], return_type: :string
      end

      assert.received_call! ffi, :get_static_method_id, [class_reference, 'myMethod', '(I)Ljava/lang/String;']

      result = java_class.my_method(1)

      assert.received_call! ffi, :call_static_object_method, [class_reference, method_id, %i[int], 1]
      assert.equal! result, 'Hello, World!'
    end

    it 'can register and call a static object method' do
      method_id = 1234
      ffi = a_mock {
        responding_to(:get_static_method_id) do
          always_returning(method_id)
        end
        responding_to(:call_static_object_method) {
          always_returning({ qualifier: 'some result representation' })
        }
      }
      class_reference = { qualifier: 'class com.example.MyClass' }
      java_class = JavaClass.new(class_reference, ffi: ffi)

      java_class.register do
        static_method :my_method, argument_types: %i[int], return_type: 'java.lang.Integer'
      end

      assert.received_call! ffi, :get_static_method_id, [class_reference, 'myMethod', '(I)Ljava/lang/Integer;']

      result = java_class.my_method(1)

      assert.received_call! ffi, :call_static_object_method, [class_reference, method_id, %i[int], 1]
      assert.equal! result.class, JavaObject
      assert.equal! result.reference.qualifier, 'some result representation'
    end
  end
end
