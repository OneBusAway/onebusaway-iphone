//
//  OBAEditStopBookmarkGroupViewController.h
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 12/19/13.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OBAModelDAO;
@class OBABookmarkGroup;

NS_ASSUME_NONNULL_BEGIN

@protocol OBABookmarkGroupVCDelegate <NSObject>
- (void)didSetBookmarkGroup:(nullable OBABookmarkGroup*)group;
@end

@interface OBAEditStopBookmarkGroupViewController : UITableViewController <UITextFieldDelegate>
@property (nonatomic,strong) NSArray *groups;
@property (nonatomic,strong,nullable) OBABookmarkGroup *selectedGroup;
@property (nonatomic,strong) id <OBABookmarkGroupVCDelegate> delegate;

- (id)initWithSelectedBookmarkGroup:(OBABookmarkGroup*)group;

@end

NS_ASSUME_NONNULL_END