# Uncomment this line to define a global platform for your project
platform :ios, '9.0'

inhibit_all_warnings!

target 'OBAKit' do
  use_frameworks!

  # pod 'PromiseKit', '3.0.2'
  pod 'PromiseKit/CorePromise', '3.0.2'
  pod 'PromiseKit/CoreLocation', '3.0.2'
  pod 'PromiseKit/CloudKit', '3.0.2'
  pod 'PromiseKit/Foundation', '3.0.2'
  pod 'PromiseKit/MapKit', '3.0.2'

end

target 'OneBusAway' do
  use_frameworks!

  # Pods for OneBusAway
  pod 'ABReleaseNotesViewController', '0.1.1'
  pod 'GoogleAnalytics', '3.14.0'
  pod 'libextobjc', '0.4.1'
  pod 'SVProgressHUD', :git => "https://github.com/aaronbrethorst/SVProgressHUD.git"
  pod 'Masonry', '0.6.4'
  pod 'DateTools', '1.7.0'
  pod 'DZNEmptyDataSet', '1.7.3'
  pod 'apptentive-ios', '3.1.1'

  # pod 'PromiseKit', '3.0.2'
  pod 'PromiseKit/CorePromise', '3.0.2'
  pod 'PromiseKit/CoreLocation', '3.0.2'
  pod 'PromiseKit/CloudKit', '3.0.2'
  pod 'PromiseKit/Foundation', '3.0.2'
  pod 'PromiseKit/MapKit', '3.0.2'


  target 'OneBusAwayTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
    end
  end
end