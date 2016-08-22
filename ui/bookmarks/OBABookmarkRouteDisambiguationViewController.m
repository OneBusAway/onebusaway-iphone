//
//  OBABookmarkRouteDisambiguationViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/31/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABookmarkRouteDisambiguationViewController.h"
#import <OBAKit/OBAArrivalsAndDeparturesForStopV2.h>
#import "OBATableRow.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBAApplication.h"

@interface OBABookmarkRouteDisambiguationViewController ()
@property(nonatomic,strong) OBAArrivalsAndDeparturesForStopV2 *arrivalsAndDepartures;
@end

@implementation OBABookmarkRouteDisambiguationViewController

- (instancetype)initWithArrivalsAndDeparturesForStop:(OBAArrivalsAndDeparturesForStopV2*)arrivalsAndDepartures {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"Choose a Route", @"Title of OBABookmarkRouteDisambiguationViewController");
        _arrivalsAndDepartures = arrivalsAndDepartures;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];

    OBATableSection *stopSection = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"Bookmark the Stop", @"")];
    [stopSection addRow:^OBABaseRow *{
        OBATableRow *row = [[OBATableRow alloc] initWithTitle:self.arrivalsAndDepartures.stop.nameWithDirection action:^{
            OBABookmarkV2 *bookmark = [[OBABookmarkV2 alloc] initWithStop:self.arrivalsAndDepartures.stop region:self.region];
            OBAEditStopBookmarkViewController *bookmarkViewController = [[OBAEditStopBookmarkViewController alloc] initWithBookmark:bookmark];
            [self.navigationController pushViewController:bookmarkViewController animated:YES];
        }];
        row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return row;
    }];

    OBATableSection *routeSection = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"Bookmark a Route at the Stop", @"")];

    for (OBAArrivalAndDepartureV2 *dep in self.arrivalsAndDepartures.arrivalsAndDepartures) {
        [routeSection addRow:^OBABaseRow *{
            OBATableRow *row = [[OBATableRow alloc] initWithTitle:[NSString stringWithFormat:@"%@ - %@", dep.bestAvailableName, dep.tripHeadsign] action:^{
                OBABookmarkV2 *bookmark = [[OBABookmarkV2 alloc] initWithArrivalAndDeparture:dep region:self.region];
                OBAEditStopBookmarkViewController *bookmarkViewController = [[OBAEditStopBookmarkViewController alloc] initWithBookmark:bookmark];
                [self.navigationController pushViewController:bookmarkViewController animated:YES];
            }];
            row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return row;
        }];
    }
    self.sections = @[stopSection, routeSection];
}

#pragma mark - Actions

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Accessors

- (OBARegionV2*)region {
    if (!_region) {
        _region = [OBAApplication sharedApplication].modelDao.region;
    }
    return _region;
}

@end
