//
//  ApptentiveSurveyCollectionViewLayout.m
//  CVSurvey
//
//  Created by Frank Schmitt on 2/23/16.
//  Copyright © 2016 Apptentive, Inc. All rights reserved.
//

#import "ApptentiveSurveyCollectionViewLayout.h"
#import "ApptentiveSurveyCollectionView.h"
#import "ApptentiveSurveyLayoutAttributes.h"


@implementation ApptentiveSurveyCollectionViewLayout

- (CGSize)collectionViewContentSize {
	CGSize superSize = [super collectionViewContentSize];

	if ([self.collectionView isKindOfClass:[ApptentiveSurveyCollectionView class]]) {
		ApptentiveSurveyCollectionView *myCollectionView = (ApptentiveSurveyCollectionView *)self.collectionView;
		superSize.height += CGRectGetHeight(myCollectionView.collectionHeaderView.bounds) + CGRectGetHeight(myCollectionView.collectionFooterView.bounds) + self.sectionInset.top + self.sectionInset.bottom;

		superSize.height = fmax(superSize.height, CGRectGetHeight(self.collectionView.bounds) - self.collectionView.contentInset.top - self.collectionView.contentInset.bottom);
	}

	return superSize;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(NSString *)decorationViewKind atIndexPath:(NSIndexPath *)indexPath {
	NSInteger section = indexPath.section;
	NSInteger numberOfItems = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:section];

	UICollectionViewLayoutAttributes *attributesForFirstItem = nil;
	UICollectionViewLayoutAttributes *attributesForLastItem = nil;
	if (numberOfItems) {
		attributesForFirstItem = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
		attributesForLastItem = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:numberOfItems - 1 inSection:section]];
	}

	UICollectionViewLayoutAttributes *headerLayoutAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader atIndexPath:indexPath];
	UICollectionViewLayoutAttributes *footerLayoutAttributes = [self layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter atIndexPath:indexPath];

	UICollectionViewLayoutAttributes *topLayoutAttributes = CGRectGetHeight(headerLayoutAttributes.frame) > 0 ? headerLayoutAttributes : attributesForFirstItem;
	UICollectionViewLayoutAttributes *bottomLayoutAttributes = CGRectGetHeight(footerLayoutAttributes.frame) > 0 ? footerLayoutAttributes : attributesForLastItem;

	CGPoint origin = topLayoutAttributes.frame.origin;
	CGSize size = CGSizeMake(CGRectGetMaxX(bottomLayoutAttributes.frame) - origin.x, CGRectGetMaxY(bottomLayoutAttributes.frame) - origin.y);
	ApptentiveSurveyLayoutAttributes *layoutAttributes = [ApptentiveSurveyLayoutAttributes layoutAttributesForDecorationViewOfKind:decorationViewKind withIndexPath:indexPath];

	if ([self.collectionView.dataSource conformsToProtocol:@protocol(ApptentiveCollectionViewDataSource)]) {
		layoutAttributes.valid = [(id<ApptentiveCollectionViewDataSource>)self.collectionView.dataSource sectionAtIndexIsValid:indexPath.section];
		layoutAttributes.validColor = [(id<ApptentiveCollectionViewDataSource>)self.collectionView.dataSource validColor];
		layoutAttributes.invalidColor = [(id<ApptentiveCollectionViewDataSource>)self.collectionView.dataSource invalidColor];
		layoutAttributes.backgroundColor = [(id<ApptentiveCollectionViewDataSource>)self.collectionView.dataSource backgroundColor];
	}

	layoutAttributes.frame = UIEdgeInsetsInsetRect(CGRectMake(origin.x, origin.y, size.width, size.height), self.sectionInset);
	layoutAttributes.zIndex = -1;

	return layoutAttributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
	CGFloat headerHeight = 0;
	if ([self.collectionView isKindOfClass:[ApptentiveSurveyCollectionView class]]) {
		headerHeight = CGRectGetHeight(((ApptentiveSurveyCollectionView *)self.collectionView).collectionHeaderView.bounds) + self.sectionInset.bottom;
	}

	rect = CGRectOffset(rect, 0, -headerHeight);

	NSArray *superAttributes = [super layoutAttributesForElementsInRect:rect];
	NSMutableArray *newAttributes = [superAttributes mutableCopy];
	NSMutableArray *decorationViewAttributes = [NSMutableArray array];

	NSInteger i = 0;
	for (UICollectionViewLayoutAttributes *attributes in superAttributes) {
		if (attributes.representedElementCategory == UICollectionElementCategorySupplementaryView) {
			[newAttributes replaceObjectAtIndex:i withObject:[self layoutAttributesForSupplementaryViewOfKind:attributes.representedElementKind atIndexPath:attributes.indexPath]];
			[decorationViewAttributes addObject:[self layoutAttributesForDecorationViewOfKind:@"QuestionBackground" atIndexPath:attributes.indexPath]];
		}

		i++;
	}

	NSArray *result = [newAttributes arrayByAddingObjectsFromArray:decorationViewAttributes];

	[newAttributes removeAllObjects];
	for (UICollectionViewLayoutAttributes *attributes in result) {
		UICollectionViewLayoutAttributes *movedAttributes = [attributes copy];
		movedAttributes.frame = CGRectOffset(attributes.frame, 0, headerHeight);
		[newAttributes addObject:movedAttributes];
	}

	return newAttributes;
}

@end
