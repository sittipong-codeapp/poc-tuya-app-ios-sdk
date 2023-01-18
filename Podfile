source 'https://cdn.cocoapods.org/'
source 'https://github.com/tuya/TuyaPublicSpecs.git'
source 'https://github.com/tuya/tuya-pod-specs.git'

platform :ios, '12.0'

target 'smart-life-sdk' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for smart-life-sdk
  use_modular_headers!

  pod 'SVProgressHUD'
  pod 'SGQRCode', '~> 4.1.0'

  pod 'TuyaSmartHomeKit', '>= 4.0.0'
end

post_install do |installer|
  `cd TuyaAppSDKSample-iOS-Swift; [[ -f AppKey.swift ]] || cp AppKey.swift.default AppKey.swift;`
  
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end

