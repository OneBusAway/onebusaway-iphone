//
//  ApptentiveAttachmentController.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 10/9/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

@class ApptentiveAttachButton, ApptentiveMessageCenterViewController;


@interface ApptentiveAttachmentController : UIResponder <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) IBOutlet ApptentiveAttachButton *attachButton;
@property (weak, nonatomic) IBOutlet ApptentiveMessageCenterViewController *viewController;

@property (readonly, nonatomic) NSArray *attachments;
@property (assign, nonatomic, getter=isActive) BOOL active;

- (void)viewDidLoad;
- (void)saveDraft;
- (void)clear;

@end


@interface ApptentiveAttachmentController (QuickLook) <QLPreviewControllerDataSource>
@end
