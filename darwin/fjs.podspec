#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint fjs.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'fjs'
  s.version          = '3.3.0'
  s.summary          = 'A high-performance JavaScript runtime for Flutter applications, built with Rust and powered by QuickJS.'
  s.description      = <<-DESC
A high-performance JavaScript runtime for Flutter applications, built with Rust and powered by QuickJS.
                       DESC
  s.homepage         = 'https://github.com/fluttercandies/fjs'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'iota9star' => 'iota.9star@gmail.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'fjs/Sources/fjs/**/*'

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.14'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'

  s.swift_version = '5.0'

  s.script_phase = {
    :name => 'Build Rust library',
    :script => 'sh "$PODS_TARGET_SRCROOT/../cargokit/build_pod.sh" ../libfjs fjs',
    :execution_position => :before_compile,
    :input_files => ['${BUILT_PRODUCTS_DIR}/cargokit_phony'],
    :output_files => ["${BUILT_PRODUCTS_DIR}/libfjs.a"],
  }

  s.ios.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/libfjs.a',
  }
  s.osx.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_LDFLAGS' => '-force_load ${BUILT_PRODUCTS_DIR}/libfjs.a',
  }
end
