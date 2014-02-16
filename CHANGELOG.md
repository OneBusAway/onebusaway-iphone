# Changelog for OneBusAway for iPhone

## 2.2

* Added support for finding and contributing information about bus stops in Stop Details page for Puget Sound (see http://stopinfo.pugetsound.onebusaway.org for more details)
* Added option to show experimental servers (such as Washington D.C.)
* Added feature to create groups for bookmarks
* Fixed address search by updating to Google Geocoding V3 API
* Fixed "Out of Service Area" message appearing for certain covered areas
* Made various accessibility improvements for VoiceOver
* UI consistency improvement
* Upgraded TestFlight SDK
* Added Google Analytics
* Attached subject and footer with relevant info to e-mail under "Contact Us"

## 2.1

Special thanks to the volunteer developers and many testers for their work on this version!

New:
* Startup on last opened tab
* Design for iOS 7 users
* Load arrivals beyond 35 minutes in the future
* View your current location on the route map
* Link to feature request tracker, be sure to vote on and suggest new features from the Info tab
* Link to Facebook page
* What's new message in app
* Analytics package to help determine what parts of the app are most popular as well as fix bugs and crashes
* Display usage purposes of location services on initial permission prompt

* Cosmetic improvements
* Improved search results at high zoom levels and when searching at locations not near your current location
* Improved map status message logic
* Improved list view when no stops present
* Improved debugging information
* Fixed bug where trips departing in 1 or -1 minutes would appear as departing NOW
* Fixed bugs only exposed with location services disabled
* Fixed trip problem reporting bugs
* Fixed bug where zooming in on current location would force zoom out
* Fixed bug where you couldn't select route after searching and receiving multiple route results
* Removed obsolete code

##2.0.1

* Fixes bug with connection error when location services are disabled 
* Fixes bug with "Report a problem"

## 2.0

Special thanks to Sebastian Kießling, Chaya Hiruncharoenvate, and the many testers for their work on this version!

* Added multiregion support - now also includes Atlanta, GA and Tampa, FL
* Extended search radius to 15,000 meters
* Fixed bug where you couldn't select the route if multiple options appeared (e.g. searching for "A Line")
* Updated privacy policy link
* Updated copyright notice
* Fix and improve "No stops at this location" logic
* Other small bug fixes

## 1.2

Special thanks to Sebastian Kießling, Aaron Brethorst, and all other parties involved for making this update possible. 

* Support for larger iPhone 5 screen
* New search from map screen
* Updated user interface with OneBusAway branding (green)
* New app icon
* Current location displayed with standard iOS maps blue dot
* VoiceOver accessibility improvements
* Added privacy policy link
* Updated credits
* Default API now points at new Puget Sound API server address
* Code cleanup
* Other random bug fixes
