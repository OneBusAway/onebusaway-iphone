//
//  WeatherForecast_Tests.swift
//  OneBusAwayTests
//
//  Created by Aaron Brethorst on 7/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import Quick
import Nimble
import OBAKit
import IGListKit

class WeatherForecast_Tests: QuickSpec {
    override func spec() {
        context("With good data") {
            let data = OBATestHelpers.data(fromFile: "weather.json")
            var weatherForecast: WeatherForecast!
            beforeEach {
                let decoder = WeatherForecast.decoder
                // swiftlint:disable force_try
                weatherForecast = try! decoder.decode(WeatherForecast.self, from: data)
                // swiftlint:enable force_try
            }

            describe("deserialization") {

                it("has the correct lat/lon") {
                    expect(weatherForecast.latitude).to(equal(47.63671875))
                    expect(weatherForecast.longitude).to(equal(-122.6953125))
                }

                it("has the right region identifier") {
                    expect(weatherForecast.regionIdentifier).to(equal(1))
                }

                it("has the right region name") {
                    expect(weatherForecast.regionName).to(equal("Puget Sound"))
                }

                it("has the right retrieval date") {
                    let date = Date(timeIntervalSince1970: 1531262074)
                    expect(weatherForecast.forecastRetrievedAt).to(equal(date))
                }

                it("has the right summary") {
                    expect(weatherForecast.todaySummary).to(equal("Partly cloudy until this evening."))
                }

                it("has the right icon") {
                    expect(weatherForecast.currentForecast.icon).to(equal("partly-cloudy-day"))
                }

                it("has the right precipitation probability") {
                    expect(weatherForecast.currentForecast.precipProbability).to(equal(0))
                }

                it("has the right currentTemperature") {
                    expect(weatherForecast.currentForecast.temperature).to(equal(72.5))
                }
            }

            describe("IGListKit Integration") {
                it("conforms to the ListDiffable protocol") {
                    let conformity = weatherForecast.conforms(to: ListDiffable.self)
                    expect(conformity).to(beTrue())
                }
            }
        }
    }
}
