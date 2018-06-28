//
//  OBATestHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/9/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import Foundation;
@import OBAKit;
@import OHHTTPStubs;
#import "OBATestHarnessPersistenceLayer.h"

/* HTTP Stubs

 [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
    return [request.URL.host isEqualToString:@"mywebservice.com"];
 } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
    // Stub it with our "wsresponse.json" stub file (which is in same bundle as self)
    NSString* fixture = OHPathForFile(@"wsresponse.json", self.class);
    return [OHHTTPStubsResponse responseWithFileAtPath:fixture statusCode:200 headers:@{@"Content-Type":@"application/json"}];
 }];

 stub(isHost("mywebservice.com")) { _ in
    // Stub it with our "wsresponse.json" stub file (which is in same bundle as self)
    let stubPath = OHPathForFile("wsresponse.json", type(of: self))
    return fixture(filePath: stubPath!, headers: ["Content-Type":"application/json"])
 }
 */

NS_ASSUME_NONNULL_BEGIN

@class OBARegionV2;

@interface OBATestHelpers : NSObject

/**
 Convenience property for constructing an entire model service/factory/references stack.
 */
@property(nonatomic,strong,class,readonly) PromisedModelService *tampaModelService;

/**
 First, serializes an NSCoding compatible object into an NSData object, and then deserializes it back
 into the original kind of object that it was. Useful for testing NSCoding implementations.
 */
+ (id)roundtripObjectThroughNSCoding:(id<NSCoding>)obj;

/**
 Locates the file with the specified file name in the test bundle.

 @param fileName The name of the file to load, with extension.

 @return The full path to the file
 */
+ (NSString*)pathToTestFile:(NSString*)fileName;

/**
 Returns a string containing the contents of the provided file name. The file must be part of the test target.

 @param fileName The name of the file to load, with extension.

 @return The contents of the file as a UTF-8 string.
 */
+ (NSString*)contentsOfTestFile:(NSString*)fileName;

/**
 Returns the deserialized object from the JSON file specified.
 */
+ (id)jsonObjectFromFile:(NSString*)fileName;

/**
 Creates a deserialized object from the specified string.
 */
+ (id)jsonObjectFromString:(NSString*)string;

/**
 Used to help create test fixture data. It archives the NSCoding-conforming object to `path`, which can be outside of the iOS app sandbox.

 @param object Any object that conforms to NSCoding
 @param path   The full output path for the plist.
 */
+ (void)archiveObject:(id<NSCoding>)object toPath:(NSString*)path;

/**
 Locates the file with the specified name in the test bundle, and unarchives it.

 @param fileName A file name with extension (not a full path)

 @return The unarchived object
 */
+ (id)unarchiveBundledTestFile:(NSString*)fileName;

// Fixture Helpers

@property(class,nonatomic,readonly,copy) OBARegionV2 *pugetSoundRegion;
@property(class,nonatomic,readonly,copy) OBARegionV2 *tampaRegion;
@property(class,nonatomic,readonly,copy) NSArray<OBARegionV2*> *regionsList;

// Time and Time Zones

@property(class,nonatomic,readonly,assign) NSInteger timeZoneOffsetForTests;
@property(class,nonatomic,readonly,copy) NSTimeZone *timeZoneForTests;
+ (void)configureDefaultTimeZone;

@end

NS_ASSUME_NONNULL_END
