#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint snowm_scanner.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'stratosfy_scanner'
  s.version          = '0.0.1'
  s.summary          = 'A scanner package to scan snowm beacons.'
  s.description      = <<-DESC
A scanner package to scan snowm beacons.
                       DESC
  s.homepage         = 'https://snowm.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'SnowM Inc.' => 'info@snowm.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '10.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
end
