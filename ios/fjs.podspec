#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint fjs.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'fjs'
  s.version          = '1.0.0'
  s.summary          = 'A high-performance JavaScript runtime for Flutter applications, built with Rust and powered by QuickJS.'
  s.description      = <<-DESC
A high-performance JavaScript runtime for Flutter applications, built with Rust and powered by QuickJS.
                       DESC
  s.homepage         = 'https://github.com/fluttercandies/fjs'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'iota9star' => 'iota.9star@gmail.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  # Remove the old single line configuration
  s.swift_version = '5.0'

  s.script_phase = {
    :name => 'Build Rust library',
    # First argument is relative path to the `rust` folder, second is name of rust library
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../libfjs fjs',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    # Let XCode know that the static library referenced in -force_load below is
    # created by this build step.
    :output_files => ["${BUILT_PRODUCTS_DIR}/libfjs.a"],
  }
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    # Exclude architectures for iOS simulator only:
    # - i386: Flutter.framework does not contain a i386 slice
    # - arm64: rquickjs build issues on aarch64-apple-ios-sim target
    # Note: This ONLY affects iOS simulator, real iOS devices (arm64) work normally
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 arm64',
    'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/libfjs.a',
  }
end