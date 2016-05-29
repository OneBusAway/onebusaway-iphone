# Uncomment this line to define a global platform for your project
platform :ios, '9.0'

use_pk_400 = !ENV['xcode8'].nil?

inhibit_all_warnings!

target 'OBAKit' do
  use_frameworks!

  if use_pk_400
    pod 'PromiseKit/CorePromise', git: 'https://github.com/mxcl/PromiseKit.git', branch: '4.0.0-beta2'
    pod 'PromiseKit/CoreLocation', git: 'https://github.com/mxcl/PromiseKit.git', branch: '4.0.0-beta2'
    pod 'PromiseKit/CloudKit', git: 'https://github.com/mxcl/PromiseKit.git', branch: '4.0.0-beta2'
    pod 'PromiseKit/Foundation', git: 'https://github.com/mxcl/PromiseKit.git', branch: '4.0.0-beta2'
    pod 'PromiseKit/MapKit', git: 'https://github.com/mxcl/PromiseKit.git', branch: '4.0.0-beta2'
  else
   pod 'PromiseKit/CorePromise', '3.2.0'
   pod 'PromiseKit/CoreLocation', '3.2.0'
   pod 'PromiseKit/CloudKit', '3.2.0'
   pod 'PromiseKit/Foundation', '3.2.0'
   pod 'PromiseKit/MapKit', '3.2.0'
 end
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

  if use_pk_400
    pod 'PromiseKit/CorePromise', git: 'https://github.com/mxcl/PromiseKit.git', branch: '4.0.0-beta2'
    pod 'PromiseKit/CoreLocation', git: 'https://github.com/mxcl/PromiseKit.git', branch: '4.0.0-beta2'
    pod 'PromiseKit/CloudKit', git: 'https://github.com/mxcl/PromiseKit.git', branch: '4.0.0-beta2'
    pod 'PromiseKit/Foundation', git: 'https://github.com/mxcl/PromiseKit.git', branch: '4.0.0-beta2'
    pod 'PromiseKit/MapKit', git: 'https://github.com/mxcl/PromiseKit.git', branch: '4.0.0-beta2'
  else
   pod 'PromiseKit/CorePromise', '3.2.0'
   pod 'PromiseKit/CoreLocation', '3.2.0'
   pod 'PromiseKit/CloudKit', '3.2.0'
   pod 'PromiseKit/Foundation', '3.2.0'
   pod 'PromiseKit/MapKit', '3.2.0'
 end

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
