//
//  OBATableSection.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBATableSection : NSObject
@property(nonatomic,copy,nullable) NSString *title;
@property(nonatomic,copy) NSArray* rows;
@property(nonatomic,strong,nullable) UIView *headerView;
@property(nonatomic,strong,nullable) UIView *footerView;

+ (instancetype)tableSectionWithTitle:(nullable NSString*)title rows:(NSArray*)rows;
- (instancetype)initWithTitle:(nullable NSString*)title rows:(NSArray*)rows NS_DESIGNATED_INITIALIZER;
@end

NS_ASSUME_NONNULL_END