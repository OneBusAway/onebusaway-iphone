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