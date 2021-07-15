#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "CPUtils.h"

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
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
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
-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)anError {
    error = anError;
    done = YES;
    
    [outputHandle closeFile];
}

#pragma mark - completion call back
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)anError {
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
        
        /*
         NSArray* cachedFiles = [[NSUserDefaults standardUserDefaults] objectForKey:@"CACHED_MEDIA"];
         NSMutableArray* appendedCache;
         if (cachedFiles) {
         appendedCache = [[NSMutableArray alloc] initWithArray:cachedFiles];
         [appendedCache addObject:name];
         } else {
         appendedCache = [[NSMutableArray alloc] initWithObjects:name, nil];
         }
         
         [[NSUserDefaults standardUserDefaults] setObject:appendedCache forKey:@"CACHED_MEDIA"];
         [[NSUserDefaults standardUserDefaults] synchronize];
         */
        
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
    if (fontFamily == nil) {
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

+ (void)openSafari:(NSURL*)URL dismissViewController:(UIViewController*)controller {
    [controller dismissViewControllerAnimated:YES completion:^{
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"CleverPush_APP_BANNER_VISIBLE"];
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

@end
