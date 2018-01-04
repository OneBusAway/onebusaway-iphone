//
//  OBAPlaceholderRow.m
//  OBAKit
//
//  Created by Aaron Brethorst on 1/4/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

#import <OBAKit/OBAPlaceholderRow.h>
#import <OBAKit/OBAViewModelRegistry.h>
#import <OBAKit/OBAPlaceholderCell.h>

@implementation OBAPlaceholderRow

+ (void)load {
    [OBAViewModelRegistry registerClass:self.class];
}

+ (void)registerViewsWithTableView:(UITableView *)tableView {
    [tableView registerClass:[OBAPlaceholderCell class] forCellReuseIdentifier:[self cellReuseIdentifier]];
}

- (NSString*)cellReuseIdentifier {
    return NSStringFromClass(self.class);
}

@end
