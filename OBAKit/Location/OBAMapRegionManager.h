//
//  OBAMapRegionManager.h
//  org.onebusaway.iphone2
//
//  Created by Brian Ferris on 5/8/11.
//  Copyright 2011 OneBusAway. All rights reserved.
//

@import Foundation;
#import <OBAKit/OBARegionChangeRequest.h>
#import <OBAKit/OBANavigationTarget.h>

NS_ASSUME_NONNULL_BEGIN

@class OBAMapRegionManager;
@protocol OBAMapRegionDelegate<NSObject>
- (void)mapRegionManager:(OBAMapRegionManager*)manager setRegion:(MKCoordinateRegion)region animated:(BOOL)animated;
@end

@interface OBAMapRegionManager : NSObject
@property (nonatomic) BOOL lastRegionChangeWasProgrammatic;

- (void)addDelegate:(id<OBAMapRegionDelegate>)delegate NS_SWIFT_NAME(add(delegate:));
- (void)removeDelegate:(id<OBAMapRegionDelegate>)delegate NS_SWIFT_NAME(remove(delegate:));

- (void)setRegion:(MKCoordinateRegion)region;
- (void)setRegion:(MKCoordinateRegion)region changeWasProgrammatic:(BOOL)changeWasProgrammatic;
- (void)setRegionFromNavigationTarget:(OBANavigationTarget*)navigationTarget;

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated;

/**
 * @return YES, if applying a pending region-change request, otherwise false
 */

- (BOOL)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
