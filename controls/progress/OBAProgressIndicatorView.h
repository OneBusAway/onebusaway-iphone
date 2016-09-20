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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAProgressIndicatorView : UIView {
    UILabel * _label;
    UILabel * _progressLabel;
    UIActivityIndicatorView * _activityIndicator;
    UIProgressView * _progressView;
}

- (id)initWithFrame:(CGRect)frame;

- (void)setMessage:(nullable NSString*)message inProgress:(BOOL)inProgress progress:(CGFloat)progress;
- (void)setInProgress:(BOOL)inProgress progress:(CGFloat)progress;

@end

NS_ASSUME_NONNULL_END
