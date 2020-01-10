//
//  OBAModelService_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/20/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import XCTest;
#import "OBATestHelpers.h"

@interface OBAModelService_Tests : XCTestCase
@property(nonatomic,strong) PromisedModelService *promisedModelService;
@end

@implementation OBAModelService_Tests

- (void)setUp {
    [super setUp];

    self.promisedModelService = [OBATestHelpers tampaModelService];
}

- (void)testEncodingOfStopIDsWithAlphanumerics {
    NSURL *URL = [self URLForRequestWithStopID:@"1234" minutesBefore:5 minutesAfter:30];
    NSString *goodURLString = [NSString stringWithFormat:@"http://api.tampa.onebusaway.org/api/api/where/arrivals-and-departures-for-stop/1234.json?key=org.onebusaway.iphone&app_uid=test&app_ver=%@&version=2&minutesBefore=5&minutesAfter=30", self.appVersion];
    [self assertURL:URL equivalentToString:goodURLString];
}

- (void)testEncodingOfStopIDsWithSlashes {
    NSURL *URL = [self URLForRequestWithStopID:@"Foo/Bar" minutesBefore:5 minutesAfter:30];
    NSString *goodURLString = [NSString stringWithFormat:@"http://api.tampa.onebusaway.org/api/api/where/arrivals-and-departures-for-stop/Foo%%2FBar.json?key=org.onebusaway.iphone&app_uid=test&app_ver=%@&version=2&minutesBefore=5&minutesAfter=30", self.appVersion];
    [self assertURL:URL equivalentToString:goodURLString];
}

- (void)testEncodingOfStopIDsWithSpaces {
    NSURL *URL = [self URLForRequestWithStopID:@"Foo Bar" minutesBefore:5 minutesAfter:30];
    NSString *goodURLString = [NSString stringWithFormat:@"http://api.tampa.onebusaway.org/api/api/where/arrivals-and-departures-for-stop/Foo%%20Bar.json?key=org.onebusaway.iphone&app_uid=test&app_ver=%@&version=2&minutesBefore=5&minutesAfter=30", self.appVersion];
    [self assertURL:URL equivalentToString:goodURLString];
}

- (void)testEncodingOfStopIDsWithSlashesAndSpaces {
    NSURL *URL = [self URLForRequestWithStopID:@"Foo/Bar Baz" minutesBefore:5 minutesAfter:30];
    NSString *goodURLString = [NSString stringWithFormat:@"http://api.tampa.onebusaway.org/api/api/where/arrivals-and-departures-for-stop/Foo%%2FBar%%20Baz.json?key=org.onebusaway.iphone&app_uid=test&app_ver=%@&version=2&minutesBefore=5&minutesAfter=30", self.appVersion];
    [self assertURL:URL equivalentToString:goodURLString];
}

- (NSURL*)URLForRequestWithStopID:(NSString*)stopID
                    minutesBefore:(NSInteger)minutesBefore
                     minutesAfter:(NSInteger)minutesAfter {
    NSURLRequest *originalRequest = [self.promisedModelService buildURLRequestForStopArrivalsAndDeparturesWithID:stopID minutesBefore:minutesBefore minutesAfter:minutesAfter];
    return originalRequest.URL;
}

- (NSString*)appVersion {
    return [OBAApplication sharedApplication].formattedAppBuild;
}

#pragma mark - Assertion Helpers

/**
 * Assert the given URL is semantically identical to the given good URL string,
 * such that there's no difference except for the order of the URLs' query items.
 *
 * @param URL the actual URL obtained.
 * @param goodURLString the expected URL string to get.
 */
- (void)assertURL:(NSURL*)URL equivalentToString:(NSString*)goodURLString {
    NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
    NSURLComponents *goodURLComponents = [NSURLComponents componentsWithString:goodURLString];
    [self normalizeURLComponents:URLComponents];
    [self normalizeURLComponents:goodURLComponents];
    XCTAssertEqualObjects(URLComponents, goodURLComponents);
}

/**
 * Sort the query items of the given URLComponents by their names.
 *
 * @param URLComponents the NSURLComponents to normalize.
 */
- (void)normalizeURLComponents:(NSURLComponents*)URLComponents {
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    URLComponents.queryItems = [URLComponents.queryItems sortedArrayUsingDescriptors:@[sortDescriptor]];
}

@end
