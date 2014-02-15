//
//  OBAEditBookmarkGroupViewController.h
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 28/12/2013.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OBAApplicationDelegate;
@class OBABookmarkGroup;

typedef enum {
    OBABookmarkGroupEditNew=0,
    OBABookmarkGroupEditExisting=1
} OBABookmarkGroupEditType;

@interface OBAEditBookmarkGroupViewController : UITableViewController

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate bookmarkGroup:(OBABookmarkGroup*)bookmarkGroup editType:(OBABookmarkGroupEditType)editType;

@end
