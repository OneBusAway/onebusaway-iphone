//
//  OBATableRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBABaseRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBATableRow : OBABaseRow
@property(nonatomic,copy,nullable) UIColor *titleColor;
@property(nonatomic,copy,nullable) NSString *title;
@property(nonatomic,copy,nullable) NSString *subtitle;
@property(nonatomic,assign) UITableViewCellStyle style;
@property(nonatomic,strong,nullable) UIImage *image;
@property(nonatomic,assign) NSTextAlignment textAlignment;
@property(nonatomic,assign) UITableViewCellSelectionStyle selectionStyle;
@property(nonatomic,strong,nullable) UIView *accessoryView;

- (instancetype)initWithTitle:(NSString*)title action:( void (^ _Nullable )())action;
@end

NS_ASSUME_NONNULL_END
