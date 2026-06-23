Pod::Spec.new do |s|
  s.name             = 'pm_offline'
  s.version          = '0.1.0'
  s.summary          = 'Offline near-field transport bridges for mesh-market.'
  s.description      = 'MultipeerConnectivity bridge for Apple platforms.'
  s.homepage         = 'https://hammerhead.tech'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Hammerhead' => 'hammerhead.software@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.swift_version = '5.0'
end
