//
//  OBATestHelpers.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/9/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OBATestHarnessPersistenceLayer.h"

@class OBARegionV2;

@interface OBATestHelpers : NSObject

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
 Used to help create test fixture data. It archives the NSCoding-conforming object to path, which can be outside of the iOS app sandbox.

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

+ (OBARegionV2*)pugetSoundRegion;

+ (OBARegionV2*)tampaRegion;

@end
