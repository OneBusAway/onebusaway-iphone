//
//  OBATableSection.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBATableSection.h"
@import OBAKit;

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

- (void)addRowWithBlock:(OBABaseRow* (^)(void))addBlock {
    [_rows addObject:addBlock()];
}

- (void)addRow:(OBABaseRow*)row {
    [_rows addObject:row];
}

- (void)removeRowAtIndex:(NSUInteger)index {
    OBAGuard(index < self.rows.count) else {
        return;
    }

    [_rows removeObjectAtIndex:index];
}
@end
