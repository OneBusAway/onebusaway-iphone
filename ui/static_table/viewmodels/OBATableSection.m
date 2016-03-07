//
//  OBATableSection.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBATableSection.h"

@implementation OBATableSection

+ (instancetype)tableSectionWithTitle:(nullable NSString*)title rows:(NSArray*)rows {
    return [[self alloc] initWithTitle:title rows:rows];
}

- (instancetype)init {
    return [self initWithTitle:nil rows:@[]];
}

- (instancetype)initWithTitle:(nullable NSString*)title rows:(NSArray*)rows {
    self = [super init];
    
    if (self) {
        _title = title;
        _rows = rows;
    }
    return self;
}
@end
