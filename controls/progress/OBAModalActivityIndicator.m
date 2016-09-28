/**
 * Copyright (C) 2009-2016 bdferris <bdferris@onebusaway.org>, University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBAModalActivityIndicator.h"

@implementation OBAModalActivityIndicator

- (void) show:(UIView*)view {
    _modalView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    _modalView.alpha = 0.5;
    _modalView.backgroundColor = [UIColor grayColor];
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]; 
    [_modalView addSubview:_activityIndicatorView];   
    _activityIndicatorView.center = _modalView.center;  
    [view addSubview:_modalView];  
    [view bringSubviewToFront:_modalView];  
    [_activityIndicatorView startAnimating];  
}

- (void) hide {
    [_modalView removeFromSuperview];
    _modalView = nil;
    _activityIndicatorView = nil;
}

@end
