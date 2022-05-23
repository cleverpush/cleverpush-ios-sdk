#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SafariServices/SafariServices.h>
#import "CleverPush.h"

@interface CPUtils : NSObject

#pragma mark - Utilities singleton functions
+ (NSString*)downloadMedia:(NSString*)urlString;
+ (NSDictionary *)dictionaryWithPropertiesOfObject:(id)obj;
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;
+ (void)updateLastTopicCheckedTime;
+ (NSDate*)getLastTopicCheckedTime;
+ (NSString *)hexStringFromColor:(UIColor *)color;
+ (BOOL)fontFamilyExists:(NSString*)fontFamily;
+ (BOOL)isEmpty:(id)thing;
+ (void)openSafari:(NSURL*)URL;
+ (CGFloat)frameHeightWithoutSafeArea;
+ (void)openSafari:(NSURL*)URL dismissViewController:(UIViewController*)controller;
+ (NSString*)deviceName;
+ (void)updateLastTimeAutomaticallyShowed;
+ (NSDate*)getLastTimeAutomaticallyShowed;
+ (BOOL)newTopicAdded:(NSDictionary*)config;
+ (NSDate*)getLocalDateTimeFromUTC:(NSString*)dateString;
+ (NSString*)getCurrentDateString;
+ (NSInteger)secondsBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;
+ (NSBundle *)getAssetsBundle;
+ (NSString *)timeAgoStringFromDate:(NSDate *)date;
+ (NSUserDefaults *)getUserDefaultsAppGroup;

@end
