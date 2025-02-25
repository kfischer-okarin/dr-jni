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

TESTS = {}
TESTS['Access Game Activity'] = lambda do
end

def run_jni_tests(args)
  results = {}
  TESTS.each do |name, test|
    test.call
    results[name] = 'OK'
  rescue StandardError => e
    results[name] = "FAIL: #{e}"
    puts e
  end
  args.state.results = results
end

def render_jni_test_results(args)
  results = args.state.results
  y = 1260
  results.each do |name, result|
    args.outputs.labels << {
      x: 20, y: y, text: "#{name}: #{result}", size_enum: 2
    }
    y -= 20
  end
end
