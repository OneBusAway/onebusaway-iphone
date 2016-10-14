//
//  OBAEmptyDataSetSource.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/14/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBAEmptyDataSetSource.h"

@implementation OBAEmptyDataSetSource

- (instancetype)initWithTitle:(NSString*)title description:(NSString*)description {
    self = [super init];

    if (self) {
        _title = [title copy];
        _dataSetDescription = [description copy];
    }
    return self;
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    return [[NSAttributedString alloc] initWithString:self.title];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    return [[NSAttributedString alloc] initWithString:self.dataSetDescription];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return self.image;
}

@end
