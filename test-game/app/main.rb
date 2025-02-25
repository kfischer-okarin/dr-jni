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
    puts "========== #{name} =========="
    test.call
    results[name] = 'OK'
  rescue StandardError => e
    results[name] = "FAIL: #{e}"
    puts "  #{e.message} (#{e.class})"
  ensure
    puts '=' * (22 + name.length)
    puts ' '
  end
  args.state.results = results
end

def render_jni_test_results(args)
  args.outputs.background_color = { r: 0x00, g: 0x00, b: 0x00 }
  results = args.state.results
  y = 1260
  results.each do |name, result|
    success = result == 'OK'
    color = success ? { r: 0x62, g: 0x9e, b: 0x51 } : { r: 0xbf, g: 0x1b, b: 0x00 }
    args.outputs.labels << {
      x: 20, y: y, text: "#{name}:", size_enum: 2, **color
    }
    args.outputs.labels << {
      x: 700, y: y, text: result, size_enum: 2, alignment_enum: 2, **color
    }
    y -= 25
  end
end
