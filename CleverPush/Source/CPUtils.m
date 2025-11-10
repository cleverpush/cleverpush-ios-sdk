#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import "CPUtils.h"
#import "CPLog.h"
#import "NSDictionary+SafeExpectations.h"
#import "CPAppBannerViewController.h"

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
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* filePath = [paths[0] stringByAppendingPathComponent:name];

    @try {
        NSError *error;
        NSString *mimeType = [NSURLSession downloadItemAtURL:url toFile:filePath error:&error];
        if (error) {
            [CPLog error:@"error while attempting to download file with URL: %@", error];
            return nil;
        }

        if (!extension && mimeType) {
            extension = [self extensionFromMimeType:mimeType];
            if (!extension || ![supportedAttachmentTypes containsObject:extension]) {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                return nil;
            }
        }
        
        if (extension) {
            NSString* newName = [name stringByAppendingString:[NSString stringWithFormat:@".%@", extension]];
            NSString* newFilePath = [paths[0] stringByAppendingPathComponent:newName];
            NSError *moveError;
            [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:newFilePath error:&moveError];
            if (moveError) {
                [CPLog error:@"error while renaming downloaded file: %@", moveError];
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                return nil;
            }
            return newName;
        }

        return name;
    } @catch (NSException *exception) {
        [CPLog error:@"error while downloading file (%@), error: %@", url, exception.description];
        return nil;
    }
}

#pragma mark - Get file extension from MIME type
+ (NSString*)extensionFromMimeType:(NSString*)mimeType {
    if (!mimeType) return nil;

    NSString *lowerMimeType = [mimeType lowercaseString];

    if ([lowerMimeType isEqualToString:@"image/jpeg"] || [lowerMimeType isEqualToString:@"image/jpg"]) {
        return @"jpeg";
    } else if ([lowerMimeType isEqualToString:@"image/png"]) {
        return @"png";
    } else if ([lowerMimeType isEqualToString:@"image/gif"]) {
        return @"gif";
    }
    return nil;
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
    CGColorSpaceModel colorSpace = CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor));
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    CGFloat r = 1.0, g = 1.0, b = 1.0, a = 1.0;

    if (colorSpace == kCGColorSpaceModelMonochrome) {
        r = components[0];
        g = components[0];
        b = components[0];
        a = components[1];
    }
    else if (colorSpace == kCGColorSpaceModelRGB) {
        r = components[0];
        g = components[1];
        b = components[2];
        a = components[3];
    }
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255),
            lroundf(a * 255)];
}

#pragma mark -  Check the font family has been exist in the UIBundle or not.
+ (BOOL)fontFamilyExists:(NSString*)fontFamily {
    if (fontFamily == nil || fontFamily.length == 0) {
        return NO;
    }

    return [UIFont fontWithName:fontFamily size:18.0f] != nil;
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
    if ([self isValidURL:URL]) {
        if ([SFSafariViewController class] != nil) {
            SFSafariViewController *safariController = [[SFSafariViewController alloc] initWithURL:URL];
            safariController.delegate = (id<SFSafariViewControllerDelegate>)CleverPush.topViewController;
            safariController.modalPresentationStyle = UIModalPresentationPageSheet;
            [CleverPush.topViewController presentViewController:safariController animated:YES completion:nil];
        }
    }
}

#pragma mark -  Frame height without safeArea.
+ (CGFloat)frameHeightWithoutSafeArea {
    UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
    CGFloat topPadding = window.safeAreaInsets.top;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    CGFloat height = UIScreen.mainScreen.bounds.size.height - (topPadding + bottomPadding);
    return height;
}

#pragma mark -  Open safari and dismiss on a specific controller.
+ (void)openSafari:(NSURL*)URL dismissViewController:(UIViewController*)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:CLEVERPUSH_APP_BANNER_VISIBLE_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if ([self isValidURL:URL]) {
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
                              @"iPhone14,6" : @"iPhone SE 3rd Gen",
                              @"iPhone14,7" : @"iPhone 14",
                              @"iPhone14,8" : @"iPhone 14 Plus",
                              @"iPhone15,2" : @"iPhone 14 Pro",
                              @"iPhone15,3" : @"iPhone 14 Pro Max",
                              @"iPhone15,4" : @"iPhone 15",
                              @"iPhone15,5" : @"iPhone 15 Plus",
                              @"iPhone16,1" : @"iPhone 15 Pro",
                              @"iPhone16,2" : @"iPhone 15 Pro Max",
                              @"iPhone17,1" : @"iPhone 16 Pro",
                              @"iPhone17,2" : @"iPhone 16 Pro Max",
                              @"iPhone17,3" : @"iPhone 16",
                              @"iPhone17,4" : @"iPhone 16 Plus",
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
                              @"iPad14,2": @"iPad mini (6th generation) Wi-Fi + Cellular",
                              @"iPad14,3" : @"iPad Pro 11 inch 4th Gen",
                              @"iPad14,4" : @"iPad Pro 11 inch 4th Gen",
                              @"iPad14,5" : @"iPad Pro 12.9 inch 6th Gen",
                              @"iPad14,6" : @"iPad Pro 12.9 inch 6th Gen",
                              @"iPad14,8" : @"iPad Air 6th Gen",
                              @"iPad14,9" : @"iPad Air 6th Gen",
                              @"iPad14,10" : @"iPad Air 7th Gen",
                              @"iPad14,11" : @"iPad Air 7th Gen",
                              @"iPad16,3" : @"iPad Pro 11 inch 5th Gen",
                              @"iPad16,4" : @"iPad Pro 11 inch 5th Gen",
                              @"iPad16,5" : @"iPad Pro 12.9 inch 7th Gen",
                              @"iPad16,6" : @"iPad Pro 12.9 inch 7th Gen",
        };
    }

    NSString* deviceName = [deviceNamesByCode objectForKey:code];
    if (!deviceName) {
        if ([code rangeOfString:@"iPod"].location != NSNotFound) {
            deviceName = @"iPod Touch";
        } else if ([code rangeOfString:@"iPad"].location != NSNotFound) {
            deviceName = @"iPad";
        } else if([code rangeOfString:@"iPhone"].location != NSNotFound) {
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

    NSArray* channelTopics = [config cleverPushArrayForKey:@"channelTopics"];
    if (channelTopics != nil && [channelTopics count] > 0) {
        for (id channelTopic in channelTopics) {
            if (channelTopic != nil && ([channelTopic cleverPushStringForKey:@"createdAt"] == nil || [[channelTopic cleverPushStringForKey:@"createdAt"] isKindOfClass:[NSString class]])) {
                NSDate *createdAt = [self getLocalDateTimeFromUTC:[channelTopic cleverPushStringForKey:@"createdAt"]];
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
    bundle = bundle ? : [NSBundle bundleWithPath:[mainBundle pathForResource:@"CleverPush_CleverPush" ofType:@"bundle"]];
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
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:[NSString stringWithFormat:@"group.%@%@", [bundle bundleIdentifier], [CleverPush getAppGroupIdentifierSuffix]]];
    return userDefaults;
}

+ (UIColor *)readableForegroundColorForBackgroundColor:(UIColor*)backgroundColor {
    size_t count = CGColorGetNumberOfComponents(backgroundColor.CGColor);
    const CGFloat *componentColors = CGColorGetComponents(backgroundColor.CGColor);

    CGFloat darknessScore = 0;
    if (count == 2) {
        darknessScore = (((componentColors[0]*255) * 299) + ((componentColors[0]*255) * 587) + ((componentColors[0]*255) * 114)) / 1000;
    } else if (count == 4) {
        darknessScore = (((componentColors[0]*255) * 299) + ((componentColors[1]*255) * 587) + ((componentColors[2]*255) * 114)) / 1000;
    }

    if (darknessScore >= 125) {
        return [UIColor blackColor];
    }

    return [UIColor whiteColor];
}

#pragma mark - Find the particular word in the string and replace it in the original string.
+ (NSString *)replaceString:(NSString *)originalString withReplacement:(NSString *)replacement inString:(NSString *)inputString {
    NSString *result = [inputString stringByReplacingOccurrencesOfString:originalString withString:replacement];
    return result;
}

#pragma mark - Get the current time stamp in a particular date format.
+ (NSString *)getCurrentTimestampWithFormat:(NSString *)dateFormat {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:dateFormat];
    NSDate *currentDate = [NSDate date];
    NSString *currentTimeStamp = [dateFormatter stringFromDate:currentDate];
    return currentTimeStamp;
}

#pragma mark - Find the particular word in the url and replace it in the original url.
+ (NSURL *)replaceAndEncodeURL:(NSURL *)url withReplacement:(NSString *)replacement {
    if (url == nil || replacement == nil) {
        return nil;
    }

    NSString *urlString = [url absoluteString];
    NSString *replacedURLString = [self replaceString:@"{voucherCode}" withReplacement:replacement inString:urlString];
    NSString *encodedURLString = [replacedURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    return [NSURL URLWithString:encodedURLString];
}

#pragma mark - CleverPush Javascript functions
+ (NSString *)cleverPushJavaScript {
    return @"\
       <script>\
           if (typeof window.CleverPush === 'undefined') {\
               window.CleverPush = {};\
           }\
           window.CleverPush.subscribe = function subscribe() {\
               window.webkit.messageHandlers.subscribe.postMessage(null);\
           };\
           window.CleverPush.unsubscribe = function unsubscribe() {\
               window.webkit.messageHandlers.unsubscribe.postMessage(null);\
           };\
           window.CleverPush.closeBanner = function closeBanner() {\
               window.webkit.messageHandlers.closeBanner.postMessage(null);\
           };\
           window.CleverPush.trackEvent = function trackEvent(ID, properties) {\
               window.webkit.messageHandlers.trackEvent.postMessage({ eventId: ID, properties: properties });\
           };\
           window.CleverPush.setSubscriptionAttribute = function setSubscriptionAttribute(attributeId, value) {\
               window.webkit.messageHandlers.setSubscriptionAttribute.postMessage({ attributeKey: attributeId, attributeValue: value });\
           };\
           window.CleverPush.getSubscriptionAttribute = function getSubscriptionAttribute(attributeId) {\
                   window.webkit.messageHandlers.getSubscriptionAttribute.postMessage({ attributeKey: attributeId });\
           };\
           window.CleverPush.addSubscriptionTag = function addSubscriptionTag(tagId) {\
               window.webkit.messageHandlers.addSubscriptionTag.postMessage(tagId);\
           };\
           window.CleverPush.removeSubscriptionTag = function removeSubscriptionTag(tagId) {\
               window.webkit.messageHandlers.removeSubscriptionTag.postMessage(tagId);\
           };\
           window.CleverPush.setSubscriptionTopics = function setSubscriptionTopics(topicIds) {\
               window.webkit.messageHandlers.setSubscriptionTopics.postMessage(topicIds);\
           };\
           window.CleverPush.addSubscriptionTopic = function addSubscriptionTopic(topicId) {\
               window.webkit.messageHandlers.addSubscriptionTopic.postMessage(topicId);\
           };\
           window.CleverPush.removeSubscriptionTopic = function removeSubscriptionTopic(topicId) {\
               window.webkit.messageHandlers.removeSubscriptionTopic.postMessage(topicId);\
           };\
           window.CleverPush.showTopicsDialog = function showTopicsDialog() {\
               window.webkit.messageHandlers.showTopicsDialog.postMessage(null);\
           };\
           window.CleverPush.openWebView = function openWebView(url) {\
               window.webkit.messageHandlers.openWebView.postMessage(url);\
           };\
           window.CleverPush.trackClick = function trackClick(ID, properties) {\
               window.webkit.messageHandlers.trackClick.postMessage({ buttonId: ID, properties: properties });\
           };\
           window.CleverPush.previousScreen = function previousScreen() {\
               window.webkit.messageHandlers.previousScreen.postMessage(null);\
           };\
           window.CleverPush.nextScreen = function nextScreen() {\
               window.webkit.messageHandlers.nextScreen.postMessage(null);\
           };\
           window.CleverPush.goToScreen = function goToScreen(screenId) {\
               window.webkit.messageHandlers.goToScreen.postMessage(screenId);\
           };\
           window.CleverPush.copyToClipboard = function copyToClipboard(text) {\
               window.webkit.messageHandlers.copyToClipboard.postMessage(text);\
           };\
           window.CleverPush.handleLinkBySystem = function handleLinkBySystem(url) {\
               window.webkit.messageHandlers.handleLinkBySystem.postMessage(url);\
           };\
       </script>";
}

+ (NSString *)generateBannerHTMLStringWithFunctions:(NSString *)content {
    if ([content containsString:@"</body>"]) {
        content = [content stringByReplacingOccurrencesOfString:@"</body>" withString:@""];
    }
    if ([content containsString:@"</html>"]) {
        content = [content stringByReplacingOccurrencesOfString:@"</html>" withString:@""];
    }

    NSString *script = [self cleverPushJavaScript];

    NSString *closingBodyHtmlTag = @"</body></html>";
    NSString *scriptSource = [NSString stringWithFormat:@"%@%@%@", content, script, closingBodyHtmlTag];

    NSString *headerString = @"<head><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></head>";

    NSString *finalHTMLString = [headerString stringByAppendingString:scriptSource];

    return finalHTMLString;
}

+ (NSArray<NSString *> *)scriptMessageNames {
    return @[@"close", @"subscribe", @"unsubscribe", @"closeBanner", @"trackEvent",
             @"setSubscriptionAttribute", @"getSubscriptionAttribute", @"addSubscriptionTag", @"removeSubscriptionTag",
             @"setSubscriptionTopics", @"addSubscriptionTopic", @"removeSubscriptionTopic",
             @"showTopicsDialog", @"trackClick", @"openWebView", @"goToScreen", @"nextScreen", @"previousScreen", @"copyToClipboard", @"handleLinkBySystem"];
}

+ (void)configureWebView:(WKWebView *)webView {
    webView.scrollView.bounces = NO;
    webView.opaque = NO;
    webView.allowsBackForwardNavigationGestures = NO;
    webView.contentMode = UIViewContentModeScaleToFill;
}

+ (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message withBanner:(CPAppBanner *)banner {
    [CPLog debug:@"Received message: %@ with body: %@", message.name, message.body];

    if (message != nil && message.name != nil) {
        if ([message.name isEqualToString:@"close"] || [message.name isEqualToString:@"closeBanner"]) {
            UIViewController *topController = [CleverPush topViewController];
            if (topController) {
                [CPLog debug:@"Dismissing controller: %@", topController];
                [topController dismissViewControllerAnimated:YES completion:^{
                    [CPLog debug:@"Controller dismissed"];
                }];
            } else {
                [CPLog debug:@"No controller to dismiss"];
            }
        } else if ([message.name isEqualToString:@"nextScreen"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NavigateToNextPageNotification" object:nil];
        } else if ([message.name isEqualToString:@"previousScreen"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NavigateToPreviousPageNotification" object:nil];
        } else if ([message.name isEqualToString:@"subscribe"]) {
            [self handleSubscribeActionWithCallback:^(BOOL success) {
                if (success) {
                    [CleverPush subscribe];
                }
            }];
        } else if ([message.name isEqualToString:@"unsubscribe"]) {
            [CleverPush unsubscribe];
        } else if ([message.name isEqualToString:@"showTopicsDialog"]) {
            [CleverPush showTopicsDialog];
        }

        if (message.body != nil && ![message.body isKindOfClass:[NSNull class]]) {
            if ([message.name isEqualToString:@"trackEvent"]) {
                [CleverPush trackEvent:[message.body objectForKey:@"eventId"] properties:[message.body objectForKey:@"properties"]];
            } else if ([message.name isEqualToString:@"setSubscriptionAttribute"]) {
                [CleverPush setSubscriptionAttribute:[message.body objectForKey:@"attributeKey"] value:[message.body objectForKey:@"attributeValue"]];
            } else if ([message.name isEqualToString:@"getSubscriptionAttribute"]) {
                NSDictionary *bodyDict = (NSDictionary *)message.body;
                if (bodyDict && bodyDict.count > 0) {
                    NSString *attributeKey = bodyDict[@"attributeKey"];
                    if (![CPUtils isNullOrEmpty:attributeKey]) {
                        NSString *attributeValue = (NSString *)[CleverPush getSubscriptionAttribute:attributeKey];
                        if (![CPUtils isNullOrEmpty:attributeValue]) {
                            NSString *jsCallback = [NSString stringWithFormat:@"window.CleverPush.callback('%@');", attributeValue];
                            [message.webView evaluateJavaScript:jsCallback completionHandler:nil];
                        }
                    }
                }
            } else if ([message.name isEqualToString:@"addSubscriptionTag"]) {
                [CleverPush addSubscriptionTag:message.body];
            } else if ([message.name isEqualToString:@"removeSubscriptionTag"]) {
                [CleverPush removeSubscriptionTag:message.body];
            } else if ([message.name isEqualToString:@"setSubscriptionTopics"]) {
                [CleverPush setSubscriptionTopics:message.body];
            } else if ([message.name isEqualToString:@"addSubscriptionTopic"]) {
                [CleverPush addSubscriptionTopic:message.body];
            } else if ([message.name isEqualToString:@"removeSubscriptionTopic"]) {
                [CleverPush removeSubscriptionTopic:message.body];
            } else if ([message.name isEqualToString:@"trackClick"]) {
                CPAppBannerAction *action;
                NSMutableDictionary *buttonBlockDic = [[NSMutableDictionary alloc] init];
                buttonBlockDic = [message.body mutableCopy];
                buttonBlockDic[@"bannerAction"] = @"type";
                action = [[CPAppBannerAction alloc] initWithJson:buttonBlockDic];

                NSBundle *bundle = [CPUtils getAssetsBundle];
                if (!bundle) {
                    bundle = [NSBundle mainBundle];
                }

                CPAppBannerViewController *appBannerViewController = [[CPAppBannerViewController alloc] initWithNibName:@"CPAppBannerViewController" bundle:bundle];

                if (appBannerViewController && action) {
                    [appBannerViewController actionCallback:action];
                }
                if (banner != nil) {
                    [CPAppBannerModule sendBannerEvent:@"clicked" forBanner:banner forScreen:nil forButtonBlock:nil forImageBlock:nil blockType:nil withCustomData:buttonBlockDic];
                }
            } else if ([message.name isEqualToString:@"openWebView"]) {
                NSURL *webUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@", message.body]];
                if (webUrl && webUrl.scheme && webUrl.host) {
                    [self openSafari:webUrl dismissViewController:CleverPush.topViewController];
                }
            } else if ([message.name isEqualToString:@"goToScreen"]) {
                if (message.name != nil && [message.name isKindOfClass:[NSString class]]) {
                    if (![self isNullOrEmpty:message.body]) {
                        NSDictionary *banner = @{
                            @"screenId": message.body
                        };
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"NavigateToPageNotification" object:nil userInfo:banner];
                    }
                }
            } else if ([message.name isEqualToString:@"copyToClipboard"]) {
                [UIPasteboard generalPasteboard].string = [NSString stringWithFormat:@"%@", message.body];
            } else if ([message.name isEqualToString:@"handleLinkBySystem"]) {
                [self handleLinkBySystem:[NSString stringWithFormat:@"%@", message.body]];
            }
        }
    }
}

#pragma mark - Notification Settings
+ (void)handleSubscribeActionWithCallback:(void (^)(BOOL))callback {
    [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
                NSString *settingsURLString;

                if (@available(iOS 15.4, *)) {
                    settingsURLString = UIApplicationOpenNotificationSettingsURLString;
                } else {
                    settingsURLString = UIApplicationOpenSettingsURLString;
                }

                NSURL *url = [NSURL URLWithString:settingsURLString];

                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                }
                callback(NO);
            } else {
                callback(YES);
            }
        });
    }];
}

#pragma mark -  Handle link by system using URLs.
+ (void)handleLinkBySystem:(NSString*)urlString {
    if (urlString && urlString.length > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *url = [NSURL URLWithString:urlString];
            if (url) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                    if (!success) {
                        [CPLog debug:@"Failed to open URL: %@", urlString];
                    }
                }];
            } else {
                [CPLog debug:@"Invalid URL string, cannot create URL: %@", urlString];
            }
        });
    }
}

#pragma mark - Check string is nil, null or empty
+ (BOOL)isNullOrEmpty:(NSString *)string {
    if (string == nil || [string isEqual:[NSNull null]] || [string isEqualToString:@""]) {
        return YES;
    }
    return NO;
}

#pragma mark - String validation of a key exists or not
+ (NSString *)valueForKey:(NSString *)key inDictionary:(NSDictionary *)dictionary {
    if (!dictionary || dictionary.count == 0) {
        return nil;
    }
    NSString *voucherCode = dictionary[key];
    return voucherCode;
}

#pragma mark -  URL Handling
+ (void)tryOpenURL:(NSURL *)url {
    if (![self isValidURL:url]) {
        return;
    }

    NSString *scheme = [url scheme];
    UIApplication *application = [UIApplication sharedApplication];

    if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"]) {
        if ([application canOpenURL:url]) {
            [application openURL:url options:@{} completionHandler:nil];
        }
        return;
    }

    NSArray<NSString *> *domains = [CleverPush getHandleUniversalLinksInAppForDomains];
    if (domains && [domains isKindOfClass:[NSArray class]] && domains.count > 0) {
        if ([self isAssociatedDomainURL:url]) {
            NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
            userActivity.webpageURL = url;

            if ([CleverPush getHandleUrlFromSceneDelegate]) {
                if (@available(iOS 13.0, *)) {
                    UIWindowScene *scene = (UIWindowScene *)[application.connectedScenes anyObject];
                    [scene.delegate scene:scene continueUserActivity:userActivity];
                }
            } else {
                [application.delegate application:application continueUserActivity:userActivity restorationHandler:^(NSArray<id<UIUserActivityRestoring>> * _Nullable restorableObjects) {
                }];
            }
        } else {
            if ([application canOpenURL:url]) {
                [application openURL:url options:@{} completionHandler:nil];
            }
        }
    } else {
        if ([application canOpenURL:url]) {
            [application openURL:url options:@{} completionHandler:nil];
        }
    }
}

+ (BOOL)isAssociatedDomainURL:(NSURL *)url {
    NSArray<NSString *> *associatedDomains = [self fetchAssociatedDomains];
    NSString *urlString = url.absoluteString;

    for (NSString *domain in associatedDomains) {
        if ([self doesURL:urlString matchPattern:domain]) {
            return YES;
        }
    }

    return NO;
}

+ (NSArray<NSString *> *)fetchAssociatedDomains {
    NSMutableArray<NSString *> *domains = [NSMutableArray array];
    for (NSString *domain in [CleverPush getHandleUniversalLinksInAppForDomains]) {
        if (domain != nil && ![domain isKindOfClass:[NSNull class]] && [domain isKindOfClass:[NSString class]]) {
            NSString *trimmedDomain = domain;

            if (![trimmedDomain hasPrefix:@"http://"] && ![trimmedDomain hasPrefix:@"https://"]) {
                trimmedDomain = [NSString stringWithFormat:@"https://%@", trimmedDomain];
            }

            [domains addObject:trimmedDomain];
        }
    }

    return [domains copy];
}

+ (BOOL)doesURL:(NSString *)url matchPattern:(NSString *)pattern {
    NSString *regexPattern = [pattern stringByReplacingOccurrencesOfString:@"*" withString:@".*"];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:url options:0 range:NSMakeRange(0, [url length])];
    return numberOfMatches > 0;
}


+ (BOOL)isValidURL:(NSURL *)url {
    if (url == nil || [url isKindOfClass:[NSNull class]] || ([[url absoluteString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length == 0) || (url.scheme == nil || [url.scheme isEqualToString:@""])) {
        return NO;
    }
    return YES;
}

+ (NSURL *)removeQueryParametersFromURL:(NSURL *)url {
    if (!url) {
        return nil;
    }

    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.query = nil;

    return components.URL;
}

#pragma mark - Converts UISceneConnectionOptions to launch options.
+ (NSDictionary *)convertConnectionOptionsToLaunchOptions:(UISceneConnectionOptions *)connectionOptions API_AVAILABLE(ios(13.0)) {
    NSMutableDictionary *launchOptions = [NSMutableDictionary dictionary];

    if (connectionOptions.notificationResponse) {
        NSDictionary *userInfo = connectionOptions.notificationResponse.notification.request.content.userInfo;
        [launchOptions setObject:userInfo forKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    }

    return launchOptions;
}

#pragma mark - image resizing
+ (UIImage *)resizedImageNamed:(NSString *)imageName withSize:(CGSize)newSize {
    if (@available(iOS 13.0, *)) {
        UIImage *image = [UIImage systemImageNamed:imageName];
        if (!image) {
            return nil;
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    } 
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return resizedImage;
}

+ (NSCache *)sharedImageCache {
    static NSCache *sharedImageCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedImageCache = [[NSCache alloc] init];
    });
    return sharedImageCache;
}

#pragma mark - Check if delta contains rich text formatting
+ (BOOL)deltaHasFormatting:(NSDictionary *)delta {
    NSArray *ops = [delta objectForKey:@"ops"];
    if (ops == nil || ![ops isKindOfClass:[NSArray class]]) {
        return NO;
    }
    
    for (id op in ops) {
        if ([op isKindOfClass:[NSDictionary class]]) {
            NSDictionary *opDict = (NSDictionary *)op;
            NSDictionary *attributes = [opDict objectForKey:@"attributes"];
            
            if (attributes != nil && 
                [attributes isKindOfClass:[NSDictionary class]] && 
                [attributes count] > 0) {
                return YES;
            }
        }
    }
    
    return NO;
}

#pragma mark - Convert Quill Delta to HTML
+ (NSString *)htmlFromDelta:(NSDictionary *)delta {
    if (!delta || ![delta isKindOfClass:[NSDictionary class]]) {
        return @"";
    }
    
    NSArray *ops = [delta objectForKey:@"ops"];
    if (!ops || ![ops isKindOfClass:[NSArray class]] || ops.count == 0) {
        return @"";
    }
    
    NSMutableString *html = [NSMutableString string];
    
    for (NSDictionary *op in ops) {
        if (![op isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        NSString *insertText = [op objectForKey:@"insert"];
        if (!insertText || ![insertText isKindOfClass:[NSString class]]) {
            continue;
        }
        
        NSDictionary *attributes = [op objectForKey:@"attributes"];
        
        BOOL isBold = NO;
        BOOL isItalic = NO;
        BOOL isUnderline = NO;
        BOOL isStrike = NO;
        
        if (attributes && [attributes isKindOfClass:[NSDictionary class]]) {
            isBold = [[attributes objectForKey:@"bold"] boolValue];
            isItalic = [[attributes objectForKey:@"italic"] boolValue];
            isUnderline = [[attributes objectForKey:@"underline"] boolValue];
            isStrike = [[attributes objectForKey:@"strike"] boolValue];
        }
        
        NSArray *lines = [insertText componentsSeparatedByString:@"\n"];
        for (NSInteger i = 0; i < lines.count; i++) {
            NSString *line = lines[i];
            
            if (line.length > 0) {
                line = [line stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
                line = [line stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
                line = [line stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
                line = [line stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
            
                if (isStrike) {
                    line = [NSString stringWithFormat:@"<s>%@</s>", line];
                }
                if (isUnderline) {
                    line = [NSString stringWithFormat:@"<u>%@</u>", line];
                }
                if (isItalic) {
                    line = [NSString stringWithFormat:@"<i>%@</i>", line];
                }
                if (isBold) {
                    line = [NSString stringWithFormat:@"<b>%@</b>", line];
                }
                
                [html appendString:line];
            }
            
            if (i < lines.count - 1) {
                [html appendString:@"<br/>"];
            }
        }
    }
    
    return html;
}

#pragma mark - Convert Delta directly to NSAttributedString (Android-like approach)
+ (NSAttributedString *)attributedStringFromDelta:(NSDictionary *)delta withFont:(UIFont *)font textColor:(UIColor *)textColor textAlignment:(NSTextAlignment)textAlignment {
    if (!delta || ![delta isKindOfClass:[NSDictionary class]]) {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    
    NSArray *ops = [delta objectForKey:@"ops"];
    if (!ops || ![ops isKindOfClass:[NSArray class]] || ops.count == 0) {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = textAlignment;
    
    UIFont *baseFont = font ?: [UIFont systemFontOfSize:18.0];
    UIColor *baseColor = textColor ?: [UIColor blackColor];
    
    NSDictionary *baseAttributes = @{
        NSFontAttributeName: baseFont,
        NSForegroundColorAttributeName: baseColor,
        NSParagraphStyleAttributeName: paragraphStyle
    };
    
    for (NSDictionary *op in ops) {
        if (![op isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        NSString *insertText = [op objectForKey:@"insert"];
        if (!insertText || ![insertText isKindOfClass:[NSString class]]) {
            continue;
        }
        
        NSUInteger start = attributedString.length;
        NSAttributedString *plainSegment = [[NSAttributedString alloc] initWithString:insertText];
        [attributedString appendAttributedString:plainSegment];
        NSUInteger end = attributedString.length;
        
        // Only apply formatting if text was actually added AND attributes exist (matching Android's: end > start && op.getAttributes() != null)
        NSDictionary *attributes = [op objectForKey:@"attributes"];
        if (end > start && attributes != nil && [attributes isKindOfClass:[NSDictionary class]]) {
            BOOL isBold = [[attributes objectForKey:@"bold"] boolValue];
            BOOL isItalic = [[attributes objectForKey:@"italic"] boolValue];
            BOOL isUnderline = [[attributes objectForKey:@"underline"] boolValue];
            BOOL isStrike = [[attributes objectForKey:@"strike"] boolValue];
            
            UIFont *currentFont = baseFont;
            if (isBold && isItalic) {
                UIFontDescriptor *fontDescriptor = [baseFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic];
                if (fontDescriptor != nil) {
                    UIFont *font = [UIFont fontWithDescriptor:fontDescriptor size:baseFont.pointSize];
                    if (font != nil) {
                        currentFont = font;
                    }
                }
            } else if (isBold) {
                UIFontDescriptor *fontDescriptor = [baseFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
                if (fontDescriptor != nil) {
                    UIFont *font = [UIFont fontWithDescriptor:fontDescriptor size:baseFont.pointSize];
                    if (font != nil) {
                        currentFont = font;
                    }
                }
            } else if (isItalic) {
                UIFontDescriptor *fontDescriptor = [baseFont.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
                if (fontDescriptor != nil) {
                    UIFont *font = [UIFont fontWithDescriptor:fontDescriptor size:baseFont.pointSize];
                    if (font != nil) {
                        currentFont = font;
                    }
                }
            }
            
            NSMutableDictionary *textAttributes = [baseAttributes mutableCopy];
            [textAttributes setObject:currentFont forKey:NSFontAttributeName];
            
            if (isUnderline) {
                [textAttributes setObject:@(NSUnderlineStyleSingle) forKey:NSUnderlineStyleAttributeName];
            }
            
            if (isStrike) {
                [textAttributes setObject:@(NSUnderlineStyleSingle) forKey:NSStrikethroughStyleAttributeName];
            }
            
            // Replace the plain segment with formatted version
            NSRange range = NSMakeRange(start, end - start);
            NSAttributedString *formattedSegment = [[NSAttributedString alloc] initWithString:insertText attributes:textAttributes];
            [attributedString replaceCharactersInRange:range withAttributedString:formattedSegment];
        } else if (end > start) {
            // Apply base attributes if text was added but no formatting attributes
            NSRange range = NSMakeRange(start, end - start);
            NSAttributedString *baseSegment = [[NSAttributedString alloc] initWithString:insertText attributes:baseAttributes];
            [attributedString replaceCharactersInRange:range withAttributedString:baseSegment];
        }
    }
    
    return attributedString;
}

#pragma mark - Convert HTML string to NSAttributedString
+ (NSAttributedString *)attributedStringFromHTML:(NSString *)htmlString withFont:(UIFont *)font textColor:(UIColor *)textColor textAlignment:(NSTextAlignment)textAlignment {
    if (!htmlString || htmlString.length == 0) {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    
    BOOL containsHTML = [htmlString rangeOfString:@"<"].location != NSNotFound && [htmlString rangeOfString:@">"].location != NSNotFound;
    
    if (!containsHTML) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = textAlignment;
        
        NSDictionary *attributes = @{
            NSFontAttributeName: font ?: [UIFont systemFontOfSize:18.0],
            NSForegroundColorAttributeName: textColor ?: [UIColor blackColor],
            NSParagraphStyleAttributeName: paragraphStyle
        };
        return [[NSAttributedString alloc] initWithString:htmlString attributes:attributes];
    }
    
    NSString *fontFamily = font.fontName ?: @"system-ui";
    CGFloat fontSize = font.pointSize;
    UIColor *safeColor = textColor ?: [UIColor blackColor];
    NSString *colorHex = [self hexStringFromColor:safeColor];
    
    NSString *alignmentString = @"center";
    switch (textAlignment) {
        case NSTextAlignmentLeft:
            alignmentString = @"left";
            break;
        case NSTextAlignmentRight:
            alignmentString = @"right";
            break;
        case NSTextAlignmentCenter:
            alignmentString = @"center";
            break;
        case NSTextAlignmentJustified:
            alignmentString = @"justify";
            break;
        default:
            alignmentString = @"left";
            break;
    }
    
    NSString *htmlWithStyle = [NSString stringWithFormat:@"<html><head><style>body{font-family:'%@';font-size:%.0fpx;color:%@;text-align:%@;margin:0;padding:0;}</style></head><body>%@</body></html>",
                               fontFamily, fontSize, colorHex, alignmentString, htmlString];
    
    NSData *data = [htmlWithStyle dataUsingEncoding:NSUTF8StringEncoding];
    
    @try {
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithData:data
                                                                                 options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                          NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                      documentAttributes:nil
                                                                                   error:nil];
        
        if (attributedString) {
            NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
            NSRange range = NSMakeRange(0, mutableAttributedString.length);
            
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.alignment = textAlignment;
            [mutableAttributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
            
            return mutableAttributedString;
        }
    } @catch (NSException *exception) {
        [CPLog error:@"Error converting HTML to attributed string: %@", exception];
    }
    
    
    return [[NSAttributedString alloc] initWithString:htmlString];
}

@end
