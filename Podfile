platform :ios, '9.0'

inhibit_all_warnings!
use_frameworks!

link_with 'OneBusAway', 'OneBusAwayTests'

pod 'TWSReleaseNotesView', '1.2.0'
pod 'GoogleAnalytics-iOS-SDK', '3.11'
pod 'libextobjc', '0.4.1'
pod 'SVProgressHUD', '2.0-beta'
pod 'PromiseKit', '3.0.2'

post_install do |installer_representation|
  installer_representation.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
    end
  end
end