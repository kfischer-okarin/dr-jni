#include <stdbool.h>
#include <dragonruby.h>
#include <jni.h>

// Global reference to DragonRuby's API
static drb_api_t *drb;
// Global reference to JNIEnv
static JNIEnv *jni_env;

struct references {
  struct RClass *jni;
  struct RClass *jni_reference;
  struct RClass *jni_pointer;
  struct RClass *jni_exception;
};

static struct references refs;

// ----- JNI Debugging Helpers -----

static void print_last_jni_exception() {
  if ((*jni_env)->ExceptionCheck(jni_env)) {
    (*jni_env)->ExceptionDescribe(jni_env);
    (*jni_env)->ExceptionClear(jni_env);
  }
}

static void drb_log_writef(const char *format, ...) {
  va_list args;
  va_start(args, format);
  char buffer[1000];
  vsnprintf(buffer, 1000, format, args);
  drb->drb_log_write("Game", 2, buffer);
  va_end(args);
}

// ----- Helper Functions -----

static mrb_value jstring_to_mrb_string(mrb_state *mrb, jstring jstring) {
  const char *cstr = (*jni_env)->GetStringUTFChars(jni_env, jstring, NULL);
  mrb_value result = drb->mrb_str_new_cstr(mrb, cstr);
  (*jni_env)->ReleaseStringUTFChars(jni_env, jstring, cstr);
  return result;
}

static jstring get_java_object_class_name(jobject object) {
  jclass class_class = (*jni_env)->FindClass(jni_env, "java/lang/Class");
  jmethodID get_name_method = (*jni_env)->GetMethodID(jni_env, class_class, "getName", "()Ljava/lang/String;");
  jclass object_class = (*jni_env)->GetObjectClass(jni_env, object);
  return (*jni_env)->CallObjectMethod(jni_env, object_class, get_name_method);
}

static bool jstring_equals_cstr(jstring jstring, const char *expected_cstr) {
  const char *cstr = (*jni_env)->GetStringUTFChars(jni_env, jstring, NULL);
  bool result = strcmp(cstr, expected_cstr) == 0;
  (*jni_env)->ReleaseStringUTFChars(jni_env, jstring, cstr);
  return result;
}

// ----- JNI Reference Data Type -----

static const jstring java_object_to_string(jobject object) {
  jclass class = (*jni_env)->GetObjectClass(jni_env, object);
  jmethodID to_string_method = (*jni_env)->GetMethodID(jni_env, class, "toString", "()Ljava/lang/String;");
  return (*jni_env)->CallObjectMethod(jni_env, object, to_string_method);
}

static void jni_reference_free(mrb_state *mrb, void *ptr) {
  (*jni_env)->DeleteGlobalRef(jni_env, ptr);
}

static const mrb_data_type jni_reference_data_type = {
    "JNI::Reference",
    jni_reference_free,
};

static mrb_value wrap_jni_reference_in_object(mrb_state *mrb,
                                              jobject reference,
                                              const char *type_name) {
  jobject global_reference = (*jni_env)->NewGlobalRef(jni_env, reference);
  struct RData *data = drb->mrb_data_object_alloc(mrb, refs.jni_reference, global_reference, &jni_reference_data_type);
  mrb_value result = drb->mrb_obj_value(data);
  drb->mrb_iv_set(mrb, result, drb->mrb_intern_lit(mrb, "@type_name"), drb->mrb_str_new_cstr(mrb, type_name));

  jstring qualifier = java_object_to_string(reference);
  drb->mrb_iv_set(mrb, result, drb->mrb_intern_lit(mrb, "@qualifier"), jstring_to_mrb_string(mrb, qualifier));
  return result;
}

static jobject unwrap_jni_reference_from_object(mrb_state *mrb, mrb_value object) {
  return drb->mrb_data_check_get_ptr(mrb, object, &jni_reference_data_type);
}

// ----- JNI Reference Data Type END -----

// ----- JNI Pointer Data Type -----

static mrb_value wrap_jni_pointer_in_object(mrb_state *mrb, void *pointer, const char *type_name, mrb_value qualifier) {
  mrb_value pointer_value = drb->mrb_word_boxing_cptr_value(mrb, pointer);
  mrb_value result = drb->mrb_obj_new(mrb, refs.jni_pointer, 0, NULL);
  drb->mrb_iv_set(mrb, result, drb->mrb_intern_lit(mrb, "@pointer"), pointer_value);
  drb->mrb_iv_set(mrb, result, drb->mrb_intern_lit(mrb, "@type_name"), drb->mrb_str_new_cstr(mrb, type_name));
  drb->mrb_iv_set(mrb, result, drb->mrb_intern_lit(mrb, "@qualifier"), qualifier);
  return result;
}

static void *unwrap_jni_pointer_from_object(mrb_state *mrb, mrb_value object) {
  mrb_value pointer_value = drb->mrb_iv_get(mrb, object, drb->mrb_intern_lit(mrb, "@pointer"));
  return mrb_cptr(pointer_value);
}

// ----- JNI Pointer Data Type END -----

static jstring get_exception_message(jthrowable exception) {
  jclass exception_class = (*jni_env)->GetObjectClass(jni_env, exception);
  jmethodID get_message_method = (*jni_env)->GetMethodID(jni_env, exception_class, "getMessage", "()Ljava/lang/String;");
  return (*jni_env)->CallObjectMethod(jni_env, exception, get_message_method);
}

static void handle_jni_exception(mrb_state *mrb) {
  jthrowable exception = (*jni_env)->ExceptionOccurred(jni_env);
  if (exception == NULL) {
    return;
  }
  (*jni_env)->ExceptionClear(jni_env);

  jstring exception_class_name = get_java_object_class_name(exception);
  mrb_value exception_message = jstring_to_mrb_string(mrb, get_exception_message(exception));

  struct RClass *exception_class = drb->mrb_class_get_under(mrb, refs.jni, "JavaException");

  if (jstring_equals_cstr(exception_class_name, "java.lang.ClassNotFoundException")) {
    exception_class = drb->mrb_class_get_under(mrb, refs.jni, "ClassNotFound");
  } else if (jstring_equals_cstr(exception_class_name, "java.lang.NoSuchMethodError")) {
    exception_class = drb->mrb_class_get_under(mrb, refs.jni, "NoSuchMethod");
  } else {
    exception_message = drb->mrb_str_cat_cstr(mrb, exception_message, " (");
    exception_message = drb->mrb_str_cat_str(mrb, exception_message, jstring_to_mrb_string(mrb, exception_class_name));
    exception_message = drb->mrb_str_cat_cstr(mrb, exception_message, ")");
  }

  drb->mrb_exc_raise(mrb, drb->mrb_exc_new_str(mrb, exception_class, exception_message));
}

// ----- JNI Methods -----

static mrb_value jni_find_class_m(mrb_state *mrb, mrb_value self) {
  const char *class_name;
  drb->mrb_get_args(mrb, "z", &class_name);

  jclass class = (*jni_env)->FindClass(jni_env, class_name);
  handle_jni_exception(mrb);

  return wrap_jni_reference_in_object(mrb, class, "jclass");
}

typedef jmethodID (*jni_method_id_getter_fn)(JNIEnv*, jclass, const char*, const char*);

static mrb_value jni_get_method_id_with_getter(mrb_state *mrb, mrb_value self, jni_method_id_getter_fn getter_fn) {
  mrb_value class_reference;
  const char *method_name;
  const char *method_signature;
  drb->mrb_get_args(mrb, "ozz", &class_reference, &method_name, &method_signature);

  jclass class = (jclass)unwrap_jni_reference_from_object(mrb, class_reference);
  jmethodID method_id = getter_fn(jni_env, class, method_name, method_signature);
  handle_jni_exception(mrb);

  mrb_value qualifier = drb->mrb_iv_get(mrb, class_reference, drb->mrb_intern_lit(mrb, "@qualifier"));
  qualifier = drb->mrb_str_dup(mrb, qualifier); // Copy the string to avoid modifying the original
  qualifier = drb->mrb_str_cat_cstr(mrb, qualifier, " ");
  qualifier = drb->mrb_str_cat_cstr(mrb, qualifier, method_name);
  qualifier = drb->mrb_str_cat_cstr(mrb, qualifier, method_signature);

  return wrap_jni_pointer_in_object(mrb, method_id, "jmethodID", qualifier);
}

static mrb_value jni_get_static_method_id_m(mrb_state *mrb, mrb_value self) {
  return jni_get_method_id_with_getter(mrb, self, (*jni_env)->GetStaticMethodID);
}

static mrb_value jni_get_method_id_m(mrb_state *mrb, mrb_value self) {
  return jni_get_method_id_with_getter(mrb, self, (*jni_env)->GetMethodID);
}

static mrb_value jni_get_object_class_m(mrb_state *mrb, mrb_value self) {
  mrb_value object_reference;
  drb->mrb_get_args(mrb, "o", &object_reference);

  jobject object = unwrap_jni_reference_from_object(mrb, object_reference);
  jclass class = (*jni_env)->GetObjectClass(jni_env, object);
  handle_jni_exception(mrb);

  return wrap_jni_reference_in_object(mrb, class, "jclass");
}

static jvalue *convert_mrb_args_to_jni_args(mrb_state *mrb,
                                            mrb_value *args,
                                            mrb_int argc,
                                            mrb_value argument_types_array) {
  jvalue *jni_args = drb->mrb_malloc(mrb, sizeof(jvalue) * argc);

  // error message
  char *error_message = NULL;
  int error_argument_index = -1;

  for (int i = 0; i < argc; i++) {
    mrb_value type = RARRAY_PTR(argument_types_array)[i];

    if (mrb_symbol_p(type)) {
      const char *type_name = drb->mrb_sym2name(mrb, mrb_symbol(type));

      if (strcmp(type_name, "boolean") == 0) {
        if (mrb_true_p(args[i]) || mrb_false_p(args[i])) {
          jni_args[i].z = (jboolean)mrb_bool(args[i]);
        } else {
          error_message = "Expected boolean argument";
        }
      } else if (strcmp(type_name, "byte") == 0) {
        if (mrb_integer_p(args[i])) {
          jni_args[i].b = (jbyte)mrb_integer(args[i]);
        } else {
          error_message = "Expected byte argument";
        }
      } else if (strcmp(type_name, "char") == 0) {
        if (mrb_string_p(args[i]) && RSTRING_LEN(args[i]) == 1) {
          jni_args[i].c = (jchar)RSTRING_PTR(args[i])[0];
        } else {
          error_message = "Expected char argument";
        }
      } else if (strcmp(type_name, "short") == 0) {
        if (mrb_integer_p(args[i])) {
          jni_args[i].s = (jshort)mrb_integer(args[i]);
        } else {
          error_message = "Expected short argument";
        }
      } else if (strcmp(type_name, "int") == 0) {
        if (mrb_integer_p(args[i])) {
          jni_args[i].i = (jint)mrb_integer(args[i]);
        } else {
          error_message = "Expected int argument";
        }
      } else if (strcmp(type_name, "long") == 0) {
        if (mrb_integer_p(args[i])) {
          jni_args[i].j = (jlong)mrb_integer(args[i]);
        } else {
          error_message = "Expected long argument";
        }
      } else if (strcmp(type_name, "float") == 0) {
        if (mrb_float_p(args[i])) {
          jni_args[i].f = (jfloat)mrb_float(args[i]);
        } else {
          error_message = "Expected float argument";
        }
      } else if (strcmp(type_name, "double") == 0) {
        if (mrb_float_p(args[i])) {
          jni_args[i].d = (jdouble)mrb_float(args[i]);
        } else {
          error_message = "Expected double argument";
        }
      } else if (strcmp(type_name, "string") == 0) {
        if (mrb_string_p(args[i])) {
          jni_args[i].l = (*jni_env)->NewStringUTF(jni_env, drb->mrb_string_value_cstr(mrb, &args[i]));
        } else if (mrb_nil_p(args[i])) {
          jni_args[i].l = NULL;
        } else {
          error_message = "Expected string argument or nil";
        }
      } else {
        error_message = "Unknown type symbol";
      }
    } else if (mrb_string_p(type)) {
      // Java class type
      if (drb->mrb_obj_is_instance_of(mrb, args[i], refs.jni_reference)) {
        jobject obj = unwrap_jni_reference_from_object(mrb, args[i]);
        jni_args[i].l = obj;
      } else if (mrb_nil_p(args[i])) {
        jni_args[i].l = NULL;
      } else {
        error_message = "Expected JNI::Reference object or nil";
      }
    } else {
      error_message = "Type must be a symbol or string";
    }

    if (error_message) {
      error_argument_index = i;
      break;
    }
  }

  if (error_message) {
    drb->mrb_free(mrb, jni_args);
    struct RClass *exception_class = drb->mrb_class_get_under(mrb, refs.jni, "WrongArgumentType");
    drb->mrb_raisef(mrb, exception_class, "Argument %d: %s", error_argument_index + 1, error_message);
    return NULL;
  }

  return jni_args;
}

#define CALL_METHOD_BEGINNING\
  mrb_value object_reference;\
  mrb_value method_id_reference;\
  mrb_value argument_types_array;\
  mrb_value *args;\
  mrb_int argc;\
  drb->mrb_get_args(mrb, "ooo*", &object_reference, &method_id_reference, &argument_types_array, &args, &argc);\
  \
  jobject object = unwrap_jni_reference_from_object(mrb, object_reference);\
  jmethodID method_id = (jmethodID)unwrap_jni_pointer_from_object(mrb, method_id_reference);\
  \
  if (!mrb_array_p(argument_types_array) || RARRAY_LEN(argument_types_array) != argc) {\
    drb->mrb_raise(mrb, refs.jni_exception, "argument_types must be an array with the same length as args");\
    return mrb_nil_value();\
  }\
  \
  jvalue *jni_args = convert_mrb_args_to_jni_args(mrb, args, argc, argument_types_array);

#define CALL_METHOD_CLEANUP\
  drb->mrb_free(mrb, jni_args);\
  handle_jni_exception(mrb);

static mrb_value jni_call_static_void_method_m(mrb_state *mrb, mrb_value self) {
  CALL_METHOD_BEGINNING;

  (*jni_env)->CallStaticVoidMethodA(jni_env, (jclass)object, method_id, jni_args);

  CALL_METHOD_CLEANUP;

  return mrb_nil_value();
}

static mrb_value jni_call_static_object_method_m(mrb_state *mrb, mrb_value self) {
  CALL_METHOD_BEGINNING;

  jobject jni_result = (*jni_env)->CallStaticObjectMethodA(jni_env, (jclass)object, method_id, jni_args);

  CALL_METHOD_CLEANUP;

  if (jstring_equals_cstr(get_java_object_class_name(jni_result), "java.lang.String")) {
    return jstring_to_mrb_string(mrb, (jstring) jni_result);
  }

  return wrap_jni_reference_in_object(mrb, jni_result, "jobject");
}

static mrb_value jni_call_static_boolean_method_m(mrb_state *mrb, mrb_value self) {
  CALL_METHOD_BEGINNING;

  jboolean jni_result = (*jni_env)->CallStaticBooleanMethodA(jni_env, (jclass)object, method_id, jni_args);

  CALL_METHOD_CLEANUP;

  return mrb_bool_value(jni_result);
}

static mrb_value jni_call_static_byte_method_m(mrb_state *mrb, mrb_value self) {
  CALL_METHOD_BEGINNING;

  jbyte jni_result = (*jni_env)->CallStaticByteMethodA(jni_env, (jclass)object, method_id, jni_args);

  CALL_METHOD_CLEANUP;

  return mrb_fixnum_value(jni_result);
}

static mrb_value jni_call_static_char_method_m(mrb_state *mrb, mrb_value self) {
  CALL_METHOD_BEGINNING;

  jchar jni_result = (*jni_env)->CallStaticCharMethodA(jni_env, (jclass)object, method_id, jni_args);

  CALL_METHOD_CLEANUP;

  return drb->mrb_str_new_cstr(mrb, (char *)&jni_result);
}

static mrb_value jni_call_static_short_method_m(mrb_state *mrb, mrb_value self) {
  CALL_METHOD_BEGINNING;

  jshort jni_result = (*jni_env)->CallStaticShortMethodA(jni_env, (jclass)object, method_id, jni_args);

  CALL_METHOD_CLEANUP;

  return mrb_fixnum_value(jni_result);
}

static mrb_value jni_call_static_int_method_m(mrb_state *mrb, mrb_value self) {
  CALL_METHOD_BEGINNING;

  jint jni_result = (*jni_env)->CallStaticIntMethodA(jni_env, (jclass)object, method_id, jni_args);

  CALL_METHOD_CLEANUP;

  return mrb_fixnum_value(jni_result);
}

static mrb_value jni_call_static_long_method_m(mrb_state *mrb, mrb_value self) {
  CALL_METHOD_BEGINNING;

  jlong jni_result = (*jni_env)->CallStaticLongMethodA(jni_env, (jclass)object, method_id, jni_args);

  CALL_METHOD_CLEANUP;

  return mrb_fixnum_value(jni_result);
}

static mrb_value jni_call_static_float_method_m(mrb_state *mrb, mrb_value self) {
  CALL_METHOD_BEGINNING;

  jfloat jni_result = (*jni_env)->CallStaticFloatMethodA(jni_env, (jclass)object, method_id, jni_args);

  CALL_METHOD_CLEANUP;

  return drb->mrb_float_value(mrb, jni_result);
}

static mrb_value jni_call_static_double_method_m(mrb_state *mrb, mrb_value self) {
  CALL_METHOD_BEGINNING;

  jdouble jni_result = (*jni_env)->CallStaticDoubleMethodA(jni_env, (jclass)object, method_id, jni_args);

  CALL_METHOD_CLEANUP;

  return drb->mrb_float_value(mrb, jni_result);
}

static mrb_value jni_new_object_m(mrb_state *mrb, mrb_value self) {
  CALL_METHOD_BEGINNING;

  jobject jni_result = (*jni_env)->NewObjectA(jni_env, (jclass)object, method_id, jni_args);

  CALL_METHOD_CLEANUP;

  return wrap_jni_reference_in_object(mrb, jni_result, "jobject");
}

// ----- JNI Methods END -----

DRB_FFI_EXPORT
void drb_register_c_extensions_with_api(mrb_state *mrb, struct drb_api_t *local_drb) {
  drb = local_drb;
  drb->drb_log_write("Game", 2, "* INFO - Retrieving JNIEnv");
  jni_env = (JNIEnv *)drb->drb_android_get_jni_env();

  refs.jni = drb->mrb_module_get_under(mrb, drb->mrb_module_get(mrb, "JNI"), "FFI");
  refs.jni_pointer = drb->mrb_class_get_under(mrb, refs.jni, "Pointer");
  refs.jni_reference = drb->mrb_class_get_under(mrb, refs.jni, "Reference");
  refs.jni_exception = drb->mrb_class_get_under(mrb, refs.jni, "Exception");
  MRB_SET_INSTANCE_TT(refs.jni_reference, MRB_TT_DATA);

  drb->mrb_define_class_method(mrb, refs.jni, "find_class", jni_find_class_m, MRB_ARGS_REQ(1));
  drb->mrb_define_class_method(mrb, refs.jni, "get_object_class", jni_get_object_class_m, MRB_ARGS_REQ(1));
  drb->mrb_define_class_method(mrb, refs.jni, "get_static_method_id", jni_get_static_method_id_m, MRB_ARGS_REQ(3));
  drb->mrb_define_class_method(mrb, refs.jni, "get_method_id", jni_get_method_id_m, MRB_ARGS_REQ(3));

#define FOR_JNI_TYPE(type)\
  drb->mrb_define_class_method(mrb,\
                               refs.jni,\
                               "call_static_" #type "_method",\
                               jni_call_static_ ## type ## _method_m,\
                               MRB_ARGS_REQ(3) | MRB_ARGS_REST());
#include "define_for_jni_types.c.inc"
#undef FOR_JNI_TYPE

  drb->mrb_define_class_method(mrb, refs.jni, "new_object", jni_new_object_m, MRB_ARGS_REQ(3) | MRB_ARGS_REST());

  jobject activity = (jobject) drb->drb_android_get_sdl_activity();
  drb->mrb_iv_set(mrb,
                  drb->mrb_obj_value(refs.jni),
                  drb->mrb_intern_lit(mrb, "@game_activity_reference"),
                  wrap_jni_reference_in_object(mrb, activity, "jobject"));
}
