//
//  OBARegionV2_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/24/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OBAKit/OBAModelFactory.h>
#import <OBAKit/OBAReferencesV2.h>
#import <OBAKit/OBARegionBoundsV2.h>
#import <OBAKit/OBARegionV2.h>
#import "OBATestHelpers.h"

@interface OBARegionV2_Tests : XCTestCase
@property(nonatomic,strong) OBAModelFactory *modelFactory;
@property(nonatomic,strong) id regionsJSON;
@end

@implementation OBARegionV2_Tests

- (void)setUp {
    [super setUp];

    OBAReferencesV2 *references = [[OBAReferencesV2 alloc] init];
    self.modelFactory = [[OBAModelFactory alloc] initWithReferences:references];
    self.regionsJSON = [OBATestHelpers jsonObjectFromFile:@"regions-v3.json"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (NSArray<OBARegionV2*>*)getRegions {
    NSArray *regions = [[self.modelFactory getRegionsV2FromJson:self.regionsJSON error:nil] values];
    return regions;
}

- (OBARegionV2*)getTampaRegion {
    return [self getRegions][0];
}

- (void)testRegionsCount {
    NSArray<OBARegionV2*>* regions = [self getRegions];
    XCTAssertEqual(regions.count, 12);
}

#pragma mark - Region Name

- (void)testRemovalOfBetaTextFromName {
    OBARegionV2 *region = [[OBARegionV2 alloc] init];
    region.regionName = @"San Joaquin RTD (beta)";
    XCTAssertEqualObjects(region.regionName, @"San Joaquin RTD");
}

- (void)testRemovalOfBetaTextFromNameCaseInsensitive {
    OBARegionV2 *region = [[OBARegionV2 alloc] init];
    region.regionName = @"San Joaquin RTD (BETA)";
    XCTAssertEqualObjects(region.regionName, @"San Joaquin RTD");
}

- (void)testRemovalOfBetaTextSansParentheses {
    OBARegionV2 *region = [[OBARegionV2 alloc] init];
    region.regionName = @"San Joaquin RTD BETA";
    XCTAssertEqualObjects(region.regionName, @"San Joaquin RTD");
}

- (void)testRegionNameWithoutBeta {
    OBARegionV2 *region = [[OBARegionV2 alloc] init];
    region.regionName = @"Puget Sound";
    XCTAssertEqualObjects(region.regionName, @"Puget Sound");
}

- (void)testNilRegionName {
    OBARegionV2 *region = [[OBARegionV2 alloc] init];
    XCTAssertNil(region.regionName);
}

#pragma mark - Other Methods

- (void)testCenterCoordinate {
    OBARegionV2 *tampa = [self getTampaRegion];
    MKMapRect tampaServiceRect = MKMapRectMake(72439895.221134216, 112245249.35188442, 516632.36992569268, 476938.48868602514);
    MKMapPoint centerPoint = MKMapPointMake(MKMapRectGetMidX(tampaServiceRect), MKMapRectGetMidY(tampaServiceRect));
    CLLocationCoordinate2D knownGoodCoordinate = MKCoordinateForMapPoint(centerPoint);

    CLLocationCoordinate2D testCoordinate = tampa.centerCoordinate;

    XCTAssertEqual(knownGoodCoordinate.latitude, testCoordinate.latitude);
    XCTAssertEqual(knownGoodCoordinate.longitude, testCoordinate.longitude);
}

- (void)testValidModelsMustHaveNames {
    OBARegionV2 *region = [[OBARegionV2 alloc] init];
    region.obaBaseUrl = @"https://www.example.com";

    XCTAssertFalse(region.isValidModel);
}

- (void)testValidModelsMustBeHTTPS {
    OBARegionV2 *region = [[OBARegionV2 alloc] init];
    region.obaBaseUrl = @"https://www.example.com";
    region.regionName = @"Region Name";

    XCTAssertTrue(region.isValidModel);
}

- (void)testValidModelsCannotBeHTTP {
    OBARegionV2 *region = [[OBARegionV2 alloc] init];
    region.obaBaseUrl = @"http://www.example.com";
    region.regionName = @"Region Name";

    XCTAssertFalse(region.isValidModel);
}


#pragma mark - Tampa

- (void)testTampa {
    NSArray<OBARegionV2*>* regions = [self getRegions];
    OBARegionV2 *tampa = regions[0];

    [self testTampaWithRegion:tampa];
}

- (void)testUnarchivedTampa {
    NSArray<OBARegionV2*>* regions = [self getRegions];
    OBARegionV2 *firstTampa = regions[0];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:firstTampa];

    OBARegionV2 *tampa = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    [self testTampaWithRegion:tampa];
}

- (void)testTampaWithRegion:(OBARegionV2*)tampa {
    NSMutableArray *regionBounds = [NSMutableArray array];
    [regionBounds addObject:({
        OBARegionBoundsV2 *bounds = [[OBARegionBoundsV2 alloc] init];
        bounds.lat = 27.976910500000002;
        bounds.lon = -82.445851;
        bounds.latSpan = 0.5424609999999994;
        bounds.lonSpan = 0.576357999999999;
        bounds;
    })];
    [regionBounds addObject:({
        OBARegionBoundsV2 *bounds = [[OBARegionBoundsV2 alloc] init];
        bounds.lat = 27.919249999999998;
        bounds.lon = -82.652145;
        bounds.latSpan = 0.47208000000000183;
        bounds.lonSpan = 0.3967700000000036;
        bounds;
    })];

    MKMapRect tampaServiceRect = MKMapRectMake(72439895.221134216, 112245249.35188442, 516632.36992569268, 476938.48868602514);

    XCTAssertEqualObjects(tampa.siriBaseUrl, @"http://tampa.onebusaway.org/onebusaway-api-webapp/siri/");
    XCTAssertEqualObjects(tampa.obaVersionInfo, @"1.1.11-SNAPSHOT|1|1|11|SNAPSHOT|6950d86123a7a9e5f12065bcbec0c516f35d86d9");
    XCTAssertTrue(tampa.supportsSiriRealtimeApis);
    XCTAssertTrue(tampa.supportsObaDiscoveryApis);
    XCTAssertTrue(tampa.supportsObaRealtimeApis);
    XCTAssertFalse(tampa.experimental);
    XCTAssertEqualObjects(tampa.language, @"en_US");
    XCTAssertEqualObjects(tampa.twitterUrl, @"http://mobile.twitter.com/OBA_tampa");
    XCTAssertTrue(tampa.active);
    XCTAssertEqualObjects(tampa.facebookUrl, @"");
    XCTAssertEqualObjects(tampa.obaBaseUrl, @"http://api.tampa.onebusaway.org/api/");
    XCTAssertEqualObjects(tampa.baseURL, [NSURL URLWithString:@"http://api.tampa.onebusaway.org/api/"]);
    XCTAssertEqual(tampa.identifier, 0);
    XCTAssertEqualObjects(tampa.regionName, @"Tampa Bay");
    XCTAssertEqualObjects(tampa.contactEmail, @"onebusaway@gohart.org");
    XCTAssertEqual(tampa.bounds.count, 2);
    XCTAssertEqualObjects(tampa.bounds, regionBounds);
    XCTAssertTrue(MKMapRectEqualToRect(tampa.serviceRect, tampaServiceRect));
}

#pragma mark - Boston

- (void)testBoston {
    NSArray<OBARegionV2*>* regions = [self getRegions];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"regionName == %@", @"Boston"];
    OBARegionV2 *boston = [[regions filteredArrayUsingPredicate:predicate] firstObject];
    [self testBostonWithRegion:boston];
}

- (void)testUnarchivingBoston {
    NSArray<OBARegionV2*>* regions = [self getRegions];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"regionName == %@", @"Boston"];
    OBARegionV2 *boston = [[regions filteredArrayUsingPredicate:predicate] firstObject];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:boston];
    OBARegionV2 *bostonAgain = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    [self testBostonWithRegion:bostonAgain];
}

- (void)testBostonWithRegion:(OBARegionV2*)boston {
    XCTAssertNotNil(boston);
    XCTAssertEqualObjects(boston.obaVersionInfo, @"");
    XCTAssertTrue(boston.experimental);
}

@end
