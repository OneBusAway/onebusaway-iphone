//
//  ModelFactory_Tests.swift
//  OneBusAwayTests
//
//  Created by Aaron Brethorst on 7/24/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import Quick
import Nimble
import OBAKit

// swiftlint:disable force_cast

class ModelFactory_getAgenciesWithCoverageV2_Tests: QuickSpec {
    override func spec() {
        context("with good data") {
            let modelFactory = OBAModelFactory.init()
            let jsonData = OBATestHelpers.jsonDictionary(fromFile: "agencies_with_coverage.json")
            var listWithRange: OBAListWithRangeAndReferencesV2!
            var agencies: [OBAAgencyWithCoverageV2]!
            var error: NSError?

            beforeEach {
                // The model factory expects that only the `data` field gets passed in.
                let subset = jsonData["data"] as! [String: Any]
                listWithRange = modelFactory.getAgenciesWithCoverageV2(fromJson: subset, error: &error)
                agencies = listWithRange.values as! [OBAAgencyWithCoverageV2]
            }

            describe("list with range") {
                it("has the expected values") {
                    expect(listWithRange.limitExceeded).to(beFalse())
                    expect(listWithRange.outOfRange).to(beFalse())
                    expect(listWithRange.references).toNot(beNil())
                }
            }

            describe("agency data") {
                it("has the right number of elements") {
                    expect(agencies.count).to(equal(12))
                }

                it("has the correct information for Sound Transit") {
                    let soundTransit = agencies[8]
                    expect(soundTransit.agencyId).to(equal("40"))
                    expect(soundTransit.agency?.name).to(equal("Sound Transit"))
                    expect(soundTransit.lat).to(equal(47.532444))
                    expect(soundTransit.lon).to(equal(-122.329459))
                    expect(soundTransit.latSpan).to(equal(0.8850059999999971))
                    expect(soundTransit.lonSpan).to(equal(0.621138000000002))

                    let regionBounds = OBARegionBoundsV2(lat: 47.532444, latSpan: 0.8850059999999971, lon: -122.329459, lonSpan: 0.621138000000002)
                    expect(soundTransit.regionBounds).to(equal(regionBounds))
                }
            }

            describe("modelFactory.references") {
                it("has a list of agencies") {
                    expect(modelFactory.references.agencies.keys.count).to(equal(12))
                }
            }

            describe("error") {
                it("is nil") {
                    expect(error).to(beNil())
                }
            }
        }
    }
}
