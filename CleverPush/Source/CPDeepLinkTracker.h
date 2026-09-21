#ifndef CPDeepLinkTracker_h
#define CPDeepLinkTracker_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPDeepLinkTracker : NSObject

+ (void)captureFromURL:(NSURL * _Nullable)url requireAllowlist:(BOOL)requireAllowlist;
+ (void)captureFromURLString:(NSString * _Nullable)urlString requireAllowlist:(BOOL)requireAllowlist;
+ (void)captureFromUserActivity:(NSUserActivity * _Nullable)userActivity;
+ (void)captureFromLaunchOptions:(NSDictionary * _Nullable)launchOptions;
+ (void)captureFromConnectionOptions:(UISceneConnectionOptions * _Nullable)connectionOptions API_AVAILABLE(ios(13.0));
+ (void)captureFromOpenURLContexts:(NSSet<UIOpenURLContext *> * _Nullable)URLContexts API_AVAILABLE(ios(13.0));
+ (void)storeDeepLinkURLString:(NSString * _Nullable)urlString;
+ (void)addAttributionToEventData:(NSMutableDictionary *)dataDic;
+ (BOOL)isTrackableDeepLinkURLString:(NSString * _Nullable)urlString;
+ (NSString * _Nullable)normalizeDeepLinkURLString:(NSString * _Nullable)urlString;
+ (BOOL)isWithinAttributionWindowForTimeString:(NSString * _Nullable)lastDeepLinkTime;

@end

NS_ASSUME_NONNULL_END

#endif
