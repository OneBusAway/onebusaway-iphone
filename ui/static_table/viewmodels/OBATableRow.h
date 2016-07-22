//
//  OBATableRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBABaseRow.h"

@interface OBATableRow : OBABaseRow
@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) NSString *subtitle;
@property(nonatomic,assign) UITableViewCellStyle style;
@property(nonatomic,strong) UIImage *image;
@property(nonatomic,assign) NSTextAlignment textAlignment;

- (instancetype)initWithTitle:(NSString*)title action:(void (^)())action;
+ (instancetype)tableRowWithTitle:(NSString*)title action:(void (^)())action;
@end
