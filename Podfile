platform :ios, '9.0'

inhibit_all_warnings!
use_frameworks!

link_with 'OneBusAway', 'OneBusAwayTests'

pod 'ABReleaseNotesViewController', '0.1.0'
pod 'GoogleAnalytics', '3.14.0'
pod 'libextobjc', '0.4.1'
pod 'SVProgressHUD', :git => "https://github.com/aaronbrethorst/SVProgressHUD.git"
pod 'Masonry', '0.6.4'
pod 'DateTools', '1.7.0'

# pod 'PromiseKit', '3.0.2'
pod 'PromiseKit/CorePromise', '3.0.2'
pod 'PromiseKit/CoreLocation', '3.0.2'
pod 'PromiseKit/Foundation', '3.0.2'
pod "PromiseKit/MapKit", '3.0.2'

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
    end
  end
end