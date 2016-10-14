//
//  OBAEmptyDataSetSource.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/14/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

@import DZNEmptyDataSet;

NS_ASSUME_NONNULL_BEGIN

@interface OBAEmptyDataSetSource : NSObject<DZNEmptyDataSetSource>
@property(nonatomic,copy,nullable) NSString *title;
@property(nonatomic,copy,nullable) NSString *dataSetDescription;
@property(nonatomic,strong,nullable) UIImage *image;

- (instancetype)initWithTitle:(NSString*)title description:(nullable NSString*)description;

@end

NS_ASSUME_NONNULL_END
