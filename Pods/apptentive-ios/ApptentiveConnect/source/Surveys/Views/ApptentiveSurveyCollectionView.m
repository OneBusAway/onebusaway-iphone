//
//  ApptentiveSurveyCollectionView.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/26/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyCollectionView.h"


@interface ApptentiveSurveyCollectionView ()

@property (strong, nonatomic) NSLayoutConstraint *footerConstraint;

@end


@implementation ApptentiveSurveyCollectionView

- (void)setCollectionHeaderView:(UIView *)collectionHeaderView {
	if (_collectionHeaderView != collectionHeaderView) {
		if (_collectionHeaderView) {
			[_collectionHeaderView removeFromSuperview];
		}

		_collectionHeaderView = collectionHeaderView;
		collectionHeaderView.translatesAutoresizingMaskIntoConstraints = NO;

		[self addSubview:collectionHeaderView];

		[self addConstraints:@[
			[NSLayoutConstraint constraintWithItem:collectionHeaderView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0],
			[NSLayoutConstraint constraintWithItem:collectionHeaderView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0],
			[NSLayoutConstraint constraintWithItem:collectionHeaderView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]
		]];
	}

	[self.collectionViewLayout invalidateLayout];
}

- (void)setCollectionFooterView:(UIView *)collectionFooterView {
	if (_collectionFooterView != collectionFooterView) {
		if (_collectionFooterView) {
			[_collectionFooterView removeFromSuperview];
		}

		_collectionFooterView = collectionFooterView;
		collectionFooterView.translatesAutoresizingMaskIntoConstraints = NO;

		[self addSubview:collectionFooterView];

		self.footerConstraint = [NSLayoutConstraint constraintWithItem:collectionFooterView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];

		[self addConstraints:@[
			[NSLayoutConstraint constraintWithItem:collectionFooterView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0],
			[NSLayoutConstraint constraintWithItem:collectionFooterView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0],
			self.footerConstraint
		]];
	}

	[self.collectionViewLayout invalidateLayout];
}

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated {
	// The OS calls this incompetently and screws up our positioning.
	return;
}

- (void)scrollHeaderAtIndexPathToTop:(NSIndexPath *)indexPath animated:(BOOL)animated {
	CGRect headerFrame = [self layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath].frame;

	// Make sure we don't scroll off the bottom of the content + footer
	headerFrame.origin.y = fmin(headerFrame.origin.y - self.contentInset.top, self.contentSize.height - CGRectGetHeight(self.bounds) + self.contentInset.bottom);

	[self setContentOffset:headerFrame.origin animated:animated];
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGFloat top = [self.collectionViewLayout collectionViewContentSize].height - CGRectGetHeight(self.collectionFooterView.bounds);
	top = fmax(top, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.collectionFooterView.bounds) - self.contentInset.top - self.contentInset.bottom);

	self.footerConstraint.constant = top;

	[super layoutSubviews];
}

@end
