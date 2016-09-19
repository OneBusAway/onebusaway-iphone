//
//  OBAEditBookmarkGroupViewController.h
//  org.onebusaway.iphone
//
//  Created by Aengus McMillin on 28/12/2013.
//  Copyright (c) 2013 OneBusAway. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OBAKit/OBAKit.h>

typedef NS_ENUM(NSInteger, OBABookmarkGroupEditType) {
    OBABookmarkGroupEditNew=0,
    OBABookmarkGroupEditExisting,
};

NS_ASSUME_NONNULL_BEGIN

@interface OBAEditBookmarkGroupViewController : UITableViewController
@property(nonatomic,strong) OBAModelDAO *modelDAO;

- (instancetype)initWithBookmarkGroup:(OBABookmarkGroup*)bookmarkGroup editType:(OBABookmarkGroupEditType)editType;

@end

NS_ASSUME_NONNULL_END
