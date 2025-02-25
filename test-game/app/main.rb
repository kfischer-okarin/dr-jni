require 'lib/jni'

def tick(args)
  if $gtk.platform? :android
    if Kernel.tick_count.zero?
      run_jni_tests(args)
    else
      render_jni_test_results(args)
    end
  else
    args.outputs.labels << {
      x: 640, y: 360, text: 'This example only works on Android.', size_enum: 2,
      alignment_enum: 1, vertical_alignment_enum: 1
    }
  end
end

def run_jni_tests(args)

end

def render_jni_test_results(args)

end
