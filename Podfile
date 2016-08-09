# Uncomment this line to define a global platform for your project
platform :ios, '9.0'

use_pk_400 = !ENV['xcode8'].nil?

inhibit_all_warnings!

def pod_promise_kit
  pod 'PromiseKit/CorePromise', '3.3.0'
  pod 'PromiseKit/CoreLocation', '3.3.0'
  pod 'PromiseKit/CloudKit', '3.3.0'
  pod 'PromiseKit/Foundation', '3.3.0'
  pod 'PromiseKit/MapKit', '3.3.0'
end

target 'OBAKit' do
  use_frameworks!
  pod_promise_kit
end

target 'OneBusAway' do
  use_frameworks!

  # Pods for OneBusAway
  pod 'ABReleaseNotesViewController', '0.1.1'
  pod 'GoogleAnalytics', '3.14.0'
  pod 'libextobjc', '0.4.1'
  pod 'SVProgressHUD', '2.0.3'
  pod 'Masonry', '0.6.4'
  pod 'DateTools', '1.7.0'
  pod 'DZNEmptyDataSet', '1.7.3'
  pod 'apptentive-ios', '3.1.1'
  pod 'Pulley', '1.0.0'

  pod_promise_kit

  target 'OneBusAwayTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'OCMock', '~> 3.3'
  end

end

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
    end
  end
end
