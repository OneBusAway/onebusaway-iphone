//
//  PTEConsoleLogger.m
//  LumberjackConsole
//
//  Created by Ernesto Rivera on 2013/05/23.
//  Copyright (c) 2013-2015 PTEz.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <OBAKit/OBAConsoleLogger.h>

#define LOG_LEVEL 2

#define NSLogError(frmt, ...)    do{ if(LOG_LEVEL >= 1) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogWarn(frmt, ...)     do{ if(LOG_LEVEL >= 2) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogInfo(frmt, ...)     do{ if(LOG_LEVEL >= 3) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogDebug(frmt, ...)    do{ if(LOG_LEVEL >= 4) NSLog((frmt), ##__VA_ARGS__); } while(0)
#define NSLogVerbose(frmt, ...)  do{ if(LOG_LEVEL >= 5) NSLog((frmt), ##__VA_ARGS__); } while(0)

// Private marker message class
@interface PTEMarkerLogMessage : DDLogMessage
@end

@implementation PTEMarkerLogMessage
@end

@interface OBAConsoleLogger ()
// Managing incoming messages
@property(nonatomic,strong) dispatch_queue_t consoleQueue;
@property(nonatomic,strong) NSMutableArray * messages;             // All currently displayed messages
@property(nonatomic,strong) NSMutableArray * messagesBuffer;    // Messages not yet added to _messages

// Scheduling table view updates
@property(nonatomic,assign) BOOL updateScheduled;
@property(nonatomic,assign) NSTimeInterval minIntervalToUpdate;
@property(nonatomic,copy) NSDate *lastUpdate;

// Filtering messages
@property(nonatomic,assign) BOOL filteringEnabled;
@property(nonatomic,copy) NSString *currentSearchText;
@property(nonatomic,assign) NSInteger currentLogLevel;
@property(nonatomic,strong) NSMutableArray *filteredMessages;

// Managing expanding/collapsing messages
@property(nonatomic,strong) NSMutableSet *expandedMessages;

// UI
@property(nonatomic,copy) UIFont *font;
@end


@implementation OBAConsoleLogger

- (instancetype)init {
    self = [super init];
    if (self) {
        // Default values
        _maxMessages = 500;
        _font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
        _lastUpdate = NSDate.date;
        _minIntervalToUpdate = 0.3;
        _currentLogLevel = DDLogLevelVerbose;
        
        // Init queue
        _consoleQueue = dispatch_queue_create("console_queue", NULL);
        
        // Init message arrays and sets
        _messages = [NSMutableArray arrayWithCapacity:_maxMessages];
        _messagesBuffer = NSMutableArray.array;
        _expandedMessages = NSMutableSet.set;
    }
    return self;
}

#pragma mark - Logger

- (void)logMessage:(DDLogMessage *)logMessage
{
    // The method is called from the logger queue
    dispatch_async(_consoleQueue, ^{
        // Add new message to buffer
        [self.messagesBuffer insertObject:logMessage atIndex:0];

        // Trigger update
        [self updateOrScheduleTableViewUpdateInConsoleQueue];
    });
}

#pragma mark - Log formatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    if (_logFormatter)
    {
        return [_logFormatter formatLogMessage:logMessage];
    }
    else
    {
        return [NSString stringWithFormat:@"%@:%@ %@",
                logMessage.fileName,
                @(logMessage->_line),
                logMessage->_message];
    }
}

- (NSString *)formatShortLogMessage:(DDLogMessage *)logMessage
{
    if (self.shortLogFormatter)
    {
        return [self.shortLogFormatter formatLogMessage:logMessage];
    }
    else
    {
        return [[logMessage->_message
                 stringByReplacingOccurrencesOfString:@"  " withString:@""]
                stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    }
}

#pragma mark - Methods

- (void)clearConsole
{
    // The method is called from the main queue
    dispatch_async(_consoleQueue, ^{
        // Clear all messages
        [self.messagesBuffer removeAllObjects];
        [self.messages removeAllObjects];
        [self.filteredMessages removeAllObjects];
        [self.expandedMessages removeAllObjects];

        [self updateTableViewInConsoleQueue];
    });
}

- (void)addMarker
{
    PTEMarkerLogMessage * marker = PTEMarkerLogMessage.new;
    marker->_message = [NSString stringWithFormat:@"Marker %@", NSDate.date];
    [self logMessage:marker];
}

#pragma mark - Handling new messages

- (void)updateOrScheduleTableViewUpdateInConsoleQueue
{
    if (_updateScheduled)
        return;
    
    // Schedule?
    NSTimeInterval timeToWaitForNextUpdate = _minIntervalToUpdate + _lastUpdate.timeIntervalSinceNow;
    NSLogVerbose(@"timeToWaitForNextUpdate: %@", @(timeToWaitForNextUpdate));
    if (timeToWaitForNextUpdate > 0) {
        _updateScheduled = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToWaitForNextUpdate * NSEC_PER_SEC)), _consoleQueue, ^{
            [self updateTableViewInConsoleQueue];
            self.updateScheduled = NO;
        });
    }
    // Update directly
    else
    {
        [self updateTableViewInConsoleQueue];
    }
}

- (void)updateTableViewInConsoleQueue
{
    _lastUpdate = NSDate.date;
    
    // Add and trim block
    __block NSInteger itemsToRemoveCount;
    __block NSInteger itemsToInsertCount;
    __block NSInteger itemsToKeepCount;
    void (^addAndTrimMessages)(NSMutableArray * messages, NSArray * newItems) = ^(NSMutableArray * messages, NSArray * newItems)
    {
        NSArray * tmp = [NSArray arrayWithArray:messages];
        [messages removeAllObjects];
        [messages addObjectsFromArray:newItems];
        [messages addObjectsFromArray:tmp];
        itemsToRemoveCount = MAX(0, (NSInteger)(messages.count - self.maxMessages));
        if (itemsToRemoveCount > 0)
        {
            [messages removeObjectsInRange:NSMakeRange(self.maxMessages, itemsToRemoveCount)];
        }
        itemsToInsertCount = MIN(newItems.count, self.maxMessages);
        itemsToKeepCount = messages.count - itemsToInsertCount;
    };
    
    // Update regular messages' array
    addAndTrimMessages(self.messages, self.messagesBuffer);
    NSLogDebug(@"Messages to add: %@ keep: %@ remove: %@", @(itemsToInsertCount), @(itemsToKeepCount), @(itemsToRemoveCount));
    
    // Handle filtering
    BOOL forceReload = NO;
    if (self.filteringEnabled)
    {
        // Just swithed on filtering?
        if (!self.filteredMessages)
        {
            self.filteredMessages = [self filterMessages:self.messages];
            forceReload = YES;
        }
        
        // Update filtered messages' array
        addAndTrimMessages(self.filteredMessages, [self filterMessages:self.messagesBuffer]);
        NSLogDebug(@"Filtered messages to add: %@ keep: %@ remove: %@", @(itemsToInsertCount), @(itemsToKeepCount), @(itemsToRemoveCount));
    }
    else
    {
        // Just turned off filtering ?
        if (self.filteredMessages)
        {
            // Clear filtered messages and force table reload
            self.filteredMessages = nil;
            forceReload = YES;
        }
    }
    
    // Empty buffer
    [self.messagesBuffer removeAllObjects];
    
    // Update table view (dispatch sync to ensure the messages' arrayt doesn't get modified)
    dispatch_sync(dispatch_get_main_queue(), ^{
        // Completely update table view?
        if (itemsToKeepCount == 0 || forceReload)
        {
            [self.tableView reloadData];

        }
        // Partial only
        else
        {
            [self updateTableViewRowsRemoving:itemsToRemoveCount inserting:itemsToInsertCount];
        }
    });
}

- (void)updateTableViewRowsRemoving:(NSInteger)itemsToRemoveCount inserting:(NSInteger)itemsToInsertCount {

    UITableView *tableView = self.tableView;

    // Remove paths
    NSMutableArray * removePaths = [NSMutableArray arrayWithCapacity:itemsToRemoveCount];
    if (itemsToRemoveCount > 0)
    {
        NSUInteger tableCount = [tableView numberOfRowsInSection:0];
        for (NSInteger i = tableCount - itemsToRemoveCount; i < tableCount; i++)
        {
            [removePaths addObject:[NSIndexPath indexPathForRow:i
                                                     inSection:0]];
        }
    }
    
    // Insert paths
    NSMutableArray * insertPaths = [NSMutableArray arrayWithCapacity:itemsToInsertCount];
    for (NSInteger i = 0; i < itemsToInsertCount; i++)
    {
        [insertPaths addObject:[NSIndexPath indexPathForRow:i
                                                 inSection:0]];
    }
    
    // Update table view, we should never crash
    @try
    {
        [tableView beginUpdates];
        if (itemsToRemoveCount > 0)
        {
            [tableView deleteRowsAtIndexPaths:removePaths withRowAnimation:UITableViewRowAnimationFade];
            NSLogVerbose(@"deleteRowsAtIndexPaths: %@", removePaths);
        }
        if (itemsToInsertCount > 0)
        {
            [tableView insertRowsAtIndexPaths:insertPaths
                                  withRowAnimation:UITableViewRowAnimationFade];
        }
        NSLogVerbose(@"insertRowsAtIndexPaths: %@", insertPaths);
        [tableView endUpdates];
    }
    @catch (NSException * exception)
    {
        NSLogError(@"Exception when updating LumberjackConsole: %@", exception);
        
        [tableView reloadData];
    }
}

#pragma mark - Table's delegate/data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLogInfo(@"numberOfRowsInSection: %@", @((self.filteringEnabled ? self.filteredMessages : self.messages).count));
    return (self.filteringEnabled ? self.filteredMessages : self.messages).count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Expanded cell?
    DDLogMessage * logMessage = (self.filteringEnabled ? self.filteredMessages : self.messages)[indexPath.row];
    if (![self.expandedMessages containsObject:logMessage])
    {
        return 40.0;
    }
    
    // Collapsed cell
    NSString * string = [self textForCellWithLogMessage:logMessage];
    CGSize size;
    // Save a sample label reference
    static UILabel * labelModel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        labelModel = [self labelForNewCell];
    });

    labelModel.text = string;
    size = [labelModel textRectForBounds:CGRectMake(0.f, 0.f, tableView.bounds.size.width, CGFLOAT_MAX) limitedToNumberOfLines:0].size;

    return size.height + 20.f;
}

- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLogInfo(@"willSelectRowAtIndexPath: %@ Expanded messages: %@", indexPath, _expandedMessages);
    
    // Remove/add row to expanded messages
    DDLogMessage * logMessage = (_filteringEnabled ? _filteredMessages : _messages)[indexPath.row];
    if ([_expandedMessages containsObject:logMessage])
    {
        [_expandedMessages removeObject:logMessage];
    }
    else
    {
        [_expandedMessages addObject:logMessage];
    }
    
    // Update cell's text
    UILabel * label = (UILabel *)[tableView cellForRowAtIndexPath:indexPath].contentView.subviews[0];
    label.text = [self textForCellWithLogMessage:logMessage];
    
    // The method is called from the main queue
    dispatch_async(_consoleQueue, ^
                   {
                       // Trigger row height update
                       [self updateTableViewInConsoleQueue];
                   });
    
    // Don't select the cell
    return nil;
}

- (UILabel *)labelForNewCell
{
    UILabel * label = [UILabel new];
    label.backgroundColor = [UIColor clearColor];
    label.font = _font;
    label.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    label.numberOfLines = 0;
    
    return label;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // A marker?
    DDLogMessage * logMessage = (_filteringEnabled ? _filteredMessages : _messages)[indexPath.row];
    BOOL marker = [logMessage isKindOfClass:[PTEMarkerLogMessage class]];
    
    // Load cell
    NSString * identifier = marker ? @"marker" : @"logMessage";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    UILabel * label;
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
        cell.clipsToBounds = YES;
        cell.backgroundColor = UIColor.clearColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        label = [self labelForNewCell];
        label.frame = cell.contentView.bounds;
        [cell.contentView addSubview:label];
        
        if (marker)
        {
            label.backgroundColor = [UIColor colorWithWhite:0.5 alpha:1.0];
            label.textAlignment = NSTextAlignmentCenter;
            cell.userInteractionEnabled = NO;
        }
    }
    else
    {
        label = (UILabel *)cell.contentView.subviews[0];
    }
    
    // Configure the label
    if (marker)
    {
        label.text = logMessage->_message;
    }
    else
    {
        switch (logMessage->_flag)
        {
            case DDLogFlagError   : label.textColor = [UIColor redColor];       break;
            case DDLogFlagWarning : label.textColor = [UIColor orangeColor];    break;
            case DDLogFlagInfo    : label.textColor = [UIColor greenColor];     break;
            case DDLogFlagDebug   : label.textColor = [UIColor whiteColor];     break;
            default               : label.textColor = [UIColor lightGrayColor]; break;
        }
        label.text = [self textForCellWithLogMessage:logMessage];
    }
    
    return cell;
}

- (NSString *)textForCellWithLogMessage:(DDLogMessage *)logMessage
{
    NSString * prefix;
    switch (logMessage->_flag)
    {
        case DDLogFlagError   : prefix = @"Ⓔ"; break;
        case DDLogFlagWarning : prefix = @"Ⓦ"; break;
        case DDLogFlagInfo    : prefix = @"Ⓘ"; break;
        case DDLogFlagDebug   : prefix = @"Ⓓ"; break;
        default               : prefix = @"Ⓥ"; break;
    }
    
    // Expanded message?
    if ([_expandedMessages containsObject:logMessage])
    {
        return [NSString stringWithFormat:@" %@ %@", prefix, [self formatLogMessage:logMessage]];
    }
    
    // Collapsed message
    return [NSString stringWithFormat:@" %@ %@", prefix, [self formatShortLogMessage:logMessage]];
}

#pragma mark - Copying text

- (BOOL)tableView:(UITableView *)tableView
shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView
 canPerformAction:(SEL)action
forRowAtIndexPath:(NSIndexPath *)indexPath
       withSender:(id)sender
{
    return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView
    performAction:(SEL)action
forRowAtIndexPath:(NSIndexPath *)indexPath
       withSender:(id)sender
{
    if (action == @selector(copy:))
    {
        DDLogMessage * logMessage = (_filteringEnabled ? _filteredMessages : _messages)[indexPath.row];
        NSString * textToCopy = [self formatLogMessage:logMessage];
        UIPasteboard.generalPasteboard.string = textToCopy;
        
        NSLogInfo(@"Copied: %@", textToCopy);
    }
}

#pragma mark - Message filtering

- (NSMutableArray *)filterMessages:(NSArray *)messages
{
    NSMutableArray * filteredMessages = NSMutableArray.array;
    for (DDLogMessage * message in messages)
    {
        if ([self messagePassesFilter:message])
        {
            [filteredMessages addObject:message];
        }
    }
    return filteredMessages;
}

- (BOOL)messagePassesFilter:(DDLogMessage *)message {
    NSStringCompareOptions opts = (NSStringCompareOptions)(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch);
    // Message is a marker OR (Log flag matches AND (no search text OR contains search text))
    return ([message isKindOfClass:[PTEMarkerLogMessage class]] ||
            ((message->_flag & _currentLogLevel) &&
             (_currentSearchText.length == 0 ||
              [[self formatLogMessage:message] rangeOfString:_currentSearchText
                                                     options:opts].location != NSNotFound)));
}

#pragma mark - Search bar delegate

- (void)searchBarStateChanged
{
    // The method is called from the main queue
    dispatch_async(_consoleQueue, ^{
        // Filtering enabled?
        self.filteringEnabled = (self.currentSearchText.length > 0 ||        // Some text input
                                 self.currentLogLevel != DDLogLevelVerbose); // Or log level != verbose
        
        // Force reloading filtered messages
        if (self.filteringEnabled)
        {
            self.filteredMessages = nil;
        }
        
        // Update
        [self updateTableViewInConsoleQueue];
    });
}

- (void)searchBar:(UISearchBar *)searchBar
selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    switch (selectedScope)
    {
        case 0  : _currentLogLevel = DDLogLevelVerbose; break;
        case 1  : _currentLogLevel = DDLogLevelDebug;   break;
        case 2  : _currentLogLevel = DDLogLevelInfo;    break;
        case 3  : _currentLogLevel = DDLogLevelWarning; break;
        default : _currentLogLevel = DDLogLevelError;   break;
    }
    
    [self searchBarStateChanged];
}

- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)searchText
{
    if ([_currentSearchText isEqualToString:searchText])
        return;
    
    _currentSearchText = searchBar.text;
    
    [self searchBarStateChanged];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
}

@end

