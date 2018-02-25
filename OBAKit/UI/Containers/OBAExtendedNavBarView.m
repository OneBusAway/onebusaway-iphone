//
//  OBAExtendedNavBarView.m
//  OBAKit
//
//  Created by Aaron Brethorst on 2/23/18.
//  Copyright © 2018 OneBusAway. All rights reserved.
//

/*
 File: ExtendedNavBarView.m
 Abstract: A UIView subclass that draws a gray hairline along its bottom
 border, similar to a navigation bar.  This view is used as the navigation
 bar extension view in the Extended Navigation Bar example.

 Version: 1.12

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2014 Apple Inc. All Rights Reserved.

 */

#import <OBAKit/OBAExtendedNavBarView.h>
#import <OBAKit/OBAImageHelpers.h>

@interface OBAExtendedNavBarView ()
@property(nonatomic,strong) UINavigationBar *navBar;
@end

@implementation OBAExtendedNavBarView

// For the extended navigation bar effect to work, a few changes
// must be made to the actual navigation bar.
+ (void)customizeNavigationBar:(UINavigationBar*)navigationBar {
    // Translucency of the navigation bar is disabled so that it matches with
    // the non-translucent background of the extension view.
    navigationBar.translucent = NO;

    // The navigation bar's shadowImage is set to a transparent image.  In
    // conjunction with providing a custom background image, this removes
    // the grey hairline at the bottom of the navigation bar.  The
    // OBAExtendedNavBarView will draw its own hairline.
    UIImage *transparent = [OBAImageHelpers imageOfColor:[UIColor clearColor] size:CGSizeMake(1.f, 1.f)];
    navigationBar.shadowImage = transparent;
}

//| ----------------------------------------------------------------------------
//  Called when the view is about to be displayed.  May be called more than
//  once.
- (void)willMoveToWindow:(UIWindow *)newWindow {

    if (![self.subviews containsObject:self.navBar]) {
        [self addSubview:self.navBar];
        [self sendSubviewToBack:self.navBar];
    }
}

- (UINavigationBar*)navBar {
    if (!_navBar) {
        _navBar = [[UINavigationBar alloc] initWithFrame:self.bounds];
        _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _navBar.translucent = NO;
        _navBar.userInteractionEnabled = NO;
    }

    return _navBar;
}

@end
