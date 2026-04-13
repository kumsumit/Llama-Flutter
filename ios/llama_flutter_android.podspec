Pod::Spec.new do |s|
  s.name             = 'llama_flutter_android'
  s.version          = '0.1.2'
  s.summary          = 'Run GGUF models on iOS/Android with llama.cpp'
  s.description      = 'A Flutter plugin to run GGUF quantized LLM models locally using llama.cpp, with Metal GPU acceleration on iOS.'
  s.homepage         = 'https://github.com/dragneel2074/Llama-Flutter'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'dragneel2074' => '' }
  s.source           = { :path => '.' }
  s.ios.deployment_target = '14.0'
  s.swift_version    = '5.0'
  s.dependency 'Flutter'

  # Copy llama.cpp sources into the pod's own directory so CocoaPods
  # glob resolution works correctly regardless of symlink depth.
  s.prepare_command = <<-CMD
    set -e
    LLAMA_SRC="$(pwd)/../android/src/main/cpp/llama.cpp"
    DST="$(pwd)/llama_cpp_src"
    rm -rf "$DST"
    mkdir -p "$DST"
    cp -r "$LLAMA_SRC/include"       "$DST/include"
    cp -r "$LLAMA_SRC/src"           "$DST/src"
    cp -r "$LLAMA_SRC/ggml"          "$DST/ggml"
  CMD

  llama_root = '$(PODS_TARGET_SRCROOT)/llama_cpp_src'

  s.source_files = [
    'Classes/**/*.{swift,h,m,mm}',
    'llama_cpp_src/src/*.cpp',
    'llama_cpp_src/ggml/src/ggml.c',
    'llama_cpp_src/ggml/src/ggml.cpp',
    'llama_cpp_src/ggml/src/ggml-alloc.c',
    'llama_cpp_src/ggml/src/ggml-backend.cpp',
    'llama_cpp_src/ggml/src/ggml-backend-reg.cpp',
    'llama_cpp_src/ggml/src/ggml-opt.cpp',
    'llama_cpp_src/ggml/src/ggml-quants.c',
    'llama_cpp_src/ggml/src/ggml-threading.cpp',
    'llama_cpp_src/ggml/src/gguf.cpp',
    'llama_cpp_src/ggml/src/ggml-cpu/ggml-cpu.c',
    'llama_cpp_src/ggml/src/ggml-cpu/ggml-cpu.cpp',
    'llama_cpp_src/ggml/src/ggml-cpu/quants.c',
    'llama_cpp_src/ggml/src/ggml-cpu/binary-ops.cpp',
    'llama_cpp_src/ggml/src/ggml-cpu/ops.cpp',
    'llama_cpp_src/ggml/src/ggml-cpu/repack.cpp',
    'llama_cpp_src/ggml/src/ggml-metal/ggml-metal.cpp',
    'llama_cpp_src/ggml/src/ggml-metal/ggml-metal-common.cpp',
    'llama_cpp_src/ggml/src/ggml-metal/ggml-metal-device.cpp',
    'llama_cpp_src/ggml/src/ggml-metal/ggml-metal-ops.cpp',
  ]

  s.resource_bundles = {
    'llama_flutter_android_metal' => [
      'llama_cpp_src/ggml/src/ggml-metal/ggml-metal.metal',
    ]
  }

  s.frameworks = 'Metal', 'MetalKit', 'MetalPerformanceShaders', 'Accelerate', 'Foundation'
  s.libraries  = 'c++'

  s.pod_target_xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS'  => '$(inherited) GGML_USE_METAL=1 NDEBUG=1',
    'OTHER_CPLUSPLUSFLAGS'          => '$(inherited) -std=c++17 -O3 -DNDEBUG -DGGML_USE_METAL=1',
    'OTHER_CFLAGS'                  => '$(inherited) -O3 -DNDEBUG -DGGML_USE_METAL=1',
    'CLANG_CXX_LANGUAGE_STANDARD'  => 'c++17',
    'HEADER_SEARCH_PATHS'           => [
      "#{llama_root}/include",
      "#{llama_root}/ggml/include",
      "#{llama_root}/src",
      "#{llama_root}/ggml/src",
      "#{llama_root}/ggml/src/ggml-cpu",
      "#{llama_root}/ggml/src/ggml-metal",
    ].join(' '),
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }
end
