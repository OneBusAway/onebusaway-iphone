//
//  OBATableSection.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBATableSection.h"

@interface OBATableSection () {
    NSMutableArray *_rows;
}
@end

@implementation OBATableSection

+ (instancetype)tableSectionWithTitle:(nullable NSString*)title rows:(NSArray*)rows {
    return [[self alloc] initWithTitle:title rows:rows];
}

- (instancetype)initWithTitle:(nullable NSString*)title {
    return [self initWithTitle:title rows:@[]];
}

- (instancetype)init {
    return [self initWithTitle:nil rows:@[]];
}

- (instancetype)initWithTitle:(nullable NSString*)title rows:(NSArray*)rows {
    self = [super init];
    
    if (self) {
        _title = title;
        _rows = [NSMutableArray arrayWithArray:(rows.count > 0 ? rows : @[])];
    }
    return self;
}

#pragma mark - Rows

- (void)setRows:(NSArray *)rows {
    if (rows.count == 0) {
        _rows = [NSMutableArray array];
    }
    else {
        _rows = [NSMutableArray arrayWithArray:rows];
    }
}

- (NSArray*)rows {
    return [NSArray arrayWithArray:_rows];
}

- (void)addRow:(OBABaseRow* (^)(void))addBlock {
    [_rows addObject:addBlock()];
}
@end
