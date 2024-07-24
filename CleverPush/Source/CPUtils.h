#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SafariServices/SafariServices.h>
#import "CleverPush.h"

@interface CPUtils : NSObject

#define HTTP_GET @"GET"
#define HTTP_POST @"POST"

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
+ (UIColor *)readableForegroundColorForBackgroundColor:(UIColor*)backgroundColor;
+ (NSString *)replaceString:(NSString *)originalString withReplacement:(NSString *)replacement inString:(NSString *)inputString;
+ (NSString *)getCurrentTimestampWithFormat:(NSString *)dateFormat;
+ (NSString *)cleverPushJavaScript;
+ (NSString *)generateBannerHTMLStringWithFunctions:(NSString *)content;
+ (NSArray<NSString *> *)scriptMessageNames;
+ (void)configureWebView:(WKWebView *)webView;
+ (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;
+ (void)handleSubscribeActionWithCallback:(void (^)(BOOL))callback;
+ (BOOL)isNullOrEmpty:(NSString *)string;
+ (NSURL*)replaceAndEncodeURL:(NSURL *)url withReplacement:(NSString *)replacement;
+ (NSString *)valueForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary;
+ (void)tryOpenURL:(NSURL *)url;
+ (BOOL)isValidURL:(NSURL *)url;
+ (NSURL *)removeQueryParametersFromURL:(NSURL *)url;
+ (NSDictionary *)convertConnectionOptionsToLaunchOptions:(UISceneConnectionOptions* )connectionOptions  API_AVAILABLE(ios(13.0));
+ (UIImage *)resizedImageNamed:(NSString *)imageName withSize:(CGSize)newSize;

@end
