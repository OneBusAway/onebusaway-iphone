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

#import "OBAProgressIndicatorView.h"
#import "UITableViewController+oba_Additions.h"
#import <OBAKit/OBAKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBARequestDrivenTableViewController : UITableViewController

@property (nonatomic, strong) NSString *progressLabel;
@property (nonatomic) BOOL showUpdateTime;

@property (nonatomic) BOOL refreshable;
@property (nonatomic) NSInteger refreshInterval;

@property (nonatomic, strong, nullable) NSTimer *timer;
@property (nonatomic, strong, nullable) id<OBAModelServiceRequest> request;
@property (nonatomic, copy, readonly) OBADataSourceProgress progressCallback;

- (BOOL)isLoading;
- (void)refresh;

/**
    Subclasses must override this method to initiate a "refresh" operation.
    Once the operation completes or fails, the two methods below must be called
    to update the refresh control state.
 */
- (nullable id<OBAModelServiceRequest>)handleRefresh;

/**
    Must be called with an HTTP status code to property update the UI of the
    refresh control.  Completion means any HTTP code that is not a result of a networking error.
 */
- (void)refreshCompleteWithCode:(NSUInteger)statusCode;
/**
    If a network operation failed with an error, this method must be called to complete the refresh.
 */
- (void)refreshFailedWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
