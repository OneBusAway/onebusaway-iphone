//
//  OBATimelineBarRow.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/16/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATimelineBarRow.h"
#import "OBAViewModelRegistry.h"
#import "OBATimelineBarCell.h"

@implementation OBATimelineBarRow

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

+ (void)registerViewsWithTableView:(UITableView*)tableView {
    [tableView registerClass:[OBATimelineBarCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

- (NSString*)cellReuseIdentifier {
    return [self.class cellReuseIdentifier];
}

+ (NSString*)cellReuseIdentifier {
    return NSStringFromClass(self);
}
@end
