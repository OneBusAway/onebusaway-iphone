//
//  OBATestHelpers.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/9/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATestHelpers.h"

@implementation OBATestHelpers

+ (NSString*)pathToTestFile:(NSString*)fileName {
    return [[NSBundle bundleForClass:self.class] pathForResource:[fileName stringByDeletingPathExtension] ofType:[fileName pathExtension]];
}

+ (void)archiveObject:(id<NSCoding>)object toPath:(NSString*)path {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    [data writeToFile:path atomically:YES];
}

+ (id)unarchiveBundledTestFile:(NSString*)fileName {
    NSString *filePath = [OBATestHelpers pathToTestFile:fileName];
    NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

@end
