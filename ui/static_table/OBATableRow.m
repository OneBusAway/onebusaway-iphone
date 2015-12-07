//
//  OBATableRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBATableRow.h"

@implementation OBATableRow

+ (instancetype)tableRowWithTitle:(NSString*)title action:(void (^)())action {
    return [[self alloc] initWithTitle:title action:action];
}

- (instancetype)initWithTitle:(NSString*)title action:(void (^)())action {
    self = [super init];
    
    if (self) {
        _title = title;
        _action = action;
    }
    return self;
}

#pragma mark - Public

- (NSString*)cellReuseIdentifier {
    return [NSString stringWithFormat:@"UITableViewCell_Style_%@", @(self.style)];
}

@end
