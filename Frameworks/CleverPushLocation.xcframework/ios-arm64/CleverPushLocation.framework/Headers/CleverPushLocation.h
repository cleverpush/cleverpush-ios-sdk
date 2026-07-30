#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef void(^CPBeaconDetectedHandler)(NSDictionary *beacon);

@interface CleverPushLocation : NSObject <CLLocationManagerDelegate>

+ (void)init;
+ (void)initBeacons;
+ (void)onBeaconDetected:(CPBeaconDetectedHandler)handler;
+ (void)setBeaconEventInterval:(NSInteger)minutes;
+ (void)setBeaconDebugScanAll:(BOOL)enabled;
+ (void)requestLocationPermission;
+ (BOOL)hasLocationPermission;
+ (void)trackBeaconEvent:(NSDictionary *)beacon;

@end
