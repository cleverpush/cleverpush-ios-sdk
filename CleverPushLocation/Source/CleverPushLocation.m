#import "CleverPushLocation.h"
#import "CleverPush.h"
#import "CleverPushHTTPClient.h"
#import "NSDictionary+SafeExpectations.h"
#import "CPLog.h"

@implementation CleverPushLocation

CLLocationManager* locationManager;
NSTimer *geoFencetimer;
double geoFencetimerValue;
bool isCompletedGeoFence;
NSMutableArray *geoFenceArray;

+ (void)init {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        [CleverPush getSubscriptionId:^(NSString* subscriptionId) {
            [CleverPush getChannelConfig:^(NSDictionary* channelConfig) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (channelConfig != nil && [channelConfig arrayForKey:@"geoFences"] != nil) {
                        if (!locationManager) {
                            locationManager = [CLLocationManager new];
                        }
                        locationManager.delegate = (id)self;
                        [geoFencetimer invalidate];
                        geoFencetimerValue = 0;
                        isCompletedGeoFence = false;
                        [geoFenceArray removeAllObjects];
                        geoFenceArray = [[NSMutableArray alloc] initWithCapacity:0];
                        
                        NSArray* geoFencesDict = [channelConfig arrayForKey:@"geoFences"];
                        for (NSDictionary *geoFence in geoFencesDict) {
                            if (geoFence != nil) {
                                CLLocationCoordinate2D center = CLLocationCoordinate2DMake([[geoFence objectForKey:@"latitude"] doubleValue], [[geoFence objectForKey:@"longitude"] doubleValue]);
                                CLRegion *region = [[CLCircularRegion alloc]initWithCenter:center
                                                                                    radius:[[geoFence objectForKey:@"radius"] longValue]
                                                                                identifier:[geoFence valueForKey:@"_id"]];
                                double num = [[geoFence objectForKey:@"delay"]doubleValue];
                                NSMutableDictionary* dataDic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                [NSNumber numberWithDouble:num], @"delay",
                                                                region, @"region",
                                                                nil];
                                [geoFenceArray addObject:dataDic];
                                [locationManager startMonitoringForRegion:region];
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
            isCompletedGeoFence = false;
            if (geoFenceArray.count == 0) {
                [geoFencetimer invalidate];
                geoFencetimerValue = 0;
                isCompletedGeoFence = false;
                [geoFenceArray removeAllObjects];
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
    if (isCompletedGeoFence  == false) {
        [geoFencetimer invalidate];
        geoFencetimerValue = 0;
        geoFencetimer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                         target:self
                                                       selector:@selector(geoFenceHandleTimer:)
                                                       userInfo:nil
                                                        repeats:YES];
    } else {
        [self trackGeoFence:[region identifier] withState:@"enter"];
    }
}

+ (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [CPLog info:@"LocationManager: Exited Geo Fence %@", [region identifier]];
    if (isCompletedGeoFence == false) {
        [geoFencetimer invalidate];
        geoFencetimerValue = 0;
        geoFencetimer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                                         target:self
                                                       selector:@selector(geoFenceHandleTimer:)
                                                       userInfo:nil
                                                        repeats:YES];
    } else {
        [self trackGeoFence:[region identifier] withState:@"exit"];
    }
}

+ (void)geoFenceHandleTimer: (NSTimer *) Timer {
    for (NSMutableDictionary *geoFence in geoFenceArray) {
        double xD = [[geoFence objectForKey:@"delay"] doubleValue];
        CLRegion *region1 = [geoFence objectForKey:@"region"];
        if (geoFencetimerValue == xD) {
            isCompletedGeoFence = true;
            [geoFenceArray removeObject:geoFence];
            [locationManager startMonitoringForRegion:region1];
            break;
        }
    }
    geoFencetimerValue += 1;
}

@end
