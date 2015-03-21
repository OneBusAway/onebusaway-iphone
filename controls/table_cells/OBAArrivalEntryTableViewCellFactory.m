#import "OBAArrivalEntryTableViewCellFactory.h"
#import "OBAPresentation.h"

@implementation OBAArrivalEntryTableViewCellFactory

- (id) initWithappDelegate:(OBAApplicationDelegate*)appDelegate tableView:(UITableView*)tableView {
    self = [super init];
    if( self ) {
        _appDelegate = appDelegate;
        _tableView = tableView;
        
        _timeFormatter = [[NSDateFormatter alloc] init];
        [_timeFormatter setDateStyle:NSDateFormatterNoStyle];
        [_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        
        _showServiceAlerts = YES;
    }
    return self;
}


- (OBAArrivalEntryTableViewCell*) createCellForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrival {

    OBAArrivalEntryTableViewCell * cell = [OBAArrivalEntryTableViewCell getOrCreateCellForTableView:_tableView];
    
    NSDate * time = [NSDate dateWithTimeIntervalSince1970:(arrival.bestDepartureTime / 1000)];            
    NSTimeInterval interval = [time timeIntervalSinceNow];
    NSInteger minutes = (NSInteger)(interval / 60.0);
    NSMutableAttributedString * attributedStatusLabel = [[NSMutableAttributedString alloc]
                                             initWithString:[NSString stringWithFormat:@"%@ - ",[_timeFormatter stringFromDate:time]]
                                             attributes:nil];
    NSMutableAttributedString *statusColoredString = [[NSMutableAttributedString alloc]
                                                      initWithString:[self getStatusLabelForArrival:arrival time:time minutes:minutes]];
    
    [statusColoredString addAttribute:NSForegroundColorAttributeName
                                value:[self getMinutesColorForArrival:arrival]
                                range:NSMakeRange(0, [statusColoredString length])];
    [attributedStatusLabel appendAttributedString:statusColoredString];
    
    cell.destinationLabel.text = [OBAPresentation getTripHeadsignForArrivalAndDeparture:arrival];
    cell.routeLabel.text = [OBAPresentation getRouteShortNameForArrivalAndDeparture:arrival];
    cell.alertStyle = [self getAlertStyleForArrival:arrival];
    [cell.statusLabel setAttributedText:attributedStatusLabel];

    if( arrival.predicted && arrival.predictedDepartureTime == 0 ) {
        if( arrival.distanceFromStop < 500 ) {
            cell.minutesLabel.text = [NSString stringWithFormat:@"%ld",(long) arrival.distanceFromStop];
            cell.minutesSubLabel.text = NSLocalizedString(@"meters",@"cell.minutesSubLabel.text");
        }
        else {
            cell.minutesLabel.text = [NSString stringWithFormat:@"%0.1f",(arrival.distanceFromStop/1000.0)];    
            cell.minutesSubLabel.text = @"km";
        }
        
        cell.minutesLabel.textColor = [UIColor greenColor];
        cell.minutesSubLabel.hidden = NO;
        
    }
    else {
        cell.minutesLabel.text = [self getMinutesLabelForMinutes:minutes];
        cell.minutesLabel.textColor = [self getMinutesColorForArrival:arrival];
        cell.minutesSubLabel.hidden = YES;
    }
    
    NSString *minutesUntilArrivalText;
    if ([cell.minutesLabel.text isEqualToString:@"NOW"])
        minutesUntilArrivalText = NSLocalizedString(@"arriving now", "minutes==0");
    else if (cell.minutesLabel.text.intValue > 1)
        minutesUntilArrivalText = [NSString stringWithFormat:NSLocalizedString(@"%@ minutes until arrival", @"minutes > 1"), cell.minutesLabel.text];
    else if (cell.minutesLabel.text.intValue == 1)
        minutesUntilArrivalText = NSLocalizedString(@"1 minute until arrival", "minutes==1");
    else if (cell.minutesLabel.text.intValue == -1)
            minutesUntilArrivalText = NSLocalizedString(@"departed 1 minute ago", "minutes==-1");
    else if (cell.minutesLabel.text.intValue < -1) {
        NSInteger positiveMins = cell.minutesLabel.text.intValue * -1;
        minutesUntilArrivalText = [NSString stringWithFormat:NSLocalizedString(@"departed %i minutes ago", @"minutes < 0"), positiveMins];
    }
    else
        minutesUntilArrivalText = NSLocalizedString(@"unknown arrival time", @"minutes unknown");
    
    cell.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@ toward %@, %@ at %@", "arrivalEntryTable.cell.accessibilityLabel"), cell.routeLabel.text, cell.destinationLabel.text, minutesUntilArrivalText, cell.statusLabel.text];
    
    return cell;    
}

- (NSString*) getMinutesLabelForMinutes:(NSInteger)minutes {
    if (minutes == 0) {
        return NSLocalizedString(@"NOW",@"minutes == 0");
    }
    else {
        return [NSString stringWithFormat:@"%@",@(minutes)];
    }
}

- (UIColor*) getMinutesColorForArrival:(OBAArrivalAndDepartureV2*)arrival {
    
    if( arrival.predictedDepartureTime > 0 ) {
        double diff = (arrival.predictedDepartureTime - arrival.scheduledDepartureTime) / ( 1000.0 * 60.0);            
        if( diff < -1.5) {
            return [UIColor redColor];
        }
        else if( diff < 1.5 ) {
            return OBALABELGREEN;
        }
        else {
            return [UIColor blueColor];
        }
    }
    else {
        return [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];;
    }
}

- (NSString*) getStatusLabelForArrival:(OBAArrivalAndDepartureV2*)arrival time:(NSDate*)time minutes:(NSInteger)minutes {
    
    if (arrival.frequency) {
        OBAFrequencyV2 * freq = arrival.frequency;
        NSInteger headway = freq.headway / 60;
        
        NSDate * now = [NSDate date];
        NSDate * startTime = [NSDate dateWithTimeIntervalSince1970:(freq.startTime / 1000)];
        NSDate * endTime = [NSDate dateWithTimeIntervalSince1970:(freq.endTime / 1000)];
        
        if ([now compare:startTime]  == NSOrderedAscending) {
            return [NSString stringWithFormat:@"%@ %@ %@ %@",NSLocalizedString(@"Every",@"[now compare:startTime]"), @(headway), NSLocalizedString(@"mins from", @"[now compare:startTime] == NSOrderedAscending"), [_timeFormatter stringFromDate:startTime]];
        }
        else {
            return [NSString stringWithFormat:@"%@ %@ %@ %@",NSLocalizedString(@"Every",@"[now compare:startTime]"), @(headway), NSLocalizedString(@"mins until",@"[now compare:startTime] # NSOrderedAscending"), [_timeFormatter stringFromDate:endTime]];
        }
    }
    
    NSString *status = nil;
    
    if (arrival.predictedDepartureTime > 0) {
        double diff = (arrival.predictedDepartureTime - arrival.scheduledDepartureTime) / (1000.0 * 60.0);
        NSInteger minDiff = (NSInteger) fabs(diff);
        if (diff < -1.5) {
            if (minutes < 0)
                status = [NSString stringWithFormat:@"%@ %@ %@",NSLocalizedString(@"departed",@"minutes < 0"), @(minDiff), NSLocalizedString(@"min early", @"diff < -1.5")];
            else
                status = [NSString stringWithFormat:@"%@ %@", @(minDiff), NSLocalizedString(@"min early",@"diff < -1.5")];
        }
        else if(diff < 1.5) {
            if (minutes < 0)
                status = NSLocalizedString(@"departed on time",@"minutes < 0");
            else
                status = NSLocalizedString(@"on time",@"minutes >= 0");
        }
        else {
            if (minutes < 0)
                status = [NSString stringWithFormat:@"%@ %@ %@",NSLocalizedString(@"departed",@"minutes < 0"), @(minDiff), NSLocalizedString(@"min late",@"diff")];
            else
                status = [NSString stringWithFormat:@"%@ %@", @(minDiff), NSLocalizedString(@"min delay",@"diff")];
        }
    }
    else {
        if( minutes < 0 )
            status = NSLocalizedString(@"scheduled departure", @"minutes < 0");
        else
            status = NSLocalizedString(@"scheduled arrival", @"minutes >= 0");
    }
    
    return status;
}

- (OBAArrivalEntryTableViewCellAlertStyle) getAlertStyleForArrival:(OBAArrivalAndDepartureV2*)arrival {
    
    if (!_showServiceAlerts) {
        return OBAArrivalEntryTableViewCellAlertStyleNone;
    }

    NSArray * situations = arrival.situations;
    if (situations.count == 0) {
        return OBAArrivalEntryTableViewCellAlertStyleNone;
    }

    OBAModelDAO * modelDao = _appDelegate.modelDao;
    OBAServiceAlertsModel * serviceAlerts = [modelDao getServiceAlertsModelForSituations:situations];

    if (serviceAlerts.unreadCount > 0) {
        return OBAArrivalEntryTableViewCellAlertStyleActive;
    }
    else {
        return OBAArrivalEntryTableViewCellAlertStyleInactive;
    }
}

@end

