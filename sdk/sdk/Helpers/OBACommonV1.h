@import Foundation;

typedef NS_ENUM(NSInteger, OBANavigationTargetType) {
    OBANavigationTargetTypeRoot=0,
    OBANavigationTargetTypeSearch,
    OBANavigationTargetTypeSearchResults,
    OBANavigationTargetTypeBookmarks,
    OBANavigationTargetTypeRecentStops,
    OBANavigationTargetTypeStop,
    OBANavigationTargetTypeEditBookmark,
    OBANavigationTargetTypeEditStopPreferences,
    OBANavigationTargetTypeSettings,
    OBANavigationTargetTypeContactUs,
    OBANavigationTargetTypeAgencies,
};

typedef NS_ENUM(NSInteger, OBASearchViewType) {
    OBASearchViewTypeByStop = 0,
    OBASearchViewTypeByRoute,
    OBASearchViewTypeByAddress,
};


#define APP_DELEGATE ((OBAApplicationDelegate*)[UIApplication sharedApplication].delegate)

#define OBARGBCOLOR(__r, __g, __b) [UIColor colorWithRed:(__r / 255.f) green:(__g / 255.f) blue:(__b / 255.f) alpha:1.f]
#define OBARGBACOLOR(__r, __g, __b, __a) [UIColor colorWithRed:(__r / 255.f) green:(__g / 255.f) blue:(__b / 255.f) alpha:__a]
#define OBAGREENWITHALPHA(__a) [UIColor colorWithHue:(86.f/360.f) saturation:0.68f brightness:0.67f alpha:__a]
#define OBAGREEN [UIColor colorWithHue:(86.f/360.f) saturation:0.68f brightness:0.67f alpha:1.f]
#define OBAGREENBACKGROUND [UIColor colorWithRed:0.92f green:0.95f blue:0.88f alpha:.67f]
#define OBADARKGREEN [UIColor colorWithRed:0.2f green:.4f blue:0.f alpha:1.f]

#define OBAViewedArrivalsAndDeparturesForStopNotification @"OBAViewedArrivalsAndDeparturesForStopNotification"
#define OBAMostRecentStopsChangedNotification @"OBAMostRecentStopsChangedNotification"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)