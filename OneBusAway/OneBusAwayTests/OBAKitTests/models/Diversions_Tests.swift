//
//  Diversions_Tests.swift
//  OneBusAwayTests
//
//  Created by Aaron Brethorst on 7/20/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

import Quick
import Nimble
import OBAKit

// swiftlint:disable force_cast

class Diversions_Tests: QuickSpec {
    override func spec() {
        context("with good data") {
            let jsonData: [String: Any] = OBATestHelpers.jsonObject(fromFile: "shape_1_40046045.json") as! [String: Any]
            var polylineString: String!
            beforeEach {
                let data = jsonData["data"] as! [String: Any]
                let entry = data["entry"] as! [String: Any]
                polylineString = (entry["points"] as! String)
            }

            describe("deserialization") {
                it("has the correct bounding rect") {
                    let polyline = OBASphericalGeometryLibrary.polyline(fromEncodedShape: polylineString)
                    let boundingMapRect = polyline.boundingMapRect
                    let comparisonRect = MKMapRect.init(origin: MKMapPoint(x: 42944923.143736877, y: 93660021.209015116), size: MKMapSize(width: 70374.828714609146, height: 38123.949899420142))

                    expect(MKMapRectEqualToRect(boundingMapRect, comparisonRect)).to(beTrue())
                }
            }
        }
    }
}
