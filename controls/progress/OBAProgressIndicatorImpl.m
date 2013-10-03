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

#import "OBAProgressIndicatorImpl.h"
#import "OBACommon.h"

@interface OBAProgressIndicatorImpl ()
@property (strong,readwrite) NSString * message;
@property (readwrite) BOOL inProgress;
@property (readwrite) float progress;
@end

@implementation OBAProgressIndicatorImpl

@synthesize message = _message;
@synthesize inProgress = _inProgress;
@synthesize progress = _progress;
@synthesize delegate = _delegate;

- (id) init {
    if( self = [super init] ) {
        _inProgress = NO;
        _progress = 0.0;
    }
    return self;
}

- (void) setMessage:(NSString*)message inProgress:(BOOL)inProgress progress:(float)progress {
    _message = message;
    _inProgress = inProgress;
    _progress = progress;
    [_delegate progressUpdated];
}

- (void) setInProgress:(BOOL)inProgress progress:(float)progress {
    [self setMessage:nil inProgress:inProgress progress:progress];
}


@end
