#import "OBATripScheduleListViewController.h"
#import "OBATripStopTimeV2.h"
#import "OBATripScheduleMapViewController.h"
#import "OBAStopViewController.h"
#import "UITableViewController+oba_Additions.h"
#import "OBAAnalytics.h"
#import "UITableViewCell+oba_Additions.h"
#import "UINavigationController+oba_Additions.h"
#import <OBAKit/OBAKit.h>
#import "OBATripScheduleSectionBuilder.h"

typedef NS_ENUM(NSUInteger, OBASectionType) {
    OBASectionTypeNone = 0,
    OBASectionTypeLoading,
    OBASectionTypeSchedule,
    OBASectionTypePreviousStops,
    OBASectionTypeConnections
};

@interface OBATripScheduleListViewController ()
@property(nonatomic,strong) OBATripInstanceRef *tripInstance;
@property(nonatomic,strong) OBAProgressIndicatorView *progressView;
@end

@implementation OBATripScheduleListViewController

- (instancetype)initWithTripInstance:(OBATripInstanceRef *)tripInstance {
    self = [super init];

    if (self) {
        _tripInstance = tripInstance;

        CGRect r = CGRectMake(0, 0, 160, 33);
        _progressView = [[OBAProgressIndicatorView alloc] initWithFrame:r];
        [self.navigationItem setTitleView:_progressView];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"map"] style:UIBarButtonItemStylePlain target:self action:@selector(showMap:)];
        item.accessibilityLabel = NSLocalizedString(@"Map", @"initWithTitle");
        self.navigationItem.rightBarButtonItem = item;

        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Schedule", @"initWithTitle") style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.backBarButtonItem = backItem;
    }

    return self;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.tripDetails) {
        [self buildUI];
        return;
    }

    [[OBAApplication sharedApplication].modelService requestTripDetailsForTripInstance:self.tripInstance].then(^(OBATripDetailsV2 *tripDetails) {
        self.tripDetails = tripDetails;
        [self buildUI];
    }).catch(^(NSError *error) {
        if (error.code == 404) {
            [self.progressView setMessage:NSLocalizedString(@"Trip not found", @"message") inProgress:NO progress:0];
        }
        else if (error.code >= 300) {
            [self.progressView setMessage:NSLocalizedString(@"Unknown error", @"message") inProgress:NO progress:0];
        }
        else {
            NSLog(@"Error: %@", error);
            [self.progressView setMessage:NSLocalizedString(@"Error connecting", @"message") inProgress:NO progress:0];
        }
    });
}

#pragma mark - Static tables

- (void)buildUI {
    NSMutableArray *sections = [[NSMutableArray alloc] init];

    OBATableSection *stopsSection = [OBATripScheduleSectionBuilder buildStopsSection:self.tripDetails navigationController:self.navigationController];

    [sections addObject:stopsSection];

    if ([self.tripDetails hasTripConnections]) {
        OBATableSection *connectionsSection = [OBATripScheduleSectionBuilder buildConnectionsSectionWithTripDetails:self.tripDetails tripInstance:self.tripInstance navigationController:self.navigationController];
        [sections addObject:connectionsSection];
    }

    self.sections = [NSArray arrayWithArray:sections];
    [self.tableView reloadData];

    NSUInteger stopIndex = [self currentStopIndex];
    if (stopIndex != NSNotFound) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:stopIndex inSection:[self.sections indexOfObject:stopsSection]];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

#pragma mark - Actions

- (void)showMap:(id)sender {
    OBATripScheduleMapViewController *vc = [[OBATripScheduleMapViewController alloc] init];

    vc.tripDetails = _tripDetails;
    vc.currentStopId = self.currentStopId;
    [self.navigationController replaceViewController:vc animated:YES];
}

#pragma mark - Private

- (NSUInteger)currentStopIndex {
    return [OBATripScheduleSectionBuilder indexOfStopID:self.currentStopId inSchedule:self.tripDetails.schedule];
}

@end
