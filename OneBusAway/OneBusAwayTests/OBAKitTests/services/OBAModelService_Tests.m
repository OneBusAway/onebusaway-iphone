//
//  OBAModelService_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/20/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OBATestHelpers.h"

@interface OBAModelService_Tests : XCTestCase
@property(nonatomic,strong) OBAModelService *modelService;
@end

@implementation OBAModelService_Tests

- (void)setUp {
    [super setUp];

    self.modelService = [OBAModelService modelServiceWithBaseURL:[NSURL URLWithString:@"http://api.tampa.onebusaway.org/api/"]];
}

- (void)testEncodingOfStopIDsWithAlphanumerics {
    NSURL *URL = [self URLForRequestWithStopID:@"1234" minutesBefore:5 minutesAfter:30];
    NSString *goodURLString = [NSString stringWithFormat:@"http://api.tampa.onebusaway.org/api/api/where/arrivals-and-departures-for-stop/1234.json?key=org.onebusaway.iphone&app_uid=test&app_ver=%@&version=2&minutesAfter=30&minutesBefore=5", self.appVersion];
    XCTAssertEqualObjects(URL.absoluteString, goodURLString);
}

- (void)testEncodingOfStopIDsWithSlashes {
    NSURL *URL = [self URLForRequestWithStopID:@"Foo/Bar" minutesBefore:5 minutesAfter:30];
    NSString *goodURLString = [NSString stringWithFormat:@"http://api.tampa.onebusaway.org/api/api/where/arrivals-and-departures-for-stop/Foo%%2FBar.json?key=org.onebusaway.iphone&app_uid=test&app_ver=%@&version=2&minutesAfter=30&minutesBefore=5",self.appVersion];
    XCTAssertEqualObjects(goodURLString, URL.absoluteString);
}

- (void)testEncodingOfStopIDsWithSpaces {
    NSURL *URL = [self URLForRequestWithStopID:@"Foo Bar" minutesBefore:5 minutesAfter:30];
    NSString *goodURLString = [NSString stringWithFormat:@"http://api.tampa.onebusaway.org/api/api/where/arrivals-and-departures-for-stop/Foo%%20Bar.json?key=org.onebusaway.iphone&app_uid=test&app_ver=%@&version=2&minutesAfter=30&minutesBefore=5", self.appVersion];
    XCTAssertEqualObjects(goodURLString, URL.absoluteString);
}

- (void)testEncodingOfStopIDsWithSlashesAndSpaces {
    NSURL *URL = [self URLForRequestWithStopID:@"Foo/Bar Baz" minutesBefore:5 minutesAfter:30];
    NSString *goodURLString = [NSString stringWithFormat:@"http://api.tampa.onebusaway.org/api/api/where/arrivals-and-departures-for-stop/Foo%%2FBar%%20Baz.json?key=org.onebusaway.iphone&app_uid=test&app_ver=%@&version=2&minutesAfter=30&minutesBefore=5", self.appVersion];
    XCTAssertEqualObjects(goodURLString, URL.absoluteString);
}


- (NSURL*)URLForRequestWithStopID:(NSString*)stopID minutesBefore:(NSInteger)minutesBefore minutesAfter:(NSInteger)minutesAfter {
    OBAModelServiceRequest *request = [self.modelService requestStopWithArrivalsAndDeparturesForId:stopID withMinutesBefore:minutesBefore withMinutesAfter:minutesAfter completionBlock:^(id responseData, NSUInteger responseCode, NSError *error) {}];
    NSURLRequest *originalRequest = request.connection.originalRequest;
    return originalRequest.URL;
}

- (NSString*)appVersion {
    return [OBAApplication sharedApplication].formattedAppBuild;
}

@end
