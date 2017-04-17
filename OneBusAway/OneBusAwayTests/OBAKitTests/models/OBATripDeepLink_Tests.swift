//
//  OBATripDeepLink_Tests.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 4/16/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import Quick
import Nimble
import OBAKit

class OBATripDeepLink_Tests: QuickSpec {
    override func spec() {
        context("in Tampa") {
            let region = OBATestHelpers.tampaRegion

            describe("a deep link") {
                var deepLink: OBATripDeepLink!
                beforeEach {
                    deepLink = OBATripDeepLink.init()
                    deepLink.regionIdentifier = region.identifier
                    deepLink.stopID = "Hillsborough Area Regional Transit_4551"
                    deepLink.tripID = "Hillsborough Area Regional Transit_232378"
                    deepLink.serviceDate = 1486098000000
                    deepLink.stopSequence = 8
                }

                it("has a properly encoded URL") {
                    let deepLinkURL = URL.init(string: "https://www.onebusaway.co/regions/0/stops/Hillsborough%20Area%20Regional%20Transit_4551/trips?trip_id=Hillsborough%20Area%20Regional%20Transit_232378&service_date=1486098000000&stop_sequence=8")!
                    expect(deepLink.deepLinkURL).to(equal(deepLinkURL))
                }
            }
        }

        context("in Puget Sound") {
            let region = OBATestHelpers.pugetSoundRegion

            describe("a deep link") {
                var deepLink: OBATripDeepLink!
                beforeEach {
                    deepLink = OBATripDeepLink.init()
                    deepLink.regionIdentifier = region.identifier
                    deepLink.stopID = "1_1234567"
                    deepLink.tripID = "1_232378"
                    deepLink.serviceDate = 1486098000000
                    deepLink.stopSequence = 8
                }

                it("has a properly encoded URL") {
                    let deepLinkURL = URL.init(string: "https://www.onebusaway.co/regions/1/stops/1_1234567/trips?trip_id=1_232378&service_date=1486098000000&stop_sequence=8")!
                    expect(deepLink.deepLinkURL).to(equal(deepLinkURL))
                }
            }
        }
    }
}
