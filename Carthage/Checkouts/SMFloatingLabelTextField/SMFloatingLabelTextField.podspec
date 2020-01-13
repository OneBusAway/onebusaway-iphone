#
# Be sure to run `pod lib lint SMFloatingLabelTextField.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SMFloatingLabelTextField'
  s.version          = '0.3.1'
  s.summary          = 'A subclass of UITextField that displays floating placeholder'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This CocoaPod providers the ability to use a UITextField that displays floating placeholder. When user type some text into field, or text is set programatically, placeholder label is displayed above field itself. The placeholder labes appears and disappears using animation.
                       DESC

  s.homepage         = 'https://github.com/AzimoLabs/SMFloatingLabelTextField'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Michał Moskała' => 'micmos@azimo.com' }
  s.source           = { :git => 'https://github.com/AzimoLabs/SMFloatingLabelTextField.git', :tag => s.version.to_s }
   s.social_media_url = 'https://twitter.com/azimolabs'

  s.ios.deployment_target = '8.0'

  s.source_files = 'SMFloatingLabelTextField/Classes/**/*'
  
  # s.resource_bundles = {
  #   'SMFloatingLabelTextField' => ['SMFloatingLabelTextField/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
