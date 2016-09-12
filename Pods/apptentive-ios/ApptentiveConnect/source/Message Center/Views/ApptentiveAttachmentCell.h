//
//  ApptentiveAttachmentCell.h
//  ApptentiveConnect
//
//  Created by Frank Schmitt on 10/23/15.
//  Copyright © 2015 Apptentive, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ApptentiveAttachmentCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *extensionLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UIButton *deleteButton;

@property (assign, nonatomic) BOOL usePlaceholder;

+ (CGSize)sizeForScreen:(UIScreen *)screen withMargin:(CGSize)margin;
+ (CGFloat)heightForScreen:(UIScreen *)screen withMargin:(CGSize)margin;

@end
