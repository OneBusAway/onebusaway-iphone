//
//  OBATableRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBABaseRow.h"

NS_ASSUME_NONNULL_BEGIN

/*
 IMPORTANT NOTE FOR SUBCLASSERS:
 
 If you decide to subclass OBATableRow, be sure to override the
 implementation of -cellReuseIdentifier. Otherwise, the cell you
 expect to see appear will not!
 */

@interface OBATableRow : OBABaseRow
@property(nonatomic,copy,nullable) UIColor *titleColor;
@property(nonatomic,copy,nullable) NSString *title;

/**
 An attributed string that will be used to draw the title label. This takes
 precedence over `title` if it is available.
 */
@property(nonatomic,copy,nullable) NSAttributedString *attributedTitle;

@property(nonatomic,copy,nullable) NSString *subtitle;
@property(nonatomic,copy,nullable) UIFont *titleFont;
@property(nonatomic,assign) UITableViewCellStyle style;
@property(nonatomic,strong,nullable) UIImage *image;
@property(nonatomic,assign) NSTextAlignment textAlignment;
@property(nonatomic,assign) UITableViewCellSelectionStyle selectionStyle;
@property(nonatomic,strong,nullable) UIView *accessoryView;

- (instancetype)initWithTitle:(NSString*)title action:( void (^ _Nullable )())action;
- (instancetype)initWithAttributedTitle:(NSAttributedString*)attributedTitle action:( void (^ _Nullable )())action;
@end

NS_ASSUME_NONNULL_END
