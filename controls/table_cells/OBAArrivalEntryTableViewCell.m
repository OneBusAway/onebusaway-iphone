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

#import "OBAArrivalEntryTableViewCell.h"

@interface OBAArrivalEntryTableViewCell ()
@property(nonatomic,strong) NSTimer * transitionTimer;
@end

@implementation OBAArrivalEntryTableViewCell

+ (OBAArrivalEntryTableViewCell*) getOrCreateCellForTableView:(UITableView*)tableView {
    
    static NSString *cellId = @"OBAArrivalEntryTableViewCell";
    
    // Try to retrieve from the table view a now-unused cell with the given identifier
    OBAArrivalEntryTableViewCell *cell = (OBAArrivalEntryTableViewCell *) [tableView dequeueReusableCellWithIdentifier:cellId];
    
    // If no cell is available, create a new one using the given identifier
    if (!cell) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellId owner:self options:nil];
        cell = nib[0];
    }
    
    return cell;
}

- (void)dealloc {
    [self cancelTimer];
}

- (void)setAlertStyle:(OBAArrivalEntryTableViewCellAlertStyle)alertStyle {
    
    _alertStyle = alertStyle;

    if (_alertStyle == OBAArrivalEntryTableViewCellAlertStyleNone) {
        [self cancelTimer];
        self.alertImage.hidden = YES;
        self.minutesLabel.hidden = NO;
    }
    else {
        self.minutesLabel.alpha = 1.0;
        self.alertImage.alpha = 0.0;
        self.alertImage.hidden = NO;

        if (!self.transitionTimer) {
            self.transitionTimer = [NSTimer scheduledTimerWithTimeInterval:1.2 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
        }
    }
}

- (void)timerFired:(NSTimer*)theTimer {
    
    UIImage *activeImage = nil;
    if (self.alertStyle == OBAArrivalEntryTableViewCellAlertStyleActive) {
        activeImage = [UIImage imageNamed:@"Alert"];
    }
    else {
        activeImage = [UIImage imageNamed:@"AlertGrayscale"];
    }
    
    self.alertImage.image = activeImage;
    
    [UIView animateWithDuration:0.35 animations:^{
        if (self.minutesLabel.alpha == 0.0) {
            self.minutesLabel.alpha = 1.0;
            self.alertImage.alpha = 0.0;
        }
        else {
            self.minutesLabel.alpha = 0.0;
            self.alertImage.alpha = 1.0;
        }
    }];
}

#pragma mark - Private

- (void)cancelTimer {
    if (self.transitionTimer) {
        [self.transitionTimer invalidate];
        self.transitionTimer = nil;
    }    
}

@end
