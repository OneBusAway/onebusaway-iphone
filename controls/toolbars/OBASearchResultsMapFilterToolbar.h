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


@class OBAApplicationDelegate;

@interface OBASearchResultsMapFilterToolbar : UIToolbar {
    NSString * _filterDescription;
    BOOL _currentlyShowing;
    
    OBAApplicationDelegate * _appDelegate;
    id                      _filterDelegate;
    
    UILabel * _labelOutput; // "Search: "
    UILabel * _descOutput;  // "Route 8" or "Transit Agencies", etc
}

@property (nonatomic, strong) NSString *              filterDescription;
@property (nonatomic, strong) OBAApplicationDelegate * appDelegate;

-(OBASearchResultsMapFilterToolbar*) initWithDelegate:(id)delegate andappDelegate:(OBAApplicationDelegate*)context;
-(void) dealloc;

-(void) showWithDescription:(NSString*)filterDescString animated:(BOOL)animated;
-(void) hideWithAnimated:(BOOL)animated;

@end
