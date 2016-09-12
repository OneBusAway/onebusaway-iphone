//
//  ApptentiveCompoundReplyCell.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 11/10/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterReplyCell.h"
#import "ApptentiveMessageCenterCellProtocols.h"

@class ApptentiveIndexedCollectionView;


@interface ApptentiveCompoundReplyCell : ApptentiveMessageCenterReplyCell <ApptentiveMessageCenterCompoundCell>

@property (weak, nonatomic) IBOutlet ApptentiveIndexedCollectionView *collectionView;
@property (assign, nonatomic) BOOL messageLabelHidden;

@end
