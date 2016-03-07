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

#import "OBABookmarkV2.h"
#import "OBAEditStopBookmarkGroupViewController.h"

@class OBAStopV2;

typedef NS_ENUM(NSInteger, OBABookmarkEditType) {
    OBABookmarkEditNew=0,
    OBABookmarkEditExisting=1
};

NS_ASSUME_NONNULL_BEGIN

@interface OBAEditStopBookmarkViewController : UITableViewController <OBABookmarkGroupVCDelegate>

- (instancetype)initWithBookmark:(OBABookmarkV2 *)bookmark forStop:(OBAStopV2*)stop;
- (id)initWithBookmark:(OBABookmarkV2*)bookmark editType:(OBABookmarkEditType)editType __deprecated;
@end

NS_ASSUME_NONNULL_END