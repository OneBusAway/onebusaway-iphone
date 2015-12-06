//
//  OBATableRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OBATableRow : NSObject
@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) NSString *subtitle;
@property(nonatomic,assign) UITableViewCellStyle style;
@property(nonatomic,assign) UITableViewCellAccessoryType accessoryType;
@property(nonatomic,copy) void (^action)();

+ (instancetype)tableRowWithTitle:(NSString*)title action:(void (^)())action;
- (instancetype)initWithTitle:(NSString*)title action:(void (^)())action;

- (NSString*)cellReuseIdentifier;
@end
