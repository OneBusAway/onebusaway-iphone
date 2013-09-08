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

#import "OBAProgressIndicatorView.h"

@interface OBAProgressIndicatorView (Private)

- (void) setup;
- (void) setupLabel:(UILabel*)label;

@end


@implementation OBAProgressIndicatorView

- (id) initWithCoder:(NSCoder *)aDecoder {
    if ( self = [super initWithCoder:aDecoder] ) {
        [self setup];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame {
    if( self = [super initWithFrame:frame] ) {
        [self setup];
    }
    return self;
}


- (void) setMessage:(NSString*)message inProgress:(BOOL)inProgress progress:(float)progress {

    BOOL hasMessage = (message != nil) && ([message length] > 0);
    
    if( inProgress && hasMessage )
        _progressLabel.text = message;
    
    if( ! inProgress && hasMessage )
        _label.text = message;
    
    if( inProgress && hasMessage )
        [_activityIndicator startAnimating];
    else
        [_activityIndicator stopAnimating];
    
    _progressView.progress = progress;
    
    _label.hidden = ! (!inProgress && hasMessage);
    _progressLabel.hidden = ! (inProgress  && hasMessage);
    _activityIndicator.hidden = ! (inProgress && hasMessage);
    _progressView.hidden = ! (inProgress && ! hasMessage);
}

- (void) setInProgress:(BOOL)inProgress progress:(float)progress {
    [self setMessage:nil inProgress:inProgress progress:progress];
}

@end

@implementation OBAProgressIndicatorView (Private)

- (void) setup {
    
    CGRect r = self.frame;
    
    CGRect labelFrame = CGRectMake(0, 0, r.size.width, r.size.height);
    CGRect progressLabelFrame = CGRectMake(25, 0, r.size.width-25, r.size.height);
    CGRect acitivityIndicatorFrame = CGRectMake(0, (r.size.height-20) / 2, 20, 20);
    CGRect progressViewFrame;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        progressViewFrame = CGRectMake(0, (r.size.height-1)/2, r.size.width, 11);
    } else {
        progressViewFrame = CGRectMake(0, (r.size.height-11)/2, r.size.width, 11);
    }
    
    
    _label = [[UILabel alloc] initWithFrame:labelFrame];        
    _progressLabel = [[UILabel alloc] initWithFrame:progressLabelFrame];
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                          SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") ? UIActivityIndicatorViewStyleGray : UIActivityIndicatorViewStyleWhite];
    _progressView = [[UIProgressView alloc] initWithFrame:progressViewFrame];    

    self.backgroundColor = [UIColor clearColor];
    self.autoresizesSubviews = YES;
    
    [self setupLabel:_label];
    [self setupLabel:_progressLabel];
    _activityIndicator.frame = acitivityIndicatorFrame;
    _label.textAlignment = UITextAlignmentCenter;
    _progressLabel.textAlignment = UITextAlignmentCenter;    
    
    [self addSubview:_label];
    [self addSubview:_progressLabel];
    [self addSubview:_activityIndicator];
    [self addSubview:_progressView];
    
    _label.hidden = YES;
    _progressLabel.hidden = YES;
    _activityIndicator.hidden = YES;
    _progressView.hidden = YES;
}

- (void) setupLabel:(UILabel*)label {
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.backgroundColor = [UIColor clearColor];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        label.font = [UIFont boldSystemFontOfSize:16.0];
        label.textColor = [UIColor blackColor];
    } else {
        label.font = [UIFont fontWithName:@"Helvetica-Bold" size:17.0];
        label.textColor = [UIColor whiteColor];
        label.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        label.shadowOffset = CGSizeMake(0,-1);
    }
}

@end

