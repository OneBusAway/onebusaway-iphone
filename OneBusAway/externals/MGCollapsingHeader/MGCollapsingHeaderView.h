//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Matthew Gardner
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import <UIKit/UIKit.h>

@protocol MGCollapsingHeaderDelegate <NSObject>

- (void)headerDidCollapseToOffset:(double)offset;
- (void)headerDidFinishCollapsing;
- (void)headerDidExpandToOffset:(double)offset;
- (void)headerDidFinishExpanding;

@end

// TODO: Transform Functions
typedef enum : NSUInteger {
    MGTransformCurveLinear = 0,
    MGTransformCurveEaseIn,
    MGTransformCurveEaseOut,
    MGTransformCurveEaseInOut,
} MGTransformCurve;

/*!
 * @typedef MGAttribute
 * @brief Enumeration of attributes that can be transformed when scrolling.
 */
typedef enum : NSUInteger {
    MGAttributeX = 1,
    MGAttributeY,
    MGAttributeWidth,
    MGAttributeHeight,
    MGAttributeAlpha,
    MGAttributeCornerRadius,
    MGAttributeShadowRadius,
    MGAttributeShadowOpacity,
    MGAttributeFontSize
} MGAttribute;

/*!
 * @brief Defines an attribute to be transformed when scrolling.
 */
@interface MGTransform : NSObject

@property (nonatomic) MGAttribute attribute;
@property (nonatomic) MGTransformCurve curve;
@property (nonatomic) CGFloat value, origValue;

+ (instancetype)transformAttribute:(MGAttribute)attr byValue:(CGFloat)val;

@end

/*!
 * @brief Subclass of UIView that manages collapsing and expanding.
 */
@interface MGCollapsingHeaderView : UIView {
    NSArray *hdrConstrs, *hdrConstrVals;
    NSMutableArray *transfViews, *fadeViews;
    NSMutableDictionary *constrs, *constrVals, *transfAttrs, *alphaRatios;
    NSDictionary *vertConstraints;
    CGFloat lastOffset;
    CGFloat header_ht, scroll_ht, offset_max;
    UIFont *font;
}

/**
 * @brief An implementation of the header delegate.
 */
@property (strong, nonatomic) id<MGCollapsingHeaderDelegate> delegate;

/*!
 * @brief The minimum height of the header in it's collapsed state.
 */
@property (nonatomic) CGFloat minimumHeaderHeight;

/*!
 * @brief Forces the header to always collapse, even if the scrollable content is less
 * than the offset to collapse the header.
 * @discussion If set to @p NO, then the header will only collapse if there is enough
 * content in the scroll view to collapse the header completely.
 */
@property (nonatomic) BOOL alwaysCollapse;

/*!
 * @brief Adds a constraint whose constant is offset when @p collapseWithScroll is called.
 * @discussion Constraints are expected to have vertical alignment. Different behavior can
 * be achieved depending on the constraints added. For example, adding the header height
 * constraint will cause the header to change its frame size while automatically adjusting
 * constraints of views within it. Adding the top or bottom constraint will cause the
 * header to slide up.
 * @param c Constraint to offset.
 */
- (void)setCollapsingConstraint:(NSLayoutConstraint *)c;

/*!
 * @brief Adds a set of constraints whose constants are offset when @p collapseWithScroll
 * is called.
 * @discussion Constraints are expected to have vertical alignment. Different behavior can
 * be achieved depending on the constraints added. For example, adding the header height
 * constraint will cause the header to change its frame size while automatically adjusting
 * constraints of views within it. Adding the top or bottom constraint will cause the
 * header to slide up.
 * @param constrs Array of constraints to offset.
 */
- (void)setCollapsingConstraints:(NSArray *)constrs;

/*!
 * @discussion Adds a view that transforms as the user scrolls.
 * @param view The view to transform.
 * @param attrs An array of MGTransformAttributes that describe the view in it's condensed
 * form.
 * @return Boolean identifying if the transform was successfully added.
 */
- (BOOL)addTransformingSubview:(UIView *)view attributes:(NSArray *)attrs;

/*!
 * @discussion Adds a view that fades as the user scrolls.
 * @param view The view to fade away.
 * @param ratio The ratio of collapsing at which the subview will finish fading away.
 * @return Boolean identifying if the fading subview was successfully added.
 */
- (BOOL)addFadingSubview:(UIView *)view fadeBy:(CGFloat)ratio;

/*!
 * @brief Tells the header to collapse with the scrolling of a UIScrollView.
 * @discussion This method should be called from a @p scrollViewDidScroll: delegate call.
 * @param scrollView The active scroll view.
 */
- (void)collapseWithScroll:(UIScrollView *)scrollView;

@end
