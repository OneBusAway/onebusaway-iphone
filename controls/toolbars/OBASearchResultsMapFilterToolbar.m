/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBASearchResultsMapFilterToolbar.h"
#import "OBAApplicationDelegate.h" // for OBAApplicationDelegate.window


// hidden declarations
@interface OBASearchResultsMapFilterToolbar (hidden)

-(void) hideInternal;

@end


// public implementation
@implementation OBASearchResultsMapFilterToolbar

// propeties
@synthesize filterDescription = _filterDescription;
@synthesize appDelegate = _appDelegate;


// methods
-(OBASearchResultsMapFilterToolbar*) initWithDelegate:(id)delegate andappDelegate:(OBAApplicationDelegate*)context {
    self = [super init];
    
    if (self != nil) {
        // init
        self.appDelegate = context;

        _filterDelegate = delegate;
        assert([_filterDelegate respondsToSelector:@selector(onFilterClear)]);
        
        _currentlyShowing = NO;
        self.filterDescription = nil;
        
        //-------------------------------------------------
        // set up filter toolbar, with "cancel filter" button
        //-------------------------------------------------
        UIBarButtonItem * clearItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:_filterDelegate action:@selector(onFilterClear)];
        clearItem.style = UIBarButtonItemStyleBordered;
        
        // right align the clear buttom
        UIBarButtonItem * flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        // set up the UIToolbar
        NSArray * items = @[flexItem, clearItem];
        
        self.barStyle = UIBarStyleBlackTranslucent;
        [self setItems:items animated:NO];
        
        // Release toolbar button items -- they're now owned by the toolbar
    }
    
    return self;
}


-(void) dealloc {
    [self hideInternal];
}


-(void) setupLabels {
    //-------------------------------------------------
    // set up filter text labels
    //-------------------------------------------------
    const CGFloat filterFontSize = [UIFont labelFontSize];
    
    // Find size for the title text
    NSString* filterLabelText     = NSLocalizedString(@"Search: ",@"setupLabels text");
    UIFont*   filterLabelFont     = [UIFont boldSystemFontOfSize:filterFontSize];
    CGSize    filterLabelTextSize = [filterLabelText sizeWithFont:filterLabelFont];
    
    // Find size for the description text
    UIFont*   filterDescFont     = [UIFont systemFontOfSize:filterFontSize];
    CGSize    filterDescTextSize = [self.filterDescription sizeWithFont:filterLabelFont];
    
    // Find total width of concatenated strings
    const CGFloat filterLabelAndDescSeparation = 0.0;
    const CGFloat filterLabelsWidth = filterLabelTextSize.width + filterLabelAndDescSeparation + filterDescTextSize.width; 
    
    // Calculate origins of UILabels
    const CGFloat frameCenterX = self.frame.origin.x + self.frame.size.width / 2.0;
    const CGFloat xOriginOfLabel = frameCenterX - filterLabelsWidth / 2.0;
    const CGFloat xOriginOfDesc  = xOriginOfLabel + filterLabelTextSize.width + filterLabelAndDescSeparation;
    
    // Calculate frames
    CGRect labelFrame     = self.bounds;
    labelFrame.origin.x   = xOriginOfLabel;
    labelFrame.size.width = filterLabelTextSize.width;
    
    CGRect descFrame     = self.bounds;
    descFrame.origin.x   = xOriginOfDesc;
    descFrame.size.width = filterDescTextSize.width;
    
    // Create text labels
    UILabel *labelOutput        = [[UILabel alloc] initWithFrame:labelFrame];
    labelOutput.backgroundColor = [UIColor clearColor];
    labelOutput.shadowColor     = [UIColor colorWithWhite:0.0 alpha:0.5];
    labelOutput.textColor       = [UIColor whiteColor];
    
    labelOutput.font = filterLabelFont;
    labelOutput.text = filterLabelText;
    _labelOutput = labelOutput;
    
    UILabel *descOutput        = [[UILabel alloc] initWithFrame:descFrame];
    descOutput.backgroundColor = [UIColor clearColor];
    descOutput.shadowColor     = [UIColor colorWithWhite:0.0 alpha:0.5];
    descOutput.textColor       = [UIColor whiteColor];
    
    descOutput.font = filterDescFont;
    descOutput.text = self.filterDescription;
    _descOutput = descOutput;
    
    // Attach text labels to the filter toolbar 
    [self addSubview:_labelOutput];
    [self addSubview:_descOutput];
    
    // Release text labels -- the filter toolbar now owns them
}


-(void) showWithDescription:(NSString*)filterDescString animated:(BOOL)animated {
    BOOL justRefreshLabels = NO;
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    
    if (_currentlyShowing) {
        if (self.filterDescription != filterDescString) {
            justRefreshLabels = YES;
        }
        else {
            return;
        }
    }
        
    self.filterDescription = filterDescString;
    _currentlyShowing = YES;
    
    if (justRefreshLabels) {
        [_labelOutput removeFromSuperview];
        [_descOutput  removeFromSuperview];
        
        [self setupLabels];
        return;
    }
    
    // Size up the toolbar and set its frame
    self.alpha = 1.0;
    
    // place the toolbar right on top of the tab bar
    const CGFloat tabbarHeight = CGRectGetHeight(keyWindow.frame);

    [self sizeToFit];
    const CGFloat toolbarHeight = CGRectGetHeight(self.frame);

    const CGRect mainViewBounds = [self.appDelegate window].bounds;
    
    [self setFrame:CGRectMake(CGRectGetMinX(mainViewBounds),
                              CGRectGetMinY(mainViewBounds) + CGRectGetHeight(mainViewBounds) - tabbarHeight - (toolbarHeight),
                              CGRectGetWidth(mainViewBounds),
                              toolbarHeight)];


    // Set up labels
    [self setupLabels];
    
    // Attach the filter toolbar to the window view
    [keyWindow addSubview:self];
}


-(void) hideWithAnimated:(BOOL)animated {
    if (!_currentlyShowing)
        return;
    
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        
        {
            [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
            [UIView setAnimationDuration:0.1];
            
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(hideInternal)];

            self.alpha = 0.0;
        }
        
        [UIView commitAnimations];
    } else {
        [self hideInternal];
    }
}

@end


// hidden implementation
@implementation OBASearchResultsMapFilterToolbar (hidden)

-(void) hideInternal {
    if (_currentlyShowing) {
        [_labelOutput removeFromSuperview];
        [_descOutput  removeFromSuperview];
        
        _labelOutput = nil;
        _descOutput  = nil;
        
        [self removeFromSuperview];
        _currentlyShowing = NO;
    }
}

@end
