//
//  OBAArrivalDepartureOptionsSheet.m
//  OneBusAway
//
//  Created by Aaron Brethorst on 9/3/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

#import "OBAArrivalDepartureOptionsSheet.h"
#import "GKActionSheetPicker.h"
#import "OBAPushManager.h"
@import SVProgressHUD;
#import "OBAEditStopBookmarkViewController.h"
#import "OneBusAway-Swift.h"

@interface OBAArrivalDepartureOptionsSheet ()
@property(nonatomic,weak) id<OBAArrivalDepartureOptionsSheetDelegate> delegate;
@property(nonatomic,strong) GKActionSheetPicker *actionSheetPicker;
@end

@implementation OBAArrivalDepartureOptionsSheet

- (instancetype)initWithDelegate:(id<OBAArrivalDepartureOptionsSheetDelegate>)delegate {
    self = [super init];

    if (self) {
        _delegate = delegate;
    }

    return self;
}

#pragma mark - Bookmarks

- (void)presentAlertToRemoveBookmarkForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"msg_ask_remove_bookmark", @"Tap on Remove Bookmarks on OBAStopViewController.") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"msg_remove", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        OBABookmarkV2 *bookmark = [self.modelDAO bookmarkForArrivalAndDeparture:dep];
        [self.modelDAO removeBookmark:bookmark];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];

    [self.delegate optionsSheet:self presentViewController:alert fromView:nil];
}

#pragma mark - Alarm

- (void)createAlarmForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    NSUInteger alarmIncrements = dep.minutesUntilBestDeparture <= OBAAlarmIncrementsInMinutes ? 1 : OBAAlarmIncrementsInMinutes;

    NSMutableArray *items = [[NSMutableArray alloc] init];

    for (NSInteger i = dep.minutesUntilBestDeparture - (dep.minutesUntilBestDeparture % alarmIncrements); i > 0; i -=alarmIncrements) {
        NSString *pickerItemTitle = [NSString stringWithFormat:NSLocalizedString(@"alarms.picker.formatted_item", @"The format string used for picker items for choosing when an alarm should ring."), @(i)];
        [items addObject:[GKActionSheetPickerItem pickerItemWithTitle:pickerItemTitle value:@(i*60)]];
    }

    self.actionSheetPicker = [GKActionSheetPicker stringPickerWithItems:items selectCallback:^(id selected) {
        [self registerAlarmForArrivalAndDeparture:dep timeInterval:[selected doubleValue]];
    } cancelCallback:nil];

    self.actionSheetPicker.title = NSLocalizedString(@"alarms.picker.title", @"The title of the picker view that lets you choose how many minutes before your bus departs you will get an alarm.");

    if (dep.minutesUntilBestDeparture >= 10) {
        [self.actionSheetPicker selectValue:@(10*60)];
    }

    UIView *view = [self.delegate optionsSheetPresentationView:self];
    [self.actionSheetPicker presentPickerOnView:view];
}

- (void)presentAlertToRemoveAlarmForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"alarms.confirm_deletion_alert_title", @"The title of the alert controller that prompts the user about whether they really want to delete this alarm.") message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"alarms.confirm_deletion_alert_cancel_button", @"This is the button that cancels the alarm deletion.") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"alarms.confirm_deletion_alert_delete_button", @"This is the button that confirms that the user really does want to delete their alarm.") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteAlarmForArrivalAndDeparture:dep];
    }]];

    [self.delegate optionsSheet:self presentViewController:alert fromView:nil];
}

- (void)registerAlarmForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalDeparture timeInterval:(NSTimeInterval)timeInterval {
    OBAAlarm *alarm = [[OBAAlarm alloc] initWithArrivalAndDeparture:arrivalDeparture regionIdentifier:self.modelDAO.currentRegion.identifier timeIntervalBeforeDeparture:timeInterval];

    [SVProgressHUD show];

    [[OBAPushManager pushManager] requestUserPushNotificationID].then(^(NSString *pushNotificationID) {
        return [self.modelService requestAlarm:alarm userPushNotificationID:pushNotificationID];
    }).then(^(NSDictionary *serverResponse) {
        alarm.alarmURL = [NSURL URLWithString:serverResponse[@"url"]];
        [self.modelDAO addAlarm:alarm];

        id<OBAArrivalDepartureOptionsSheetDelegate> delegate = self.delegate;
        if ([delegate respondsToSelector:@selector(optionsSheet:addedAlarm:forArrivalAndDeparture:)]) {
            [delegate optionsSheet:self addedAlarm:alarm forArrivalAndDeparture:arrivalDeparture];
        }

        NSString *title = NSLocalizedString(@"alarms.alarm_created_alert_title", @"The title of the non-modal alert displayed when a push notification alert is registered for a vehicle departure.");
        NSString *body = [NSString stringWithFormat:NSLocalizedString(@"alarms.alarm_created_alert_body", @"The body of the non-modal alert that appears when a push notification alarm is registered."), @((NSUInteger)timeInterval / 60)];

        [AlertPresenter showSuccess:title body:body];
    }).catch(^(NSError *error) {
        [AlertPresenter showError:error];
    }).always(^{
        [SVProgressHUD dismiss];
    });
}

- (void)deleteAlarmForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    OBAAlarm *alarm = [self.modelDAO alarmForKey:dep.alarmKey];
    id<OBAArrivalDepartureOptionsSheetDelegate> delegate = self.delegate;

    NSURLRequest *request = [self.modelService.obaJsonDataSource requestWithURL:alarm.alarmURL HTTPMethod:@"DELETE"];
    [self.modelService.obaJsonDataSource performRequest:request completionBlock:^(id responseData, NSHTTPURLResponse *response, NSError *error) {
        if ([delegate respondsToSelector:@selector(optionsSheet:deletedAlarmForArrivalAndDeparture:)]) {
            [delegate optionsSheet:self deletedAlarmForArrivalAndDeparture:dep];
        }
    }];
}

#pragma mark - Accessors

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

- (OBAModelService*)modelService {
    if (!_modelService) {
        _modelService = [OBAApplication sharedApplication].modelService;
    }
    return _modelService;
}

#pragma mark - Action Menu

- (void)showActionMenuForDepartureRow:(OBADepartureRow*)departureRow fromPresentingView:(UIView*)presentingView {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"classic_departure_cell.context_alert.title", @"Title for the context menu button's alert controller.") message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];

    // Add Bookmark
    UIAlertAction *action = [UIAlertAction actionWithTitle:[self bookmarkButtonTitleForArrivalAndDeparture:departureRow.model] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self toggleBookmarkActionForArrivalAndDeparture:departureRow.model];
    }];
    [action setValue:[UIImage imageNamed:@"Favorites_Selected"] forKey:@"image"];
    [alert addAction:action];

    // Set Alarm
    if (departureRow.hasArrived) {
        action = [UIAlertAction actionWithTitle:[self.class alarmButtonTitleForDepartureRow:departureRow] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self toggleAlarmActionForArrivalAndDeparture:departureRow.model];
        }];
        [action setValue:[UIImage imageNamed:@"bell"] forKey:@"image"];
        [alert addAction:action];
    }

    action = [UIAlertAction actionWithTitle:NSLocalizedString(@"classic_departure_cell.context_alert.share_trip_status", @"Title for alert controller's Share Trip Status option.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [self shareActionForDepartureRow:departureRow];
    }];
    [action setValue:[UIImage imageNamed:@"share"] forKey:@"image"];
    [alert addAction:action];

    [self.delegate optionsSheet:self presentViewController:alert fromView:presentingView];
}

#pragma mark - Row Actions

- (void)toggleBookmarkActionForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    if ([self.modelDAO bookmarkForArrivalAndDeparture:dep]) {
        [self presentAlertToRemoveBookmarkForArrivalAndDeparture:dep];
    }
    else {
        OBABookmarkV2 *bookmark = [[OBABookmarkV2 alloc] initWithArrivalAndDeparture:dep region:self.modelDAO.currentRegion];
        OBAEditStopBookmarkViewController *editor = [[OBAEditStopBookmarkViewController alloc] initWithBookmark:bookmark];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editor];

        [self.delegate optionsSheet:self presentViewController:nav fromView:nil];
    }
}

- (void)shareActionForDepartureRow:(OBADepartureRow*)row {
    OBAGuard(row && row.model) else {
        return;
    }

    id<OBAArrivalDepartureOptionsSheetDelegate> delegate = self.delegate;

    OBAArrivalAndDepartureV2 *dep = row.model;
    OBATripDeepLink *deepLink = [[OBATripDeepLink alloc] initWithArrivalAndDeparture:dep region:self.modelDAO.currentRegion];
    NSURL *URL = deepLink.deepLinkURL;

    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[self, URL] applicationActivities:nil];

    UIView *view = [delegate optionsSheet:self viewForArrivalAndDeparture:dep];

    [delegate optionsSheet:self presentViewController:controller fromView:view];
}

#pragma mark - Alarms

- (void)toggleAlarmActionForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)dep {
    OBAGuard(dep) else {
        return;
    }

    if ([self.modelDAO alarmForKey:dep.alarmKey]) {
        [self presentAlertToRemoveAlarmForArrivalAndDeparture:dep];
    }
    else {
        [self createAlarmForArrivalAndDeparture:dep];
    }
}

#pragma mark - Labels

- (NSString*)bookmarkButtonTitleForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrivalDeparture {
    if ([self.modelDAO bookmarkForArrivalAndDeparture:arrivalDeparture]) {
        return NSLocalizedString(@"msg_remove_bookmark", @"Title for the alert controller option that removes an existing bookmark");
    }
    else {
        return NSLocalizedString(@"msg_add_bookmark",);
    }
}

+ (NSString*)alarmButtonTitleForDepartureRow:(OBADepartureRow*)departureRow {
    if (departureRow.alarmExists) {
        return NSLocalizedString(@"classic_departure_cell.context_alert.remove_alarm", @"Title for alert controller's Remove Alarm option.");
    }
    else {
        return NSLocalizedString(@"classic_departure_cell.context_alert.set_alarm", @"Title for alert controller's Set Alarm option.");
    }
}

@end
