#import "OBAArrivalEntryTableViewCellFactory.h"


@interface OBAArrivalEntryTableViewCellFactory (Private)

- (NSString*) getMinutesLabelForMinutes:(int)minutes;
- (UIColor*) getMinutesColorForArrival:(OBAArrivalAndDepartureV2*)arrival;
- (NSString*) getStatusLabelForArrival:(OBAArrivalAndDepartureV2*)arrival time:(NSDate*)time minutes:(int)minutes;
- (OBAArrivalEntryTableViewCellAlertStyle) getAlertStyleForArrival:(OBAArrivalAndDepartureV2*)arrival;

@end


@implementation OBAArrivalEntryTableViewCellFactory

@synthesize showServiceAlerts = _showServiceAlerts;

- (id) initWithAppContext:(OBAApplicationContext*)appContext tableView:(UITableView*)tableView {
	if( self = [super init] ) {
		_appContext = [appContext retain];
		_tableView = [tableView retain];
		
		_timeFormatter = [[NSDateFormatter alloc] init];
		[_timeFormatter setDateStyle:NSDateFormatterNoStyle];
		[_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
		
		_showServiceAlerts = TRUE;
	}
	return self;
}

- (void) dealloc {
	[_appContext release];
	[_tableView release];
	[_timeFormatter release];
	[super dealloc];
}

- (OBAArrivalEntryTableViewCell*) createCellForArrivalAndDeparture:(OBAArrivalAndDepartureV2*)arrival {

	OBAArrivalEntryTableViewCell * cell = [OBAArrivalEntryTableViewCell getOrCreateCellForTableView:_tableView];
	
	NSDate * time = [NSDate dateWithTimeIntervalSince1970:(arrival.bestDepartureTime / 1000)];			
	NSTimeInterval interval = [time timeIntervalSinceNow];
	int minutes = interval / 60;
	
	cell.destinationLabel.text = arrival.tripHeadsign;
	cell.routeLabel.text = arrival.routeShortName;
	cell.statusLabel.text = [self getStatusLabelForArrival:arrival time:time minutes:minutes];
	cell.alertStyle = [self getAlertStyleForArrival:arrival];

	if( arrival.predicted && arrival.predictedDepartureTime == 0 ) {
		if( arrival.distanceFromStop < 500 ) {
			cell.minutesLabel.text = [NSString stringWithFormat:@"%d",(NSInteger) arrival.distanceFromStop];	
			cell.minutesSubLabel.text = @"meters";
		}
		else {
			cell.minutesLabel.text = [NSString stringWithFormat:@"%0.1f",(arrival.distanceFromStop/1000.0)];	
			cell.minutesSubLabel.text = @"km";
		}
		
		cell.minutesLabel.textColor = [UIColor greenColor];
		cell.minutesSubLabel.hidden = FALSE;
		
	}
	else {
		cell.minutesLabel.text = [self getMinutesLabelForMinutes:minutes];
		cell.minutesLabel.textColor = [self getMinutesColorForArrival:arrival];
		cell.minutesSubLabel.hidden = TRUE;
	}
	

	
	return cell;	
}


@end

@implementation OBAArrivalEntryTableViewCellFactory (Private)

- (NSString*) getMinutesLabelForMinutes:(int)minutes {
	if(abs(minutes) <=1)
		return @"NOW";
	else
		return [NSString stringWithFormat:@"%d",minutes];
}

- (UIColor*) getMinutesColorForArrival:(OBAArrivalAndDepartureV2*)arrival {
	
	if( arrival.predictedDepartureTime > 0 ) {
		double diff = (arrival.predictedDepartureTime - arrival.scheduledDepartureTime) / ( 1000.0 * 60.0);			
		if( diff < -1.5) {
			return [UIColor redColor];
		}
		else if( diff < 1.5 ) {
			return [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
		}
		else {
			return [UIColor blueColor];
		}
	}
	else {
		return [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];;
	}
}

- (NSString*) getStatusLabelForArrival:(OBAArrivalAndDepartureV2*)arrival time:(NSDate*)time minutes:(int)minutes {
	
	if( arrival.frequency ) {
		OBAFrequencyV2 * freq = arrival.frequency;
		int headway = freq.headway / 60;
		
		NSDate * now = [NSDate date];
		NSDate * startTime = [NSDate dateWithTimeIntervalSince1970:(freq.startTime / 1000)];
		NSDate * endTime = [NSDate dateWithTimeIntervalSince1970:(freq.endTime / 1000)];
		
		if ([now compare:startTime]  == NSOrderedAscending) {
			return [NSString stringWithFormat:@"Every %d mins from %@",headway,[_timeFormatter stringFromDate:startTime]];
		}
		else {
			return [NSString stringWithFormat:@"Every %d mins until %@",headway,[_timeFormatter stringFromDate:endTime]];
		}
	}
	
	NSString * status;
	
	if( arrival.predictedDepartureTime > 0 ) {
		double diff = (arrival.predictedDepartureTime - arrival.scheduledDepartureTime) / ( 1000.0 * 60.0);
		int minDiff = (int) abs(diff);
		if( diff < -1.5) {
			if( minutes < 0 )
				status = [NSString stringWithFormat:@"departed %d min early",minDiff];
			else
				status = [NSString stringWithFormat:@"%d min early",minDiff];
		}
		else if( diff < 1.5 ) {
			if( minutes < 0 )
				status = @"departed on time";
			else
				status = @"on time";
		}
		else {
			if( minutes < 0 )
				status = [NSString stringWithFormat:@"departed %d min late",minDiff];
			else
				status = [NSString stringWithFormat:@"%d min delay",minDiff];
		}
	}
	else {
		if( minutes < 0 )
			status = @"scheduled departure";
		else
			status = @"scheduled arrival";
	}
	
	return [NSString stringWithFormat:@"%@ - %@",[_timeFormatter stringFromDate:time],status];	
}

- (OBAArrivalEntryTableViewCellAlertStyle) getAlertStyleForArrival:(OBAArrivalAndDepartureV2*)arrival {
	
	if( ! _showServiceAlerts )
		return OBAArrivalEntryTableViewCellAlertStyleNone;
	
	NSArray * situations = arrival.situations;
	if( [situations count] == 0 )
		return OBAArrivalEntryTableViewCellAlertStyleNone;
	OBAModelDAO * modelDao = _appContext.modelDao;
	OBAServiceAlertsModel * serviceAlerts = [modelDao getServiceAlertsModelForSituations:arrival.situations];
	if( serviceAlerts.unreadCount > 0 )
		return OBAArrivalEntryTableViewCellAlertStyleActive;
	else
		return OBAArrivalEntryTableViewCellAlertStyleInactive;
}

@end

