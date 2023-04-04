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
NSString* geoFenceEnterState = @"enter";
NSString* geoFenceExitState = @"exit";
double geoFenceTimerInterval = 1.0;

+ (void)init {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        [CleverPush getSubscriptionId:^(NSString* subscriptionId) {
            [CleverPush getChannelConfig:^(NSDictionary* channelConfig) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (channelConfig != nil && [channelConfig cleverPushArrayForKey:@"geoFences"] != nil) {
                        if (!locationManager) {
                            locationManager = [CLLocationManager new];
                        }
                        locationManager.delegate = (id)self;
                        [geoFenceTimer invalidate];
                        geoFenceTimerDelay = 0;
                        geoFenceTimeoutCompleted = false;
                        [delayedGeoFences removeAllObjects];
                        delayedGeoFences = [[NSMutableArray alloc] init];
                        
                        NSArray* geoFencesDict = [channelConfig cleverPushArrayForKey:@"geoFences"];
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

#pragma mark - Location delegates
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [CPLog info:@"LocationManager: didChangeAuthorizationStatus %@", status];
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
    [CPLog info:@"LocationManager: Entered Geo Fence %@", [region identifier]];
    if (geoFenceTimeoutCompleted  == false) {
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

+ (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
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
