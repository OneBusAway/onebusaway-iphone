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

#import "MGCollapsingHeaderView.h"

@implementation MGTransform

+ (instancetype)transformAttribute:(MGAttribute)attr byValue:(CGFloat)val
{
    MGTransform *a = [MGTransform alloc];
    a.attribute    = attr;
    a.value        = val;
    a.curve        = MGTransformCurveLinear;
    
    return a;
}

@end

@implementation MGCollapsingHeaderView

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    transfViews     = [@[] mutableCopy];
    fadeViews       = [@[] mutableCopy];
    transfAttrs     = [@{} mutableCopy];
    constrs         = [@{} mutableCopy];
    constrVals      = [@{} mutableCopy];
    alphaRatios     = [@{} mutableCopy];
    vertConstraints = @{
                        @(NSLayoutAttributeTop) : @YES,
                        @(NSLayoutAttributeTopMargin) : @YES,
                        @(NSLayoutAttributeBottom) : @YES,
                        @(NSLayoutAttributeBottomMargin) : @YES
                        };
    
    header_ht = self.frame.size.height;
    scroll_ht = -1.;
    [self setMinimumHeaderHeight:60.];
    [self setAlwaysCollapse:YES];
}

- (void)setMinimumHeaderHeight:(CGFloat)minimumHeaderHeight
{
    _minimumHeaderHeight = minimumHeaderHeight;
    offset_max           = header_ht - _minimumHeaderHeight;
}

- (void)setCollapsingConstraint:(NSLayoutConstraint *)c
{
    [self setCollapsingConstraints:@[ c ]];
}

- (void)setCollapsingConstraints:(NSArray *)cs
{
    hdrConstrs           = cs;
    NSMutableArray *vals = [@[] mutableCopy];
    
    for (NSLayoutConstraint *c in cs) {
        [vals addObject:@(c.constant)];
    }
    hdrConstrVals = vals;
}

- (void)collapseWithScroll:(UIScrollView *)scrollView
{
    CGFloat dy = scrollView.contentOffset.y;
    if (scroll_ht < 0.) scroll_ht = scrollView.frame.size.height;
    CGFloat scrollableHeight = scrollView.contentSize.height - scroll_ht;
    
    if (scrollableHeight / 2.0 < offset_max) {
        if (_alwaysCollapse) {
            UIEdgeInsets scrInset   = scrollView.contentInset;
            scrInset.bottom         = 2. * offset_max - scrollableHeight;
            scrollView.contentInset = scrInset;
        } else {
            return;
        }
    }
    
    if (dy > 0.) {
        if (header_ht - dy > _minimumHeaderHeight) {
            [self scrollHeaderToOffset:dy];
            if (self.delegate) {
                if (dy > lastOffset) {
                    [self.delegate headerDidCollapseToOffset:dy];
                } else {
                    [self.delegate headerDidExpandToOffset:dy];
                }
            }
        } else if (header_ht - lastOffset > _minimumHeaderHeight) {
            [self scrollHeaderToOffset:offset_max];
            if (self.delegate) {
                [self.delegate headerDidFinishCollapsing];
            }
        }
    } else if (lastOffset > 0.) {
        [self scrollHeaderToOffset:0.];
        if (self.delegate) {
            if (dy < 0) { // Report negative offset from bouncing at top of scroll
                [self.delegate headerDidExpandToOffset:dy];
            } else {
                [self.delegate headerDidFinishExpanding];
            }
        }
    }
    
    [self.superview setNeedsUpdateConstraints];
    [self.superview setNeedsLayout];
    [self.superview layoutIfNeeded];
    
    lastOffset = dy;
}

- (BOOL)addTransformingSubview:(UIView *)view attributes:(NSArray *)attrs
{
    NSMutableDictionary *constrDict    = [@{} mutableCopy];
    NSMutableDictionary *constrValDict = [@{} mutableCopy];
    
    UIView *v = view;
    while (v) {
        for (NSLayoutConstraint *c in v.constraints) {
            if (c.firstItem == view) {
                [constrDict setObject:c forKey:@(c.firstAttribute)];
                [constrValDict setObject:@(c.constant) forKey:@(c.firstAttribute)];
            } else if (c.secondItem == view) {
                [constrDict setObject:c forKey:@(c.secondAttribute)];
                [constrValDict setObject:@(c.constant) forKey:@(c.secondAttribute)];
            }
        }
        v = v.superview;
    }
    
    for (MGTransform *ta in attrs) {
        ta.origValue = [self getViewAttribute:[ta attribute] view:view];
    }
    
    [transfViews addObject:view];
    
    [transfAttrs setObject:attrs forKey:@(view.hash)];
    
    [constrs setObject:constrDict forKey:@(view.hash)];
    
    [constrVals setObject:constrValDict forKey:@(view.hash)];
    
    return YES;
}

- (BOOL)addFadingSubview:(UIView *)view fadeBy:(CGFloat)ratio
{
    if (ratio < 0. || ratio > 1.) {
        return NO;
    }
    
    [fadeViews addObject:view];
    
    [alphaRatios setObject:@(ratio) forKey:@(view.hash)];
    
    return YES;
}

- (void)scrollHeaderToOffset:(CGFloat)offset
{
    CGFloat ratio = offset / offset_max;
    
    for (UIView *view in fadeViews) {
        CGFloat alphaRatio = [[alphaRatios objectForKey:@(view.hash)] doubleValue];
        view.alpha         = -ratio / alphaRatio + 1;
    }
    
    for (UIView *view in transfViews) {
        NSDictionary *cs  = [constrs objectForKey:@(view.hash)];
        NSDictionary *cvs = [constrVals objectForKey:@(view.hash)];
        NSDictionary *as  = [transfAttrs objectForKey:@(view.hash)];
        
        for (MGTransform *a in as) {
            [self setAttribute:a
                          view:view
                         ratio:ratio
                   constraints:cs
              constraintValues:cvs];
        }
    }
    
    CGRect hdrFrame   = self.frame;
    hdrFrame.origin.y = -offset;
    self.frame        = hdrFrame;
    
    for (int i = 0; i < [hdrConstrs count]; i++) {
        [(NSLayoutConstraint *)hdrConstrs[i]
         setConstant:[hdrConstrVals[i] floatValue] - offset];
    }
}

#pragma mark -
#pragma mark Helpers

- (CGFloat)getViewAttribute:(MGAttribute)attribute view:(UIView *)view
{
    switch (attribute) {
        case MGAttributeX:
            return view.frame.origin.x;
        case MGAttributeY:
            return view.frame.origin.y;
        case MGAttributeWidth:
            return view.frame.size.width;
        case MGAttributeHeight:
            return view.frame.size.height;
        case MGAttributeAlpha:
            return view.alpha;
        case MGAttributeCornerRadius:
            return view.layer.cornerRadius;
        case MGAttributeShadowOpacity:
            return view.layer.shadowOpacity;
        case MGAttributeShadowRadius:
            return view.layer.shadowRadius;
        case MGAttributeFontSize:
            if ([view isKindOfClass:[UILabel class]]) {
                return [[(UILabel *)view font] pointSize];
            } else if ([view isKindOfClass:[UIButton class]]) {
                return [[[(UIButton *)view titleLabel] font] pointSize];
            } else if ([view isKindOfClass:[UITextField class]]) {
                return [[(UITextField *)view font] pointSize];
            } else if ([view isKindOfClass:[UITextView class]]) {
                return [[(UITextView *)view font] pointSize];
            }
    }
    
    return 0.0f;
}

- (void)setAttribute:(MGTransform *)attr
                view:(UIView *)view
               ratio:(CGFloat)ratio
         constraints:(NSDictionary *)cs
    constraintValues:(NSDictionary *)cvals
{
    switch (attr.attribute) {
        case MGAttributeX:
            [self updateConstraint:[cs objectForKey:@(NSLayoutAttributeLeading)]
                       constrValue:[[cvals objectForKey:@(NSLayoutAttributeLeading)]
                                    doubleValue]
                         transform:attr
                             ratio:ratio];
            [self updateConstraint:[cs objectForKey:@(NSLayoutAttributeLeadingMargin)]
                       constrValue:[[cvals objectForKey:@(NSLayoutAttributeLeadingMargin)]
                                    doubleValue]
                         transform:attr
                             ratio:ratio];
            [self updateConstraint:[cs objectForKey:@(NSLayoutAttributeTrailing)]
                       constrValue:[[cvals objectForKey:@(NSLayoutAttributeTrailing)]
                                    doubleValue]
                         transform:attr
                             ratio:ratio];
            [self updateConstraint:[cs objectForKey:@(NSLayoutAttributeTrailingMargin)]
                       constrValue:[[cvals objectForKey:@(NSLayoutAttributeLeadingMargin)]
                                    doubleValue]
                         transform:attr
                             ratio:ratio];
            break;
        case MGAttributeY:
            [self updateConstraint:[cs objectForKey:@(NSLayoutAttributeTop)]
                       constrValue:[[cvals objectForKey:@(NSLayoutAttributeTop)] doubleValue]
                         transform:attr
                             ratio:ratio];
            [self updateConstraint:[cs objectForKey:@(NSLayoutAttributeTopMargin)]
                       constrValue:[[cvals objectForKey:@(NSLayoutAttributeTopMargin)]
                                    doubleValue]
                         transform:attr
                             ratio:ratio];
            [self
             updateConstraint:[cs objectForKey:@(NSLayoutAttributeBottom)]
             constrValue:[[cvals objectForKey:@(NSLayoutAttributeBottom)] doubleValue]
             transform:attr
             ratio:ratio];
            [self updateConstraint:[cs objectForKey:@(NSLayoutAttributeBottomMargin)]
                       constrValue:[[cvals objectForKey:@(NSLayoutAttributeBottomMargin)]
                                    doubleValue]
                         transform:attr
                             ratio:ratio];
            break;
        case MGAttributeWidth:
            [self
             updateConstraint:[cs objectForKey:@(NSLayoutAttributeWidth)]
             constrValue:[[cvals objectForKey:@(NSLayoutAttributeWidth)] doubleValue]
             transform:attr
             ratio:ratio];
            break;
        case MGAttributeHeight:
            [self
             updateConstraint:[cs objectForKey:@(NSLayoutAttributeHeight)]
             constrValue:[[cvals objectForKey:@(NSLayoutAttributeHeight)] doubleValue]
             transform:attr
             ratio:ratio];
            break;
        case MGAttributeCornerRadius:
            view.layer.cornerRadius = attr.origValue + ratio * attr.value;
            break;
        case MGAttributeAlpha:
            view.alpha = attr.origValue + ratio * attr.value;
            break;
        case MGAttributeShadowRadius:
            view.layer.shadowRadius = attr.origValue + ratio * attr.value;
            break;
        case MGAttributeShadowOpacity:
//            view.layer.shadowOpacity = attr.origValue + ratio * attr.value; // FIXME
            break;
        case MGAttributeFontSize:
            if ([view isKindOfClass:[UILabel class]]) {
                font = [UIFont fontWithName:[(UILabel *)view font].familyName
                                       size:attr.origValue + ratio * attr.value];
                [(UILabel *)view setFont:font];
            } else if ([view isKindOfClass:[UIButton class]]) {
                font = [UIFont fontWithName:[[(UIButton *)view titleLabel] font].familyName
                                       size:attr.origValue + ratio * attr.value];
                [[(UIButton *)view titleLabel] setFont:font];
            } else if ([view isKindOfClass:[UITextField class]]) {
                font = [UIFont fontWithName:[(UITextField *)view font].familyName
                                       size:attr.origValue + ratio * attr.value];
                [(UITextField *)view setFont:font];
            } else if ([view isKindOfClass:[UITextView class]]) {
                font = [UIFont fontWithName:[(UITextView *)view font].familyName
                                       size:attr.origValue + ratio * attr.value];
                [(UITextView *)view setFont:font];
            }
            break;
    }
}

- (void)updateConstraint:(NSLayoutConstraint *)constraint
             constrValue:(CGFloat)cv
               transform:(MGTransform *)ta
                   ratio:(CGFloat)ratio
{
    if (constraint) {
        switch (constraint.firstAttribute) {
            case NSLayoutAttributeTop:
            case NSLayoutAttributeTopMargin:
            case NSLayoutAttributeLeading:
            case NSLayoutAttributeLeadingMargin:
            case NSLayoutAttributeWidth:
            case NSLayoutAttributeHeight:
                constraint.constant = cv + ratio * ta.value;
                break;
            case NSLayoutAttributeBottom:
            case NSLayoutAttributeBottomMargin:
            case NSLayoutAttributeTrailing:
            case NSLayoutAttributeTrailingMargin:
                constraint.constant = cv - ratio * ta.value;
                break;
            default:
                break;
        }
    }
}

@end
