//
//  OBAAlerts.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 10/31/15.
//  Copyright © 2015 OneBusAway. All rights reserved.
//

#import "OBAAlerts.h"
#import "EXTScope.h"
@import OBAKit;

@interface OBATextFieldAlertController : UIAlertController
@property(nonatomic,strong) UIAlertAction *saveButton;

+ (instancetype)alertWithTitle:(NSString*)title configurationHandler:(void (^ __nullable)(UITextField *textField))configurationHandler;
@end

@implementation OBATextFieldAlertController

+ (instancetype)alertWithTitle:(NSString*)title configurationHandler:(void (^ __nullable)(UITextField *textField))configurationHandler {
    OBATextFieldAlertController *alert = [OBATextFieldAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:configurationHandler];
    for (UITextField *field in alert.textFields) {
        [field addTarget:alert action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }

    return alert;
}

- (void)textFieldDidChange:(UITextField *)textField {
    if (self.saveButton) {
        self.saveButton.enabled = (textField.text.length > 0);
    }
}

@end

@implementation OBAAlerts

+ (UIAlertController*)locationServicesDisabledAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"msg_location_services_disabled", @"view.title")
                                                                   message:NSLocalizedString(@"msg_alert_location_services_disabled", @"view.message") preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:OBAStrings.dismiss style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"msg_fix_it", @"Location services alert button.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSURL *appSettings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        // Appropriate use of -openURL:. Don't replace.
        [UIApplication.sharedApplication openURL:appSettings options:@{} completionHandler:nil];
    }]];

    return alert;
}


+ (UIAlertController*)buildAddBookmarkGroupAlertWithModelDAO:(OBAModelDAO*)modelDAO completion:(void(^)(void))completion {
    OBABookmarkGroup *group = nil;

    OBATextFieldAlertController *alertController = [OBATextFieldAlertController alertWithTitle:NSLocalizedString(@"msg_add_bookmark_group",) configurationHandler:^(UITextField *textField) {
        textField.placeholder = NSLocalizedString(@"msg_name_of_group",);
        textField.text = group.name;
    }];

    [alertController addAction:[UIAlertAction actionWithTitle:OBAStrings.cancel style:UIAlertActionStyleCancel handler:nil]];

    UIAlertAction *saveButton = [UIAlertAction actionWithTitle:OBAStrings.save style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        OBABookmarkGroup *newGroup = [[OBABookmarkGroup alloc] initWithName:alertController.textFields.firstObject.text];
        [modelDAO saveBookmarkGroup:newGroup];
        completion();
    }];
    [alertController addAction:saveButton];
    alertController.saveButton = saveButton;

    return alertController;
}

@end
