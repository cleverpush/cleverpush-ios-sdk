#import "CleverPushLocation.h"
#import "CleverPush.h"
#import "CleverPushHTTPClient.h"
#import "NSDictionary+SafeExpectations.h"
#import "CPLog.h"

@implementation CleverPushLocation

CLLocationManager* locationManager;
NSTimer *geoFenceTimer;
double geoFenceTimerDelay;
bool geoFenceTimeoutCompleted;
NSMutableArray *delayedGeoFences;
NSMutableArray *beacons;
NSString* geoFenceEnterState = @"enter";
NSString* geoFenceExitState = @"exit";
double geoFenceTimerInterval = 1.0;

+ (void)init {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        [CleverPush getSubscriptionId:^(NSString* subscriptionId) {
            if (subscriptionId == nil) {
                [CPLog debug:@"CleverPushLocation: init: There is no subscription for CleverPush SDK."];
            }
            [CleverPush getChannelConfig:^(NSDictionary* channelConfig) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!locationManager) {
                        locationManager = [CLLocationManager new];
                    }
                    locationManager.delegate = (id)self;
                    
                    NSArray* geoFencesDict = [channelConfig cleverPushArrayForKey:@"geoFences"];
                    if (channelConfig != nil && geoFencesDict != nil && [geoFencesDict count] > 0) {
                        [geoFenceTimer invalidate];
                        geoFenceTimerDelay = 0;
                        geoFenceTimeoutCompleted = false;
                        [delayedGeoFences removeAllObjects];
                        delayedGeoFences = [[NSMutableArray alloc] init];
                        
                        for (NSDictionary *geoFence in geoFencesDict) {
                            if (geoFence != nil) {
                                CLLocationCoordinate2D center = CLLocationCoordinate2DMake([[geoFence objectForKey:@"latitude"] doubleValue], [[geoFence objectForKey:@"longitude"] doubleValue]);
                                CLRegion *region = [[CLCircularRegion alloc]initWithCenter:center
                                                                                    radius:[[geoFence objectForKey:@"radius"] longValue]
                                                                                identifier:[geoFence valueForKey:@"_id"]];
                                
                                if ([geoFence objectForKey:@"delay"]) {
                                    double delayValue = [[geoFence objectForKey:@"delay"]doubleValue];
                                    NSMutableDictionary* dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                    [NSNumber numberWithDouble:delayValue], @"delay",
                                                                    region, @"region",
                                                                    nil];
                                    [delayedGeoFences addObject:dataDic];
                                    [locationManager startMonitoringForRegion:region];
                                }
                            }
                        }
                    }
                    
                    NSArray* beaconsDict = [channelConfig cleverPushArrayForKey:@"beacons"];
                    beacons = [[NSMutableArray alloc] init];
                    if (@available(iOS 13.0, *)) {
                        if (channelConfig != nil && beaconsDict != nil && [beaconsDict count] > 0) {
                            for (NSDictionary *beacon in beaconsDict) {
                                if (beacon == nil) continue;

                                NSString *uuidString = [beacon objectForKey:@"uuid"];
                                NSString *beaconId   = [beacon valueForKey:@"_id"];
                                if (!uuidString || !beaconId) continue;

                                NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
                                if (!uuid) continue;

                                NSNumber *majorValue = [beacon objectForKey:@"major"];
                                NSNumber *minorValue = [beacon objectForKey:@"minor"];

                                CLBeaconRegion *region = nil;
                                if (majorValue && minorValue) {
                                    region = [[CLBeaconRegion alloc] initWithUUID:uuid major:[majorValue unsignedShortValue] minor:[minorValue unsignedShortValue] identifier:beaconId];
                                } else if (majorValue) {
                                    region = [[CLBeaconRegion alloc] initWithUUID:uuid major:[majorValue unsignedShortValue] identifier:beaconId];
                                } else {
                                    region = [[CLBeaconRegion alloc] initWithUUID:uuid identifier:beaconId];
                                }

                                if (region == nil) continue;

                                region.notifyOnEntry = YES;
                                region.notifyOnExit = YES;
                                region.notifyEntryStateOnDisplay = YES;

                                [beacons addObject:beacon];
                                [locationManager startMonitoringForRegion:region];
                                [CPLog info:@"CleverPushLocation: Started monitoring beacon %@ (UUID: %@)", beaconId, uuidString];
                            }
                        }
                    } else {
                        [CPLog info:@"CleverPushLocation: Beacon monitoring requires iOS 13.0 or later."];
                    }
                });
            }];
        }];
    });
}

#pragma mark - Check the authority of location permission
- (BOOL)hasLocationPermission {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    return status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse;
}

#pragma mark - Request to access location permission
+ (void)requestLocationPermission {
    if (!locationManager) {
        locationManager = [CLLocationManager new];
    }
    [locationManager requestAlwaysAuthorization];
}

+ (void)trackGeoFence:(NSString *)geoFenceId withState:(NSString *)state {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSMutableURLRequest* request = [[CleverPushHTTPClient sharedClient] requestWithMethod:@"POST" path:@"subscription/geo-fence"];
        NSDictionary* dataDic = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [CleverPush channelId], @"channelId",
                                 geoFenceId, @"geoFenceId",
                                 state, @"state",
                                 [CleverPush getSubscriptionId], @"subscriptionId",
                                 nil];
        
        NSData* postData = [NSJSONSerialization dataWithJSONObject:dataDic options:0 error:nil];
        [request setHTTPBody:postData];
        
        [CleverPush enqueueRequest:request onSuccess:^(NSDictionary* results) {
            if (delayedGeoFences.count == 0) {
                [geoFenceTimer invalidate];
                geoFenceTimerDelay = 0;
                geoFenceTimeoutCompleted = false;
            }
        } onFailure:nil];
    });
}

#pragma mark - Track beacon
+ (void)trackBeaconEvent:(NSDictionary *)beacon {
    NSString *eventName = [beacon objectForKey:@"eventName"];
    if (!eventName) {
        [CPLog error:@"CleverPushLocation: trackBeaconEvent: eventName is nil"];
        return;
    }
    [CPLog info:@"CleverPushLocation: trackBeaconEvent - eventName: %@", eventName];
    [CleverPush trackEvent:eventName];
}

#pragma mark - Beacon matching
+ (NSDictionary *)findMatchingBeaconForRegion:(CLBeaconRegion *)beaconRegion {
    if (beaconRegion == nil || beacons.count == 0) return nil;

    if (@available(iOS 13.0, *)) {
        NSString *detectedUUID = beaconRegion.UUID.UUIDString;
        [CPLog info:@"CleverPushLocation: findMatchingBeacon - detected uuid: %@, major: %@, minor: %@",
         detectedUUID, beaconRegion.major, beaconRegion.minor];

        for (NSDictionary *storedBeacon in beacons) {
            NSString *storedUUID  = [storedBeacon objectForKey:@"uuid"];
            NSNumber *storedMajor = [storedBeacon objectForKey:@"major"];
            NSNumber *storedMinor = [storedBeacon objectForKey:@"minor"];

            BOOL uuidMatch  = [storedUUID caseInsensitiveCompare:detectedUUID] == NSOrderedSame;
            BOOL majorMatch = storedMajor ? ([storedMajor unsignedShortValue] == [beaconRegion.major unsignedShortValue]) : YES;
            BOOL minorMatch = storedMinor ? ([storedMinor unsignedShortValue] == [beaconRegion.minor unsignedShortValue]) : YES;

            [CPLog info:@"CleverPushLocation: Comparing - storedUUID: %@, uuidMatch: %d, majorMatch: %d, minorMatch: %d",
             storedUUID, uuidMatch, majorMatch, minorMatch];

            if (uuidMatch && majorMatch && minorMatch) {
                [CPLog info:@"CleverPushLocation: Beacon matched - %@", [storedBeacon objectForKey:@"_id"]];
                return storedBeacon;
            }
        }

        [CPLog info:@"CleverPushLocation: No matching beacon found for uuid: %@", detectedUUID];
    }
    return nil;
}

#pragma mark - Location delegates
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [CPLog info:@"LocationManager: didChangeAuthorizationStatus %d", status];
}

+ (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    [CPLog info:@"LocationManager: didStartMonitoringForRegion %@", [region identifier]];
}

+ (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    [CPLog info:@"LocationManager: LocationManager didDetermineState %@", [region identifier]];
    if (state == CLRegionStateInside) {
        [self locationManager:manager didEnterRegion:region];
    }  else if (state == CLRegionStateOutside) {
        [self locationManager:manager didExitRegion:region];
    }
}

+ (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        if (@available(iOS 13.0, *)) {
            [CPLog info:@"LocationManager: Entered Beacon region - uuid: %@", beaconRegion.UUID.UUIDString];
            NSDictionary *matchedBeacon = [self findMatchingBeaconForRegion:beaconRegion];
            if (matchedBeacon) {
                [self trackBeaconEvent:matchedBeacon];
            }
        }
    } else {
        [CPLog info:@"LocationManager: Entered Geo Fence %@", [region identifier]];
        if (geoFenceTimeoutCompleted == false) {
            [geoFenceTimer invalidate];
            geoFenceTimerDelay = 0;
            geoFenceTimer = [NSTimer scheduledTimerWithTimeInterval:geoFenceTimerInterval
                                                             target:self
                                                           selector:@selector(geoFenceHandleTimer:)
                                                           userInfo:nil
                                                            repeats:YES];
        } else {
            [self trackGeoFence:[region identifier] withState:geoFenceEnterState];
        }
    }
}

+ (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
        if (@available(iOS 13.0, *)) {
            [CPLog info:@"LocationManager: Exited Beacon region - uuid: %@", beaconRegion.UUID.UUIDString];
            NSDictionary *matchedBeacon = [self findMatchingBeaconForRegion:beaconRegion];
            if (matchedBeacon) {
                [self trackBeaconEvent:matchedBeacon];
            }
        }
    } else {
        [CPLog info:@"LocationManager: Exited Geo Fence %@", [region identifier]];
        if (geoFenceTimeoutCompleted == false) {
            [geoFenceTimer invalidate];
            geoFenceTimerDelay = 0;
            geoFenceTimer = [NSTimer scheduledTimerWithTimeInterval:geoFenceTimerInterval
                                                             target:self
                                                           selector:@selector(geoFenceHandleTimer:)
                                                           userInfo:nil
                                                            repeats:YES];
        } else {
            [self trackGeoFence:[region identifier] withState:geoFenceExitState];
        }
    }
}

+ (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    [CPLog error:@"LocationManager: monitoringDidFailForRegion %@ error: %@", [region identifier], error.localizedDescription];
}

+ (void)geoFenceHandleTimer:(NSTimer *)timer {
    for (NSMutableDictionary *geoFence in delayedGeoFences) {
        if ([geoFence objectForKey:@"delay"] != nil) {
            double delayValue = [[geoFence objectForKey:@"delay"] doubleValue];
            CLRegion *regionValue = [geoFence objectForKey:@"region"];
            if (geoFenceTimerDelay >= delayValue) {
                geoFenceTimeoutCompleted = true;
                [delayedGeoFences removeObject:geoFence];
                [locationManager startMonitoringForRegion:regionValue];
                break;
            }
        }
    }
    geoFenceTimerDelay += 1;
}

@end
