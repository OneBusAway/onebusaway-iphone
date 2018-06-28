//
//  OBATestHelpers.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/9/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATestHelpers.h"

@implementation OBATestHelpers

+ (PromisedModelService*)tampaModelService {
    NSURL *URL = [NSURL URLWithString:@"http://api.tampa.onebusaway.org/api/"];
    return [PromisedModelService modelServiceWithBaseURL:URL];
}

+ (id)roundtripObjectThroughNSCoding:(id<NSCoding>)obj {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:obj];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

+ (NSString*)pathToTestFile:(NSString*)fileName {
    return [[NSBundle bundleForClass:self.class] pathForResource:[fileName stringByDeletingPathExtension] ofType:[fileName pathExtension]];
}

+ (NSString*)contentsOfTestFile:(NSString*)fileName {
    return [NSString stringWithContentsOfFile:[self pathToTestFile:fileName] encoding:NSUTF8StringEncoding error:nil];
}

+ (id)jsonObjectFromFile:(NSString*)fileName {
    NSString *filePath = [OBATestHelpers pathToTestFile:fileName];
    NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
    assert(data.length > 0);
    return [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:nil];
}

+ (id)jsonObjectFromString:(NSString*)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:nil];
}

+ (void)archiveObject:(id<NSCoding>)object toPath:(NSString*)path {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    [data writeToFile:path atomically:YES];
}

+ (id)unarchiveBundledTestFile:(NSString*)fileName {
    NSString *filePath = [OBATestHelpers pathToTestFile:fileName];
    NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
    assert(data.length > 0);
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

+ (OBARegionV2*)pugetSoundRegion {
    return self.regionsList[1];
}

+ (OBARegionV2*)tampaRegion {
    return self.regionsList[0];
}

+ (NSArray<OBARegionV2*>*)regionsList {
    OBAModelFactory *modelFactory = [[OBAModelFactory alloc] initWithReferences:[[OBAReferencesV2 alloc] init]];
    id jsonData = [OBATestHelpers jsonObjectFromFile:@"regions-v3.json"][@"data"];
    OBAListWithRangeAndReferencesV2 *list = [modelFactory getRegionsV2FromJson:jsonData error:nil];
    return list.values;
}

#pragma mark - Time and Time Zones

// this is the number of seconds that Seattle is behind GMT during DST.
+ (NSInteger)timeZoneOffsetForTests {
    return -25200;
}

+ (NSTimeZone*)timeZoneForTests {
    return [NSTimeZone timeZoneForSecondsFromGMT:[OBATestHelpers timeZoneOffsetForTests]];
}

+ (void)configureDefaultTimeZone {
    NSTimeZone.defaultTimeZone = [OBATestHelpers timeZoneForTests];
}

@end
