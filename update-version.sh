#!/usr/bin/env ruby

require 'date'

PLISTBUDDY_PATH = "/usr/libexec/PlistBuddy"
PLISTS = [
  './OneBusAway/Info.plist',
  './OneBusAway Today/Info.plist',
  './OBAKit/Info.plist'
]

def update_build_version
  build_version = DateTime.now.strftime("%Y%m%d.%H")

  puts "Updating bundle build number to #{build_version}."

  PLISTS.each do |plist|
    %x( #{PLISTBUDDY_PATH} -c "Set :CFBundleVersion #{build_version}" "#{plist}" )
  end  
end

def update_version
  app_version = ARGV[0]

  puts "Updating app version to #{app_version}"

  PLISTS.each do |plist|
    %x( #{PLISTBUDDY_PATH} -c "Set :CFBundleShortVersionString #{app_version}" "#{plist}" )
  end
end

update_build_version
update_version if ARGV.count > 0
