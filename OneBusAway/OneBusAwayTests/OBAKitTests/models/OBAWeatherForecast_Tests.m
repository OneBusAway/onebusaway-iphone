//
//  OBAWeatherForecast_Tests.m
//  OneBusAwayTests
//
//  Created by Aaron Brethorst on 5/20/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

@import XCTest;
@import Mantle;
#import "OBATestHelpers.h"
#import <OBAKit/OBAWeatherForecast.h>

@interface OBAWeatherForecast_Tests : XCTestCase
@end

@implementation OBAWeatherForecast_Tests

- (void)setUp {
    [super setUp];

    [OBATestHelpers configureDefaultTimeZone];
}

- (void)testDeserialization {
    NSDictionary *jsonData = [OBATestHelpers jsonObjectFromFile:@"weather.json"];
    NSError *error = nil;
    OBAWeatherForecast *forecast = [MTLJSONAdapter modelOfClass:OBAWeatherForecast.class fromJSONDictionary:jsonData error:&error];

    XCTAssertNil(error);

    XCTAssertEqual(forecast.latitude, 47.63671875);
    XCTAssertEqual(forecast.longitude, -122.6953125);
    XCTAssertEqual(forecast.regionIdentifier, 1);
    XCTAssertEqualObjects(forecast.regionName, @"Puget Sound");
    XCTAssertEqualObjects(forecast.forecastRetrievedAt, [NSDate dateWithTimeIntervalSince1970:1526882190]);
    XCTAssertEqualObjects(forecast.currentSummary, @"Mostly Cloudy");
    XCTAssertEqualObjects(forecast.currentSummaryIconName, @"partly-cloudy-night");
    XCTAssertEqual(forecast.currentPrecipProbability, 0);
    XCTAssertEqual(forecast.currentTemperature, 54.09);
}

@end
