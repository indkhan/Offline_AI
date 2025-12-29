# llama_wrapper.podspec
# CocoaPods spec for building llama_wrapper on iOS

Pod::Spec.new do |s|
  s.name             = 'llama_wrapper'
  s.version          = '1.0.0'
  s.summary          = 'Native llama.cpp wrapper for Flutter'
  s.description      = 'Provides on-device LLM inference using llama.cpp'
  s.homepage         = 'https://github.com/example/offline_llm_app'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Developer' => 'dev@example.com' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '14.0'
  
  s.source_files = [
    '../native/llama_wrapper.cpp',
    '../native/llama_wrapper.h',
    '../native/llama.cpp/src/**/*.{cpp,c}',
    '../native/llama.cpp/common/**/*.{cpp,c}',
    '../native/llama.cpp/ggml/src/**/*.{cpp,c}',
  ]
  
  s.public_header_files = '../native/llama_wrapper.h'
  
  s.header_mappings_dir = '../native'
  
  s.preserve_paths = [
    '../native/llama.cpp/**/*'
  ]
  
  s.xcconfig = {
    'HEADER_SEARCH_PATHS' => [
      '"${PODS_ROOT}/../native"',
      '"${PODS_ROOT}/../native/llama.cpp/include"',
      '"${PODS_ROOT}/../native/llama.cpp/common"',
      '"${PODS_ROOT}/../native/llama.cpp/ggml/include"',
      '"${PODS_ROOT}/../native/llama.cpp/ggml/src"',
    ].join(' '),
    'GCC_PREPROCESSOR_DEFINITIONS' => 'GGML_USE_ACCELERATE=1 NDEBUG=1',
    'OTHER_CPLUSPLUSFLAGS' => '-std=c++17 -O3 -fexceptions -frtti -DGGML_USE_ACCELERATE',
    'OTHER_CFLAGS' => '-O3 -DGGML_USE_ACCELERATE',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'GCC_OPTIMIZATION_LEVEL' => '3',
  }
  
  s.frameworks = 'Accelerate', 'Foundation', 'Metal', 'MetalKit'
  s.library = 'c++'
  
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'VALID_ARCHS' => 'arm64',
  }
  
  s.compiler_flags = '-Wno-shorten-64-to-32'
end
