//
//  OBAKit.h
//  OBAKit
//
//  Created by Aaron Brethorst on 2/19/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//! Project version number for OBAKit.
FOUNDATION_EXPORT double OBAKitVersionNumber;

//! Project version string for OBAKit.
FOUNDATION_EXPORT const unsigned char OBAKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <OBAKit/PublicHeader.h>

#import <OBAKit/JsonUrlFetcherImpl.h>
#import <OBAKit/NSArray+OBAAdditions.h>
#import <OBAKit/NSObject+OBADescription.h>
#import <OBAKit/OBAAgencyV2.h>
#import <OBAKit/OBAAgencyWithCoverageV2.h>
#import <OBAKit/OBAAnimation.h>
#import <OBAKit/OBAApplication.h>
#import <OBAKit/OBAArrivalAndDepartureInstanceRef.h>
#import <OBAKit/OBAArrivalAndDepartureV2.h>
#import <OBAKit/OBAArrivalsAndDeparturesForStopV2.h>
#import <OBAKit/OBABookmarkGroup.h>
#import <OBAKit/OBABookmarkV2.h>
#import <OBAKit/OBACallMethodJsonDigesterRule.h>
#import <OBAKit/OBACommon.h>
#import <OBAKit/OBACommonV1.h>
#import <OBAKit/OBACoordinateBounds.h>
#import <OBAKit/OBACreateObjectJsonDigesterRule.h>
#import <OBAKit/OBADataSource.h>
#import <OBAKit/OBADataSourceConfig.h>
#import <OBAKit/OBADateHelpers.h>
#import <OBAKit/OBADepartureCellHelpers.h>
#import <OBAKit/OBADepartureStatus.h>
#import <OBAKit/OBADepartureTimeLabel.h>
#import <OBAKit/OBAEmailHelper.h>
#import <OBAKit/OBAEntryWithReferencesV2.h>
#import <OBAKit/OBAFrequencyV2.h>
#import <OBAKit/OBAHasReferencesV2.h>
#import <OBAKit/OBAHasServiceAlerts.h>
#import <OBAKit/OBAImageHelpers.h>
#import <OBAKit/OBAJsonDataSource.h>
#import <OBAKit/OBAJsonDigester.h>
#import <OBAKit/OBAListWithRangeAndReferencesV2.h>
#import <OBAKit/OBALocationManager.h>
#import <OBAKit/OBAMacros.h>
#import <OBAKit/OBAMapHelpers.h>
#import <OBAKit/OBAMapRegionManager.h>
#import <OBAKit/OBAModelDAO.h>
#import <OBAKit/OBAModelDAOUserPreferencesImpl.h>
#import <OBAKit/OBAModelFactory.h>
#import <OBAKit/OBAModelPersistenceLayer.h>
#import <OBAKit/OBAModelService.h>
#import <OBAKit/OBAModelServiceRequest.h>
#import <OBAKit/OBANavigationTarget.h>
#import <OBAKit/OBANavigationTargetAnnotation.h>
#import <OBAKit/OBAPlacemark.h>
#import <OBAKit/OBAPlacemarks.h>
#import <OBAKit/OBAProgressIndicatorSource.h>
#import <OBAKit/OBAReachability.h>
#import <OBAKit/OBAReferencesV2.h>
#import <OBAKit/OBARegionBoundsV2.h>
#import <OBAKit/OBARegionChangeRequest.h>
#import <OBAKit/OBARegionHelper.h>
#import <OBAKit/OBARegionV2.h>
#import <OBAKit/OBAReportProblemWithStopV2.h>
#import <OBAKit/OBAReportProblemWithTripV2.h>
#import <OBAKit/OBARouteFilter.h>
#import <OBAKit/OBARouteType.h>
#import <OBAKit/OBARouteV2.h>
#import <OBAKit/OBASearch.h>
#import <OBAKit/OBASearchResult.h>
#import <OBAKit/OBASelectorJsonDigesterRule.h>
#import <OBAKit/OBAServiceAlertsModel.h>
#import <OBAKit/OBASetCoordinatePropertyJsonDigesterRule.h>
#import <OBAKit/OBASetDatePropertyJsonDigesterRule.h>
#import <OBAKit/OBASetLocationPropertyJsonDigesterRule.h>
#import <OBAKit/OBASetNextOBAJsonDigesterRule.h>
#import <OBAKit/OBASetPropertyJsonDigesterRule.h>
#import <OBAKit/OBASituationConsequenceV2.h>
#import <OBAKit/OBASituationV2.h>
#import <OBAKit/OBASphericalGeometryLibrary.h>
#import <OBAKit/OBAStopAccessEventV2.h>
#import <OBAKit/OBAStopIconFactory.h>
#import <OBAKit/OBAStopPreferencesV2.h>
#import <OBAKit/OBAStopV2.h>
#import <OBAKit/OBAStopsForRouteV2.h>
#import <OBAKit/OBAStrings.h>
#import <OBAKit/OBATheme.h>
#import <OBAKit/OBATripContinuationMapAnnotation.h>
#import <OBAKit/OBATripDetailsV2.h>
#import <OBAKit/OBATripInstanceRef.h>
#import <OBAKit/OBATripScheduleV2.h>
#import <OBAKit/OBATripStatusV2.h>
#import <OBAKit/OBATripStopTimeMapAnnotation.h>
#import <OBAKit/OBATripStopTimeV2.h>
#import <OBAKit/OBATripV2.h>
#import <OBAKit/OBAUIBuilder.h>
#import <OBAKit/OBAURLHelpers.h>
#import <OBAKit/OBAUser.h>
#import <OBAKit/OBAVehicleMapAnnotation.h>
#import <OBAKit/OBAVehicleStatusV2.h>
#import <OBAKit/UILabel+OBAAdditions.h>
