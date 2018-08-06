//
//  OBAButtonBarRow.h
//  OBAKit
//
//  Created by Aaron Brethorst on 8/13/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

@import UIKit;
#import <OBAKit/OBABaseRow.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAButtonBarRow : OBABaseRow
@property(nonatomic,strong) NSArray<UIBarButtonItem*>* barButtonItems;

- (instancetype)initWithBarButtonItems:(NSArray<UIBarButtonItem*>*)barButtonItems NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithAction:(nullable OBARowAction)action NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
