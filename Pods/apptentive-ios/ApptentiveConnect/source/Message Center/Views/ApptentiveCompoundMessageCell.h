//
//  ApptentiveCompoundMessageCell.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 10/23/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveMessageCenterMessageCell.h"
#import "ApptentiveMessageCenterCellProtocols.h"

@class ATIndexedCollectionView;


@interface ApptentiveCompoundMessageCell : ApptentiveMessageCenterMessageCell <ApptentiveMessageCenterCompoundCell>

@property (weak, nonatomic) IBOutlet ApptentiveIndexedCollectionView *collectionView;
@property (assign, nonatomic) BOOL messageLabelHidden;

@end
