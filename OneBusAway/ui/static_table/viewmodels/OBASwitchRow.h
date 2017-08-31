//
//  OBASwitchRow.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 8/21/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBATableRow.h"

NS_ASSUME_NONNULL_BEGIN

@interface OBASwitchRow : OBATableRow
@property(nonatomic,assign) BOOL switchValue;
- (instancetype)initWithTitle:(NSString*)title action:(nullable OBARowAction)action switchValue:(BOOL)switchValue;
@end

NS_ASSUME_NONNULL_END
