platform :ios, '9.3'

def pod_promise_kit
  pod 'PromiseKit/CorePromise', '3.5.1'
  pod 'PromiseKit/CoreLocation', '3.5.1'
  pod 'PromiseKit/CloudKit', '3.5.1'
  pod 'PromiseKit/Foundation', '3.5.1'
  pod 'PromiseKit/MapKit', '3.5.1'
end

target 'OBAKit' do
  use_frameworks!
  pod_promise_kit
end

target 'OneBusAway' do
  use_frameworks!

  # Pods for OneBusAway
  pod 'GoogleAnalytics', '3.16.0'
  pod 'libextobjc', '0.4.1'
  pod 'SVProgressHUD', '2.0.3'
  pod 'Masonry', '1.0.1'
  pod 'DateTools', '1.7.0'
  pod 'DZNEmptyDataSet', '1.8.1'
  pod 'apptentive-ios', '3.2.1'
  pod 'Pulley', '1.0.0'
  # pod 'SwiftMessages', '1.1.3'
  pod 'SwiftMessages', git: 'https://github.com/SwiftKickMobile/SwiftMessages.git', :branch => 'swift2.3'

  pod 'SMFloatingLabelTextField', '0.2.0'

  pod_promise_kit

  target 'OneBusAwayTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'OCMock', '3.3.1'
  end

end

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
    end
  end
end
