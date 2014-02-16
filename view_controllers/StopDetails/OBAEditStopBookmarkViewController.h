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

#import "OBAApplicationDelegate.h"
#import "OBABookmarkV2.h"
#import "OBAEditStopBookmarkGroupViewController.h"


typedef enum {
    OBABookmarkEditNew=0,
    OBABookmarkEditExisting=1
} OBABookmarkEditType;


@interface OBAEditStopBookmarkViewController : UITableViewController <OBAModelServiceDelegate, OBABookmarkGroupVCDelegate> {
    OBAApplicationDelegate * _appDelegate;
    OBABookmarkEditType _editType;
    OBABookmarkV2 * _bookmark;
    OBABookmarkGroup * _selectedGroup;
    NSMutableArray * _requests;
    NSMutableDictionary * _stops;
    UITextField * _textField;
}

- (id) initWithApplicationDelegate:(OBAApplicationDelegate*)appDelegate bookmark:(OBABookmarkV2*)bookmark editType:(OBABookmarkEditType)editType;

- (IBAction) onCancelButton:(id)sender;
- (IBAction) onSaveButton:(id)sender;

@end
