//
//  OBAMapRegionManager.h
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 5/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OBAKit/OBARegionChangeRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface OBAMapRegionManager : NSObject
@property (nonatomic) BOOL lastRegionChangeWasProgrammatic;

- (id)initWithMapView:(MKMapView*)mapView;

- (void)setRegion:(MKCoordinateRegion)region;
- (void)setRegion:(MKCoordinateRegion)region changeWasProgrammatic:(BOOL)changeWasProgrammatic;

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated;

/**
 * @return TRUE, if applying a pending region-change request, otherwise false
 */
- (BOOL)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
