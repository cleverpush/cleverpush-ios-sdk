#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import "CPUtils.h"
#import "NSDictionary+SafeExpectations.h"

static BOOL existanceOfNewTopic = NO;
static BOOL topicsDialogShowWhenNewAdded = NO;
NSString * const dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
NSString * const localeIdentifier = @"en_US_POSIX";

#pragma mark - Custom delegate of download
@interface DirectDownloadDelegate : NSObject <NSURLSessionDataDelegate> {
    NSError* error;
    NSURLResponse* response;
    BOOL done;
    NSFileHandle* outputHandle;
}

@property (readonly, getter=isDone) BOOL done;
@property (readonly) NSError* error;
@property (readonly) NSURLResponse* response;

@end

@implementation DirectDownloadDelegate
@synthesize error, response, done;

#pragma mark - Recieve data and write
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [outputHandle writeData:data];
}

#pragma mark - Recieve data task and response
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)aResponse completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    response = aResponse;
    long long expectedLength = response.expectedContentLength;
    if (expectedLength > 50000000) {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    completionHandler(NSURLSessionResponseAllow);
}

#pragma mark - error call back
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)anError {
    error = anError;
    done = YES;
    
    [outputHandle closeFile];
}

#pragma mark - completion call back
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)anError {
    done = YES;
    error = anError;
    [outputHandle closeFile];
}

#pragma mark - Initialised file path
- (id)initWithFilePath:(NSString*)path {
    if (self = [super init]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        outputHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    return self;
}
@end

#pragma mark - custom delegate of direct download from URL and write to local file
@interface NSURLSession (DirectDownload)
+ (NSString *)downloadItemAtURL:(NSURL *)url toFile:(NSString *)localPath error:(NSError **)error;
@end


@implementation NSURLSession (DirectDownload)

+ (NSString *)downloadItemAtURL:(NSURL *)url toFile:(NSString *)localPath error:(NSError **)error {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    DirectDownloadDelegate *delegate = [[DirectDownloadDelegate alloc] initWithFilePath:localPath];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:delegate delegateQueue:nil];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    
    [task resume];
    
    [session finishTasksAndInvalidate];
    
    while (![delegate isDone]) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    }
    
    NSError *downloadError = [delegate error];
    if (downloadError != nil) {
        if (error)
            *error = downloadError;
        return nil;
    }
    
    return delegate.response.MIMEType;
}

@end

@implementation CPUtils
#pragma mark - Generate random string for uniquing
+ (NSString*)randomStringWithLength:(int)length {
    NSString* letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString* randomString = [[NSMutableString alloc] initWithCapacity:length];
    for (int i = 0; i < length; i++) {
        int ln = (uint32_t)letters.length;
        int rand = arc4random_uniform(ln);
        [randomString appendFormat:@"%C", [letters characterAtIndex:rand]];
    }
    return randomString;
}

#pragma mark - dictionary with properties of object.
+ (NSDictionary *)dictionaryWithPropertiesOfObject:(id)obj {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    unsigned count;
    objc_property_t *properties = class_copyPropertyList([obj class], &count);
    
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        [dict setObject:[obj valueForKey:key] forKey:key];
    }
    
    free(properties);
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

#pragma mark - Defined extensions of media files
+ (NSString*)downloadMedia:(NSString*)urlString {
    NSURL* url = [NSURL URLWithString:urlString];
    NSString* extension = url.pathExtension;
    
    if ([extension isEqualToString:@""]) {
        extension = nil;
    }
    
    NSArray *supportedAttachmentTypes = @[@"aiff", @"wav", @"mp3", @"mp4", @"jpg", @"jpeg", @"png", @"gif", @"mpeg", @"mpg", @"avi", @"m4a", @"m4v"];
    if (extension != nil && ![supportedAttachmentTypes containsObject:extension]) {
        return nil;
    }
    
    NSString* name = [self randomStringWithLength:8];
    if (extension) {
        name = [name stringByAppendingString:[NSString stringWithFormat:@".%@", extension]];
    }
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* filePath = [paths[0] stringByAppendingPathComponent:name];
    
    @try {
        NSError *error;
        [NSURLSession downloadItemAtURL:url toFile:filePath error:&error];
        if (error) {
            NSLog(@"CleverPush: error while attempting to download file with URL: %@", error);
            return nil;
        }
 
        return name;
    } @catch (NSException *exception) {
        NSLog(@"CleverPush: error while downloading file (%@), error: %@", url, exception.description);
        return nil;
    }
}

#pragma mark - daysBetweenDate(instance method and class method)
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime {
    NSDate *fromDate;
    NSDate *toDate;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&fromDate interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay startDate:&toDate interval:NULL forDate:toDateTime];
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay fromDate:fromDate toDate:toDate options:0];
    return [difference day];
}

#pragma mark - Update last check out time of topic dialog
+ (void)updateLastTopicCheckedTime {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSDate date] forKey:CLEVERPUSH_LAST_CHECKED_TIME_KEY];
    [userDefaults synchronize];
}

#pragma mark - Get the last check out time of topic dialog
+ (NSDate*)getLastTopicCheckedTime {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:CLEVERPUSH_LAST_CHECKED_TIME_KEY] ? [userDefaults objectForKey:CLEVERPUSH_LAST_CHECKED_TIME_KEY] : [NSDate date];
}

#pragma mark -  General function to get the color from hex string
+ (NSString *)hexStringFromColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    
    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255)];
}

#pragma mark -  Check the font family has been exist in the UIBundle or not.
+ (BOOL)fontFamilyExists:(NSString*)fontFamily {
    if (fontFamily == nil || fontFamily.length == 0) {
        return NO;
    }
    
    UIFontDescriptor *fontDescriptor = [UIFontDescriptor fontDescriptorWithFontAttributes:@{NSFontAttributeName:fontFamily}];
    NSArray *matches = [fontDescriptor matchingFontDescriptorsWithMandatoryKeys: nil];
    
    return ([matches count] > 0);
}

#pragma mark -  Check the empty.
+ (BOOL)isEmpty:(id)thing {
    return thing == nil
    || [thing isKindOfClass:[NSNull class]]
    || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
    || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}

#pragma mark -  Openup given URL in a SFSafariViewController.
+ (void)openSafari:(NSURL*)URL {
    if (URL) {
        if ([SFSafariViewController class] != nil) {
            SFSafariViewController *safariController = [[SFSafariViewController alloc] initWithURL:URL];
            safariController.modalPresentationStyle = UIModalPresentationPageSheet;
            [CleverPush.topViewController presentViewController:safariController animated:YES completion:nil];
        }
    }
}

#pragma mark -  Frame height without safeArea.
+ (CGFloat)frameHeightWithoutSafeArea {
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
        CGFloat topPadding = window.safeAreaInsets.top;
        CGFloat bottomPadding = window.safeAreaInsets.bottom;
        CGFloat height = UIScreen.mainScreen.bounds.size.height - (topPadding + bottomPadding);
        return height;
    } else {
        return UIScreen.mainScreen.bounds.size.height;
    }
}

#pragma mark -  Open safari and dismiss on a specific controller.
+ (void)openSafari:(NSURL*)URL dismissViewController:(UIViewController*)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if (URL) {
                if ([SFSafariViewController class] != nil) {
                    SFSafariViewController *safariController = [[SFSafariViewController alloc] initWithURL:URL];
                    safariController.modalPresentationStyle = UIModalPresentationPageSheet;
                    [CleverPush.topViewController presentViewController:safariController animated:YES completion:nil];
                }
            }
        });
    }];
}

#pragma mark -  get the device name based on their model names.
+ (NSString*)deviceName {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString* code = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    static NSDictionary* deviceNamesByCode = nil;
    if (!deviceNamesByCode) {
        deviceNamesByCode = @{@"i386": @"iPhone Simulator",
                              @"x86_64": @"iPhone Simulator",
                              @"arm64": @"iPhone Simulator",
                              //iPhones
                              @"iPhone1,1": @"iPhone",
                              @"iPhone1,2": @"iPhone 3G",
                              @"iPhone2,1": @"iPhone 3GS",
                              @"iPhone3,1": @"iPhone 4",
                              @"iPhone3,2": @"iPhone 4 GSM Rev A",
                              @"iPhone3,3": @"iPhone 4 CDMA",
                              @"iPhone4,1": @"iPhone 4S",
                              @"iPhone5,1": @"iPhone 5 (GSM)",
                              @"iPhone5,2": @"iPhone 5 (GSM+CDMA)",
                              @"iPhone5,3": @"iPhone 5C (GSM)",
                              @"iPhone5,4": @"iPhone 5C (Global)",
                              @"iPhone6,1": @"iPhone 5S (GSM)",
                              @"iPhone6,2": @"iPhone 5S (Global)",
                              @"iPhone7,1": @"iPhone 6 Plus",
                              @"iPhone7,2": @"iPhone 6",
                              @"iPhone8,1": @"iPhone 6s",
                              @"iPhone8,2": @"iPhone 6s Plus",
                              @"iPhone8,4": @"iPhone SE (GSM)",
                              @"iPhone9,1": @"iPhone 7",
                              @"iPhone9,2": @"iPhone 7 Plus",
                              @"iPhone9,3": @"iPhone 7",
                              @"iPhone9,4": @"iPhone 7 Plus",
                              @"iPhone10,1": @"iPhone 8",
                              @"iPhone10,2": @"iPhone 8 Plus",
                              @"iPhone10,3": @"iPhone X Global",
                              @"iPhone10,4": @"iPhone 8",
                              @"iPhone10,5": @"iPhone 8 Plus",
                              @"iPhone10,6": @"iPhone X GSM",
                              @"iPhone11,2": @"iPhone XS",
                              @"iPhone11,4": @"iPhone XS Max",
                              @"iPhone11,6": @"iPhone XS Max Global",
                              @"iPhone11,8": @"iPhone XR",
                              @"iPhone12,1": @"iPhone 11",
                              @"iPhone12,3": @"iPhone 11 Pro",
                              @"iPhone12,5": @"iPhone 11 Pro Max",
                              @"iPhone12,8": @"iPhone SE 2nd Gen",
                              @"iPhone13,1": @"iPhone 12 Mini",
                              @"iPhone13,2": @"iPhone 12",
                              @"iPhone13,3": @"iPhone 12 Pro",
                              @"iPhone13,4": @"iPhone 12 Pro Max",
                              @"iPhone14,2": @"iPhone 13 Pro",
                              @"iPhone14,3": @"iPhone 13 Pro Max",
                              @"iPhone14,4": @"iPhone 13 mini",
                              @"iPhone14,5": @"iPhone 13",
                              //iPods
                              @"iPod1,1": @"1st Gen iPod",
                              @"iPod2,1": @"2nd Gen iPod",
                              @"iPod3,1": @"3rd Gen iPod",
                              @"iPod4,1": @"4th Gen iPod",
                              @"iPod5,1": @"5th Gen iPod",
                              @"iPod7,1": @"6th Gen iPod",
                              @"iPod9,1": @"7th Gen iPod",
                              //iPads
                              @"iPad1,1": @"iPad",
                              @"iPad1,2": @"iPad 3G",
                              @"iPad2,1": @"2nd Gen iPad",
                              @"iPad2,2": @"2nd Gen iPad GSM",
                              @"iPad2,3": @"2nd Gen iPad CDMA",
                              @"iPad2,4": @"2nd Gen iPad New Revision",
                              @"iPad3,1": @"3rd Gen iPad",
                              @"iPad3,2": @"3rd Gen iPad CDMA",
                              @"iPad3,3": @"3rd Gen iPad GSM",
                              @"iPad2,5": @"iPad mini",
                              @"iPad2,6": @"iPad mini GSM+LTE",
                              @"iPad2,7": @"iPad mini CDMA+LTE",
                              @"iPad3,4": @"4th Gen iPad",
                              @"iPad3,5": @"4th Gen iPad GSM+LTE",
                              @"iPad3,6": @"4th Gen iPad CDMA+LTE",
                              @"iPad4,1": @"iPad Air (WiFi)",
                              @"iPad4,2": @"iPad Air (GSM+CDMA)",
                              @"iPad4,3": @"1st Gen iPad Air (China)",
                              @"iPad4,4": @"iPad mini Retina (WiFi)",
                              @"iPad4,5": @"iPad mini Retina (GSM+CDMA)",
                              @"iPad4,6": @"iPad mini Retina (China)",
                              @"iPad4,7": @"iPad mini 3 (WiFi)",
                              @"iPad4,8": @"iPad mini 3 (GSM+CDMA)",
                              @"iPad4,9": @"iPad Mini 3 (China)",
                              @"iPad5,1": @"iPad mini 4 (WiFi)",
                              @"iPad5,2": @"4th Gen iPad mini (WiFi+Cellular)",
                              @"iPad5,3": @"iPad Air 2 (WiFi)",
                              @"iPad5,4": @"iPad Air 2 (Cellular)",
                              @"iPad6,3": @"iPad Pro (9.7 inch, WiFi)",
                              @"iPad6,4": @"iPad Pro (9.7 inch, WiFi+LTE)",
                              @"iPad6,7": @"iPad Pro (12.9 inch, WiFi)",
                              @"iPad6,8": @"iPad Pro (12.9 inch, WiFi+LTE)",
                              @"iPad6,11": @"iPad (2017)",
                              @"iPad6,12": @"iPad (2017)",
                              @"iPad7,1": @"iPad Pro 2nd Gen (WiFi)",
                              @"iPad7,2": @"iPad Pro 2nd Gen (WiFi+Cellular)",
                              @"iPad7,3": @"iPad Pro 10.5-inch",
                              @"iPad7,4": @"iPad Pro 10.5-inch",
                              @"iPad7,5": @"iPad 6th Gen (WiFi)",
                              @"iPad7,6": @"iPad 6th Gen (WiFi+Cellular)",
                              @"iPad7,11": @"iPad 7th Gen 10.2-inch (WiFi)",
                              @"iPad7,12": @"iPad 7th Gen 10.2-inch (WiFi+Cellular)",
                              @"iPad8,1": @"iPad Pro 11 inch 3rd Gen (WiFi)",
                              @"iPad8,2": @"iPad Pro 11 inch 3rd Gen (1TB, WiFi)",
                              @"iPad8,3": @"iPad Pro 11 inch 3rd Gen (WiFi+Cellular)",
                              @"iPad8,4": @"iPad Pro 11 inch 3rd Gen (1TB, WiFi+Cellular)",
                              @"iPad8,5": @"iPad Pro 12.9 inch 3rd Gen (WiFi)",
                              @"iPad8,6": @"iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)",
                              @"iPad8,7": @"iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)",
                              @"iPad8,8": @"iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)",
                              @"iPad8,9": @"iPad Pro 11 inch 4th Gen (WiFi)",
                              @"iPad8,10": @"iPad Pro 11 inch 4th Gen (WiFi+Cellular)",
                              @"iPad8,11": @"iPad Pro 12.9 inch 4th Gen (WiFi)",
                              @"iPad8,12": @"iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)",
                              @"iPad11,1": @"iPad mini 5th Gen (WiFi)",
                              @"iPad11,2": @"iPad mini 5th Gen",
                              @"iPad11,3": @"iPad Air 3rd Gen (WiFi)",
                              @"iPad11,4": @"iPad Air 3rd Gen",
                              @"iPad11,6": @"iPad 8th Gen (WiFi)",
                              @"iPad11,7": @"iPad 8th Gen (WiFi+Cellular)",
                              @"iPad13,1": @"iPad air 4th Gen (WiFi)",
                              @"iPad13,2": @"iPad air 4th Gen (WiFi+Cellular)",
                              @"iPad13,4": @"iPad Pro 11 inch 3rd Gen",
                              @"iPad13,5": @"iPad Pro 11 inch 3rd Gen",
                              @"iPad13,6": @"iPad Pro 11 inch 3rd Gen",
                              @"iPad13,7": @"iPad Pro 11 inch 3rd Gen",
                              @"iPad13,8": @"iPad Pro 12.9 inch 5th Gen",
                              @"iPad13,9": @"iPad Pro 12.9 inch 5th Gen",
                              @"iPad13,10": @"iPad Pro 12.9 inch 5th Gen",
                              @"iPad13,11": @"iPad Pro 12.9 inch 5th Gen",
                              @"iPad12,1": @"iPad (9th generation) Wi-Fi",
                              @"iPad12,2": @"iPad (9th generation) Wi-Fi + Cellular",
                              @"iPad14,1": @"iPad mini (6th generation) Wi-Fi",
                              @"iPad14,2": @"iPad mini (6th generation) Wi-Fi + Cellular"
        };
    }

    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    if (!deviceName) {
        if ([code rangeOfString:@"iPod"].location != NSNotFound) {
            deviceName = @"iPod Touch";
        } else if ([code rangeOfString:@"iPad"].location != NSNotFound) {
            deviceName = @"iPad";
        } else if([code rangeOfString:@"iPhone"].location != NSNotFound){
            deviceName = @"iPhone";
        } else {
            deviceName = @"Unknown";
        }
    }
    return deviceName;
}

#pragma mark -  get the seconds between two dates.
+ (NSInteger)secondsBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime {
    NSTimeInterval secondsBetween = [toDateTime timeIntervalSinceDate:fromDateTime];
    return secondsBetween;
}

#pragma mark -  update the last checked date & time of automatically displayed dilog
+ (void)updateLastTimeAutomaticallyShowed {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSDate date] forKey:CLEVERPUSH_LAST_CHECKED_TIME_AUTO_SHOWED_KEY];
    [userDefaults synchronize];
}

#pragma mark -  get the last checked date & time of automatically displayed dilog
+ (NSDate*)getLastTimeAutomaticallyShowed {
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:CLEVERPUSH_LAST_CHECKED_TIME_AUTO_SHOWED_KEY] ? [userDefaults objectForKey:CLEVERPUSH_LAST_CHECKED_TIME_AUTO_SHOWED_KEY] : [NSDate date];
}

#pragma mark - check the existance of new topic in the channel configuration.
+ (BOOL)newTopicAdded:(NSDictionary*)config {
    if (config != nil && [config objectForKey:@"topicsDialogShowWhenNewAdded"]) {
        topicsDialogShowWhenNewAdded = [[config objectForKey:@"topicsDialogShowWhenNewAdded"] boolValue];
    }

    NSArray* channelTopics = [config arrayForKey:@"channelTopics"];
    if (channelTopics != nil && [channelTopics count] > 0) {
        for (id channelTopic in channelTopics) {
            if (channelTopic != nil && ([channelTopic stringForKey:@"createdAt"] == nil || [[channelTopic stringForKey:@"createdAt"] isKindOfClass:[NSString class]])) {
                NSDate *createdAt = [self getLocalDateTimeFromUTC:[channelTopic stringForKey:@"createdAt"]];
                NSDate *addedCacheDelay = [createdAt dateByAddingTimeInterval:+60*60];
                NSComparisonResult result;
                result = [addedCacheDelay compare:[CPUtils getLastTopicCheckedTime]];
                if (topicsDialogShowWhenNewAdded && result == NSOrderedDescending) {
                    existanceOfNewTopic = YES;
                }
            }
        }
    }
    return existanceOfNewTopic;
}

#pragma mark - convert UTC date in to local date.
+ (NSDate*)getLocalDateTimeFromUTC:(NSString*)dateString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateFormat];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier]];
    NSDate *localDate = [formatter dateFromString:dateString];
    return localDate;
}

#pragma mark - convert UTC date in to local date.
+ (NSString*)getCurrentDateString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateFormat];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier]];
    return [formatter stringFromDate:[NSDate date]];
}

+ (NSBundle *)getAssetsBundle {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSBundle *sourceBundle = [NSBundle bundleForClass:[self class]];
    NSBundle *bundle = [NSBundle bundleWithPath:[mainBundle pathForResource:@"CleverPushResources" ofType:@"bundle"]];
    bundle = bundle ? : [NSBundle bundleWithPath:[sourceBundle pathForResource:@"CleverPushResources" ofType:@"bundle"]];
    return bundle ? : sourceBundle;
}

#pragma mark - time ago string based on the current time.
+ (NSString *)timeAgoStringFromDate:(NSDate *)date {
    NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
    formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;

    NSDate *now = [NSDate date];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitWeekOfMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond)
                                               fromDate:date
                                                 toDate:now
                                                options:0];

    if (components.year > 0) {
        formatter.allowedUnits = NSCalendarUnitYear;
    } else if (components.month > 0) {
        formatter.allowedUnits = NSCalendarUnitMonth;
    } else if (components.weekOfMonth > 0) {
        formatter.allowedUnits = NSCalendarUnitWeekOfMonth;
    } else if (components.day > 0) {
        formatter.allowedUnits = NSCalendarUnitDay;
    } else if (components.hour > 0) {
        formatter.allowedUnits = NSCalendarUnitHour;
    } else if (components.minute > 0) {
        formatter.allowedUnits = NSCalendarUnitMinute;
    } else {
        formatter.allowedUnits = NSCalendarUnitSecond;
    }

    NSString *formatString = NSLocalizedString(@"%@ ago", @"Used to say how much time has passed. e.g. '2 hours ago'");

    return [NSString stringWithFormat:formatString, [formatter stringFromDateComponents:components]];
}

+ (NSUserDefaults *)getUserDefaultsAppGroup {
    NSBundle *bundle = [NSBundle mainBundle];
    if ([[bundle.bundleURL pathExtension] isEqualToString:@"appex"]) {
        // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
        bundle = [NSBundle bundleWithURL:[[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
    }
    NSUserDefaults* userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@.cleverpush", [bundle bundleIdentifier]]];
    return userDefaults;
}

@end
