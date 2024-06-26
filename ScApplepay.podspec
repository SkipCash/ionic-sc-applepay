require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'ScApplepay'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  # s.platforms = {
  #   'ios' => '15.0'
  # }
  s.homepage = package['repository']['url']
  s.author = package['author']
  s.source = { :git => package['repository']['url'], :tag => s.version.to_s }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m,c,cc,mm,cpp,xcframework}'
  # s.ios.deployment_target  = '13.0'

  s.vendored_frameworks = 'ios/Plugin/Frameworks/SkipCashSDK.xcframework'
  s.dependency 'Capacitor'
  s.frameworks = 'SkipCashSDK'
  s.swift_version = '5.1'
end
