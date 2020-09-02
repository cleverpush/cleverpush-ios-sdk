#import <Foundation/Foundation.h>

#import "CleverPushUtils.h"

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

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [outputHandle writeData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)aResponse completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    response = aResponse;
    long long expectedLength = response.expectedContentLength;
    if (expectedLength > 50000000) {
        completionHandler(NSURLSessionResponseCancel);
        return;
    }
    completionHandler(NSURLSessionResponseAllow);
}

-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)anError {
    error = anError;
    done = YES;
    
    [outputHandle closeFile];
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)anError {
    done = YES;
    error = anError;
    [outputHandle closeFile];
}

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

@implementation CleverPushUtils

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

@end

