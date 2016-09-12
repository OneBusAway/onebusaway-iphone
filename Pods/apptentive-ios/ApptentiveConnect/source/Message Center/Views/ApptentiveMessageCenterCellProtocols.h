//
//  ApptentiveMessageCenterCellProtocols.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/10/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

@class ApptentiveIndexedCollectionView;

@protocol ApptentiveMessageCenterCell <NSObject>

@property (weak, nonatomic) UITextView *messageLabel;

@end

@protocol ApptentiveMessageCenterCompoundCell <ApptentiveMessageCenterCell>

@property (weak, nonatomic) ApptentiveIndexedCollectionView *collectionView;
@property (assign, nonatomic) BOOL messageLabelHidden;

@end
