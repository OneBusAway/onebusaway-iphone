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


@implementation OBASearchResultsMapFilterToolbar

@synthesize filterDescription = _filterDescription;

-(OBASearchResultsMapFilterToolbar*) initWithDelegate:(id)delegate {
    self = [super init];
    
    if (self != nil) {
        // init
        _filterDelegate = delegate;
        [_filterDelegate retain];
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
        NSArray * items = [NSArray arrayWithObjects:flexItem, clearItem, nil];
        
        self.barStyle = UIBarStyleBlackTranslucent;
        
        // size up the toolbar and set its frame
        [self sizeToFit];
        
        const CGFloat toolbarHeight = self.frame.size.height;
        const CGRect mainViewBounds = [[UIApplication sharedApplication] keyWindow].bounds;
        
        const CGFloat tabbarControllerHeight = 49.0;
        [self setFrame:CGRectMake(CGRectGetMinX(mainViewBounds),
                                                CGRectGetMinY(mainViewBounds) + CGRectGetHeight(mainViewBounds) - tabbarControllerHeight   - (toolbarHeight),
                                                CGRectGetWidth(mainViewBounds),
                                                toolbarHeight)];
        
        [self setItems:items animated:NO];
        
        // Release toolbar button items -- they're now owned by the toolbar
        [flexItem release];
        [clearItem release];
    }
    
    return self;
}

-(void) dealloc {
    [self.filterDescription release];
    [_filterDelegate release];
    
    [super dealloc];
}

-(void) showWithDescription:(NSString*)filterDescString animated:(BOOL)animated {
    if (_currentlyShowing)
        return; // for now...
    
    self.filterDescription = filterDescString;
    _currentlyShowing      = YES;

    //-------------------------------------------------
    // set up filter text labels
    //-------------------------------------------------
    const CGFloat filterFontSize = [UIFont labelFontSize];
    
    // Find size for the title text
    NSString* filterLabelText     = @"Filter: ";
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
    
    UILabel *descOutput        = [[UILabel alloc] initWithFrame:descFrame];
    descOutput.backgroundColor = [UIColor clearColor];
    descOutput.shadowColor     = [UIColor colorWithWhite:0.0 alpha:0.5];
    descOutput.textColor       = [UIColor whiteColor];
    
    descOutput.font = filterDescFont;
    descOutput.text = self.filterDescription;
    
    // Attach text labels to the filter toolbar 
    [self addSubview:labelOutput];
    [self addSubview:descOutput];
    
    // Release text labels -- the filter toolbar now owns them
    [labelOutput release];
    [descOutput  release];

    // Attach the filter toolbar to the window view
    [[[UIApplication sharedApplication] keyWindow] addSubview:self];
}

-(void) hideWithAnimated:(BOOL)animated {
    if (!_currentlyShowing)
        return;

    [self removeFromSuperview];
    _currentlyShowing = NO;
}

@end
