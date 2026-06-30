#import "CleverPushLocation.h"
#import "CleverPush.h"
#import "CleverPushHTTPClient.h"
#import "NSDictionary+SafeExpectations.h"
#import "CPLog.h"

@implementation CleverPushLocation

CLLocationManager* locationManager;
NSTimer *geoFenceTimer;
double geoFenceTimerDelay;
NSMutableArray *delayedGeoFences;
NSMutableArray *beacons;
NSString* geoFenceEnterState = @"enter";
NSString* geoFenceExitState = @"exit";
double geoFenceTimerInterval = 1.0;

static NSMutableDictionary *beaconLastFiredDate = nil;
static CPBeaconDetectedHandler beaconDetectedHandler = nil;
static NSTimeInterval beaconEventIntervalSec = 0;
static BOOL beaconDebugScanAll = NO;
static NSMutableSet *cleverPushGeoFenceIdentifiers = nil;
static NSMutableSet *cleverPushBeaconIdentifiers = nil;

#pragma mark - Geo-fence monitoring

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
                    
                    if (!cleverPushGeoFenceIdentifiers) {
                        cleverPushGeoFenceIdentifiers = [[NSMutableSet alloc] init];
                    }
                    NSArray *staleGeoFenceRegions = [locationManager.monitoredRegions.allObjects filteredArrayUsingPredicate:
                        [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *b) {
                            return [obj isKindOfClass:[CLCircularRegion class]]
                                && [cleverPushGeoFenceIdentifiers containsObject:[(CLRegion *)obj identifier]];
                        }]];
                    for (CLRegion *monitoredRegion in staleGeoFenceRegions) {
                        [locationManager stopMonitoringForRegion:monitoredRegion];
                        [CPLog info:@"CleverPushLocation: Stopped stale geo-fence region %@", monitoredRegion.identifier];
                    }
                    [cleverPushGeoFenceIdentifiers removeAllObjects];

                    [geoFenceTimer invalidate];
                    geoFenceTimerDelay = 0;
                    [delayedGeoFences removeAllObjects];
                    delayedGeoFences = [[NSMutableArray alloc] init];

                    NSArray* geoFencesDict = [channelConfig cleverPushArrayForKey:@"geoFences"];
                    if (channelConfig != nil && geoFencesDict != nil && [geoFencesDict count] > 0) {
                        for (NSDictionary *geoFence in geoFencesDict) {
                            if (geoFence != nil) {
                                NSString *geoFenceId = [geoFence valueForKey:@"_id"];
                                CLLocationCoordinate2D center = CLLocationCoordinate2DMake([[geoFence objectForKey:@"latitude"] doubleValue], [[geoFence objectForKey:@"longitude"] doubleValue]);
                                CLRegion *region = [[CLCircularRegion alloc]initWithCenter:center
                                                                                    radius:[[geoFence objectForKey:@"radius"] longValue]
                                                                                identifier:geoFenceId];
                                
                                if ([geoFence objectForKey:@"delay"]) {
                                    double delayValue = [[geoFence objectForKey:@"delay"]doubleValue];
                                    NSMutableDictionary* dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                    [NSNumber numberWithDouble:delayValue], @"delay",
                                                                    region, @"region",
                                                                    nil];
                                    [delayedGeoFences addObject:dataDic];
                                }
                                [cleverPushGeoFenceIdentifiers addObject:geoFenceId];
                                [locationManager startMonitoringForRegion:region];
                            }
                        }
                    }
                });
            }];
        }];
    });
}

#pragma mark - Beacon monitoring

+ (void)initBeacons {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        [CleverPush getSubscriptionId:^(NSString* subscriptionId) {
            if (subscriptionId == nil) {
                [CPLog debug:@"CleverPushLocation: initBeacons: There is no subscription for CleverPush SDK."];
            }
            [CleverPush getChannelConfig:^(NSDictionary* channelConfig) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!locationManager) {
                        locationManager = [CLLocationManager new];
                    }
                    locationManager.delegate = (id)self;

                    if (!cleverPushBeaconIdentifiers) {
                        cleverPushBeaconIdentifiers = [[NSMutableSet alloc] init];
                    }
                    NSArray *staleBeaconRegions = [locationManager.monitoredRegions.allObjects filteredArrayUsingPredicate:
                        [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *b) {
                            return [obj isKindOfClass:[CLBeaconRegion class]]
                                && [cleverPushBeaconIdentifiers containsObject:[(CLRegion *)obj identifier]];
                        }]];
                    for (CLRegion *monitoredRegion in staleBeaconRegions) {
                        [locationManager stopMonitoringForRegion:monitoredRegion];
                        [CPLog info:@"CleverPushLocation: Stopped stale beacon region %@", monitoredRegion.identifier];
                    }
                    [cleverPushBeaconIdentifiers removeAllObjects];

                    beacons = [[NSMutableArray alloc] init];
                    beaconLastFiredDate = [[NSMutableDictionary alloc] init];

                    NSArray* beaconsDict = [channelConfig cleverPushArrayForKey:@"beacons"];
                    if (@available(iOS 13.0, *)) {
                        if (channelConfig != nil && beaconsDict != nil && [beaconsDict count] > 0) {
                            for (NSDictionary *beacon in beaconsDict) {
                                if (beacon == nil) continue;

                                NSString *uuidString = [beacon objectForKey:@"uuid"];
                                NSString *beaconId   = [beacon valueForKey:@"_id"];
                                if (!uuidString || !beaconId) continue;

                                NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
                                if (!uuid) continue;

                                id rawMajor = [beacon objectForKey:@"major"];
                                id rawMinor = [beacon objectForKey:@"minor"];
                                NSNumber *majorValue = [rawMajor isKindOfClass:[NSNumber class]] ? rawMajor : nil;
                                NSNumber *minorValue = [rawMinor isKindOfClass:[NSNumber class]] ? rawMinor : nil;

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
                                region.notifyOnExit = NO;
                                region.notifyEntryStateOnDisplay = NO;

                                [beacons addObject:beacon];
                                [cleverPushBeaconIdentifiers addObject:beaconId];
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

#pragma mark - Beacon configuration

+ (void)onBeaconDetected:(CPBeaconDetectedHandler)handler {
    beaconDetectedHandler = handler ? [handler copy] : nil;
    [CPLog info:@"CleverPushLocation: onBeaconDetected handler %@", handler ? @"registered" : @"cleared"];
}

+ (void)setBeaconEventInterval:(NSInteger)minutes {
    beaconEventIntervalSec = (minutes > 0) ? (minutes * 60.0) : 0;
    [CPLog info:@"CleverPushLocation: beaconEventInterval set to %ld min(s)", (long)minutes];
}

+ (void)setBeaconDebugScanAll:(BOOL)enabled {
    beaconDebugScanAll = enabled;
    [CPLog info:@"CleverPushLocation: beaconDebugScanAll = %@", enabled ? @"YES" : @"NO"];
}

#pragma mark - Location permission

+ (BOOL)hasLocationPermission {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    return status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse;
}

+ (void)requestLocationPermission {
    if (!locationManager) {
        locationManager = [CLLocationManager new];
    }
    [locationManager requestAlwaysAuthorization];
}

#pragma mark - Track geo-fence

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
            }
        } onFailure:nil];
    });
}

#pragma mark - Track beacon

+ (void)trackBeaconEvent:(NSDictionary *)beacon {
    NSString *eventName = [beacon objectForKey:@"eventName"];
    NSString *beaconId = [beacon valueForKey:@"_id"];

    if (!eventName) {
        [CPLog error:@"CleverPushLocation: trackBeaconEvent: eventName is nil for beacon %@", beaconId];
        return;
    }

    if (!beaconDebugScanAll && beaconEventIntervalSec > 0 && beaconId) {
        if (!beaconLastFiredDate) {
            beaconLastFiredDate = [[NSMutableDictionary alloc] init];
        }
        NSDate *lastFired = beaconLastFiredDate[beaconId];
        if (lastFired) {
            NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:lastFired];
            if (elapsed < beaconEventIntervalSec) {
                [CPLog info:@"CleverPushLocation: Beacon %@ skipped - interval active (%.0fs remaining)",
                 beaconId, beaconEventIntervalSec - elapsed];
                return;
            }
        }
        beaconLastFiredDate[beaconId] = [NSDate date];
    }

    [CPLog info:@"CleverPushLocation: trackBeaconEvent - beaconId: %@, eventName: %@", beaconId, eventName];
    [CleverPush trackEvent:eventName];

    CPBeaconDetectedHandler handler = beaconDetectedHandler;
    if (handler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(beacon);
        });
    }
}

#pragma mark - Beacon matching

+ (NSDictionary *)findMatchingBeaconForRegion:(CLBeaconRegion *)beaconRegion {
    if (beaconRegion == nil || beacons.count == 0) return nil;

    NSString *regionIdentifier = beaconRegion.identifier;
    [CPLog info:@"CleverPushLocation: findMatchingBeacon - identifier: %@", regionIdentifier];

    for (NSDictionary *storedBeacon in beacons) {
        NSString *beaconId = [storedBeacon valueForKey:@"_id"];
        if ([beaconId isEqualToString:regionIdentifier]) {
            [CPLog info:@"CleverPushLocation: Beacon matched - %@", beaconId];
            return storedBeacon;
        }
    }

    if (beaconDebugScanAll) {
        [CPLog info:@"[BeaconDebug] No config match for identifier: %@", regionIdentifier];
    }
    return nil;
}

+ (BOOL)geoFenceRegionHasDelay:(CLRegion *)region {
    for (NSDictionary *geoFence in delayedGeoFences) {
        CLRegion *r = [geoFence objectForKey:@"region"];
        if ([[r identifier] isEqualToString:[region identifier]]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Location delegates

+ (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    [CPLog info:@"LocationManager: didStartMonitoringForRegion %@", [region identifier]];
}

+ (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
    NSString *stateStr = (state == CLRegionStateInside) ? @"Inside" : (state == CLRegionStateOutside) ? @"Outside" : @"Unknown";

    if (beaconDebugScanAll && [region isKindOfClass:[CLBeaconRegion class]]) {
        if (@available(iOS 13.0, *)) {
            CLBeaconRegion *br = (CLBeaconRegion *)region;
            [CPLog info:@"[BeaconDebug] didDetermineState - identifier: %@, state: %@, uuid: %@, major: %@, minor: %@",
             br.identifier, stateStr, br.UUID.UUIDString, br.major ?: @"-", br.minor ?: @"-"];
        }
    } else {
        [CPLog info:@"LocationManager: didDetermineState %@ - %@", [region identifier], stateStr];
    }

    if (state == CLRegionStateInside && ![region isKindOfClass:[CLBeaconRegion class]]) {
        [self locationManager:manager didEnterRegion:region];
    } else if (state == CLRegionStateOutside && ![region isKindOfClass:[CLBeaconRegion class]]) {
        [self locationManager:manager didExitRegion:region];
    }
}

+ (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        if (@available(iOS 13.0, *)) {
            CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
            if (beaconDebugScanAll) {
                [CPLog info:@"[BeaconDebug] didEnterRegion - identifier: %@, uuid: %@, major: %@, minor: %@",
                 beaconRegion.identifier, beaconRegion.UUID.UUIDString,
                 beaconRegion.major ?: @"-", beaconRegion.minor ?: @"-"];
            } else {
                [CPLog info:@"LocationManager: Entered Beacon region - identifier: %@, uuid: %@",
                 beaconRegion.identifier, beaconRegion.UUID.UUIDString];
            }
            NSDictionary *matchedBeacon = [self findMatchingBeaconForRegion:beaconRegion];
            if (matchedBeacon) {
                [self trackBeaconEvent:matchedBeacon];
            }
        }
    } else {
        [CPLog info:@"LocationManager: Entered Geo Fence %@", [region identifier]];
        if ([self geoFenceRegionHasDelay:region]) {
            for (NSMutableDictionary *gf in delayedGeoFences) {
                if ([[[gf objectForKey:@"region"] identifier] isEqualToString:[region identifier]]) {
                    [gf setObject:geoFenceEnterState forKey:@"pendingState"];
                    break;
                }
            }
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
        if (@available(iOS 13.0, *)) {
            CLBeaconRegion *beaconRegion = (CLBeaconRegion *)region;
            if (beaconDebugScanAll) {
                [CPLog info:@"[BeaconDebug] didExitRegion - identifier: %@, uuid: %@, major: %@, minor: %@",
                 beaconRegion.identifier, beaconRegion.UUID.UUIDString,
                 beaconRegion.major ?: @"-", beaconRegion.minor ?: @"-"];
            } else {
                [CPLog info:@"LocationManager: Exited Beacon region - identifier: %@, uuid: %@",
                 beaconRegion.identifier, beaconRegion.UUID.UUIDString];
            }
        }
    } else {
        [CPLog info:@"LocationManager: Exited Geo Fence %@", [region identifier]];
        if ([self geoFenceRegionHasDelay:region]) {
            for (NSMutableDictionary *gf in delayedGeoFences) {
                if ([[[gf objectForKey:@"region"] identifier] isEqualToString:[region identifier]]) {
                    [gf setObject:geoFenceExitState forKey:@"pendingState"];
                    break;
                }
            }
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
    NSMutableDictionary *expiredGeoFence = nil;
    CLRegion *expiredRegion = nil;
    NSString *pendingState = nil;
    for (NSMutableDictionary *geoFence in delayedGeoFences) {
        if ([geoFence objectForKey:@"delay"] != nil) {
            double delayValue = [[geoFence objectForKey:@"delay"] doubleValue];
            if (geoFenceTimerDelay >= delayValue) {
                expiredGeoFence = geoFence;
                expiredRegion = [geoFence objectForKey:@"region"];
                pendingState = [geoFence objectForKey:@"pendingState"];
                break;
            }
        }
    }
    if (expiredGeoFence) {
        [delayedGeoFences removeObject:expiredGeoFence];
        if (pendingState) {
            [self trackGeoFence:[expiredRegion identifier] withState:pendingState];
        } else {
            [CPLog error:@"CleverPushLocation: geoFenceHandleTimer - no pendingState recorded for %@", [expiredRegion identifier]];
        }
    }
    geoFenceTimerDelay += 1;
}

@end
