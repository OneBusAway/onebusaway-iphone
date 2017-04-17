//
//  OBARegionStorage.m
//  OBAKit
//
//  Created by Aaron Brethorst on 4/2/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import <OBAKit/OBARegionStorage.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBALogging.h>
#import <OBAKit/OBAKit-Swift.h>

static NSString * const OBALocalRegionsFileName = @"regions.json";

@interface OBARegionStorage()
@property(nonatomic,strong) OBAModelFactory *modelFactory;
@property(nonatomic,strong) dispatch_queue_t serialQueue;
@end

@implementation OBARegionStorage

- (instancetype)initWithModelFactory:(OBAModelFactory*)modelFactory {
    self = [super init];
    if (self) {
        _modelFactory = modelFactory;
        _serialQueue = dispatch_queue_create("org.onebusaway.iphone.region_storage", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - Public Properties

- (void)setRegions:(NSArray<OBARegionV2*>*)regions {
    _regions = regions ? [regions copy] : @[];

    [self writeRegionsToDisk:_regions];
}

#pragma mark - Persistence

+ (NSString*)localRegionsFilePath {
    return [FileHelpers pathToFileName:OBALocalRegionsFileName inDirectory:NSApplicationSupportDirectory];
}

- (void)writeRegionsToDisk:(NSArray<OBARegionV2*>*)regions {
    OBAGuard(regions) else {
        return;
    }

    dispatch_sync(self.serialQueue, ^{
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:regions];
        [data writeToFile:OBARegionStorage.localRegionsFilePath atomically:NO];
    });
}

- (NSArray<OBARegionV2*>*)readRegionsFromDisk {
    __block NSArray<OBARegionV2*>* regions = nil;
    dispatch_sync(self.serialQueue, ^{
        regions = [self persistedRegions] ?: [self bundledRegions];
    });
    return regions;
}

- (NSArray<OBARegionV2*>*)bundledRegions {
    NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"regions-v3" ofType:@"json"]];
    id JSON = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:nil];
    OBAListWithRangeAndReferencesV2 *references = [self.modelFactory getRegionsV2FromJson:JSON error:nil];

    return references.values;
}

- (nullable NSArray<OBARegionV2*>*)persistedRegions {
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    if (![fileManager fileExistsAtPath:OBARegionStorage.localRegionsFilePath]) {
        return nil;
    }

    NSArray<OBARegionV2*>* regions = nil;

    @try {
        regions = [NSKeyedUnarchiver unarchiveObjectWithFile:OBARegionStorage.localRegionsFilePath];
    } @catch (NSException *exception) {
        DDLogError(@"Failed to unarchive persisted regions: %@", exception);
    }

    return regions;
}

@end
