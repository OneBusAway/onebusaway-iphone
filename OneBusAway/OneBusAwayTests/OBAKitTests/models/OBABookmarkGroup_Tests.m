//
//  OBABookmarkGroup_Tests.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/25/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OBATestHelpers.h"

#import <OBAKit/OBAModelFactory.h>
#import <OBAKit/OBAReferencesV2.h>
#import <OBAKit/OBABookmarkGroup.h>

/**
 TODO: WRITE TESTS
 */

@interface OBABookmarkGroup_Tests : XCTestCase
@property(nonatomic,strong) OBAModelFactory *modelFactory;
@end

@implementation OBABookmarkGroup_Tests

- (void)setUp {
    [super setUp];

    OBAReferencesV2 *references = [[OBAReferencesV2 alloc] init];
    self.modelFactory = [[OBAModelFactory alloc] initWithReferences:references];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRegionFiltering {

    OBARegionV2 *tampa = [OBATestHelpers tampaRegion];
    OBARegionV2 *pugetSound = [OBATestHelpers pugetSoundRegion];

    OBABookmarkGroup *group = [[OBABookmarkGroup alloc] initWithName:@"group"];
    OBABookmarkV2 *bookmarkTampa = [[OBABookmarkV2 alloc] init];
    bookmarkTampa.regionIdentifier = tampa.identifier;

    OBABookmarkV2 *bookmarkPugetSound = [[OBABookmarkV2 alloc] init];
    bookmarkPugetSound.regionIdentifier = pugetSound.identifier;

    [group addBookmark:bookmarkTampa];
    [group addBookmark:bookmarkPugetSound];

    NSArray *tampaBookmarks = [group bookmarksInRegion:tampa];

    XCTAssertEqual(tampaBookmarks.count, 1);
    XCTAssertEqualObjects(tampaBookmarks.firstObject, bookmarkTampa);
}

@end
