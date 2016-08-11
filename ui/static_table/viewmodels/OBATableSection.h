//
//  OBATableSection.h
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 12/6/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OBABaseRow;

NS_ASSUME_NONNULL_BEGIN

@interface OBATableSection : NSObject

/**
 Title of the table section
 */
@property(nonatomic,copy,nullable) NSString *title;

/**
 The rows that comprise this table section.
 */
@property(nonatomic,copy) NSArray* rows;

/**
 Optional header view for the table section.
 */
@property(nonatomic,strong,nullable) UIView *headerView;

/**
 Optional footer view for the table section.
 */
@property(nonatomic,strong,nullable) UIView *footerView;

/**
 Optionally, you can attach the represented model in order to
 make it easier to change the underlying data. You are responsible
 for setting this in your view controllers.
 */
@property(nonatomic,weak,nullable) id model;

+ (instancetype)tableSectionWithTitle:(nullable NSString*)title rows:(NSArray*)rows;
- (instancetype)initWithTitle:(nullable NSString*)title rows:(NSArray*)rows NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithTitle:(nullable NSString*)title;

- (void)addRow:(OBABaseRow* (^)(void))addBlock;
@end

NS_ASSUME_NONNULL_END