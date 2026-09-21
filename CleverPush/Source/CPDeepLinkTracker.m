#import "CPDeepLinkTracker.h"
#import "CPDeepLinkAllowlist.h"
#import "CleverPushUserDefaults.h"
#import "CPUtils.h"
#import "CPLog.h"

static NSString * const kCPDeepLinkDateTimeFormat = @"yyyy-MM-dd HH:mm:ss";
static const NSTimeInterval kCPDeepLinkAttributionWindowSeconds = 24.0 * 60.0 * 60.0;

static NSString *lastProcessedURL;
static NSObject *processLock;

@implementation CPDeepLinkTracker

+ (void)initialize {
    if (self == [CPDeepLinkTracker class]) {
        processLock = [NSObject new];
    }
}

+ (NSDateFormatter *)deepLinkDateFormatter {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.timeZone = [NSTimeZone localTimeZone];
        formatter.dateFormat = kCPDeepLinkDateTimeFormat;
    });
    return formatter;
}

+ (void)captureFromURL:(NSURL *)url requireAllowlist:(BOOL)requireAllowlist {
    [self captureFromURLString:url.absoluteString requireAllowlist:requireAllowlist];
}

+ (void)captureFromURLString:(NSString *)urlString requireAllowlist:(BOOL)requireAllowlist {
    NSString *normalized = [self normalizeDeepLinkURLString:urlString];
    if (normalized == nil) {
        return;
    }
    if (requireAllowlist && ![CPDeepLinkAllowlist allowsURLString:normalized]) {
        return;
    }

    @synchronized (processLock) {
        if ([normalized isEqualToString:lastProcessedURL]) {
            return;
        }
        lastProcessedURL = normalized;
    }

    [self storeNormalizedDeepLinkURLString:normalized];
}

+ (void)captureFromUserActivity:(NSUserActivity *)userActivity {
    if (userActivity == nil) {
        return;
    }
    if (![userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        return;
    }
    [self captureFromURL:userActivity.webpageURL requireAllowlist:YES];
}

+ (void)captureFromLaunchOptions:(NSDictionary *)launchOptions {
    if (launchOptions.count == 0) {
        return;
    }

    NSURL *url = launchOptions[UIApplicationLaunchOptionsURLKey];
    if ([url isKindOfClass:[NSURL class]]) {
        [self captureFromURL:url requireAllowlist:YES];
    }

    NSDictionary *userActivityDict = launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey];
    if ([userActivityDict isKindOfClass:[NSDictionary class]]) {
        NSUserActivity *userActivity = userActivityDict[@"UIApplicationLaunchOptionsUserActivityKey"];
        if ([userActivity isKindOfClass:[NSUserActivity class]]) {
            [self captureFromUserActivity:userActivity];
        } else {
            NSURL *webpageURL = userActivityDict[@"UIApplicationLaunchOptionsUserActivityKey"];
            if ([webpageURL isKindOfClass:[NSURL class]]) {
                [self captureFromURL:webpageURL requireAllowlist:YES];
            }
        }
    }
}

+ (void)captureFromConnectionOptions:(UISceneConnectionOptions *)connectionOptions API_AVAILABLE(ios(13.0)) {
    if (connectionOptions == nil) {
        return;
    }
    [self captureFromOpenURLContexts:connectionOptions.URLContexts];
    for (NSUserActivity *userActivity in connectionOptions.userActivities) {
        [self captureFromUserActivity:userActivity];
    }
}

+ (void)captureFromOpenURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts API_AVAILABLE(ios(13.0)) {
    if (URLContexts.count == 0) {
        return;
    }
    for (UIOpenURLContext *context in URLContexts) {
        [self captureFromURL:context.URL requireAllowlist:YES];
    }
}

+ (void)storeDeepLinkURLString:(NSString *)urlString {
    NSString *normalized = [self normalizeDeepLinkURLString:urlString];
    if (normalized == nil) {
        return;
    }
    @synchronized (processLock) {
        lastProcessedURL = normalized;
    }
    [self storeNormalizedDeepLinkURLString:normalized];
}

+ (void)storeNormalizedDeepLinkURLString:(NSString *)normalizedUrl {
    @try {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *timeString = [[self deepLinkDateFormatter] stringFromDate:[NSDate date]];
        if (timeString.length == 0) {
            timeString = [CPUtils getCurrentTimestampWithFormat:kCPDeepLinkDateTimeFormat];
        }
        [userDefaults setObject:normalizedUrl forKey:CLEVERPUSH_LAST_DEEP_LINK_URL_KEY];
        [userDefaults setObject:timeString forKey:CLEVERPUSH_LAST_DEEP_LINK_TIME_KEY];
        [userDefaults removeObjectForKey:CLEVERPUSH_LAST_DEEPLINK_ID_KEY_LEGACY];
        [userDefaults removeObjectForKey:CLEVERPUSH_LAST_DEEPLINK_TIME_KEY_LEGACY];
        [userDefaults synchronize];
        [CPLog debug:@"DeepLinkTracker: stored deep link %@", normalizedUrl];
    } @catch (NSException *exception) {
        [CPLog error:@"DeepLinkTracker: failed to store deep link %@", exception];
    }
}

+ (void)addAttributionToEventData:(NSMutableDictionary *)dataDic {
    if (dataDic == nil) {
        return;
    }
    @try {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *lastDeepLinkUrl = [userDefaults stringForKey:CLEVERPUSH_LAST_DEEP_LINK_URL_KEY];
        NSString *lastDeepLinkTime = [userDefaults stringForKey:CLEVERPUSH_LAST_DEEP_LINK_TIME_KEY];

        // Migrate one-time from intermediate iOS feature-branch keys.
        if ([CPUtils isNullOrEmpty:lastDeepLinkUrl]) {
            lastDeepLinkUrl = [userDefaults stringForKey:CLEVERPUSH_LAST_DEEPLINK_ID_KEY_LEGACY];
            id legacyTime = [userDefaults objectForKey:CLEVERPUSH_LAST_DEEPLINK_TIME_KEY_LEGACY];
            if ([legacyTime isKindOfClass:[NSDate class]]) {
                lastDeepLinkTime = [[self deepLinkDateFormatter] stringFromDate:(NSDate *)legacyTime];
            } else if ([legacyTime isKindOfClass:[NSString class]]) {
                lastDeepLinkTime = (NSString *)legacyTime;
            }
            if (![CPUtils isNullOrEmpty:lastDeepLinkUrl] && lastDeepLinkTime.length > 0) {
                [userDefaults setObject:lastDeepLinkUrl forKey:CLEVERPUSH_LAST_DEEP_LINK_URL_KEY];
                [userDefaults setObject:lastDeepLinkTime forKey:CLEVERPUSH_LAST_DEEP_LINK_TIME_KEY];
                [userDefaults removeObjectForKey:CLEVERPUSH_LAST_DEEPLINK_ID_KEY_LEGACY];
                [userDefaults removeObjectForKey:CLEVERPUSH_LAST_DEEPLINK_TIME_KEY_LEGACY];
                [userDefaults synchronize];
            }
        }

        if (![CPUtils isNullOrEmpty:lastDeepLinkUrl] && [self isWithinAttributionWindowForTimeString:lastDeepLinkTime]) {
            [dataDic setObject:lastDeepLinkUrl forKey:@"deeplinkId"];
        }
    } @catch (NSException *exception) {
        [CPLog error:@"DeepLinkTracker: failed to add deep link attribution %@", exception];
    }
}

+ (NSString *)normalizeDeepLinkURLString:(NSString *)urlString {
    if (urlString.length == 0) {
        return nil;
    }
    NSString *trimmed = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![self isTrackableDeepLinkURLString:trimmed]) {
        return nil;
    }
    return trimmed;
}

+ (BOOL)isTrackableDeepLinkURLString:(NSString *)urlString {
    if (urlString.length == 0) {
        return NO;
    }
    NSString *trimmed = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSURL *url = [NSURL URLWithString:trimmed];
    if (!url || url.scheme.length == 0) {
        return NO;
    }

    NSString *scheme = [url.scheme lowercaseString];
    NSSet *blockedSchemes = [NSSet setWithArray:@[
        @"javascript", @"file", @"content", @"data", @"about", @"mailto", @"tel", @"sms"
    ]];
    if ([blockedSchemes containsObject:scheme]) {
        return NO;
    }

    if ([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"]) {
        return url.host.length > 0;
    }

    // Match Android: scheme-specific part must be non-empty for custom schemes.
    NSString *schemeSpecificPart = url.resourceSpecifier;
    return schemeSpecificPart.length > 0;
}

+ (BOOL)isWithinAttributionWindowForTimeString:(NSString *)lastDeepLinkTime {
    if (lastDeepLinkTime.length == 0) {
        return NO;
    }
    @try {
        NSDate *lastOpenedTime = [[self deepLinkDateFormatter] dateFromString:lastDeepLinkTime];
        if (lastOpenedTime == nil) {
            return NO;
        }
        NSTimeInterval seconds = fabs([[NSDate date] timeIntervalSinceDate:lastOpenedTime]);
        return seconds < kCPDeepLinkAttributionWindowSeconds;
    } @catch (NSException *exception) {
        [CPLog error:@"DeepLinkTracker: error parsing deep link time %@", exception];
        return NO;
    }
}

@end
