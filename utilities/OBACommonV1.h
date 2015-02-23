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
#define OBAGREEN [UIColor colorWithHue:(86./360.) saturation:0.68 brightness:0.67 alpha:1];
#define OBAGREENBACKGROUND [UIColor colorWithHue:(86./360.) saturation:0.68 brightness:0.67 alpha:0.1]
#define OBADARKGREEN [UIColor colorWithRed:0.2 green:.4 blue:0 alpha:1]
#define OBALABELGREEN [UIColor colorWithRed:0 green:0.478 blue:0 alpha: 1]

#define OBAPlacemarkNotification @"OBAPlacemarkNotification"
#define OBAViewedArrivalsAndDeparturesForStopNotification @"OBAViewedArrivalsAndDeparturesForStopNotification"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)