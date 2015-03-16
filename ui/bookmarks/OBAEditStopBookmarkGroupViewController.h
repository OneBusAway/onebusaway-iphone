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
@class OBAApplicationDelegate;

@protocol OBABookmarkGroupVCDelegate <NSObject>
- (void)didSetBookmarkGroup:(OBABookmarkGroup*)group;
@end

@interface OBAEditStopBookmarkGroupViewController : UITableViewController <UITextFieldDelegate>
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic, strong) OBAApplicationDelegate *appDelegate;
@property (nonatomic, strong) OBABookmarkGroup *selectedGroup;
@property (nonatomic, strong) id <OBABookmarkGroupVCDelegate> delegate;

- (id)initWithAppDelegate:(OBAApplicationDelegate*)appDelegate selectedBookmarkGroup:(OBABookmarkGroup*)group;

@end
